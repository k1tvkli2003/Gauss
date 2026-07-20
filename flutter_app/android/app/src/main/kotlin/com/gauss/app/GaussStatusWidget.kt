package com.gauss.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/**
 * A calm home-screen reading of today's study.
 *
 * It only ever mirrors what the app already recorded — charted today and
 * how many concepts are due — and never nags: no streak, no countdown, no
 * red badge. Values are written by the Flutter side into shared preferences
 * and read here, so the widget works with the app closed and needs no
 * background service.
 */
class GaussStatusWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { widgetId ->
            appWidgetManager.updateAppWidget(widgetId, buildViews(context))
        }
    }

    private fun buildViews(context: Context): RemoteViews {
        val preferences =
            context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
        val chartedToday = preferences.getInt(KEY_CHARTED_TODAY, 0)
        val due = preferences.getInt(KEY_DUE, 0)

        return RemoteViews(context.packageName, R.layout.gauss_status_widget).apply {
            setTextViewText(R.id.widget_charted_value, chartedToday.toString())
            setTextViewText(
                R.id.widget_due_value,
                if (due == 0) "—" else due.toString(),
            )
            setTextViewText(
                R.id.widget_due_label,
                if (due == 1) "CONCEPT DUE" else "CONCEPTS DUE",
            )

            val launch = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { flags = Intent.FLAG_ACTIVITY_NEW_TASK }
            if (launch != null) {
                setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(
                        context,
                        0,
                        launch,
                        PendingIntent.FLAG_IMMUTABLE or
                            PendingIntent.FLAG_UPDATE_CURRENT,
                    ),
                )
            }
        }
    }

    companion object {
        const val PREFERENCES_NAME = "gauss_widget_status"
        const val KEY_CHARTED_TODAY = "charted_today"
        const val KEY_DUE = "due"

        /** Redraws every placed widget after the app records new progress. */
        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                android.content.ComponentName(context, GaussStatusWidget::class.java),
            )
            if (ids.isEmpty()) return
            val provider = GaussStatusWidget()
            provider.onUpdate(context, manager, ids)
        }
    }
}
