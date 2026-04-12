package org.sada.messenger.growth

import android.content.Context

class ServiceProfileStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun load(): ServiceProfileState {
        return ServiceProfileState(
            publicChannelEnabled = prefs.getBoolean(KEY_PUBLIC_ENABLED, true),
            selectedTemplateId = prefs.getString(KEY_TEMPLATE_ID, "taxi") ?: "taxi",
            displayName = prefs.getString(KEY_NAME, "") ?: "",
            description = prefs.getString(KEY_DESC, "") ?: "",
            address = prefs.getString(KEY_ADDRESS, "") ?: "",
            workingHours = prefs.getString(KEY_WORKING_HOURS, "") ?: "",
            contactInfo = prefs.getString(KEY_CONTACT_INFO, "") ?: "",
            deliveryAvailable = prefs.getBoolean(KEY_DELIVERY_AVAILABLE, false),
            deliveryRadiusKm = prefs.getString(KEY_DELIVERY_RADIUS, "5") ?: "5",
            quickReply = prefs.getString(KEY_QUICK_REPLY, "") ?: "",
            updatedAt = prefs.getLong(KEY_UPDATED_AT, 0L)
        )
    }

    fun save(state: ServiceProfileState) {
        prefs.edit()
            .putBoolean(KEY_PUBLIC_ENABLED, state.publicChannelEnabled)
            .putString(KEY_TEMPLATE_ID, state.selectedTemplateId)
            .putString(KEY_NAME, state.displayName)
            .putString(KEY_DESC, state.description)
            .putString(KEY_ADDRESS, state.address)
            .putString(KEY_WORKING_HOURS, state.workingHours)
            .putString(KEY_CONTACT_INFO, state.contactInfo)
            .putBoolean(KEY_DELIVERY_AVAILABLE, state.deliveryAvailable)
            .putString(KEY_DELIVERY_RADIUS, state.deliveryRadiusKm)
            .putString(KEY_QUICK_REPLY, state.quickReply)
            .putLong(KEY_UPDATED_AT, System.currentTimeMillis())
            .apply()
    }

    companion object {
        private const val PREFS_NAME = "sada_service_profile"
        private const val KEY_PUBLIC_ENABLED = "public_enabled"
        private const val KEY_TEMPLATE_ID = "template_id"
        private const val KEY_NAME = "name"
        private const val KEY_DESC = "description"
        private const val KEY_ADDRESS = "address"
        private const val KEY_WORKING_HOURS = "working_hours"
        private const val KEY_CONTACT_INFO = "contact_info"
        private const val KEY_DELIVERY_AVAILABLE = "delivery_available"
        private const val KEY_DELIVERY_RADIUS = "delivery_radius_km"
        private const val KEY_QUICK_REPLY = "quick_reply"
        private const val KEY_UPDATED_AT = "updated_at"
    }
}
