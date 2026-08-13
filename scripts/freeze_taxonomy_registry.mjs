import fs from "node:fs";
import path from "node:path";

const root = process.cwd();
const certificationRoot = path.join(root, "data", "certification", "v1");
const taxonomyFile = path.join(certificationRoot, "taxonomy.json");
const manifestFile = path.join(certificationRoot, "manifest.jsonl");
const registryVersion = "gauss-taxonomy-v1";

const d = (
  key,
  label_en,
  label_fa,
  aliases,
  concept_tags,
  prerequisites = [],
) => ({ key, label_en, label_fa, aliases, concept_tags, prerequisites });

// This catalog is deliberately curriculum-sized. Screening proposals remain
// immutable evidence; these registered clusters are the stable runtime IDs
// used to build coherent five-question micro-lessons.
const catalog = {
  sets: [
    d("sets_membership_notation", "Membership and set notation", "عضویت و نمادگذاری مجموعه", ["membership", "element_vs_subset", "nested_sets", "empty_set", "set_notation", "عضویت", "زیرمجموعه"], ["set_membership", "subset_relation", "set_notation"]),
    d("sets_operations_identities", "Set operations and identities", "عملیات و اتحادهای مجموعه", ["set_operations", "set_identity", "union_intersection", "set_difference", "set_complement", "de_morgan", "disjoint_sets", "symmetric_difference"], ["union_intersection", "set_difference", "set_complement"]),
    d("sets_finite_infinite_cardinality", "Finite, infinite, and cardinality", "مجموعه‌های متناهی، نامتناهی و شمارش", ["finite_sets", "infinite_sets", "cardinality", "set_cardinality", "nested_cardinality"], ["finite_infinite_sets", "cardinality"], ["set_membership"]),
    d("sets_intervals_number_line", "Intervals and the number line", "بازه‌ها و محور اعداد", ["interval", "open_intervals", "closed_intervals", "interval_membership", "interval_intersection", "interval_union", "endpoint_ordering", "number_line", "parameterized_interval"], ["interval_notation", "interval_operations", "number_line"]),
    d("sets_venn_diagrams", "Venn diagrams", "نمودارهای ون", ["venn", "visual_set_representation", "shaded_region", "set_region"], ["venn_diagram", "set_operations"], ["set_operations"]),
    d("sets_inclusion_exclusion", "Inclusion-exclusion problems", "مسائل اصل شمول و عدم شمول", ["inclusion_exclusion", "survey", "only_one", "at_least_two", "word_problem", "two_set_counting", "three_set_counting"], ["inclusion_exclusion", "cardinality_modeling"], ["cardinality"]),
    d("sets_relations_and_proofs", "Set relations and logical claims", "روابط و گزاره‌های مجموعه", ["set_relation", "counterexample", "always_true", "logical_claim", "inclusion", "disjointness", "set_algebra_under"], ["set_relations", "logical_reasoning"], ["set_operations"]),
  ],
  patterns_sequences: [
    d("patterns_sequences_arithmetic", "Arithmetic sequences", "دنباله‌های حسابی", ["arithmetic_sequence", "common_difference", "linear_sequence", "arithmetic_progression"], ["arithmetic_sequence", "general_term"], ["linear_equations"]),
    d("patterns_sequences_geometric", "Geometric sequences", "دنباله‌های هندسی", ["geometric_sequence", "common_ratio", "geometric_progression"], ["geometric_sequence", "general_term"], ["exponents"]),
    d("patterns_sequences_recursive", "Recursive sequences", "دنباله‌های بازگشتی", ["recursive", "recurrence", "iteration", "successive_terms"], ["recursive_sequence", "term_generation"]),
    d("patterns_sequences_polynomial", "Polynomial sequences", "دنباله‌های چندجمله‌ای", ["quadratic_sequence", "polynomial_sequence", "finite_difference", "second_difference", "cubic_sequence"], ["finite_differences", "polynomial_general_term"], ["algebraic_expansion"]),
    d("patterns_sequences_series_sums", "Series and partial sums", "سری‌ها و مجموع جملات", ["series", "partial_sum", "sum_of_terms", "sigma", "arithmetic_series", "geometric_series"], ["series_sum", "partial_sums"], ["sequence_general_term"]),
    d("patterns_sequences_telescoping", "Telescoping patterns", "الگوهای تلسکوپی", ["telescoping", "cancellation", "partial_fraction_series"], ["telescoping_sum", "algebraic_cancellation"], ["partial_fractions"]),
    d("patterns_sequences_visual", "Visual and counting patterns", "الگوهای تصویری و شمارشی", ["visual_pattern", "shape_pattern", "matchstick", "dot_pattern", "tile_pattern", "figure_n", "geometric_pattern"], ["visual_pattern", "counting_rule"], ["basic_counting"]),
    d("patterns_sequences_mixed_models", "Mixed sequence models", "مدل‌سازی ترکیبی دنباله", ["mixed_sequence", "alternating_sequence", "piecewise_sequence", "sequence_modeling", "parameter_sequence"], ["sequence_modeling", "pattern_recognition"], ["algebra"]),
  ],
  radicals_algebraic_expressions: [
    d("radicals_exponent_root_rules", "Exponent and root rules", "قواعد توان و ریشه", ["fractional_exponents", "nth_roots", "radical_rules", "exponent_rules", "root_properties"], ["fractional_exponents", "nth_roots"]),
    d("radicals_simplification", "Radical simplification", "ساده‌سازی عبارت‌های رادیکالی", ["radical_simplification", "like_radicals", "extracting_factors", "simplify_radical"], ["radical_simplification", "factor_extraction"], ["prime_factorization"]),
    d("radicals_rationalization", "Rationalizing expressions", "گویا کردن عبارت‌ها", ["rationalization", "rationalizing_denominator", "conjugate", "denominator_radical"], ["rationalization", "conjugates"], ["algebraic_identities"]),
    d("radicals_identities_factorization", "Algebraic identities and factorization", "اتحادها و تجزیهٔ جبری", ["difference_of_squares", "difference_of_cubes", "sum_of_cubes", "factorization", "algebraic_identity", "factor_theorem", "polynomial_remainder"], ["algebraic_identities", "factorization"]),
    d("radicals_equations", "Radical equations", "معادلات رادیکالی", ["radical_equation", "extraneous_root", "squaring_both_sides", "root_equation"], ["radical_equations", "extraneous_solutions"], ["equation_solving"]),
    d("radicals_symmetric_nested", "Symmetric and nested expressions", "عبارت‌های متقارن و تودرتو", ["symmetric_expression", "nested_radical", "reciprocal_relation", "cyclic_expression"], ["symmetric_expressions", "nested_radicals"], ["algebraic_identities"]),
    d("radicals_domain_comparison", "Domains and radical comparisons", "دامنه و مقایسهٔ رادیکال‌ها", ["radical_domain", "domain_restriction", "compare_radicals", "radical_inequality", "ordering_radicals"], ["radical_domain", "radical_comparison"], ["inequalities"]),
  ],
  absolute_value_floor: [
    d("absolute_value_floor_abs_basics", "Absolute-value foundations", "مبانی قدر مطلق", ["absolute_value", "absolute_value_definition", "distance_from_zero", "piecewise_absolute"], ["absolute_value_definition", "distance_interpretation"]),
    d("absolute_value_floor_abs_equations", "Absolute-value equations", "معادلات قدر مطلق", ["absolute_value_equation", "nested_absolute_equation", "equation_with_absolute", "piecewise_equation", "distance_equation", "quadratic_equation", "number_of_roots"], ["absolute_value_equations", "case_analysis"], ["linear_equations"]),
    d("absolute_value_floor_abs_inequalities", "Absolute-value inequalities", "نامعادلات قدر مطلق", ["absolute_value_inequality", "piecewise_inequality", "distance_inequality", "sum_inequality", "rational_inequality", "integer_inequality", "compound_absolute_inequality"], ["absolute_value_inequalities", "interval_solution"], ["inequalities"]),
    d("absolute_value_floor_abs_graphs", "Absolute-value graphs", "نمودارهای قدر مطلق", ["absolute_value_graph", "piecewise_graph", "graph_transformation", "graph_translation", "graph_area", "enclosed_area", "graph_intersection", "vertex_of_absolute"], ["absolute_value_graphs", "graph_transformations"], ["coordinate_plane"]),
    d("absolute_value_floor_abs_parameters", "Parameterized absolute value", "قدر مطلق پارامتری", ["absolute_value_parameter", "parameterized_absolute", "root_count_parameter", "minimum_absolute", "maximum_absolute"], ["absolute_value_parameters", "case_analysis"], ["absolute_value_equations"]),
    d("absolute_value_floor_floor_basics", "Floor-function foundations", "مبانی جزء صحیح", ["floor_function", "greatest_integer", "integer_part", "floor_properties", "fractional_part"], ["floor_function", "integer_part"]),
    d("absolute_value_floor_floor_equations", "Floor equations and inequalities", "معادلات و نامعادلات جزء صحیح", ["floor_equation", "floor_inequality", "integer_part_equation", "nested_floor", "floor_parameter"], ["floor_equations", "integer_intervals"], ["floor_function"]),
    d("absolute_value_floor_floor_graphs", "Floor graphs and discontinuities", "نمودار و ناپیوستگی جزء صحیح", ["floor_graph", "step_function", "floor_discontinuity", "floor_limit"], ["floor_graphs", "step_discontinuity"], ["floor_function"]),
    d("absolute_value_floor_mixed_piecewise", "Mixed piecewise problems", "مسائل ترکیبی و چندضابطه‌ای", ["absolute_value_and_floor", "mixed_absolute_floor", "piecewise_function", "case_partition"], ["piecewise_analysis", "case_partition"], ["absolute_value_definition", "floor_function"]),
  ],
  rational_inequalities_sign: [
    d("rational_sign_polynomial", "Polynomial sign analysis", "تعیین علامت چندجمله‌ای", ["polynomial_sign", "sign_analysis", "root_multiplicity", "quadratic_sign"], ["polynomial_sign", "root_multiplicity"], ["factorization"]),
    d("rational_sign_tables", "Sign tables", "جدول تعیین علامت", ["sign_table", "critical_points", "interval_sign", "factor_sign"], ["sign_table", "critical_points"], ["factorization"]),
    d("rational_sign_inequalities", "Rational inequalities", "نامعادلات گویا", ["rational_inequality", "fractional_inequality", "denominator_zero", "rational_sign"], ["rational_inequalities", "domain_exclusions"], ["sign_table"]),
    d("rational_sign_absolute", "Absolute-value inequalities", "نامعادلات قدر مطلق", ["absolute_value_inequality", "rational_absolute", "modulus_inequality"], ["absolute_value_inequalities", "interval_solution"], ["absolute_value_definition"]),
    d("rational_sign_parameters", "Parameterized sign problems", "تعیین علامت پارامتری", ["parameterized_inequality", "parameter_sign", "root_order_parameter", "number_of_integer_solutions"], ["parameter_inequalities", "root_ordering"], ["sign_table"]),
    d("rational_sign_domains_roots", "Domains, roots, and multiplicity", "دامنه، ریشه و مرتبهٔ ریشه", ["domain_restriction", "zeros_and_poles", "multiplicity", "undefined_points"], ["domain_restrictions", "zeros_and_poles"], ["factorization"]),
    d("rational_sign_graphical", "Graphical sign reasoning", "تحلیل نموداری علامت", ["graph_sign", "graphical_inequality", "above_below_axis", "intersection_sign"], ["graphical_sign", "interval_reasoning"], ["coordinate_graphs"]),
  ],
  quadratic_equations_functions: [
    d("quadratic_equations_solving", "Solving quadratic equations", "حل معادلات درجهٔ دوم", ["quadratic_equation", "factoring_quadratic", "completing_square", "quadratic_formula"], ["quadratic_equations", "equation_solving"], ["factorization"]),
    d("quadratic_discriminant_roots", "Discriminant and root conditions", "دلتا و شرایط ریشه‌ها", ["discriminant", "number_of_roots", "real_roots", "repeated_root", "root_condition"], ["discriminant", "root_conditions"], ["quadratic_equations"]),
    d("quadratic_vieta", "Vieta relations", "روابط ویتا", ["vieta", "sum_of_roots", "product_of_roots", "symmetric_roots", "root_expression"], ["vieta_relations", "symmetric_root_expressions"], ["quadratic_equations"]),
    d("quadratic_function_graph", "Quadratic functions and graphs", "تابع و نمودار درجهٔ دوم", ["quadratic_function", "parabola_graph", "axis_of_symmetry", "graph_intersection"], ["quadratic_functions", "parabola_graphs"], ["coordinate_plane"]),
    d("quadratic_vertex_range", "Vertex, extrema, and range", "رأس، اکسترمم و برد سهمی", ["vertex", "minimum_quadratic", "maximum_quadratic", "range_of_quadratic", "vertex_form"], ["quadratic_vertex", "quadratic_range"], ["quadratic_functions"]),
    d("quadratic_parameters", "Parameterized quadratics", "معادلات درجهٔ دوم پارامتری", ["quadratic_parameter", "parameter_root_condition", "common_root", "integer_roots", "root_location"], ["quadratic_parameters", "root_conditions"], ["discriminant"]),
    d("quadratic_radical_rational", "Quadratic-form radical and rational equations", "معادلات رادیکالی و گویای منتهی به درجهٔ دوم", ["radical_equation", "rational_equation", "substitution_quadratic", "extraneous_solution"], ["quadratic_substitution", "domain_check"], ["quadratic_equations"]),
    d("quadratic_models_systems", "Quadratic models and systems", "مدل‌سازی و دستگاه‌های درجهٔ دوم", ["quadratic_modeling", "quadratic_system", "word_problem", "intersection_system", "motion_quadratic"], ["quadratic_modeling", "systems_of_equations"], ["quadratic_equations"]),
    d("quadratic_inequalities", "Quadratic inequalities", "نامعادلات درجهٔ دوم", ["quadratic_inequality", "quadratic_sign", "parabola_inequality"], ["quadratic_inequalities", "sign_analysis"], ["quadratic_roots"]),
  ],
  functions: [
    d("functions_definition_evaluation", "Function definition and evaluation", "تعریف و محاسبهٔ مقدار تابع", ["function_definition", "function_evaluation", "input_output", "formula_value"], ["function_definition", "function_evaluation"]),
    d("functions_domain_range", "Domain and range", "دامنه و برد تابع", ["domain", "range", "natural_domain", "domain_restriction", "range_determination"], ["function_domain", "function_range"]),
    d("functions_graph_transformations", "Graphs and transformations", "نمودار و انتقال‌های تابع", ["function_graph", "graph_transformation", "translation", "reflection", "scaling", "graph_reading"], ["function_graphs", "graph_transformations"], ["coordinate_plane"]),
    d("functions_composition", "Function composition", "ترکیب توابع", ["composition", "composite_function", "f_of_g", "iterated_function"], ["function_composition", "domain_of_composition"], ["function_evaluation"]),
    d("functions_inverse", "Inverse functions", "تابع وارون", ["inverse_function", "inverse_relation", "f_inverse", "inverse_composition"], ["inverse_functions", "one_to_one"], ["function_composition"]),
    d("functions_injectivity_monotonicity", "One-to-one and monotonic functions", "یک‌به‌یکی و یکنوایی", ["one_to_one", "injective", "monotonic", "increasing_function", "decreasing_function"], ["injectivity", "monotonicity"], ["function_definition"]),
    d("functions_piecewise_floor", "Piecewise and floor functions", "توابع چندضابطه‌ای و جزء صحیح", ["piecewise_function", "floor_function", "greatest_integer", "piecewise_graph"], ["piecewise_functions", "floor_functions"], ["intervals"]),
    d("functions_functional_equations", "Functional equations", "معادلات تابعی", ["functional_equation", "function_identity", "unknown_function", "reciprocal_functional"], ["functional_equations", "algebraic_substitution"], ["function_evaluation"]),
    d("functions_finite_discrete", "Finite and discrete functions", "توابع متناهی و گسسته", ["finite_function", "mapping_diagram", "ordered_pairs", "discrete_function", "counting_functions"], ["finite_functions", "mapping_relations"], ["sets"]),
    d("functions_symmetry_periodicity", "Symmetry and periodicity", "تقارن و تناوب تابع", ["even_function", "odd_function", "periodic_function", "function_symmetry", "parity"], ["function_parity", "periodicity"], ["function_graphs"]),
  ],
  exponential_logarithmic: [
    d("exponential_log_exponent_rules", "Exponent rules and exponential functions", "قواعد توان و تابع نمایی", ["exponent_rules", "exponential_function", "power_properties", "exponential_growth"], ["exponent_rules", "exponential_functions"]),
    d("exponential_log_exponential_equations", "Exponential equations and inequalities", "معادلات و نامعادلات نمایی", ["exponential_equation", "exponential_inequality", "same_base", "exponential_substitution"], ["exponential_equations", "exponential_inequalities"], ["exponent_rules"]),
    d("exponential_log_log_rules", "Logarithm definitions and rules", "تعریف و قواعد لگاریتم", ["logarithm_definition", "product_rule", "quotient_rule", "power_rule", "log_properties"], ["logarithm_definition", "logarithm_rules"], ["exponents"]),
    d("exponential_log_log_equations", "Logarithmic equations and inequalities", "معادلات و نامعادلات لگاریتمی", ["logarithmic_equation", "logarithmic_inequality", "log_equation", "log_domain"], ["logarithmic_equations", "domain_restrictions"], ["logarithm_rules"]),
    d("exponential_log_graph_domain", "Graphs, domains, and ranges", "نمودار، دامنه و برد نمایی و لگاریتمی", ["log_graph", "exponential_graph", "log_domain", "range", "asymptote", "graph_transformation"], ["exp_log_graphs", "domain_range"], ["function_transformations"]),
    d("exponential_log_inverse_composition", "Inverse and composition relations", "وارون و ترکیب توابع نمایی و لگاریتمی", ["inverse_exponential_log", "inverse_function", "composition", "exp_log_inverse"], ["inverse_relation", "function_composition"], ["inverse_functions"]),
    d("exponential_log_change_base", "Change of base and common logs", "تغییر مبنا و لگاریتم دهدهی", ["change_of_base", "change_base", "common_log", "natural_log", "base_conversion"], ["change_of_base", "common_logarithms"], ["logarithm_rules"]),
    d("exponential_log_models_parameters", "Exponential-log models and parameters", "مدل‌سازی و مسائل پارامتری نمایی–لگاریتمی", ["exponential_model", "logarithmic_model", "growth_decay", "parameter", "equation_modeling"], ["exp_log_modeling", "parameter_analysis"], ["exp_log_equations"]),
  ],
  limits_continuity: [
    d("limits_laws_algebraic", "Limit laws and algebraic evaluation", "قوانین حد و محاسبهٔ جبری", ["limit_laws", "direct_substitution", "algebraic_limit", "finite_limit"], ["limit_laws", "algebraic_evaluation"]),
    d("limits_indeterminate_factorization", "Indeterminate forms and factorization", "رفع ابهام با تجزیه", ["indeterminate_form", "zero_over_zero", "factorization_limit", "common_factor"], ["indeterminate_forms", "factorization"]),
    d("limits_radicals", "Radical limits and rationalization", "حدهای رادیکالی و گویاکردن", ["radical_limit", "rationalization", "conjugate_limit", "nested_radical_limit"], ["radical_limits", "rationalization"], ["algebraic_identities"]),
    d("limits_one_sided_piecewise", "One-sided and piecewise limits", "حد یک‌طرفه و توابع چندضابطه‌ای", ["one_sided_limit", "left_hand_limit", "right_hand_limit", "piecewise_limit", "jump"], ["one_sided_limits", "piecewise_analysis"], ["function_graphs"]),
    d("limits_infinity_asymptotes", "Limits at infinity and asymptotes", "حد در بی‌نهایت و مجانب‌ها", ["limit_at_infinity", "infinite_limit", "vertical_asymptote", "horizontal_asymptote", "rational_infinity"], ["limits_at_infinity", "asymptotes"], ["rational_functions"]),
    d("limits_continuity", "Continuity and parameter matching", "پیوستگی و تعیین پارامتر", ["continuity", "continuous_function", "removable_discontinuity", "continuity_parameter"], ["continuity", "parameter_matching"], ["one_sided_limits"]),
    d("limits_floor_absolute", "Floor and absolute-value limits", "حد جزء صحیح و قدر مطلق", ["floor_limit", "greatest_integer_limit", "absolute_value_limit", "step_limit"], ["floor_limits", "absolute_value_limits"], ["one_sided_limits"]),
    d("limits_graphical", "Graphical limits", "حدهای نموداری", ["graphical_limit", "limit_from_graph", "graph_reading", "hole_graph"], ["graphical_limits", "one_sided_reading"], ["function_graphs"]),
    d("limits_trigonometric", "Trigonometric limits", "حدهای مثلثاتی", ["trigonometric_limit", "sin_x_over_x", "small_angle", "trig_indeterminate"], ["trigonometric_limits", "standard_limits"], ["trigonometric_identities"]),
  ],
  derivatives: [
    d("derivatives_definition_tangent", "Derivative definition and tangent", "تعریف مشتق و خط مماس", ["derivative_definition", "difference_quotient", "tangent_slope", "limit_definition"], ["derivative_definition", "tangent_slope"], ["limits"]),
    d("derivatives_basic_rules", "Basic derivative rules", "قواعد پایهٔ مشتق", ["power_rule", "constant_rule", "sum_rule", "basic_derivative"], ["basic_derivative_rules", "power_rule"]),
    d("derivatives_product_quotient_chain", "Product, quotient, and chain rules", "قواعد ضرب، تقسیم و زنجیره‌ای", ["product_rule", "quotient_rule", "chain_rule", "composite_derivative"], ["product_rule", "quotient_rule", "chain_rule"], ["basic_derivative_rules"]),
    d("derivatives_implicit_parametric", "Implicit and parametric differentiation", "مشتق‌گیری ضمنی و پارامتری", ["implicit_derivative", "parametric_derivative", "implicit_function"], ["implicit_differentiation", "parametric_differentiation"], ["chain_rule"]),
    d("derivatives_piecewise_one_sided", "Piecewise differentiability", "مشتق‌پذیری توابع چندضابطه‌ای", ["one_sided_derivative", "piecewise_derivative", "differentiability", "corner_cusp"], ["one_sided_derivatives", "differentiability"], ["continuity"]),
    d("derivatives_higher_order", "Higher-order derivatives", "مشتق‌های مرتبهٔ بالاتر", ["second_derivative", "higher_derivative", "nth_derivative"], ["higher_order_derivatives", "derivative_patterns"], ["basic_derivative_rules"]),
    d("derivatives_special_functions", "Trigonometric, exponential, and logarithmic derivatives", "مشتق توابع مثلثاتی، نمایی و لگاریتمی", ["trig_derivative", "exponential_derivative", "logarithmic_derivative", "inverse_trig_derivative"], ["special_function_derivatives", "chain_rule"], ["basic_derivative_rules"]),
    d("derivatives_graph_table", "Derivatives from graphs and tables", "مشتق از نمودار و جدول", ["derivative_graph", "derivative_table", "slope_graph", "graphical_derivative"], ["graphical_derivatives", "slope_interpretation"], ["function_graphs"]),
    d("derivatives_parameters", "Parameterized differentiability", "مشتق‌پذیری پارامتری", ["derivative_parameter", "differentiability_parameter", "tangent_parameter"], ["parameter_differentiability", "matching_conditions"], ["piecewise_derivatives"]),
  ],
  derivative_applications: [
    d("derivative_apps_monotonicity", "Monotonicity and critical points", "یکنوایی و نقاط بحرانی", ["critical_point", "monotonicity", "increasing_decreasing", "derivative_sign"], ["critical_points", "monotonicity"], ["derivative_rules"]),
    d("derivative_apps_extrema", "Local and absolute extrema", "اکسترمم‌های نسبی و مطلق", ["local_extrema", "absolute_extrema", "maximum_minimum", "first_derivative_test"], ["extrema", "first_derivative_test"], ["critical_points"]),
    d("derivative_apps_concavity", "Concavity and inflection", "تقعر و نقطهٔ عطف", ["concavity", "inflection_point", "second_derivative_test"], ["concavity", "inflection_points"], ["second_derivative"]),
    d("derivative_apps_graph_sketching", "Graph sketching", "رسم و تحلیل نمودار", ["graph_sketching", "function_shape", "derivative_graph", "from_graph", "graph_interpretation", "graph_constraints", "sign_graph", "sign_chart_graph"], ["graph_sketching", "derivative_sign_analysis"], ["monotonicity", "concavity"]),
    d("derivative_apps_optimization", "Optimization", "بهینه‌سازی", ["optimization", "maximum_area", "minimum_distance", "economic_model", "geometric_optimization"], ["optimization_modeling", "extrema"], ["derivative_rules"]),
    d("derivative_apps_tangent_normal", "Tangent and normal lines", "خط مماس و عمود", ["tangent_line", "normal_line", "parallel_tangent", "tangent_condition"], ["tangent_lines", "normal_lines"], ["derivative_definition"]),
    d("derivative_apps_rates_motion", "Rates and motion", "نرخ تغییر و حرکت", ["related_rates", "velocity_acceleration", "motion_derivative", "rate_of_change"], ["rates_of_change", "motion_analysis"], ["derivative_rules"]),
    d("derivative_apps_parameters_roots", "Parameters, roots, and inequalities", "پارامتر، ریشه و نامعادله با مشتق", ["parameterized", "parameter_from", "parameter_bounds", "parameter_range", "parameter_constraints", "parameter_recovery", "unique_extremum", "root_count", "inequality_by_derivative", "number_of_solutions", "parameter_graph"], ["parameter_analysis", "root_counting"], ["monotonicity"]),
  ],
  trigonometry: [
    d("trigonometry_angles_unit_circle", "Angles and the unit circle", "زاویه‌ها و دایرهٔ مثلثاتی", ["unit_circle", "angle_measure", "radian", "coterminal_angle", "quadrant"], ["unit_circle", "angle_measure"]),
    d("trigonometry_values_quadrants", "Trigonometric values and quadrants", "نسبت‌های مثلثاتی و ربع‌ها", ["special_angles", "trig_values", "reference_angle", "quadrant_sign", "tangent_value"], ["trigonometric_values", "quadrant_signs"], ["unit_circle"]),
    d("trigonometry_identities", "Trigonometric identities", "اتحادهای مثلثاتی", ["trig_identity", "identity_simplification", "pythagorean_identity", "sum_difference_identity", "double_angle", "half_angle"], ["trigonometric_identities", "algebraic_simplification"], ["trigonometric_values"]),
    d("trigonometry_equations", "Trigonometric equations and inequalities", "معادلات و نامعادلات مثلثاتی", ["trig_equation", "trig_inequality", "general_solution", "solution_count"], ["trigonometric_equations", "periodic_solutions"], ["unit_circle"]),
    d("trigonometry_graphs", "Trigonometric graphs", "نمودارهای مثلثاتی", ["sine_graph", "cosine_graph", "tangent_graph", "period", "amplitude", "phase_shift", "trig_transformation"], ["trigonometric_graphs", "period_amplitude"], ["function_transformations"]),
    d("trigonometry_triangle_laws", "Sine and cosine laws", "قانون سینوس‌ها و کسینوس‌ها", ["sine_law", "cosine_law", "triangle_solution", "area_with_sine"], ["sine_law", "cosine_law"], ["triangle_geometry"]),
    d("trigonometry_geometry", "Geometric trigonometry", "کاربرد هندسی مثلثات", ["height_distance", "right_triangle", "geometric_trig", "inclination", "bearing"], ["right_triangle_trigonometry", "geometric_modeling"], ["triangle_geometry"]),
    d("trigonometry_inverse_parameters", "Inverse and parameterized trigonometry", "مثلثات وارون و پارامتری", ["inverse_trig", "parameter_trig", "root_count_parameter", "trig_composition"], ["inverse_trigonometry", "parameter_analysis"], ["trigonometric_functions"]),
  ],
  analytic_geometry: [
    d("analytic_coordinates_distance_midpoint", "Coordinates, distance, and midpoint", "مختصات، فاصله و نقطهٔ میانی", ["coordinate", "distance_between_points", "midpoint", "section_formula"], ["coordinate_geometry", "distance_midpoint"]),
    d("analytic_lines_slope", "Lines and slope", "خط و شیب", ["line_equation", "slope", "slope_intercept", "two_point_line", "line_parameter"], ["line_equations", "slope"]),
    d("analytic_parallel_perpendicular", "Parallel and perpendicular lines", "خطوط موازی و عمود", ["parallel_lines", "perpendicular_lines", "normal_slope", "angle_between_lines"], ["parallel_perpendicular", "line_angles"], ["slope"]),
    d("analytic_point_line_distance", "Point-to-line distance", "فاصلهٔ نقطه از خط", ["point_line_distance", "distance_to_line", "parallel_distance"], ["point_line_distance", "line_equations"], ["distance_formula"]),
    d("analytic_transformations_reflections", "Coordinate transformations and reflections", "تبدیل و بازتاب مختصاتی", ["reflection", "rotation", "translation", "coordinate_transformation", "symmetric_point"], ["coordinate_transformations", "reflections"], ["coordinate_plane"]),
    d("analytic_area_polygons", "Coordinate area and polygons", "مساحت و چندضلعی در مختصات", ["triangle_area", "polygon_area", "shoelace", "collinearity", "coordinate_area"], ["coordinate_area", "collinearity"], ["determinants"]),
    d("analytic_loci_bisectors", "Loci and bisectors", "مکان هندسی و نیمسازها", ["locus", "perpendicular_bisector", "angle_bisector", "equidistant_points"], ["geometric_loci", "bisectors"], ["distance_formula"]),
    d("analytic_circles_intersections", "Coordinate circles and intersections", "دایره و تقاطع در مختصات", ["circle_equation", "line_circle_intersection", "circle_center", "circle_tangent"], ["coordinate_circles", "line_circle_intersections"], ["quadratic_equations"]),
  ],
  visual_thinking_conics: [
    d("conics_circle_equations", "Circle equations", "معادله و مشخصات دایره", ["circle_equation", "general_equation", "general_form", "center_radius", "diameter_endpoint", "coefficient", "circle_existence"], ["circle_equations", "center_radius"]),
    d("conics_circle_tangency", "Circle tangency and relative position", "مماس و وضعیت نسبی دایره‌ها", ["circle_tangent", "tangency", "external_tangency", "internal_tangency", "intersecting_circles", "relative_position", "tangent_line"], ["circle_tangency", "relative_circle_position"], ["circle_equations"]),
    d("conics_circle_loci_geometry", "Circle loci and geometry", "مکان هندسی و هندسهٔ دایره", ["circle_locus", "center_locus", "chord", "radical_axis", "point_inside", "point_outside", "extreme_distance", "circumcircle", "circle_center_constraint"], ["circle_loci", "circle_geometry"], ["distance_formula"]),
    d("conics_parabolas", "Parabolas", "سهمی", ["parabola", "focus_directrix", "parabola_vertex", "parabola_equation"], ["parabola_equations", "focus_directrix"]),
    d("conics_ellipses", "Ellipse geometry", "هندسه و مشخصات بیضی", ["ellipse_axis", "major_axis", "minor_axis", "ellipse_focus", "ellipse_vertices", "ellipse_coordinates", "ellipse_area"], ["ellipse_geometry", "ellipse_foci"]),
    d("conics_hyperbolas", "Hyperbolas", "هذلولی", ["hyperbola", "hyperbola_asymptote", "hyperbola_foci", "hyperbola_equation"], ["hyperbola_equations", "hyperbola_asymptotes"]),
    d("conics_eccentricity_directrix", "Eccentricity and directrices", "خروج از مرکز و خطوط هادی", ["ellipse_eccentricity", "eccentricity", "directrix", "focus_distance", "axis_ratio", "vertex_focus_distance", "subtended_angle", "tangent_ellipse_eccentricity"], ["eccentricity", "directrices"], ["distance_formula"]),
    d("conics_transformations_intersections", "Transformations and intersections", "انتقال و تقاطع مقاطع مخروطی", ["conic_translation", "rotated_conic", "conic_intersection", "completing_square"], ["conic_transformations", "conic_intersections"], ["coordinate_transformations"]),
    d("conics_tangency_loci", "Tangency and loci", "مماس و مکان هندسی", ["conic_tangent", "tangency_condition", "locus_conic", "common_tangent"], ["conic_tangency", "geometric_loci"], ["discriminant"]),
    d("conics_spatial_visualization", "Spatial visualization and revolutions", "تجسم فضایی و دوران", ["solid_revolution", "cross_section", "spatial_visualization", "rotated_solid", "volume_of_revolution"], ["spatial_visualization", "solids_of_revolution"], ["plane_geometry"]),
  ],
  geometry: [
    d("geometry_angles_parallel", "Angles and parallel lines", "زاویه‌ها و خطوط موازی", ["angle_chasing", "parallel_lines", "transversal", "angle_relation"], ["angle_relations", "parallel_lines"]),
    d("geometry_triangles_congruence", "Triangles and congruence", "مثلث و هم‌نهشتی", ["triangle", "congruence", "triangle_inequality", "isosceles_triangle"], ["triangle_geometry", "congruence"]),
    d("geometry_similarity", "Similarity and ratios", "تشابه و تناسب", ["similarity", "similar_triangles", "scale_factor", "proportional_segments"], ["triangle_similarity", "geometric_ratios"], ["ratios"]),
    d("geometry_triangle_centers", "Triangle centers and bisectors", "مراکز و نیمسازهای مثلث", ["angle_bisector", "median", "altitude", "incenter", "circumcenter", "centroid", "orthocenter"], ["triangle_centers", "cevians"], ["triangle_geometry"]),
    d("geometry_quadrilaterals", "Quadrilaterals and polygons", "چهارضلعی‌ها و چندضلعی‌ها", ["quadrilateral", "trapezoid", "parallelogram", "rhombus", "rectangle", "polygon"], ["quadrilaterals", "polygon_properties"]),
    d("geometry_circles", "Circle geometry", "هندسهٔ دایره", ["circle_geometry", "chord", "tangent", "inscribed_angle", "cyclic_quadrilateral", "arc"], ["circle_theorems", "chords_tangents"]),
    d("geometry_area_perimeter", "Area and perimeter", "مساحت و محیط", ["area", "perimeter", "composite_area", "triangle_area", "trapezoid_area"], ["area", "perimeter"], ["basic_geometry"]),
    d("geometry_spatial", "Spatial geometry", "هندسهٔ فضایی", ["solid_geometry", "volume", "surface_area", "cube", "prism", "pyramid"], ["solid_geometry", "spatial_reasoning"], ["plane_geometry"]),
    d("geometry_loci_proofs", "Loci and geometric proofs", "مکان هندسی و اثبات", ["geometric_locus", "proof", "construction", "composite_geometry", "geometric_inequality"], ["geometric_loci", "proof_reasoning"], ["geometry_theorems"]),
  ],
  combinatorics: [
    d("combinatorics_counting_principles", "Counting principles", "اصول شمارش", ["fundamental_counting", "addition_principle", "multiplication_principle", "case_counting"], ["counting_principles", "case_partition"]),
    d("combinatorics_permutations", "Permutations", "جایگشت", ["permutation", "arrangement", "circular_permutation", "ordering"], ["permutations", "arrangements"], ["factorials"]),
    d("combinatorics_combinations", "Combinations", "ترکیب", ["combination", "choose", "selection", "committee"], ["combinations", "selection_counting"], ["factorials"]),
    d("combinatorics_repetition", "Arrangements with repetition", "آرایش با تکرار", ["multiset_permutation", "repeated_elements", "arrangement_with_repetition", "identical_objects"], ["multiset_permutations", "repetition"]),
    d("combinatorics_stars_bars", "Stars and bars", "ستاره و میله", ["stars_and_bars", "integer_solutions", "distribution", "nonnegative_solutions"], ["stars_and_bars", "integer_solution_counting"], ["combinations"]),
    d("combinatorics_binomial", "Binomial coefficients", "ضرایب دوجمله‌ای", ["binomial", "binomial_coefficient", "pascal_triangle", "binomial_expansion"], ["binomial_coefficients", "pascal_triangle"], ["combinations"]),
    d("combinatorics_inclusion_exclusion", "Inclusion-exclusion", "اصل شمول و عدم شمول", ["inclusion_exclusion", "derangement", "overlapping_cases"], ["inclusion_exclusion", "overlap_counting"], ["counting_principles"]),
    d("combinatorics_digits_paths", "Digit, path, and geometric counting", "شمارش ارقام، مسیرها و اشکال", ["digit_counting", "number_formation", "lattice_path", "path_counting", "geometric_counting"], ["digit_counting", "path_counting"], ["counting_principles"]),
    d("combinatorics_recurrence_pigeonhole", "Recurrence and pigeonhole", "بازگشت و اصل لانه‌کبوتری", ["recurrence", "pigeonhole", "invariant", "recursive_counting"], ["pigeonhole_principle", "recursive_counting"], ["counting_principles"]),
  ],
  probability: [
    d("probability_sample_spaces", "Sample spaces and classical probability", "فضای نمونه و احتمال کلاسیک", ["sample_space", "classical_probability", "equally_likely", "event_counting"], ["sample_spaces", "classical_probability"]),
    d("probability_addition_complement", "Addition and complement rules", "قواعد جمع و متمم", ["addition_rule", "complement_rule", "union_probability", "mutually_exclusive"], ["probability_addition", "complements"], ["events"]),
    d("probability_conditional", "Conditional probability", "احتمال شرطی", ["conditional_probability", "given_that", "conditional_event"], ["conditional_probability", "event_intersection"], ["classical_probability"]),
    d("probability_independence", "Independent events", "رویدادهای مستقل", ["independent_events", "independence", "product_rule"], ["event_independence", "multiplication_rule"], ["conditional_probability"]),
    d("probability_total_bayes", "Total probability and Bayes", "احتمال کل و بیز", ["total_probability", "bayes", "partition", "diagnostic_probability"], ["total_probability", "bayes_rule"], ["conditional_probability"]),
    d("probability_counting", "Combinatorial probability", "احتمال با شمارش ترکیبی", ["combinatorial_probability", "permutation_probability", "combination_probability", "counting_outcomes"], ["combinatorial_probability", "outcome_counting"], ["combinations"]),
    d("probability_repeated_binomial", "Repeated trials and binomial probability", "آزمایش‌های تکراری و احتمال دوجمله‌ای", ["binomial_probability", "bernoulli", "repeated_trials", "at_least_successes"], ["binomial_probability", "repeated_trials"], ["independent_events"]),
    d("probability_urn_sampling", "Urns and sampling", "ظرف، مهره و نمونه‌گیری", ["urn", "drawing_balls", "without_replacement", "with_replacement", "sampling"], ["urn_models", "sampling_probability"], ["conditional_probability"]),
    d("probability_geometric_expectation", "Geometric probability and expectation", "احتمال هندسی و امید ریاضی", ["geometric_probability", "expected_value", "random_variable", "expectation"], ["geometric_probability", "expected_value"], ["classical_probability"]),
  ],
  statistics: [
    d("statistics_tables_frequencies", "Data tables and frequencies", "جدول داده و فراوانی", ["frequency_table", "grouped_data", "relative_frequency", "data_table"], ["frequency_tables", "data_representation"]),
    d("statistics_mean_weighted", "Mean and weighted mean", "میانگین و میانگین وزنی", ["arithmetic_mean", "weighted_mean", "combined_mean", "average"], ["arithmetic_mean", "weighted_mean"]),
    d("statistics_median_mode", "Median and mode", "میانه و نما", ["median", "mode", "central_tendency"], ["median", "mode"]),
    d("statistics_quartiles_percentiles", "Quartiles and percentiles", "چارک و صدک", ["quartile", "percentile", "interquartile_range", "box_plot"], ["quartiles", "percentiles"]),
    d("statistics_variance_std", "Variance and standard deviation", "واریانس و انحراف معیار", ["variance", "standard_deviation", "dispersion", "sum_of_squares"], ["variance", "standard_deviation"], ["arithmetic_mean"]),
    d("statistics_coefficient_variation", "Coefficient of variation", "ضریب تغییرات", ["coefficient_of_variation", "relative_dispersion", "cv"], ["coefficient_of_variation", "relative_dispersion"], ["standard_deviation"]),
    d("statistics_transformations_combined", "Transformed and combined data", "تبدیل و ترکیب داده‌ها", ["data_transformation", "combined_variance", "shift_scale_data", "pooled_data"], ["data_transformations", "combined_statistics"], ["mean", "variance"]),
    d("statistics_charts_distributions", "Charts and distributions", "نمودارها و توزیع داده", ["histogram", "bar_chart", "distribution_shape", "cumulative_frequency", "chart_interpretation"], ["statistical_charts", "distribution_shape"], ["frequency_tables"]),
  ],
  physics_measurement: [
    d("physics_measurement_units_dimensions", "Units and dimensions", "یکا و ابعاد", ["units", "dimensions", "si_unit", "dimensional_analysis", "base_quantity"], ["si_units", "dimensional_analysis"]),
    d("physics_measurement_scientific_notation", "Scientific notation and scale", "نماد علمی و مرتبهٔ بزرگی", ["scientific_notation", "order_of_magnitude", "prefix", "powers_of_ten"], ["scientific_notation", "metric_prefixes"]),
    d("physics_measurement_precision", "Precision and significant figures", "دقت و ارقام معنادار", ["significant_figures", "precision", "resolution", "rounding"], ["significant_figures", "measurement_precision"]),
    d("physics_measurement_uncertainty", "Uncertainty and error", "عدم قطعیت و خطا", ["measurement_error", "uncertainty", "percent_error", "absolute_error", "relative_error"], ["measurement_uncertainty", "error_analysis"]),
    d("physics_measurement_instruments", "Measurement instruments", "ابزارهای اندازه‌گیری", ["vernier", "micrometer", "caliper", "instrument_reading", "scale_reading"], ["instrument_reading", "measurement_resolution"]),
    d("physics_measurement_density", "Density", "چگالی", ["density", "mass_volume", "relative_density"], ["density", "mass_volume_relation"]),
    d("physics_measurement_mixtures", "Mixtures and density modeling", "مخلوط‌ها و مدل‌سازی چگالی", ["mixture_density", "composite_density", "hollow_object", "alloy"], ["mixture_density", "volume_balance"], ["density"]),
    d("physics_measurement_conversions_rates", "Conversions and rates", "تبدیل یکا و نرخ‌ها", ["unit_conversion", "conversion_factor", "rate", "compound_unit"], ["unit_conversion", "compound_units"]),
    d("physics_measurement_vectors_scalars", "Vectors and scalars", "کمیت‌های برداری و نرده‌ای", ["vector_quantity", "scalar_quantity", "vector_components", "resultant"], ["vectors_scalars", "vector_components"]),
  ],
  physical_properties_matter: [
    d("matter_pressure_basics", "Pressure fundamentals", "مبانی فشار", ["pressure", "force_area", "solid_pressure"], ["pressure", "force_area"]),
    d("matter_hydrostatic_pressure", "Hydrostatic pressure", "فشار شارهٔ ساکن", ["hydrostatic_pressure", "liquid_pressure", "depth_pressure", "rho_gh"], ["hydrostatic_pressure", "depth_dependence"], ["density"]),
    d("matter_manometers_atmosphere", "Manometers and atmospheric pressure", "فشارسنج، مانومتر و فشار جو", ["u_tube", "manometer", "atmospheric_pressure", "gauge_pressure", "absolute_pressure", "barometer"], ["manometers", "gauge_absolute_pressure"], ["hydrostatic_pressure"]),
    d("matter_pascal_hydraulics", "Pascal principle and hydraulics", "اصل پاسکال و سامانه‌های هیدرولیکی", ["pascal", "hydraulic", "hydraulic_press", "force_amplification"], ["pascal_principle", "hydraulic_systems"], ["pressure"]),
    d("matter_buoyancy", "Buoyancy and Archimedes", "شناوری و اصل ارشمیدس", ["buoyancy", "archimedes", "floating", "apparent_weight", "displaced_fluid"], ["buoyant_force", "archimedes_principle"], ["density"]),
    d("matter_continuity_flow", "Fluid continuity and flow", "پیوستگی و شارش شاره", ["continuity_equation", "volume_flow_rate", "fluid_flow", "pipe_area_speed"], ["fluid_continuity", "flow_rate"], ["volume"]),
    d("matter_bernoulli", "Bernoulli principle", "اصل برنولی", ["bernoulli", "venturi", "dynamic_pressure", "efflux", "torricelli"], ["bernoulli_principle", "flow_energy"], ["fluid_continuity"]),
    d("matter_surface_capillarity", "Surface tension and capillarity", "کشش سطحی و موئینگی", ["surface_tension", "capillary", "meniscus", "droplet", "soap_film"], ["surface_tension", "capillarity"]),
    d("matter_elasticity", "Elasticity and deformation", "کشسانی و تغییر شکل", ["elasticity", "stress", "strain", "young_modulus", "deformation"], ["stress_strain", "elastic_modulus"]),
    d("matter_molecular_states", "Molecular properties and states", "ویژگی مولکولی و حالت‌های ماده", ["molecular_force", "adhesion", "cohesion", "states_of_matter", "compressibility"], ["molecular_interactions", "states_of_matter"]),
  ],
  temperature_heat: [
    d("temperature_heat_scales_equilibrium", "Temperature scales and equilibrium", "مقیاس دما و تعادل گرمایی", ["temperature_scale", "thermal_equilibrium", "thermometer", "celsius", "kelvin", "fahrenheit"], ["temperature_scales", "thermal_equilibrium"]),
    d("temperature_heat_linear_expansion", "Linear expansion", "انبساط طولی", ["linear_expansion", "length_expansion", "thermal_expansion_coefficient"], ["linear_thermal_expansion", "expansion_coefficient"]),
    d("temperature_heat_area_volume_expansion", "Area and volume expansion", "انبساط سطحی و حجمی", ["area_expansion", "volume_expansion", "cubical_expansion", "hole_expansion"], ["area_expansion", "volume_expansion"], ["linear_expansion"]),
    d("temperature_heat_density_expansion", "Expansion and density", "انبساط و تغییر چگالی", ["density_temperature", "anomalous_expansion", "liquid_expansion", "overflow"], ["thermal_density_change", "apparent_expansion"], ["volume_expansion"]),
    d("temperature_heat_calorimetry", "Heat capacity and calorimetry", "ظرفیت گرمایی و گرماسنجی", ["specific_heat", "heat_capacity", "calorimetry", "q_mc_delta_t"], ["specific_heat", "calorimetry"]),
    d("temperature_heat_mixing", "Thermal mixing", "اختلاط گرمایی", ["thermal_mixing", "equilibrium_temperature", "heat_exchange", "calorimeter"], ["thermal_mixing", "energy_balance"], ["calorimetry"]),
    d("temperature_heat_phase_change", "Phase change and latent heat", "تغییر فاز و گرمای نهان", ["latent_heat", "phase_change", "melting", "boiling", "heating_curve"], ["latent_heat", "phase_change"]),
    d("temperature_heat_transfer", "Heat transfer", "انتقال گرما", ["conduction", "convection", "radiation", "heat_transfer", "thermal_conductivity"], ["heat_transfer_modes", "thermal_conductivity"]),
    d("temperature_heat_thermometry", "Thermometry and calibration", "دماسنجی و کالیبراسیون", ["thermometer_calibration", "thermometric_property", "fixed_points", "scale_calibration"], ["thermometer_calibration", "linear_scales"]),
  ],
  one_dimensional_motion: [
    d("motion_1d_position_direction", "Position and direction", "مکان و جهت حرکت", ["position_sign", "position_equation", "initial_position", "origin_crossing", "turning_position", "motion_direction", "position_and_velocity"], ["position", "motion_direction"]),
    d("motion_1d_distance_displacement", "Distance and displacement", "مسافت و جابه‌جایی", ["distance_and_displacement", "distance_equals_displacement", "total_distance", "displacement", "path_length", "route"], ["distance", "displacement"]),
    d("motion_1d_average_speed", "Average speed", "تندی متوسط", ["average_speed", "minimum_average_speed", "speed_ratio", "equal_distance", "round_trip_speed"], ["average_speed", "distance_time"]),
    d("motion_1d_average_velocity", "Average velocity", "سرعت متوسط", ["average_velocity", "secant_slope", "velocity_ratio", "zero_displacement"], ["average_velocity", "displacement_time"]),
    d("motion_1d_uniform", "Uniform motion", "حرکت یکنواخت", ["uniform_motion", "constant_velocity", "x_t_linear"], ["uniform_motion", "position_time_relation"]),
    d("motion_1d_acceleration", "Constant acceleration", "حرکت با شتاب ثابت", ["constant_acceleration", "kinematic_equations", "uniformly_accelerated"], ["constant_acceleration", "kinematic_equations"]),
    d("motion_1d_free_fall", "Free fall and vertical motion", "سقوط آزاد و حرکت قائم", ["free_fall", "vertical_motion", "gravity", "projected_upward"], ["free_fall", "vertical_kinematics"], ["constant_acceleration"]),
    d("motion_1d_position_graphs", "Position-time graphs", "نمودار مکان–زمان", ["position_time_graph", "x_t_graph", "slope_position_graph"], ["position_time_graphs", "graph_slope"]),
    d("motion_1d_velocity_graphs", "Velocity-time graphs", "نمودار سرعت–زمان", ["velocity_time_graph", "v_t_graph", "area_under_velocity"], ["velocity_time_graphs", "graph_area"]),
    d("motion_1d_acceleration_graphs", "Acceleration-time graphs", "نمودار شتاب–زمان", ["acceleration_time_graph", "a_t_graph", "area_under_acceleration"], ["acceleration_time_graphs", "velocity_change"]),
    d("motion_1d_relative", "Relative motion", "حرکت نسبی", ["relative_motion", "relative_velocity", "moving_observer"], ["relative_motion", "relative_velocity"]),
    d("motion_1d_multistage_chase", "Multi-stage and chase motion", "حرکت چندمرحله‌ای و تعقیب", ["chase_problem", "multi_stage_motion", "meeting_time", "piecewise_motion"], ["multi_stage_motion", "meeting_problems"], ["kinematic_equations"]),
  ],
  dynamics: [
    d("dynamics_newton_fbd", "Newton laws and free-body diagrams", "قوانین نیوتن و نمودار جسم آزاد", ["newton_laws", "free_body_diagram", "net_force", "second_law"], ["newton_laws", "free_body_diagrams"]),
    d("dynamics_friction_horizontal", "Friction on horizontal surfaces", "اصطکاک روی سطح افقی", ["friction", "static_friction", "kinetic_friction", "horizontal_surface"], ["friction", "normal_force"], ["newton_laws"]),
    d("dynamics_inclined_planes", "Inclined planes", "سطح شیبدار", ["inclined_plane", "slope_friction", "component_of_weight"], ["inclined_plane_dynamics", "force_components"], ["newton_laws"]),
    d("dynamics_connected_bodies", "Connected bodies and tension", "اجسام متصل و کشش نخ", ["connected_bodies", "tension", "pulley", "atwood"], ["connected_body_dynamics", "tension"], ["free_body_diagrams"]),
    d("dynamics_elevator_weight", "Elevators and apparent weight", "آسانسور و وزن ظاهری", ["apparent_weight", "elevator", "scale_reading", "normal_force"], ["apparent_weight", "elevator_dynamics"], ["newton_laws"]),
    d("dynamics_springs", "Springs and Hooke law", "فنر و قانون هوک", ["hooke", "spring_force", "spring_constant", "elastic_force"], ["hooke_law", "spring_force"]),
    d("dynamics_circular", "Circular dynamics", "دینامیک حرکت دایره‌ای", ["centripetal_force", "circular_motion", "banked_curve", "vertical_circle"], ["centripetal_dynamics", "circular_motion"], ["newton_laws"]),
    d("dynamics_drag_terminal", "Drag and terminal speed", "نیروی مقاومت و تندی حدی", ["air_resistance", "drag_force", "terminal_velocity", "fluid_resistance"], ["drag_force", "terminal_speed"]),
    d("dynamics_momentum_impulse", "Momentum and impulse", "تکانه و ضربه", ["momentum", "impulse", "collision", "force_time"], ["momentum", "impulse"]),
    d("dynamics_equilibrium_force_graphs", "Equilibrium and force graphs", "تعادل و نمودار نیرو", ["equilibrium", "force_graph", "force_time_graph", "static_equilibrium"], ["force_equilibrium", "force_graphs"], ["newton_laws"]),
  ],
  work_energy_power: [
    d("work_energy_work", "Work by forces", "کار نیروها", ["work", "constant_force_work", "variable_force_work", "force_displacement"], ["mechanical_work", "force_displacement"]),
    d("work_energy_theorem", "Work-energy theorem", "قضیهٔ کار و انرژی", ["work_energy", "work_energy_theorem", "net_work"], ["work_energy_theorem", "kinetic_energy"]),
    d("work_energy_potential", "Kinetic and potential energy", "انرژی جنبشی و پتانسیل", ["kinetic_energy", "potential_energy", "gravitational_potential"], ["kinetic_energy", "potential_energy"]),
    d("work_energy_conservation", "Mechanical-energy conservation", "پایستگی انرژی مکانیکی", ["conservation_of_energy", "mechanical_energy", "energy_conservation"], ["mechanical_energy_conservation", "energy_transfer"]),
    d("work_energy_springs", "Elastic energy", "انرژی کشسانی", ["elastic_potential", "spring_energy", "spring_work"], ["elastic_potential_energy", "spring_work"], ["hooke_law"]),
    d("work_energy_power_efficiency", "Power and efficiency", "توان و بازده", ["power", "efficiency", "average_power", "instantaneous_power"], ["power", "efficiency"]),
    d("work_energy_dissipation", "Friction and energy loss", "اصطکاک و اتلاف انرژی", ["friction_energy", "dissipation", "thermal_energy", "nonconservative_work"], ["energy_dissipation", "nonconservative_work"], ["energy_conservation"]),
    d("work_energy_graphs", "Energy and work graphs", "نمودارهای کار و انرژی", ["energy_graph", "potential_energy_graph", "force_position_graph", "turning_point"], ["energy_graphs", "work_from_graphs"], ["graph_area"]),
    d("work_energy_multibody", "Multi-body energy systems", "سامانه‌های چندجسمی انرژی", ["multi_body_energy", "pulley_energy", "connected_system_energy"], ["system_energy", "multi_body_modeling"], ["energy_conservation"]),
  ],
  electrostatics: [
    d("electrostatics_charge_coulomb", "Charge and Coulomb law", "بار الکتریکی و قانون کولن", ["electric_charge", "coulomb", "coulomb_force", "charge_quantization"], ["electric_charge", "coulomb_law"]),
    d("electrostatics_field", "Electric field", "میدان الکتریکی", ["electric_field", "field_of_point_charge", "test_charge"], ["electric_field", "point_charge_field"]),
    d("electrostatics_field_superposition", "Field superposition", "برهم‌نهی میدان", ["field_superposition", "net_electric_field", "multiple_charges_field"], ["electric_field_superposition", "vector_addition"], ["electric_field"]),
    d("electrostatics_equilibrium", "Electrostatic equilibrium", "تعادل الکتروستاتیکی", ["charge_equilibrium", "electric_force_equilibrium", "zero_field_point"], ["electrostatic_equilibrium", "zero_field_points"], ["coulomb_law"]),
    d("electrostatics_potential", "Electric potential", "پتانسیل الکتریکی", ["electric_potential", "potential_difference", "equipotential"], ["electric_potential", "potential_difference"]),
    d("electrostatics_energy_work", "Potential energy and work", "انرژی پتانسیل و کار الکتریکی", ["electric_potential_energy", "electric_work", "energy_of_charges"], ["electric_potential_energy", "electric_work"], ["electric_potential"]),
    d("electrostatics_conductors", "Conductors and induction", "رساناها و القای الکتریکی", ["conductor", "electrostatic_induction", "gauss_law", "charge_distribution"], ["conductors", "electrostatic_induction"]),
    d("electrostatics_capacitance", "Capacitance and capacitor networks", "ظرفیت و شبکهٔ خازن‌ها", ["capacitance", "capacitor", "series_capacitor", "parallel_capacitor", "equivalent_capacitance"], ["capacitance", "capacitor_networks"]),
    d("electrostatics_capacitor_energy", "Capacitor energy and dielectrics", "انرژی خازن و دی‌الکتریک", ["capacitor_energy", "dielectric", "stored_energy", "capacitor_plate"], ["capacitor_energy", "dielectrics"], ["capacitance"]),
    d("electrostatics_charge_sharing", "Charge sharing", "اشتراک و بازتوزیع بار", ["charge_sharing", "connected_capacitors", "charge_redistribution"], ["charge_sharing", "potential_equalization"], ["capacitance"]),
  ],
  current_electricity: [
    d("current_charge_flow", "Current and charge flow", "جریان و شارش بار", ["electric_current", "charge_flow", "drift_velocity", "current_density"], ["electric_current", "charge_flow"]),
    d("current_resistance_resistivity", "Resistance and resistivity", "مقاومت و مقاومت ویژه", ["resistance", "resistivity", "wire_resistance", "temperature_resistance"], ["resistance", "resistivity"]),
    d("current_ohm_law", "Ohm law and I-V behavior", "قانون اهم و مشخصهٔ جریان–ولتاژ", ["ohm_law", "iv_graph", "ohmic", "non_ohmic"], ["ohm_law", "current_voltage_graphs"]),
    d("current_series_parallel", "Series and parallel circuits", "مدارهای سری و موازی", ["series_circuit", "parallel_circuit", "equivalent_resistance", "resistor_network"], ["series_parallel_circuits", "equivalent_resistance"]),
    d("current_kirchhoff", "Kirchhoff circuit analysis", "تحلیل مدار با قوانین کیرشهف", ["kirchhoff", "junction_rule", "loop_rule", "multi_loop"], ["kirchhoff_laws", "circuit_equations"], ["ohm_law"]),
    d("current_battery_internal", "Batteries and internal resistance", "باتری و مقاومت داخلی", ["internal_resistance", "emf", "terminal_voltage", "battery_combination"], ["emf", "internal_resistance"]),
    d("current_meters", "Ammeters and voltmeters", "آمپرسنج و ولت‌سنج", ["ammeter", "voltmeter", "meter_resistance", "galvanometer"], ["ammeters", "voltmeters"], ["series_parallel_circuits"]),
    d("current_power_energy", "Electrical power and energy", "توان و انرژی الکتریکی", ["electric_power", "electrical_energy", "joule_heating", "power_rating"], ["electrical_power", "electrical_energy"]),
    d("current_rheostat_switching", "Rheostats and circuit switching", "رئوستا و تغییر آرایش مدار", ["rheostat", "variable_resistor", "switch", "circuit_switching", "short_circuit"], ["rheostats", "circuit_switching"], ["series_parallel_circuits"]),
    d("current_maximum_power", "Maximum-power transfer", "بیشینهٔ توان دریافتی", ["maximum_power", "load_resistance", "power_transfer"], ["maximum_power_transfer", "load_matching"], ["internal_resistance"]),
  ],
  magnetism_induction: [
    d("magnetism_field_sources", "Magnetic fields and sources", "میدان مغناطیسی و چشمه‌های آن", ["magnetic_field", "field_of_wire", "solenoid", "current_loop", "field_superposition"], ["magnetic_fields", "field_sources"]),
    d("magnetism_force_charge", "Force on moving charges", "نیرو بر بار متحرک", ["magnetic_force_charge", "lorentz_force", "moving_charge"], ["magnetic_force_on_charge", "lorentz_force"]),
    d("magnetism_force_wire", "Force on current-carrying wires", "نیرو بر سیم حامل جریان", ["magnetic_force_wire", "force_on_wire", "parallel_wires"], ["magnetic_force_on_wire", "current_interaction"]),
    d("magnetism_torque_loop", "Torque on current loops", "گشتاور حلقهٔ جریان", ["magnetic_torque", "current_loop_torque", "magnetic_dipole"], ["magnetic_torque", "magnetic_dipole"]),
    d("magnetism_particle_motion", "Charged-particle motion", "حرکت ذرهٔ باردار در میدان", ["charged_particle_motion", "circular_path", "mass_spectrometer", "velocity_selector"], ["charged_particle_motion", "magnetic_radius"], ["magnetic_force_on_charge"]),
    d("magnetism_flux", "Magnetic flux", "شار مغناطیسی", ["magnetic_flux", "flux_angle", "flux_change"], ["magnetic_flux", "area_vector"]),
    d("magnetism_faraday_lenz", "Faraday and Lenz laws", "قوانین فاراده و لنز", ["faraday", "lenz", "induced_emf", "electromagnetic_induction"], ["faraday_law", "lenz_law"], ["magnetic_flux"]),
    d("magnetism_motional_emf", "Motional emf", "نیروی محرکهٔ القایی حرکتی", ["motional_emf", "moving_rod", "rail_emf"], ["motional_emf", "magnetic_force"], ["faraday_law"]),
    d("magnetism_inductance", "Inductance", "خودالقایی و القای متقابل", ["self_inductance", "mutual_inductance", "inductor", "inductive_energy"], ["inductance", "inductor_energy"], ["faraday_law"]),
    d("magnetism_ac_transformers", "Alternating current and transformers", "جریان متناوب و ترانسفورماتور", ["alternating_current", "sinusoidal_current", "ac", "transformer", "rms"], ["alternating_current", "transformers"]),
  ],
  oscillation_waves: [
    d("waves_shm_kinematics", "SHM kinematics", "سینماتیک نوسان هماهنگ ساده", ["simple_harmonic_motion", "shm", "oscillation_equation", "phase", "amplitude_frequency"], ["shm_kinematics", "phase_amplitude"]),
    d("waves_shm_energy", "SHM energy", "انرژی در نوسان هماهنگ ساده", ["shm_energy", "oscillator_energy", "kinetic_potential_shm"], ["shm_energy", "energy_exchange"], ["simple_harmonic_motion"]),
    d("waves_springs", "Spring oscillators", "نوسانگرهای فنری", ["spring_oscillator", "mass_spring", "effective_spring", "spring_period"], ["spring_oscillators", "spring_period"]),
    d("waves_pendulum", "Pendulums", "آونگ", ["pendulum", "simple_pendulum", "pendulum_period"], ["pendulums", "pendulum_period"]),
    d("waves_properties_equation", "Wave properties and equations", "ویژگی‌ها و معادلهٔ موج", ["wave_equation", "wavelength", "frequency", "traveling_wave", "wave_profile", "particle_motion_on_wave"], ["wave_equation", "wave_properties"]),
    d("waves_speed_strings", "Wave speed and strings", "تندی موج و موج روی تار", ["wave_speed", "string_wave", "tension_change", "loaded_spring", "travel_time", "transmission_between_strings"], ["wave_speed", "waves_on_strings"], ["wave_equation"]),
    d("waves_electromagnetic", "Electromagnetic waves", "موج‌های الکترومغناطیسی", ["electromagnetic_wave", "electromagnetic_spectrum", "electric_magnetic_fields", "em_wave", "spectrum_ordering"], ["electromagnetic_waves", "electromagnetic_spectrum"]),
    d("waves_superposition_standing", "Superposition and standing waves", "برهم‌نهی و موج ایستاده", ["superposition", "standing_wave", "node_antinode", "harmonics", "string_wave"], ["wave_superposition", "standing_waves"]),
    d("waves_sound_intensity", "Sound and intensity", "صوت و شدت", ["sound_intensity", "decibel", "sound_level", "intensity_level"], ["sound_intensity", "decibel_scale"]),
    d("waves_resonance", "Resonance", "تشدید", ["resonance", "natural_frequency", "forced_oscillation"], ["resonance", "natural_frequency"]),
    d("waves_reflection", "Wave reflection", "بازتاب موج و نور", ["wavefront_reflection", "pulse_reflection", "law_of_reflection", "echo", "reflection_boundary"], ["wave_reflection", "echo"]),
    d("waves_refraction", "Refraction and Snell law", "شکست و قانون اسنل", ["snell", "refractive_index", "speed_ratio", "wavelength_ratio", "critical_angle", "total_internal_reflection", "wavefront_refraction"], ["wave_refraction", "snell_law"]),
    d("waves_refraction_geometry", "Refraction geometry", "هندسهٔ شکست نور", ["parallel_slab", "prism", "apparent_depth", "lateral_displacement", "ray_path", "layered_media", "water_depth", "mirage"], ["refraction_geometry", "ray_tracing"], ["snell_law"]),
    d("waves_lenses_mirrors", "Lenses and mirrors", "عدسی و آینه", ["lens", "mirror_equation", "plane_mirror", "multiple_mirror", "reflected_ray", "ray_deviation", "image_formation", "focal_length", "magnification"], ["geometric_optics", "image_formation"]),
    d("waves_interference_diffraction", "Interference and diffraction", "تداخل و پراش", ["interference", "diffraction", "young_double_slit", "path_difference"], ["wave_interference", "diffraction"]),
    d("waves_doppler_echo", "Doppler effect and echo", "اثر دوپلر و پژواک", ["doppler", "echo", "moving_source", "beat_frequency"], ["doppler_effect", "echo_timing"]),
  ],
  atomic_nuclear: [
    d("atomic_photons_photoelectric", "Photons and photoelectric effect", "فوتون و اثر فوتوالکتریک", ["photon", "photoelectric", "work_function", "stopping_potential"], ["photons", "photoelectric_effect"]),
    d("atomic_spectra", "Atomic spectra", "طیف‌های اتمی", ["atomic_spectrum", "balmer", "lyman", "rydberg", "spectral_line"], ["atomic_spectra", "rydberg_relation"]),
    d("atomic_bohr_model", "Bohr model", "مدل اتمی بور", ["bohr", "bohr_radius", "hydrogen_atom", "orbit_radius"], ["bohr_model", "hydrogen_atom"]),
    d("atomic_energy_transitions", "Energy levels and transitions", "تراز انرژی و گذارها", ["energy_level", "atomic_transition", "emission", "absorption", "transition_energy"], ["atomic_energy_levels", "photon_transitions"]),
    d("atomic_wave_particle", "Wave-particle duality", "دوگانگی موج–ذره", ["de_broglie", "wave_particle", "matter_wave", "electron_diffraction"], ["wave_particle_duality", "de_broglie_wavelength"]),
    d("atomic_radioactivity", "Radioactive decay", "واپاشی پرتوزا", ["radioactive_decay", "half_life", "activity", "alpha_decay", "beta_decay", "gamma_decay"], ["radioactive_decay", "half_life"]),
    d("atomic_nuclear_reactions", "Nuclear reactions", "واکنش‌های هسته‌ای", ["nuclear_reaction", "reaction_equation", "conservation_nuclear", "q_value"], ["nuclear_reactions", "conservation_laws"]),
    d("atomic_binding_energy", "Mass defect and binding energy", "کاستی جرم و انرژی بستگی", ["mass_defect", "binding_energy", "binding_energy_per_nucleon"], ["mass_defect", "nuclear_binding_energy"]),
    d("atomic_fission_fusion", "Fission and fusion", "شکافت و همجوشی", ["fission", "fusion", "chain_reaction", "nuclear_energy"], ["nuclear_fission", "nuclear_fusion"]),
    d("atomic_nuclear_stability", "Nuclear stability", "پایداری هسته", ["nuclear_stability", "neutron_proton_ratio", "isotope", "stability_curve"], ["nuclear_stability", "isotopes"]),
    d("atomic_relativity", "Special relativity", "نسبیت خاص", ["relativity", "time_dilation", "length_contraction", "mass_energy", "lorentz_factor"], ["special_relativity", "mass_energy_equivalence"]),
  ],
};

