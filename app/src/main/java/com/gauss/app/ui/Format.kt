package com.gauss.app.ui

private val FA_DIGITS = charArrayOf('۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹')

/** Convert Western digits to Persian (Eastern Arabic-Indic). */
fun toFa(value: Any): String = buildString {
    for (c in value.toString()) {
        if (c in '0'..'9') append(FA_DIGITS[c - '0']) else append(c)
    }
}

/** Persian-digit percentage, e.g. 73 -> "۷۳٪". */
fun faPercent(value: Number): String = "${toFa(Math.round(value.toDouble()))}٪"
