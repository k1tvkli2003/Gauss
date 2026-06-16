package com.gauss.app.data

data class SubCategoryDef(val key: String, val faLabel: String)
data class CategoryDef(val key: String, val faLabel: String, val subCategories: List<SubCategoryDef>)

/** Iranian high-school curriculum tree (Dovvom-e Motevaseteh, grades 10–12). */
object Categories {
    val tree: Map<Subject, List<CategoryDef>> = mapOf(
        Subject.MATH to listOf(
            CategoryDef(
                "hesaban", "حسابان",
                listOf(
                    SubCategoryDef("limits", "حد و پیوستگی"),
                    SubCategoryDef("derivatives", "مشتق"),
                    SubCategoryDef("integrals", "انتگرال"),
                    SubCategoryDef("functions", "توابع"),
                    SubCategoryDef("trigonometry", "مثلثات"),
                ),
            ),
            CategoryDef(
                "hendeseh", "هندسه",
                listOf(
                    SubCategoryDef("analytical", "هندسه تحلیلی"),
                    SubCategoryDef("spatial", "هندسه فضایی"),
                    SubCategoryDef("circle", "دایره"),
                    SubCategoryDef("conics", "مقاطع مخروطی"),
                ),
            ),
            CategoryDef(
                "gosasteh_amar", "گسسته و آمار",
                listOf(
                    SubCategoryDef("discrete", "ریاضیات گسسته"),
                    SubCategoryDef("combinatorics", "ترکیبیات"),
                    SubCategoryDef("probability", "احتمال"),
                    SubCategoryDef("statistics", "آمار"),
                    SubCategoryDef("number_theory", "نظریه اعداد"),
                ),
            ),
        ),
        Subject.PHYSICS to listOf(
            CategoryDef(
                "mechanics", "مکانیک",
                listOf(
                    SubCategoryDef("kinematics", "سینماتیک"),
                    SubCategoryDef("dynamics", "دینامیک"),
                    SubCategoryDef("work_energy", "کار و انرژی"),
                    SubCategoryDef("momentum", "تکانه"),
                ),
            ),
            CategoryDef(
                "electromagnetism", "الکترومغناطیس",
                listOf(
                    SubCategoryDef("electrostatics", "الکتروستاتیک"),
                    SubCategoryDef("circuits", "مدارها"),
                    SubCategoryDef("magnetism", "مغناطیس"),
                    SubCategoryDef("induction", "القا"),
                ),
            ),
            CategoryDef(
                "thermodynamics", "ترمودینامیک و سیالات",
                listOf(
                    SubCategoryDef("heat", "گرما و دما"),
                    SubCategoryDef("gas_laws", "قوانین گازها"),
                    SubCategoryDef("fluids", "سیالات"),
                ),
            ),
            CategoryDef(
                "waves_modern", "موج و فیزیک نوین",
                listOf(
                    SubCategoryDef("oscillations", "نوسان"),
                    SubCategoryDef("waves", "امواج"),
                    SubCategoryDef("optics", "نور"),
                    SubCategoryDef("modern", "فیزیک اتمی و نوین"),
                ),
            ),
        ),
    )

    fun label(subject: Subject, key: String): String =
        tree[subject]?.firstOrNull { it.key == key }?.faLabel ?: key
}
