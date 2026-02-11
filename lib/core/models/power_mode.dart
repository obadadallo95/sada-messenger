/// وضع استهلاك الطاقة
/// يحدد فترات المسح والنوم للخدمة الخلفية
enum PowerMode {
  /// أداء عالي - مسح مستمر (جيد للمحادثات النشطة)
  highPerformance,

  /// متوازن - مسح 30 ثانية، نوم 5 دقائق (افتراضي)
  balanced,

  /// توفير الطاقة - مسح 30 ثانية، نوم 15 دقيقة
  lowPower,
}

extension PowerModeExtension on PowerMode {
  /// إنشاء من String
  static PowerMode fromStorageString(String value) {
    switch (value) {
      case 'high':
        return PowerMode.highPerformance;
      case 'low':
        return PowerMode.lowPower;
      case 'balanced':
      default:
        return PowerMode.balanced;
    }
  }
  /// مدة المسح بالثواني
  int get scanDurationSeconds => 30;

  /// مدة النوم بالدقائق
  int get sleepDurationMinutes {
    switch (this) {
      case PowerMode.highPerformance:
        return 0; // لا نوم - مسح مستمر
      case PowerMode.balanced:
        return 5;
      case PowerMode.lowPower:
        return 15;
    }
  }

  /// مدة النوم بالثواني
  int get sleepDurationSeconds => sleepDurationMinutes * 60;

  /// اسم الوضع بالعربية
  String getDisplayNameAr() {
    switch (this) {
      case PowerMode.highPerformance:
        return 'أداء عالي';
      case PowerMode.balanced:
        return 'متوازن';
      case PowerMode.lowPower:
        return 'توفير الطاقة';
    }
  }

  /// اسم الوضع بالإنجليزية
  String getDisplayNameEn() {
    switch (this) {
      case PowerMode.highPerformance:
        return 'High Performance';
      case PowerMode.balanced:
        return 'Balanced';
      case PowerMode.lowPower:
        return 'Low Power';
    }
  }

  /// وصف الوضع بالعربية
  String getDescriptionAr() {
    switch (this) {
      case PowerMode.highPerformance:
        return 'مسح مستمر (جيد للمحادثات النشطة)';
      case PowerMode.balanced:
        return 'مسح 30 ثانية، نوم 5 دقائق';
      case PowerMode.lowPower:
        return 'مسح 30 ثانية، نوم 15 دقيقة';
    }
  }

  /// وصف الوضع بالإنجليزية
  String getDescriptionEn() {
    switch (this) {
      case PowerMode.highPerformance:
        return 'Continuous scanning (Good for active chats)';
      case PowerMode.balanced:
        return 'Scan 30s, Sleep 5 mins';
      case PowerMode.lowPower:
        return 'Scan 30s, Sleep 15 mins';
    }
  }

  /// تحويل إلى String للحفظ
  String toStorageString() {
    switch (this) {
      case PowerMode.highPerformance:
        return 'high';
      case PowerMode.balanced:
        return 'balanced';
      case PowerMode.lowPower:
        return 'low';
    }
  }

  /// اسم الوضع (يستخدم اللغة الحالية)
  String get displayName => getDisplayNameAr();

  /// وصف الوضع (يستخدم اللغة الحالية)
  String get description => getDescriptionAr();
}