const dimensionRanges = {
  prerequisite_breadth: [0, 3],
  reasoning_depth: [0, 4],
  non_routine_insight: [0, 4],
  representation_translation: [0, 3],
  computation_load: [0, 3],
  distractor_discrimination: [0, 3],
};
const difficultyLabels = new Set([
  "above_average",
  "hard",
  "very_hard",
  "olympiad",
]);

function normalize(value) {
  return String(value ?? "")
    .toLowerCase()
    .normalize("NFKC")
    .replaceAll("ي", "ی")
    .replaceAll("ك", "ک")
    .replaceAll(/[_\-–—/\\]+/g, " ")
    .replaceAll(/[^\p{L}\p{N}]+/gu, " ")
    .trim()
    .replaceAll(/\s+/g, " ");
}

const stopWords = new Set([
  "and", "or", "of", "the", "with", "using", "problem", "problems",
  "analysis", "application", "applications", "relation", "relations",
  "function", "functions", "equation", "equations", "parameter",
  "parameterized", "math", "physics", "set", "sets", "مقدار", "رابطه",
  "مسئله", "مسائل", "تابع", "معادله", "با", "در", "و", "از", "برای",
]);

function tokens(value) {
  return normalize(value)
    .split(" ")
    .filter((token) => token.length >= 3 && !stopWords.has(token));
}

