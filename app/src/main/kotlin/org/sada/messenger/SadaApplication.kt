package org.sada.messenger

import android.app.Application
import org.sada.messenger.runtime.MeshRuntime

class SadaApplication : Application() {
    val meshRuntime: MeshRuntime by lazy(LazyThreadSafetyMode.SYNCHRONIZED) {
        MeshRuntime(applicationContext)
    }
}
