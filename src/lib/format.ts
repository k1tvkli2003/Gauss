const FA_DIGITS = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];

/** Convert any Western digits in a value to Persian (Eastern Arabic-Indic). */
export function toFa(value: string | number): string {
  return String(value).replace(/\d/g, (d) => FA_DIGITS[Number(d)]);
}

/** Persian-digit percentage, e.g. 73 -> "۷۳٪". */
export function faPercent(value: number): string {
  return `${toFa(Math.round(value))}٪`;
}