function phraseStrength(candidate, pattern) {
  const left = normalize(candidate);
  const right = normalize(pattern);
  if (!left || !right) return 0;
  if (left === right) return 4;
  if (left.includes(right) || right.includes(left)) return 2.5;
  const leftTokens = new Set(tokens(left));
  const rightTokens = new Set(tokens(right));
  const overlap = [...rightTokens].filter((token) => leftTokens.has(token));
  if (overlap.length >= 2) return 1.5 + Math.min(1, overlap.length * 0.15);
  if (overlap.length === 1 && [...rightTokens][0]?.length >= 6) return 0.45;
  return 0;
}

const broadConceptTags = new Set([
  "absolute_value", "function", "derivative", "circle", "ellipse", "wave",
  "simple_harmonic_motion", "shm", "motion", "position", "pressure",
  "energy", "current", "electric_field", "set_operations", "trigonometry",
]);

function scoreDefinition(taxonomy, definition) {
  const proposal = taxonomy.proposed_subtopic ?? {};
  const proposalKey = normalize(proposal.key) === normalize(taxonomy.topic_key)
    ? null
    : proposal.key;
  const sources = [
    // The proposed subtopic is the screener's most specific judgment. Broad
    // atomic tags such as `absolute_value` must not overpower a proposal such
    // as `absolute_value_equation` and collapse the curriculum into one bin.
    { value: proposalKey, weight: 20 },
    { value: proposal.label_en, weight: 8 },
    { value: proposal.label_fa, weight: 8 },
    ...(taxonomy.proposed_concept_tags ?? []).map((value) => ({
      value,
      weight: broadConceptTags.has(String(value)) ? 1.5 : 5,
    })),
    ...(taxonomy.proposed_secondary_concepts ?? []).map((value) => ({ value, weight: 3 })),
    ...(taxonomy.proposed_prerequisites ?? []).map((value) => ({ value, weight: 2 })),
  ].filter(({ value }) => normalize(value));
  const patterns = [
    definition.key.replace(/^[^_]+_/, ""),
    definition.label_en,
    definition.label_fa,
    ...definition.aliases,
    ...definition.concept_tags,
  ];
  let score = 0;
  const evidence = [];
  for (const source of sources) {
    let best = 0;
    let bestPattern = null;
    for (const pattern of patterns) {
      const strength = phraseStrength(source.value, pattern);
      if (strength > best) {
        best = strength;
        bestPattern = pattern;
      }
    }
    if (best > 0) {
      score += best * source.weight;
      evidence.push(`${source.value}~${bestPattern}:${best.toFixed(2)}`);
    }
  }
  return { score, evidence };
}

