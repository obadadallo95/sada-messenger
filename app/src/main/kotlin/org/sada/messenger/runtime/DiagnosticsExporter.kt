package org.sada.messenger.runtime

import android.content.Context
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

data class ExportedDiagnostics(val file: File, val uri: Uri)

object DiagnosticsExporter {
    fun write(directory: File, report: DiagnosticsReport): File {
        directory.mkdirs()
        val stamp = report.generatedAt.replace(":", "-").substringBefore('.')
        return File(directory, "sada-diagnostics-$stamp.json").also {
            it.writeText(report.encode(), Charsets.UTF_8)
        }
    }

    fun export(context: Context, report: DiagnosticsReport): ExportedDiagnostics {
        val file = write(File(context.cacheDir, "diagnostics"), report)
        val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
        return ExportedDiagnostics(file, uri)
    }
}
