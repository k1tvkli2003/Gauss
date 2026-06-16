package com.gauss.app.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.json.JSONArray

/**
 * The bundled, offline question bank. Parses `assets/questions.json` once and
 * keeps it in memory (~4k questions). All exam selection happens locally — no
 * network, instant results.
 */
class QuestionBank private constructor(private val all: List<Question>) {

    private val byId: Map<String, Question> = all.associateBy { it.id }

    /** Randomized selection matching a config (empty filter lists mean "all"). */
    fun selectExam(config: ExamConfig): List<Question> {
        val pool = all.filter { q ->
            q.subject == config.subject &&
                (config.categories.isEmpty() || q.category in config.categories) &&
                (config.subCategories.isEmpty() || q.subCategory in config.subCategories) &&
                (config.difficulties.isEmpty() || q.difficulty in config.difficulties)
        }
        return pool.shuffled().take(config.count)
    }

    fun byIds(ids: List<String>): List<Question> = ids.mapNotNull { byId[it] }

    /** Question count per top-level category, used to validate the setup screen. */
    fun availability(subject: Subject): Map<String, Int> =
        all.filter { it.subject == subject }.groupingBy { it.category }.eachCount()

    fun totalFor(subject: Subject): Int = all.count { it.subject == subject }

    companion object {
        @Volatile
        private var instance: QuestionBank? = null

        suspend fun get(context: Context): QuestionBank {
            instance?.let { return it }
            return withContext(Dispatchers.IO) {
                synchronized(this) {
                    instance ?: load(context.applicationContext).also { instance = it }
                }
            }
        }

        private fun load(context: Context): QuestionBank {
            val text = context.assets.open("questions.json")
                .bufferedReader().use { it.readText() }
            val arr = JSONArray(text)
            val list = ArrayList<Question>(arr.length())
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                list.add(
                    Question(
                        id = o.getString("id"),
                        subject = Subject.from(o.getString("subject")),
                        category = o.getString("category"),
                        subCategory = o.optStringOrNull("sub_category"),
                        difficulty = Difficulty.from(o.getString("difficulty")),
                        questionText = o.getString("question_text"),
                        imageUrl = o.optStringOrNull("image_url"),
                        options = listOf(
                            o.getString("option_1"),
                            o.getString("option_2"),
                            o.getString("option_3"),
                            o.getString("option_4"),
                        ),
                        correctOptionIndex = o.getInt("correct_option_index"),
                        classicSolution = o.getString("classic_solution"),
                        smartShortcut = o.optStringOrNull("smart_shortcut"),
                        source = o.optString("source", "seed"),
                    ),
                )
            }
            return QuestionBank(list)
        }

        private fun org.json.JSONObject.optStringOrNull(key: String): String? =
            if (isNull(key)) null else optString(key, "").ifEmpty { null }
    }
}