function classifyTaxonomy(record) {
  const definitions = catalog[record.taxonomy.topic_key];
  if (!definitions) throw new Error(`Missing catalog topic ${record.taxonomy.topic_key}`);
  const hasProposal = Boolean(record.taxonomy.proposed_subtopic?.key) ||
    (record.taxonomy.proposed_concept_tags?.length ?? 0) > 0;
  if (!hasProposal || record.taxonomy.status === "pending") {
    return { reviewed: false, reason: "missing_proposal", ranked: [] };
  }
  const ranked = definitions
    .map((definition) => ({ definition, ...scoreDefinition(record.taxonomy, definition) }))
    .sort((left, right) => right.score - left.score || left.definition.key.localeCompare(right.definition.key));
  const first = ranked[0];
  const second = ranked[1];
  const margin = first.score - second.score;
  const reviewed = first.score >= 18 && (margin >= 3 || first.score >= 34);
  return {
    reviewed,
    reason: reviewed ? "strong_registered_match" : first.score < 18 ? "weak_match" : "ambiguous_match",
    definition: first.definition,
    score: Number(first.score.toFixed(2)),
    margin: Number(margin.toFixed(2)),
    evidence: first.evidence,
    ranked: ranked.slice(0, 2).map(({ definition, score }) => ({ key: definition.key, score: Number(score.toFixed(2)) })),
  };
}

