export const curriculum = [
  {
    subject: "math",
    key: "math_10",
    faLabel: "ریاضی دهم تجربی",
    gradeLabel: "دهم",
    chapters: [
      ["sets_patterns_sequences", "مجموعه، الگو و دنباله"],
      ["trigonometry", "مثلثات"],
      ["rational_powers_algebraic_expressions", "توان‌های گویا و عبارت‌های جبری"],
      ["equations_inequalities", "معادله‌ها و نامعادله‌ها"],
      ["functions_domain_range", "تابع؛ مفهوم، دامنه و برد"],
      ["counting_without_counting", "شمارش، بدون شمردن"],
      ["statistics_probability", "آمار و احتمال"],
    ],
  },
  {
    subject: "math",
    key: "math_11",
    faLabel: "ریاضی یازدهم تجربی",
    gradeLabel: "یازدهم",
    chapters: [
      ["analytic_geometry_algebra", "هندسه تحلیلی و جبر"],
      ["geometry", "هندسه؛ تالس و تشابه"],
      ["functions_inverse_operations", "تابع؛ وارون و اعمال جبری"],
      ["trigonometry_advanced", "مثلثات؛ توابع و روابط تکمیلی"],
      ["exponential_logarithmic", "توابع نمایی و لگاریتمی"],
      ["limits_continuity", "حد و پیوستگی"],
      ["statistics_probability", "آمار و احتمال"],
    ],
  },
  {
    subject: "math",
    key: "math_12",
    faLabel: "ریاضی دوازدهم تجربی",
    gradeLabel: "دوازدهم",
    chapters: [
      ["functions_monotonic_composition", "تابع؛ صعودی، نزولی و ترکیب"],
      ["trigonometry_period_equations", "مثلثات؛ تناوب و معادلات"],
      ["infinite_limits", "حد بی‌نهایت و حد در بی‌نهایت"],
      ["derivatives", "مشتق"],
      ["derivative_applications", "کاربرد مشتق"],
      ["geometry_conics_circle", "هندسه؛ مقاطع مخروطی و دایره"],
      ["total_probability", "احتمال؛ قانون احتمال کل"],
    ],
  },
  {
    subject: "physics",
    key: "physics_10",
    faLabel: "فیزیک دهم تجربی",
    gradeLabel: "دهم",
    chapters: [
      ["physics_measurement", "فیزیک و اندازه‌گیری"],
      ["physical_properties_matter", "ویژگی‌های فیزیکی مواد"],
      ["work_energy_power", "کار، انرژی و توان"],
      ["temperature_heat", "دما و گرما"],
    ],
  },
  {
    subject: "physics",
    key: "physics_11",
    faLabel: "فیزیک یازدهم تجربی",
    gradeLabel: "یازدهم",
    chapters: [
      ["electrostatics", "الکتریسیته ساکن"],
      ["current_electricity", "الکتریسیته جاری"],
      ["magnetism_induction", "مغناطیس و القای الکترومغناطیسی"],
    ],
  },
  {
    subject: "physics",
    key: "physics_12",
    faLabel: "فیزیک دوازدهم تجربی",
    gradeLabel: "دوازدهم",
    chapters: [
      ["kinematics", "حرکت‌شناسی"],
      ["dynamics_circular_motion", "دینامیک و حرکت دایره‌ای"],
      ["oscillation_waves", "نوسان و امواج"],
      ["atomic_nuclear", "فیزیک اتمی و هسته‌ای"],
    ],
  },
];

export const validSubjects = new Set(["math", "physics"]);
export const courseByKey = new Map(curriculum.map((course) => [course.key, course]));
export const chaptersByCourse = new Map(
  curriculum.map((course) => [course.key, new Map(course.chapters.map(([key, label], index) => [key, { key, label, order: index + 1 }]))]),
);

export function isValidTopic(subject, courseKey, chapterKey) {
  const course = courseByKey.get(courseKey);
  return Boolean(
    course &&
      course.subject === subject &&
      chapterKey &&
      chaptersByCourse.get(courseKey)?.has(chapterKey),
  );
}

export function officialTopicRows() {
  return curriculum.flatMap((course) =>
    course.chapters.map(([chapterKey, chapterLabel], index) => ({
      subject: course.subject,
      course: course.key,
      courseLabel: course.faLabel,
      chapter: chapterKey,
      chapterLabel,
      order: index + 1,
    })),
  );
}
