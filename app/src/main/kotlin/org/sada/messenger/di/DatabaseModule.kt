package org.sada.messenger.di

import android.content.Context
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import org.sada.messenger.data.db.AppDatabase
import javax.inject.Singleton

/**
 * Dagger Hilt Module: Database
 * Provides database dependencies
 */
@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AppDatabase {
        return AppDatabase.getDatabase(context)
    }

    @Provides
    fun provideContactDao(database: AppDatabase) = database.contactDao()

    @Provides
    fun provideChatDao(database: AppDatabase) = database.chatDao()

    @Provides
    fun provideMessageDao(database: AppDatabase) = database.messageDao()

    @Provides
    fun provideGroupDao(database: AppDatabase) = database.groupDao()

    @Provides
    fun providePollDao(database: AppDatabase) = database.pollDao()

    @Provides
    fun provideRelayQueueDao(database: AppDatabase) = database.relayQueueDao()

    @Provides
    fun provideMediaChunkDao(database: AppDatabase) = database.mediaChunkDao()

    @Provides
    fun provideSeenMessageDao(database: AppDatabase) = database.seenMessageDao()

    @Provides
    fun provideConnectionRequestDao(database: AppDatabase) = database.connectionRequestDao()
}