function difficultyIsConsistent(difficulty, extractionStatus) {
  if (extractionStatus !== "screened_complete") return false;
  if (!difficultyLabels.has(difficulty.screened)) return false;
  if (typeof difficulty.confidence !== "number" || difficulty.confidence < 0.75) return false;
  if (!Array.isArray(difficulty.anchor_evidence) || difficulty.anchor_evidence.length === 0) return false;
  const dimensions = difficulty.dimensions;
  if (!dimensions) return false;
  for (const [key, [minimum, maximum]] of Object.entries(dimensionRanges)) {
    const value = dimensions[key];
    if (!Number.isInteger(value) || value < minimum || value > maximum) return false;
  }
  const total = Object.values(dimensions).reduce((sum, value) => sum + value, 0);
  const depth = dimensions.reasoning_depth;
  const insight = dimensions.non_routine_insight;
  if (difficulty.screened === "above_average") return total >= 3 && total <= 12 && depth <= 3 && insight <= 2;
  if (difficulty.screened === "hard") return total >= 8 && total <= 17 && depth >= 1;
  if (difficulty.screened === "very_hard") return total >= 14 && (depth >= 3 || insight >= 3);
  return total >= 18 && depth >= 3 && insight >= 3;
}

function readJsonLines(file) {
  return fs.readFileSync(file, "utf8").split(/\r?\n/).filter(Boolean).map((line, index) => {
    try {
      return JSON.parse(line);
    } catch (error) {
      throw new Error(`${file}:${index + 1}: ${error.message}`);
    }
  });
}

