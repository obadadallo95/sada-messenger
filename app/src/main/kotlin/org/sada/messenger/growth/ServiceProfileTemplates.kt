package org.sada.messenger.growth

data class ServiceProfileTemplate(
    val id: String,
    val emoji: String,
    val titleAr: String,
    val titleEn: String,
    val descAr: String,
    val descEn: String,
    val defaultWorkingHoursAr: String = "يوميًا 9:00 ص - 9:00 م",
    val defaultWorkingHoursEn: String = "Daily 9:00 AM - 9:00 PM",
    val supportsDelivery: Boolean = false
)

data class ServiceProfileState(
    val publicChannelEnabled: Boolean = true,
    val selectedTemplateId: String = "taxi",
    val displayName: String = "",
    val description: String = "",
    val address: String = "",
    val workingHours: String = "",
    val contactInfo: String = "",
    val deliveryAvailable: Boolean = false,
    val deliveryRadiusKm: String = "5",
    val quickReply: String = "",
    val updatedAt: Long = 0L
)

object ServiceProfileTemplates {
    val all: List<ServiceProfileTemplate> = listOf(
        ServiceProfileTemplate(
            id = "taxi",
            emoji = "🚕",
            titleAr = "خدمة تكسي",
            titleEn = "Taxi Service",
            descAr = "حجز مشوار قريب عبر شبكة صدى",
            descEn = "Book a nearby ride through Sada mesh",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "market",
            emoji = "🛒",
            titleAr = "متجر محلي",
            titleEn = "Local Market",
            descAr = "طلبات سريعة وتوفر المنتجات",
            descEn = "Quick orders and product availability",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "pharmacy",
            emoji = "💊",
            titleAr = "صيدلية",
            titleEn = "Pharmacy",
            descAr = "استفسار عن الأدوية والحجوزات",
            descEn = "Medicine inquiries and reservations",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "maintenance",
            emoji = "🔧",
            titleAr = "صيانة",
            titleEn = "Maintenance",
            descAr = "خدمات تصليح منزلية سريعة",
            descEn = "Fast home maintenance services",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "restaurant",
            emoji = "🍽️",
            titleAr = "مطعم",
            titleEn = "Restaurant",
            descAr = "طلبات وجبات وحجز طاولات",
            descEn = "Meals delivery and table booking",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "coffee",
            emoji = "☕",
            titleAr = "كافيه",
            titleEn = "Coffee Shop",
            descAr = "طلبات قهوة ومشروبات سريعة",
            descEn = "Coffee and quick drinks orders",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "clinic",
            emoji = "🩺",
            titleAr = "عيادة",
            titleEn = "Clinic",
            descAr = "استشارات وحجوزات طبية",
            descEn = "Medical consultations and bookings",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "grocery",
            emoji = "🥬",
            titleAr = "خضار وفواكه",
            titleEn = "Grocery",
            descAr = "طلبات مواد غذائية يومية",
            descEn = "Daily grocery orders",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "bakery",
            emoji = "🥖",
            titleAr = "مخبز",
            titleEn = "Bakery",
            descAr = "خبز ومعجنات طازجة",
            descEn = "Fresh bread and pastries",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "beauty",
            emoji = "💇",
            titleAr = "صالون تجميل",
            titleEn = "Beauty Salon",
            descAr = "حجز مواعيد تجميل وعناية",
            descEn = "Beauty and care appointments",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "electronics",
            emoji = "📱",
            titleAr = "إلكترونيات",
            titleEn = "Electronics",
            descAr = "صيانة وبيع أجهزة واكسسوارات",
            descEn = "Device repair and accessories sales",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "education",
            emoji = "📚",
            titleAr = "مركز تعليمي",
            titleEn = "Education Center",
            descAr = "دروس خاصة ومتابعة تعليمية",
            descEn = "Private lessons and tutoring",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "logistics",
            emoji = "📦",
            titleAr = "خدمة توصيل",
            titleEn = "Delivery Service",
            descAr = "استلام وتسليم الطلبات داخل المدينة",
            descEn = "Pickup and delivery across town",
            supportsDelivery = true
        ),
        ServiceProfileTemplate(
            id = "hotel",
            emoji = "🏨",
            titleAr = "فندق / إقامة",
            titleEn = "Hotel / Stay",
            descAr = "حجوزات إقامة وخدمات استقبال",
            descEn = "Stay booking and reception services",
            supportsDelivery = false
        ),
        ServiceProfileTemplate(
            id = "workshop",
            emoji = "🛠️",
            titleAr = "ورشة",
            titleEn = "Workshop",
            descAr = "خدمات صيانة فنية وميدانية",
            descEn = "Technical and field maintenance services",
            supportsDelivery = false
        )
    )

    fun findById(id: String?): ServiceProfileTemplate =
        all.firstOrNull { it.id == id } ?: all.first()
}
