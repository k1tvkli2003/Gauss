package com.gauss.app

import android.app.Application
import android.content.Context
import com.gauss.app.data.HistoryRepository
import com.gauss.app.data.QuestionBank
import com.gauss.app.data.db.GaussDatabase

/** Tiny service locator — no DI framework needed for an app this size. */
class GaussApp : Application() {

    val history: HistoryRepository by lazy { HistoryRepository(GaussDatabase.get(this)) }

    /** Loads (and caches) the bundled question bank off the main thread. */
    suspend fun questionBank(): QuestionBank = QuestionBank.get(this)

    companion object {
        fun from(context: Context): GaussApp = context.applicationContext as GaussApp
    }
}