function writeAtomic(file, content) {
  const temporary = `${file}.tmp`;
  const backup = `${file}.previous`;
  fs.writeFileSync(temporary, content, "utf8");
  if (!fs.existsSync(file)) {
    fs.renameSync(temporary, file);
    return;
  }
  if (fs.existsSync(backup)) fs.unlinkSync(backup);
  fs.renameSync(file, backup);
  try {
    fs.renameSync(temporary, file);
    fs.unlinkSync(backup);
  } catch (error) {
    if (fs.existsSync(file)) fs.unlinkSync(file);
    fs.renameSync(backup, file);
    if (fs.existsSync(temporary)) fs.unlinkSync(temporary);
    throw error;
  }
}

function registrySubtopics() {
  const keys = new Set();
  return Object.entries(catalog).flatMap(([topic_key, definitions]) =>
    definitions.map((definition, index) => {
      if (keys.has(definition.key)) throw new Error(`Duplicate subtopic key ${definition.key}`);
      keys.add(definition.key);
      return {
        key: definition.key,
        topic_key,
        label_en: definition.label_en,
        label_fa: definition.label_fa,
        order: index + 1,
        concept_tags: definition.concept_tags,
        prerequisites: definition.prerequisites,
      };
    }),
  );
}

function buildRegistry() {
  const current = JSON.parse(fs.readFileSync(taxonomyFile, "utf8"));
  const topicKeys = new Set(current.sections.flatMap((section) => section.topics));
  const catalogKeys = new Set(Object.keys(catalog));
  const missing = [...topicKeys].filter((key) => !catalogKeys.has(key));
  const extra = [...catalogKeys].filter((key) => !topicKeys.has(key));
  if (missing.length || extra.length) {
    throw new Error(`Catalog/topic mismatch. missing=${missing.join(",")} extra=${extra.join(",")}`);
  }
  return { ...current, version: registryVersion, subtopics: registrySubtopics() };
}

