package org.sada.messenger.ui.utils

import java.util.Locale

fun tr(ar: String, en: String): String {
    val lang = Locale.getDefault().language
    return if (lang.startsWith("ar")) ar else en
}
