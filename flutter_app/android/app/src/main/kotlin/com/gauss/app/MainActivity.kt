package com.gauss.app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

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
    }

    private companion object {
        const val STATUS_CHANNEL = "com.gauss.app/status_widget"
    }
}