function protectedRecord(record) {
  const clone = structuredClone(record);
  delete clone.taxonomy;
  delete clone.difficulty;
  return JSON.stringify(clone);
}

function evaluate(records) {
  const results = [];
  const topicSummary = {};
  const unresolvedExamples = [];
  let taxonomyReviewed = 0;
  let difficultyReviewed = 0;
  for (const record of records) {
    const classification = classifyTaxonomy(record);
    results.push(classification);
    const topic = record.taxonomy.topic_key;
    topicSummary[topic] ??= { total: 0, reviewed: 0, unresolved: 0, subtopics: {} };
    topicSummary[topic].total += 1;
    if (classification.reviewed) {
      taxonomyReviewed += 1;
      topicSummary[topic].reviewed += 1;
      topicSummary[topic].subtopics[classification.definition.key] =
        (topicSummary[topic].subtopics[classification.definition.key] ?? 0) + 1;
    } else {
      topicSummary[topic].unresolved += 1;
      if (unresolvedExamples.length < 40) {
        unresolvedExamples.push({
          question_id: record.question_id,
          topic,
          proposal: record.taxonomy.proposed_subtopic?.key ?? null,
          reason: classification.reason,
          ranked: classification.ranked,
        });
      }
    }
    if (difficultyIsConsistent(record.difficulty, record.extraction.status)) difficultyReviewed += 1;
  }
  return {
    results,
    report: {
      registry_version: registryVersion,
      records: records.length,
      registered_subtopics: registrySubtopics().length,
      taxonomy: { reviewed: taxonomyReviewed, unresolved: records.length - taxonomyReviewed },
      difficulty: { reviewed: difficultyReviewed, unresolved: records.length - difficultyReviewed },
      topics: Object.fromEntries(Object.entries(topicSummary).map(([topic, summary]) => [topic, {
        ...summary,
        subtopics: Object.fromEntries(Object.entries(summary.subtopics).sort(([, left], [, right]) => right - left)),
      }])),
      unresolved_examples: unresolvedExamples,
    },
  };
}

