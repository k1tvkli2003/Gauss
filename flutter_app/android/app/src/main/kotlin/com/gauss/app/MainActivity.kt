package com.gauss.app

import android.content.Context
import android.os.Build
import android.view.MotionEvent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var stylusInputChannel: MethodChannel? = null

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
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        stylusInputChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
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
    }
}
