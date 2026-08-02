package org.sada.messenger.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import org.sada.messenger.SadaApplication
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager
import javax.inject.Singleton

/**
 * Dagger Hilt Module: Network
 * Provides mesh networking dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    @Provides
    @Singleton
    fun provideKeyManager(@ApplicationContext context: Context): KeyManager {
        return KeyManager(context)
    }

    @Provides
    @Singleton
    fun provideEncryptionManager(keyManager: KeyManager): EncryptionManager {
        return EncryptionManager(keyManager)
    }

    @Provides
    @Singleton
    fun provideMeshEngine(
        @ApplicationContext context: Context
    ): MeshEngine {
        return (context.applicationContext as SadaApplication).meshRuntime.meshEngine
    }
}
