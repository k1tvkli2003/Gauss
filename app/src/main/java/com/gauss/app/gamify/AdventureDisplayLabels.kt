package com.gauss.app.gamify

import com.gauss.app.data.Subject

object AdventureDisplayLabels {
    private val mathLabels = linkedMapOf(
        "sets" to "Sets",
        "patterns_sequences" to "Patterns & Sequences",
        "quadratic_equations_functions" to "Algebra Grove",
        "rational_inequalities_sign" to "Rational Inequalities",
        "radicals_algebraic_expressions" to "Radicals & Expressions",
        "absolute_value_floor" to "Absolute Value & Floor",
        "functions" to "Functions",
        "trigonometry" to "Trigonometry",
        "limits_continuity" to "Limits",
        "derivatives" to "Calculus",
        "derivative_applications" to "Derivative Applications",
        "exponential_logarithmic" to "Exponential & Logarithmic",
        "analytic_geometry" to "Analytic Geometry",
        "visual_thinking_conics" to "Conics",
        "combinatorics" to "Combinatorics",
        "probability" to "Probability",
        "geometry" to "Geometry",
        "statistics" to "Statistics",
    )

    private val physicsLabels = linkedMapOf(
        "physics_measurement" to "Physics Measurement",
        "physical_properties_matter" to "Matter Properties",
        "work_energy_power" to "Work & Energy",
        "temperature_heat" to "Heat",
        "electrostatics" to "Electrostatics",
        "current_electricity" to "Circuits",
        "magnetism_induction" to "Electromagnetism",
        "one_dimensional_motion" to "Kinematics",
        "dynamics" to "Mechanics",
        "oscillation_waves" to "Waves",
        "atomic_nuclear" to "Atomic & Nuclear",
    )

    val allTopicLabels: Map<String, String> = mathLabels + physicsLabels

    fun roadName(subject: Subject): String =
        when (subject) {
            Subject.MATH -> "Math Road"
            Subject.PHYSICS -> "Physics Road"
        }

    fun stageName(subject: Subject, topicKey: String?): String =
        topicLabel(topicKey) ?: when (subject) {
            Subject.MATH -> "Algebra Grove"
            Subject.PHYSICS -> "Physics Workshop"
        }

    fun topicLabel(topicKey: String?): String? = topicKey?.let(allTopicLabels::get)

    fun topicLabelOrFallback(topicKey: String?): String =
        topicLabel(topicKey) ?: topicKey.orEmpty()
            .split('_')
            .filter { it.isNotBlank() && it != "physics" }
            .joinToString(" ") { word -> word.replaceFirstChar { it.uppercaseChar() } }

    fun labelsFor(subject: Subject): Map<String, String> =
        when (subject) {
            Subject.MATH -> mathLabels
            Subject.PHYSICS -> physicsLabels
        }
}