function applyClassifications(records, results) {
  const updated = structuredClone(records);
  for (let index = 0; index < updated.length; index += 1) {
    const record = updated[index];
    const result = results[index];
    if (result.reviewed) {
      record.taxonomy.registry_version = registryVersion;
      record.taxonomy.subtopic_key = result.definition.key;
      record.taxonomy.concept_tags = [...result.definition.concept_tags];
      record.taxonomy.secondary_concepts = [];
      record.taxonomy.prerequisites = [...result.definition.prerequisites];
      record.taxonomy.status = "reviewed";
    }
    if (difficultyIsConsistent(record.difficulty, record.extraction.status)) {
      record.difficulty.reviewed = record.difficulty.screened;
      record.difficulty.status = "reviewed";
    }
  }
  return updated;
}

function validateMutation(before, after, registry) {
  if (before.length !== after.length) throw new Error("Manifest row count changed");
  const registered = new Map(registry.subtopics.map((subtopic) => [subtopic.key, subtopic]));
  for (let index = 0; index < before.length; index += 1) {
    const left = before[index];
    const right = after[index];
    if (left.question_id !== right.question_id || left.source_sha256 !== right.source_sha256 || left.runtime_record_sha256 !== right.runtime_record_sha256) {
      throw new Error(`Source identity changed at row ${index + 1}`);
    }
    if (protectedRecord(left) !== protectedRecord(right)) {
      throw new Error(`Out-of-lane fields changed for ${left.question_id}`);
    }
    if (right.taxonomy.status === "reviewed") {
      const definition = registered.get(right.taxonomy.subtopic_key);
      if (!definition || definition.topic_key !== right.taxonomy.topic_key || right.taxonomy.registry_version !== registryVersion || right.taxonomy.concept_tags.length === 0) {
        throw new Error(`Invalid reviewed taxonomy for ${right.question_id}`);
      }
    }
    if (right.difficulty.status === "reviewed" && !difficultyIsConsistent(right.difficulty, right.extraction.status)) {
      throw new Error(`Invalid reviewed difficulty for ${right.question_id}`);
    }
  }
}

const command = process.argv[2] ?? "dry-run";
const records = readJsonLines(manifestFile);
const registry = buildRegistry();
const { results, report } = evaluate(records);

if (command === "dry-run") {
  console.log(JSON.stringify(report, null, 2));
} else if (command === "write-registry") {
  writeAtomic(taxonomyFile, `${JSON.stringify(registry, null, 2)}\n`);
  console.log(JSON.stringify({ wrote_registry: registryVersion, subtopics: registry.subtopics.length }, null, 2));
} else if (command === "apply") {
  const liveRegistry = JSON.parse(fs.readFileSync(taxonomyFile, "utf8"));
  if (liveRegistry.version !== registryVersion || JSON.stringify(liveRegistry.subtopics) !== JSON.stringify(registry.subtopics)) {
    throw new Error("Frozen registry does not match the reviewed catalog. Run write-registry first.");
  }
  const updated = applyClassifications(records, results);
  validateMutation(records, updated, liveRegistry);
  writeAtomic(manifestFile, `${updated.map((record) => JSON.stringify(record)).join("\n")}\n`);
  console.log(JSON.stringify({ applied: true, ...report }, null, 2));
} else {
  throw new Error("Usage: node scripts/freeze_taxonomy_registry.mjs [dry-run|write-registry|apply]");
}
