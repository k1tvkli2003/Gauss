package com.gauss.app.data

data class TopicDef(
    val key: String,
    val faLabel: String,
    val order: Int,
    val subject: Subject,
)

/** Canonical comprehensive taxonomy from the two Nardebam 1405 books. */
object ComprehensiveTaxonomy {
    private fun topic(subject: Subject, order: Int, key: String, label: String) =
        TopicDef(key, label, order, subject)

    val topics: List<TopicDef> = listOf(
        topic(Subject.MATH, 1, "sets", "مجموعه‌ها"),
        topic(Subject.MATH, 2, "patterns_sequences", "الگو و دنباله"),
        topic(Subject.MATH, 3, "quadratic_equations_functions", "معادله و تابع درجه دوم"),
        topic(Subject.MATH, 4, "rational_inequalities_sign", "نامعادلات گویا و تعیین علامت"),
        topic(Subject.MATH, 5, "radicals_algebraic_expressions", "ریشه‌گیری و عبارت‌های جبری"),
        topic(Subject.MATH, 6, "absolute_value_floor", "قدر مطلق و جزء صحیح"),
        topic(Subject.MATH, 7, "functions", "تابع"),
        topic(Subject.MATH, 8, "trigonometry", "مثلثات"),
        topic(Subject.MATH, 9, "limits_continuity", "حد و پیوستگی"),
        topic(Subject.MATH, 10, "derivatives", "مشتق"),
        topic(Subject.MATH, 11, "derivative_applications", "کاربرد مشتق"),
        topic(Subject.MATH, 12, "exponential_logarithmic", "توابع نمایی و لگاریتم"),
        topic(Subject.MATH, 13, "analytic_geometry", "هندسه تحلیلی"),
        topic(Subject.MATH, 14, "visual_thinking_conics", "تفکر تجسمی و مقاطع مخروطی"),
        topic(Subject.MATH, 15, "combinatorics", "ترکیبیات"),
        topic(Subject.MATH, 16, "probability", "احتمال"),
        topic(Subject.MATH, 17, "geometry", "هندسه"),
        topic(Subject.MATH, 18, "statistics", "آمار"),
        topic(Subject.PHYSICS, 1, "physics_measurement", "فیزیک و اندازه‌گیری"),
        topic(Subject.PHYSICS, 2, "physical_properties_matter", "ویژگی‌های فیزیکی مواد"),
        topic(Subject.PHYSICS, 3, "work_energy_power", "کار، انرژی و توان"),
        topic(Subject.PHYSICS, 4, "temperature_heat", "دما و گرما"),
        topic(Subject.PHYSICS, 5, "electrostatics", "الکتریسیته ساکن"),
        topic(Subject.PHYSICS, 6, "current_electricity", "جریان الکتریکی و مدارهای جریان مستقیم"),
        topic(Subject.PHYSICS, 7, "magnetism_induction", "مغناطیس و القای الکترومغناطیسی"),
        topic(Subject.PHYSICS, 8, "one_dimensional_motion", "حرکت بر خط راست"),
        topic(Subject.PHYSICS, 9, "dynamics", "دینامیک"),
        topic(Subject.PHYSICS, 10, "oscillation_waves", "نوسان و امواج"),
        topic(Subject.PHYSICS, 11, "atomic_nuclear", "آشنایی با فیزیک اتمی و هسته‌ای"),
    )

    private val byKey = topics.associateBy { it.key }

    fun topicsFor(subject: Subject): List<TopicDef> = topics.filter { it.subject == subject }

    fun topic(key: String?): TopicDef? = key?.let(byKey::get)

    fun label(key: String?): String = topic(key)?.faLabel ?: key.orEmpty()

    fun isValid(subject: Subject, key: String?): Boolean = topic(key)?.subject == subject
}
