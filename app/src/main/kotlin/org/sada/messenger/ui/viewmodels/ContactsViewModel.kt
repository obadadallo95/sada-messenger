package org.sada.messenger.ui.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.sada.messenger.data.db.AppDatabase
import org.sada.messenger.data.entities.ContactEntity

class ContactsViewModel(
    private val database: AppDatabase
) : ViewModel() {

    val contacts: StateFlow<List<ContactEntity>> = database.contactDao()
        .getAllContacts()
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5000),
            initialValue = emptyList()
        )

    fun addContact(name: String, publicKey: String) {
        viewModelScope.launch {
            val contact = ContactEntity(
                id = publicKey, // Using Public Key as the unique ID
                name = name,
                publicKey = publicKey
            )
            database.contactDao().insertContact(contact)
        }
    }

    fun deleteContact(contact: ContactEntity) {
        viewModelScope.launch {
            database.contactDao().deleteContact(contact)
        }
    }
}
