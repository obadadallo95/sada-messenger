package org.sada.messenger.runtime

import kotlinx.coroutines.Job
import kotlinx.coroutines.CompletableJob
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin
import java.util.concurrent.ConcurrentHashMap

/** Tracks one-shot work that must finish cancelling before an owner is stopped. */
internal class LifecycleJobSet {
    private val jobs = ConcurrentHashMap.newKeySet<Job>()

    fun track(job: Job): Job {
        jobs += job
        job.invokeOnCompletion { jobs -= job }
        return job
    }

    suspend fun cancelAndJoinAll() {
        while (true) {
            val snapshot = jobs.toList()
            if (snapshot.isEmpty()) return
            snapshot.forEach { it.cancel() }
            snapshot.forEach { it.cancelAndJoin() }
            jobs.removeAll(snapshot.toSet())
        }
    }

    val size: Int get() = jobs.size
}

/** A cancellable child-job generation that can be recreated on the next start. */
internal class RestartableCoroutineGeneration(
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO
) {
    private var rootJob: CompletableJob? = null
    private var currentScope = CoroutineScope(dispatcher + SupervisorJob().also { it.cancel() })

    val scope: CoroutineScope get() = currentScope
    val isActive: Boolean get() = rootJob?.isActive == true

    @Synchronized
    fun start(): Boolean {
        if (rootJob?.isActive == true) return false
        val freshRoot = SupervisorJob()
        rootJob = freshRoot
        currentScope = CoroutineScope(dispatcher + freshRoot)
        return true
    }

    suspend fun stop() {
        val job = synchronized(this) { rootJob } ?: return
        job.cancelAndJoin()
        synchronized(this) {
            if (rootJob === job) rootJob = null
        }
    }
}
