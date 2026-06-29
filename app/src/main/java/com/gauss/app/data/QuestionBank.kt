package com.gauss.app.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.json.JSONArray
import org.json.JSONObject

private data class TopicShard(
    val subject: Subject,
    val topicKey: String,
    val file: String,
    val count: Int,
)

/** Sharded offline question bank. Topic JSON is parsed only when requested. */
class QuestionBank private constructor(
    private val context: Context,
    private val shards: List<TopicShard>,
    private val aliases: Map<String, String>,
) {
    private val cache = HashMap<String, List<Question>>()
    private val cacheMutex = Mutex()

    suspend fun selectExam(config: ExamConfig): List<Question> {
        val keys = config.topicKeys.ifEmpty {
            shards.filter { it.subject == config.subject }.map { it.topicKey }
        }
        val pool = keys.distinct().flatMap { loadTopic(it) }.filter { question ->
            question.subject == config.subject &&
                (config.sourceBanks.isEmpty() || question.sourceBank in config.sourceBanks) &&
                (config.difficulties.isEmpty() || question.difficulty in config.difficulties)
        }
        return pool.shuffled().take(config.count)
    }

    suspend fun byIds(ids: List<String>): List<Question> {
        if (ids.isEmpty()) return emptyList()
        val wanted = ids.map { aliases[it] ?: it }.toSet()
        val found = HashMap<String, Question>()
        for (shard in shards) {
            loadTopic(shard.topicKey).forEach { if (it.id in wanted) found[it.id] = it }
            if (found.size == wanted.size) break
        }
        return ids.mapNotNull { id -> found[aliases[id] ?: id] }
    }

    fun topicAvailability(subject: Subject): Map<String, Int> =
        shards.filter { it.subject == subject }.associate { it.topicKey to it.count }

    fun totalFor(subject: Subject): Int = shards.filter { it.subject == subject }.sumOf { it.count }

    private suspend fun loadTopic(topicKey: String): List<Question> = cacheMutex.withLock {
        cache[topicKey]?.let { return@withLock it }
        val shard = shards.firstOrNull { it.topicKey == topicKey } ?: return@withLock emptyList()
        withContext(Dispatchers.IO) {
            val text = context.assets.open(shard.file).bufferedReader().use { it.readText() }
            val array = JSONArray(text)
            List(array.length()) { index -> parseQuestion(array.getJSONObject(index)) }
        }.also { cache[topicKey] = it }
    }

    companion object {
        @Volatile private var instance: QuestionBank? = null

        suspend fun get(context: Context): QuestionBank {
            instance?.let { return it }
            return withContext(Dispatchers.IO) {
                synchronized(this) {
                    instance ?: loadIndex(context.applicationContext).also { instance = it }
                }
            }
        }

        private fun loadIndex(context: Context): QuestionBank {
            val root = JSONObject(context.assets.open("question_bank/index.json").bufferedReader().use { it.readText() })
            val entries = root.getJSONArray("topics")
            val shards = List(entries.length()) { index ->
                val item = entries.getJSONObject(index)
                TopicShard(
                    subject = Subject.from(item.getString("subject")),
                    topicKey = item.getString("topic_key"),
                    file = item.getString("file"),
                    count = item.getInt("count"),
                )
            }
            val aliasesObject = root.optJSONObject("aliases")
            val aliases = aliasesObject?.keys()?.asSequence()?.associateWith { aliasesObject.getString(it) }.orEmpty()
            return QuestionBank(context, shards, aliases)
        }

        private fun parseQuestion(source: JSONObject): Question = Question(
            id = source.getString("id"),
            subject = Subject.from(source.getString("subject")),
            topicKey = source.getString("topic_key"),
            difficulty = Difficulty.from(source.getString("difficulty")),
            stem = parseContent(source.getJSONArray("stem")),
            optionBlocks = source.getJSONArray("options").let { options ->
                List(options.length()) { parseContent(options.getJSONArray(it)) }
            },
            correctOptionIndex = source.getInt("correct_option_index"),
            solution = parseContent(source.getJSONArray("solution")),
            shortcut = source.optJSONArray("smart_shortcut")?.let(::parseContent),
            sourceBank = SourceBank.from(source.optString("source_bank", "gauss")),
            provenance = source.getJSONObject("provenance").let { provenance ->
                QuestionProvenance(
                    kind = provenance.getString("kind"),
                    edition = provenance.getString("edition"),
                    questionNumber = provenance.optIntOrNull("question_number"),
                    questionPdf = provenance.optStringOrNull("question_pdf"),
                    questionPage = provenance.optIntOrNull("question_page"),
                    solutionPage = provenance.optIntOrNull("solution_page"),
                    solutionOrigin = provenance.optString("solution_origin", "existing"),
                )
            },
        )

        private fun parseContent(array: JSONArray): List<ContentBlock> = List(array.length()) { index ->
            val block = array.getJSONObject(index)
            when (block.getString("type")) {
                "image" -> ContentBlock.Image(
                    asset = block.getString("asset"),
                    alt = block.optString("alt", ""),
                    aspectRatio = if (block.has("aspect_ratio")) block.getDouble("aspect_ratio").toFloat() else null,
                )
                else -> ContentBlock.Text(block.getString("text"))
            }
        }

        private fun JSONObject.optStringOrNull(key: String): String? =
            if (isNull(key)) null else optString(key, "").ifEmpty { null }

        private fun JSONObject.optIntOrNull(key: String): Int? =
            if (isNull(key) || !has(key)) null else getInt(key)
    }
}
