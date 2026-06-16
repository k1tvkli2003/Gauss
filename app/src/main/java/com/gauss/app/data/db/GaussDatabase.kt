package com.gauss.app.data.db

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase

@Database(
    entities = [ExamEntity::class, AttemptEntity::class, SrsEntity::class],
    version = 1,
    exportSchema = false,
)
abstract class GaussDatabase : RoomDatabase() {
    abstract fun dao(): GaussDao

    companion object {
        @Volatile
        private var instance: GaussDatabase? = null

        fun get(context: Context): GaussDatabase =
            instance ?: synchronized(this) {
                instance ?: Room.databaseBuilder(
                    context.applicationContext,
                    GaussDatabase::class.java,
                    "gauss.db",
                ).build().also { instance = it }
            }
    }
}
