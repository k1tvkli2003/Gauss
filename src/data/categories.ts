import type { Subject } from "@/types";

export interface CategoryDef {
  key: string;
  label: string;
  faLabel: string;
  subCategories: { key: string; faLabel: string }[];
}

// Iranian high-school curriculum (Dovvom-e Motevaseteh, grades 10-12).
export const CATEGORIES: Record<Subject, CategoryDef[]> = {
  math: [
    {
      key: "hesaban",
      label: "Calculus",
      faLabel: "حسابان",
      subCategories: [
        { key: "limits", faLabel: "حد و پیوستگی" },
        { key: "derivatives", faLabel: "مشتق" },
        { key: "integrals", faLabel: "انتگرال" },
        { key: "functions", faLabel: "توابع" },
        { key: "trigonometry", faLabel: "مثلثات" },
      ],
    },
    {
      key: "hendeseh",
      label: "Geometry",
      faLabel: "هندسه",
      subCategories: [
        { key: "analytical", faLabel: "هندسه تحلیلی" },
        { key: "spatial", faLabel: "هندسه فضایی" },
        { key: "circle", faLabel: "دایره" },
        { key: "conics", faLabel: "مقاطع مخروطی" },
      ],
    },
    {
      key: "gosasteh_amar",
      label: "Discrete & Stats",
      faLabel: "گسسته و آمار",
      subCategories: [
        { key: "discrete", faLabel: "ریاضیات گسسته" },
        { key: "combinatorics", faLabel: "ترکیبیات" },
        { key: "probability", faLabel: "احتمال" },
        { key: "statistics", faLabel: "آمار" },
        { key: "number_theory", faLabel: "نظریه اعداد" },
      ],
    },
  ],
  physics: [
    {
      key: "mechanics",
      label: "Mechanics",
      faLabel: "مکانیک",
      subCategories: [
        { key: "kinematics", faLabel: "سینماتیک" },
        { key: "dynamics", faLabel: "دینامیک" },
        { key: "work_energy", faLabel: "کار و انرژی" },
        { key: "momentum", faLabel: "تکانه" },
      ],
    },
    {
      key: "electromagnetism",
      label: "Electromagnetism",
      faLabel: "الکترومغناطیس",
      subCategories: [
        { key: "electrostatics", faLabel: "الکتروستاتیک" },
        { key: "circuits", faLabel: "مدارها" },
        { key: "magnetism", faLabel: "مغناطیس" },
        { key: "induction", faLabel: "القا" },
      ],
    },
    {
      key: "thermodynamics",
      label: "Thermo & Fluids",
      faLabel: "ترمودینامیک و سیالات",
      subCategories: [
        { key: "heat", faLabel: "گرما و دما" },
        { key: "gas_laws", faLabel: "قوانین گازها" },
        { key: "fluids", faLabel: "سیالات" },
      ],
    },
    {
      key: "waves_modern",
      label: "Waves & Modern",
      faLabel: "موج و فیزیک نوین",
      subCategories: [
        { key: "oscillations", faLabel: "نوسان" },
        { key: "waves", faLabel: "امواج" },
        { key: "optics", faLabel: "نور" },
        { key: "modern", faLabel: "فیزیک اتمی و نوین" },
      ],
    },
  ],
};

export function categoryLabel(subject: Subject, key: string): string {
  return CATEGORIES[subject].find((c) => c.key === key)?.faLabel ?? key;
}
