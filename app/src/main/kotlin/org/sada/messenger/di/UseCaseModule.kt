package org.sada.messenger.di

import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.components.ViewModelComponent
import dagger.hilt.android.scopes.ViewModelScoped
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.domain.usecase.*
import org.sada.messenger.network.MeshEngine
import org.sada.messenger.security.EncryptionManager
import org.sada.messenger.security.KeyManager

/**
 * Dagger Hilt Module: Use Cases
 * Provides use case dependencies for ViewModels
 */
@Module
@InstallIn(ViewModelComponent::class)
object UseCaseModule {

    @Provides
    @ViewModelScoped
    fun provideSendMessageUseCase(
        database: AppDatabase,
        meshEngine: MeshEngine,
        keyManager: KeyManager,
        encryptionManager: EncryptionManager
    ): SendMessageUseCase {
        return SendMessageUseCase(database, meshEngine, keyManager, encryptionManager)
    }

    @Provides
    @ViewModelScoped
    fun provideGetMessagesUseCase(
        database: AppDatabase
    ): GetMessagesUseCase {
        return GetMessagesUseCase(database)
    }

    @Provides
    @ViewModelScoped
    fun provideDeleteMessageUseCase(
        database: AppDatabase
    ): DeleteMessageUseCase {
        return DeleteMessageUseCase(database)
    }

    @Provides
    @ViewModelScoped
    fun provideManageGroupMemberUseCase(
        database: AppDatabase,
        meshEngine: MeshEngine
    ): ManageGroupMemberUseCase {
        return ManageGroupMemberUseCase(database, meshEngine)
    }
}
