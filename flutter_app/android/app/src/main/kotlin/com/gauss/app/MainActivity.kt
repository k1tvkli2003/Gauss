package com.gauss.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private var stylusInputChannel: MethodChannel? = null
    private var pendingFeedbackExport: PendingFeedbackExport? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STATUS_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "publishStatus" -> {
                    val charted = call.argument<Int>("chartedToday") ?: 0
                    val due = call.argument<Int>("due") ?: 0
                    getSharedPreferences(
                        GaussStatusWidget.PREFERENCES_NAME,
                        Context.MODE_PRIVATE,
                    ).edit()
                        .putInt(GaussStatusWidget.KEY_CHARTED_TODAY, charted)
                        .putInt(GaussStatusWidget.KEY_DUE, due)
                        .apply()
                    GaussStatusWidget.refreshAll(applicationContext)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        stylusInputChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            STYLUS_INPUT_CHANNEL,
        )
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FEEDBACK_EXPORT_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveArchive" -> beginFeedbackExport(
                    sourcePath = call.argument<String>("sourcePath"),
                    fileName = call.argument<String>("fileName"),
                    result = result,
                )
                else -> result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        pendingFeedbackExport?.result?.error(
            "engine_detached",
            "The feedback export was interrupted.",
            null,
        )
        pendingFeedbackExport = null
        stylusInputChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }

    private fun beginFeedbackExport(
        sourcePath: String?,
        fileName: String?,
        result: MethodChannel.Result,
    ) {
        if (pendingFeedbackExport != null) {
            result.error(
                "export_in_progress",
                "Another feedback export is already open.",
                null,
            )
            return
        }
        if (sourcePath == null || fileName == null ||
            !SAFE_FEEDBACK_FILE_NAME.matches(fileName)
        ) {
            result.error("invalid_export", "Invalid feedback export request.", null)
            return
        }
        val source = try {
            File(sourcePath).canonicalFile
        } catch (_: Exception) {
            result.error("invalid_export", "Invalid feedback export source.", null)
            return
        }
        val privateCache = cacheDir.canonicalFile
        val insidePrivateCache = source.path.startsWith(
            privateCache.path + File.separator,
        )
        if (!insidePrivateCache || !source.isFile ||
            source.length() <= 0L || source.length() > MAX_FEEDBACK_EXPORT_BYTES
        ) {
            result.error(
                "invalid_export",
                "Feedback export escaped its private staging boundary.",
                null,
            )
            return
        }
        pendingFeedbackExport = PendingFeedbackExport(
            source = source,
            fileName = fileName,
            result = result,
        )
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/zip"
            putExtra(Intent.EXTRA_TITLE, fileName)
        }
        try {
            startActivityForResult(intent, FEEDBACK_EXPORT_REQUEST_CODE)
        } catch (_: Exception) {
            pendingFeedbackExport = null
            result.error(
                "document_picker_unavailable",
                "Android could not open a save location.",
                null,
            )
        }
    }

    @Deprecated("Deprecated in Android; retained for FlutterActivity result delivery.")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != FEEDBACK_EXPORT_REQUEST_CODE) {
            super.onActivityResult(requestCode, resultCode, data)
            return
        }
        val pending = pendingFeedbackExport
        pendingFeedbackExport = null
        if (pending == null) return
        if (resultCode != Activity.RESULT_OK) {
            pending.result.success(mapOf("status" to "cancelled"))
            return
        }
        val destination = data?.data
        if (destination == null) {
            pending.result.error(
                "missing_destination",
                "Android returned no feedback export destination.",
                null,
            )
            return
        }
        Thread {
            try {
                contentResolver.openOutputStream(destination, "w").use { output ->
                    requireNotNull(output) { "Destination stream is unavailable." }
                    pending.source.inputStream().use { input ->
                        input.copyTo(output)
                        output.flush()
                    }
                }
                runOnUiThread {
                    pending.result.success(
                        mapOf(
                            "status" to "saved",
                            "fileName" to pending.fileName,
                        ),
                    )
                }
            } catch (_: Exception) {
                runOnUiThread {
                    pending.result.error(
                        "feedback_export_failed",
                        "The feedback archive could not be saved.",
                        null,
                    )
                }
            }
        }.start()
    }

    override fun dispatchTouchEvent(event: MotionEvent): Boolean {
        // Android 13+ may finish a rejected palm with ACTION_POINTER_UP and
        // FLAG_CANCELED instead of delivering a Flutter PointerCancelEvent.
        // ACTION_CANCEL itself already reaches Flutter and is intentionally
        // not duplicated here, otherwise an earlier valid touch stroke could
        // be removed after the active stroke has already rolled back.
        if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            event.actionMasked == MotionEvent.ACTION_POINTER_UP &&
            event.flags and MotionEvent.FLAG_CANCELED != 0
        ) {
            val index = event.actionIndex.coerceIn(0, event.pointerCount - 1)
            if (event.getToolType(index) == MotionEvent.TOOL_TYPE_FINGER) {
                stylusInputChannel?.invokeMethod(
                    "palmRejected",
                    mapOf(
                        "pointerId" to event.getPointerId(index),
                        "eventTime" to event.eventTime,
                    ),
                )
            }
        }
        return super.dispatchTouchEvent(event)
    }

    private companion object {
        const val STATUS_CHANNEL = "com.gauss.app/status_widget"
        const val STYLUS_INPUT_CHANNEL = "com.gauss.app/stylus_input"
        const val FEEDBACK_EXPORT_CHANNEL = "com.gauss.app/feedback_export"
        const val FEEDBACK_EXPORT_REQUEST_CODE = 7401
        const val MAX_FEEDBACK_EXPORT_BYTES = 128L * 1024L * 1024L
        val SAFE_FEEDBACK_FILE_NAME =
            Regex("^gauss-feedback-[A-Za-z0-9._-]+\\.zip$")
    }

    private data class PendingFeedbackExport(
        val source: File,
        val fileName: String,
        val result: MethodChannel.Result,
    )
}
