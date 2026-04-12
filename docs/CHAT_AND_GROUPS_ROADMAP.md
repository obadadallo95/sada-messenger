# خطة تطوير الدردشة والمجموعات - الإصدار الكامل

**تاريخ الإنشاء:** 2025-01-XX  
**الحالة:** قيد التنفيذ الفوري  
**المدة:** 4-6 أسابيع

---

## 📊 مراجعة الوضع الحالي

### ✅ ما يعمل الآن (v1.0):

| الميزة | الحالة | التفاصيل |
|--------|--------|----------|
| **رسائل نصية** | ✅ | E2E encrypted، حالات (sent/delivered) |
| **رسائل صوتية** | ✅ | تسجيل + تشغيل + progress |
| **حذف الرسائل** | ✅ | فردي ومتعدد + confirm |
| **فاصل التواريخ** | ✅ | اليوم/أمس/التاريخ |
| **إنشاء مجموعات** | ✅ | Public/Private + Join policies |
| **طلبات الانضمام** | ✅ | Approval workflow |
| **دعوة أعضاء** | ✅ | عند إنشاء المجموعة |
| **إزالة أعضاء** | ✅ | مع تدوير مفتاح المجموعة |
| **ترقية/تنزيل الصلاحيات** | ⚠️ | يحتاج UI كامل |

### ⛔ ما ينقص (أولوية فورية):

| الميزة | الأولوية | السبب |
|--------|----------|-------|
| **الرد على الرسالة** (Reply/Quote) | 🔴 عالية | أساسي للمحادثات |
| **إعادة الإرسال** (Forward) | 🔴 عالية | نشر المعلومات المهمة |
| **تعديل الرسالة** (Edit) | 🟡 متوسطة | تصحيح الأخطاء |
| **تقييد المجموعة** (Restrict) | 🔴 عالية | منع الفوضى |
| **تثبيت الرسائل** (Pin) | 🟡 متوسطة | إعلانات مهمة |
| **حظر من المجموعة** (Ban/Kick) | 🔴 عالية | إدارة المجموعة |
| **صلاحيات الأدمن** | 🔴 عالية | التحكم بالمجموعة |
| **الاستطلاعات** (Polls) | 🟡 متوسطة | قرارات جماعية |
| **الفعاليات** (Events) | 🟢 منخفضة | تخطيط لقاءات |

---

## ✅ تم إكمال الخطة - Complete
**تاريخ الإنجاز**: 11 أبريل 2026
**الحالة**: جميع الميزات مُنفذة وتم البناء بنجاح ✅

---

## 🎯 خطة التطوير الفورية (4-6 أسابيع)

### الأسبوع 1: الرد والإعادة (Reply & Forward) ✅

#### اليوم 1-2: الرد على الرسالة (Reply/Quote)

**التعديلات المطلوبة:**

```kotlin
// 1. MessageEntity - إضافة حقل replyToId
data class MessageEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val senderId: String,
    val content: String,
    val timestamp: Date = Date(),
    val status: String = "pending",
    val isVoice: Boolean = false,
    val voiceDurationMs: Int = 0,
    // NEW: Reply functionality
    val replyToId: String? = null,
    val replyToSender: String? = null,
    val replyToContent: String? = null
)
```

```kotlin
// 2. ChatScreen - UI للرد
- Swipe right على الرسالة للرد
- عرض quoted message فوق مربع الكتابة
- زر X لإلغاء الرد
```

```kotlin
// 3. GlassMessageBubble - عرض الرد
@Composable
fun ReplyBubble(
    senderName: String,
    content: String,
    isCurrentUser: Boolean
) {
    // عرض مربع ملون بشكل مختلف
    // نص مختصر إذا كان طويلاً
}
```

**الملفات المعدلة:**
- `MessageEntity.kt`
- `ChatScreen.kt`
- `ChatViewModel.kt` (sendMessage مع replyTo)
- `GlassMessageBubble.kt`

---

#### اليوم 3-4: إعادة الإرسال (Forward)

**التعديلات المطلوبة:**

```kotlin
// 1. ForwardMessageDialog - اختيار جهة الاتصال/المجموعة
@Composable
fun ForwardMessageDialog(
    message: MessageEntity,
    contacts: List<ContactEntity>,
    groups: List<ChatEntity>,
    onForward: (targetId: String, isGroup: Boolean) -> Unit,
    onDismiss: () -> Unit
)
```

**المنطق:**
```kotlin
// 2. ChatViewModel
fun forwardMessage(
    originalMessage: MessageEntity,
    targetChatId: String,
    isGroup: Boolean
) {
    val newMessage = originalMessage.copy(
        id = generateNewId(),
        chatId = targetChatId,
        timestamp = Date(),
        status = "pending",
        replyToId = null // لا ينقل الرد
    )
    
    if (isGroup) {
        sendGroupMessage(newMessage)
    } else {
        sendDirectMessage(newMessage)
    }
}
```

**الملفات المعدلة:**
- `ChatScreen.kt` (menu item "إعادة إرسال")
- `ChatViewModel.kt` (forwardMessage)
- `ForwardDialog.kt` (جديد)

---

### الأسبوع 2: إدارة المجموعات المتقدمة

#### اليوم 5-7: صلاحيات الأدمن والمشرفين (Admin/Moderator Roles)

**التعديلات المطلوبة:**

```kotlin
// 1. GroupMemberEntity - تحديث الأدوار
data class GroupMemberEntity(
    val groupId: String,
    val peerId: String,
    val role: String = "member", // owner | admin | moderator | member | invited | banned
    val joinedAt: Date = Date()
)
```

**صلاحيات كل دور:**

| الصلاحية | Owner | Admin | Moderator | Member |
|----------|-------|-------|-----------|--------|
| طرد/حظر عضو | ✅ | ✅ | ✅ | ❌ |
| إضافة أدمن | ✅ | ❌ | ❌ | ❌ |
| تغيير اسم المجموعة | ✅ | ✅ | ❌ | ❌ |
| تثبيت رسالة | ✅ | ✅ | ✅ | ❌ |
| تعديل وصف | ✅ | ✅ | ❌ | ❌ |
| إنشاء استطلاع | ✅ | ✅ | ✅ | ❌ |
| إرسال رسالة | ✅ | ✅ | ✅ | ✅ (إذا مسموح) |

```kotlin
// 2. GroupManagementScreen - شاشة إدارة المجموعة
@Composable
fun GroupManagementScreen(
    groupId: String,
    viewModel: GroupViewModel,
    onBack: () -> Unit
) {
    // تبويبات:
    // 1. الأعضاء (مع أدوارهم)
    // 2. الإعدادات
    // 3. طلبات الانضمام
}
```

**الملفات الجديدة:**
- `GroupManagementScreen.kt`
- `GroupMemberItem.kt` (عنصر عضو مع دوره)
- `RoleSelectionDialog.kt`

**الملفات المعدلة:**
- `GroupDao.kt` (updateMemberRole)
- `GroupProtocol.kt` (ROLE_CHANGE payload)
- `MeshEngine.kt` (sendRoleChange)

---

#### اليوم 8-9: الحظر والطرد (Ban/Kick)

**المنطق:**

```kotlin
// Kick = إزالة من المجموعة + إمكانية العودة
// Ban = إزالة + منع من العودة

suspend fun banMember(groupId: String, peerId: String, reason: String?) {
    // 1. إزالة من group_members
    database.groupDao().removeMemberById(groupId, peerId)
    
    // 2. إضافة إلى banned list
    database.groupDao().addBannedMember(
        BannedMemberEntity(
            groupId = groupId,
            peerId = peerId,
            bannedAt = Date(),
            reason = reason,
            bannedBy = myPeerId
        )
    )
    
    // 3. تدوير مفتاح المجموعة
    rotateGroupKey(groupId)
    
    // 4. إعلام الأعضاء
    sendBanNotification(groupId, peerId)
}
```

```kotlin
// GroupDao - إضافة دوال
@Query("SELECT * FROM banned_members WHERE groupId = :groupId")
fun getBannedMembers(groupId: String): List<BannedMemberEntity>

@Insert
suspend fun addBannedMember(banned: BannedMemberEntity)

@Query("DELETE FROM banned_members WHERE groupId = :groupId AND peerId = :peerId")
suspend fun unbanMember(groupId: String, peerId: String)
```

**الملفات الجديدة:**
- `BannedMemberEntity.kt`
- `BanDialog.kt` (سبب الحظر + مدة)

---

### الأسبوع 3: تثبيت وتقييد (Pin & Restrict)

#### اليوم 10-11: تثبيت الرسائل (Pin Message)

**التعديلات:**

```kotlin
// 1. ChatEntity - إضافة pinnedMessageId
@Entity(tableName = "chats")
data class ChatEntity(
    @PrimaryKey val id: String,
    val name: String,
    // ...
    val pinnedMessageId: String? = null,
    val pinnedBy: String? = null,
    val pinnedAt: Date? = null
)
```

```kotlin
// 2. ChatScreen - عرض الرسالة المثبتة
@Composable
fun PinnedMessageBar(
    message: MessageEntity,
    onUnpin: () -> Unit
) {
    // شريط في أعلى الشات
    // يعرض نص الرسالة المثبتة
    // زر "إلغاء التثبيت" للأدمن
}
```

**القواعد:**
- تثبيت رسالة واحدة فقط
- الأدمن فقط يستطيع التثبيت
- عند تثبيت جديد، يلغى القديم

---

#### اليوم 12-14: تقييد المجموعة (Group Restrictions)

**أنواع القيود:**

```kotlin
data class GroupRestrictions(
    val allowMessages: Boolean = true, // أعضاء يستطيعون الكتابة
    val allowMedia: Boolean = true,    // إرسال صوت/صورة
    val allowReplies: Boolean = true,
    val slowModeSeconds: Int = 0,      // تأخير بين الرسائل (ثواني)
    val requireApproval: Boolean = false // موافقة الأدمن على الرسائل
)
```

**تطبيق القيود:**

```kotlin
// في ChatViewModel
fun sendMessage(content: String): Boolean {
    val restrictions = getGroupRestrictions(chatId)
    
    if (!restrictions.allowMessages && !isAdminOrModerator()) {
        showError("الأدمن فقط يستطيع الكتابة")
        return false
    }
    
    if (restrictions.slowModeSeconds > 0) {
        val lastMessage = getLastMessageTime()
        if (System.currentTimeMillis() - lastMessage < restrictions.slowModeSeconds * 1000) {
            showError("انتظر ${restrictions.slowModeSeconds} ثوانٍ")
            return false
        }
    }
    
    // ... إرسال الرسالة
}
```

**UI:**
```kotlin
@Composable
fun GroupRestrictionsDialog(
    current: GroupRestrictions,
    onSave: (GroupRestrictions) -> Unit
) {
    // Switches لكل قيد
    // Slider لـ slow mode (0, 5, 10, 30, 60, 300, 3600 ثانية)
}
```

---

### الأسبوع 4: الاستطلاعات والفعاليات

#### اليوم 15-17: الاستطلاعات (Polls/Voting)

**الهيكل:**

```kotlin
@Entity(tableName = "polls")
data class PollEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val question: String,
    val options: List<String>, // JSON serialized
    val isMultipleChoice: Boolean = false,
    val isAnonymous: Boolean = true,
    val createdBy: String,
    val createdAt: Date = Date(),
    val endsAt: Date? = null // null = لا نهاية
)

@Entity(tableName = "poll_votes")
data class PollVoteEntity(
    val pollId: String,
    val peerId: String,
    val optionIndex: Int,
    @PrimaryKey val id: String = "${pollId}_${peerId}"
)
```

**UI:**

```kotlin
@Composable
fun PollBubble(
    poll: PollEntity,
    votes: List<PollVoteEntity>,
    onVote: (optionIndex: Int) -> Unit
) {
    // عرض السؤال والخيارات
    // Progress bars لنسب التصويت
    // زر "تصويت" أو عرض النتائج
}
```

**إنشاء استطلاع:**
```kotlin
@Composable
fun CreatePollDialog(
    onCreate: (question: String, options: List<String>, isMultiple: Boolean) -> Unit
) {
    // TextField للسؤال
    // قائمة خيارات (2-10 خيارات)
    // Checkbox لـ "اختيار متعدد"
}
```

---

#### اليوم 18-19: الفعاليات (Events)

**الهيكل:**

```kotlin
@Entity(tableName = "events")
data class EventEntity(
    @PrimaryKey val id: String,
    val chatId: String,
    val title: String,
    val description: String? = null,
    val location: String? = null,
    val startTime: Date,
    val endTime: Date? = null,
    val createdBy: String,
    val createdAt: Date = Date(),
    val maxAttendees: Int? = null // null = غير محدود
)

@Entity(tableName = "event_rsvps")
data class EventRsvpEntity(
    val eventId: String,
    val peerId: String,
    val status: String, // going | maybe | not_going
    @PrimaryKey val id: String = "${eventId}_${peerId}"
)
```

**UI:**

```kotlin
@Composable
fun EventBubble(
    event: EventEntity,
    rsvps: List<EventRsvpEntity>,
    onRsvp: (status: String) -> Unit
) {
    // عنوان + وقت + موقع
    // عدد المشاركين: "12 شخص سيحضرون"
    // أزرار: "سأحضر" / "ربما" / "لن أحضر"
}
```

---

### الأسبوع 5-6: التحسينات والتكامل

#### اليوم 20-22: تعديل الرسائل (Edit Message)

**المنطق:**

```kotlin
// MessageEntity - حقل جديد
val editedAt: Date? = null,
val originalContent: String? = null // للتاريخ
```

**القيود:**
- التعديل خلال 24 ساعة فقط
- إظهار "تم التعديل" بجانب الرسالة
- لا تعديل للرسائل المُحالة (forwarded)

**UI:**
```kotlin
// في القائمة المنبثقة للرسالة
"تعديل" → يفتح مربع كتابة مع النص القديم
"تم التعديل" → علامة صغيرة تحت الرسالة
```

---

#### اليوم 23-25: التكامل والاختبار

**المهام:**
1. تكامل جميع الميزات مع MeshEngine
2. اختبار الـ Key Rotation عند تغيير الأدوار
3. اختبار Sync بين أجهزة متعددة
4. Performance testing (1000+ رسالة)
5. Battery testing (استهلاك البطارية)

**سيناريوهات الاختبار:**
- إنشاء مجموعة → إضافة أعضاء → ترقية أدمن → طرد عضو
- تثبيت رسالة → إرسال 100 رسالة → التأكد من ظهور المثبتة
- استطلاع → 10 أشخاص يصوتون → التأكد من النتائج
- قيود المجموعة → محاولة عضو الكتابة → التأكد من الرفض

---

## 📁 الملفات الجديدة والمعدلة

### ملفات جديدة:

```
ui/screens/
├── GroupManagementScreen.kt       # إدارة المجموعة
├── CreatePollDialog.kt            # إنشاء استطلاع
├── ForwardDialog.kt               # إعادة إرسال
└── GroupRestrictionsDialog.kt     # قيود المجموعة

ui/components/
├── ReplyBubble.kt                 # عرض الرد
├── PinnedMessageBar.kt            # شريط الرسالة المثبتة
├── PollBubble.kt                  # فقاعة الاستطلاع
├── EventBubble.kt                 # فقاعة الفعالية
├── RoleSelectionDialog.kt         # اختيار الدور
└── BanDialog.kt                   # حظر عضو

data/entities/
├── PollEntity.kt                  # جدول الاستطلاعات
├── PollVoteEntity.kt              # جدول الأصوات
├── EventEntity.kt                 # جدول الفعاليات
├── EventRsvpEntity.kt             # جدول الحضور
├── BannedMemberEntity.kt          # جدول المحظورين
└── GroupRestrictionsEntity.kt     # قيود المجموعة

ui/viewmodels/
└── GroupViewModel.kt              # منطق إدارة المجموعة
```

### ملفات معدلة:

```
data/entities/
├── MessageEntity.kt              # + replyToId, editedAt
└── ChatEntity.kt                 # + pinnedMessageId

data/db/
├── AppDatabase.kt                # + entities جديدة
└── GroupDao.kt                   # + دوال إدارة

network/protocols/
└── GroupProtocol.kt              # + ROLE_CHANGE, BAN

network/
└── MeshEngine.kt                 # + إرسال إشعارات

ui/screens/
├── ChatScreen.kt                 # + رد، إعادة، تعديل
├── ChatViewModel.kt              # + forwardMessage, editMessage
└── GroupsScreen.kt               # + زر الإدارة

ui/components/
└── GlassMessageBubble.kt         # + ReplyBubble
```

---

## 🧪 خطة الاختبار

### اختبار الوحدة (Unit Tests):

```kotlin
@Test
fun testReplyMessage() {
    val original = createMessage("أصلية")
    val reply = createReplyMessage(original, "رد")
    
    assertEquals(original.id, reply.replyToId)
    assertEquals(original.senderId, reply.replyToSender)
}

@Test
fun testForwardMessage() {
    val original = createMessage("أصلية")
    val forwarded = forwardMessage(original, "group_2")
    
    assertEquals("group_2", forwarded.chatId)
    assertNull(forwarded.replyToId)
    assertNotEquals(original.id, forwarded.id)
}

@Test
fun testBanMember() {
    val group = createGroup()
    val member = addMember(group, "peer_1")
    
    banMember(group.id, "peer_1", "سبب")
    
    assertFalse(isMember(group.id, "peer_1"))
    assertTrue(isBanned(group.id, "peer_1"))
}

@Test
fun testRoleChange() {
    val member = addMember(group, "peer_1", "member")
    
    changeRole(group.id, "peer_1", "admin")
    
    assertEquals("admin", getMemberRole(group.id, "peer_1"))
}
```

### اختبار التكامل (Integration Tests):

```kotlin
@Test
fun testPinMessage() {
    val message = sendMessage("سأثبت")
    pinMessage(groupId, message.id)
    
    val group = getGroup(groupId)
    assertEquals(message.id, group.pinnedMessageId)
}

@Test
fun testPollVoting() {
    val poll = createPoll("سؤال", listOf("أ", "ب"))
    
    vote(poll.id, "peer_1", 0)
    vote(poll.id, "peer_2", 0)
    vote(poll.id, "peer_3", 1)
    
    val results = getPollResults(poll.id)
    assertEquals(2, results[0].count)
    assertEquals(1, results[1].count)
}
```

---

## 📊 التقدم المتوقع

| الأسبوع | الميزات | التقدم |
|---------|---------|--------|
| 1 | رد + إعادة | 100% |
| 2 | أدوار + حظر | 100% |
| 3 | تثبيت + قيود | 100% |
| 4 | استطلاعات + فعاليات | 100% |
| 5 | تعديل + تكامل | 100% |
| 6 | اختبار + تحسين | 100% |

---

## 🎯 معايير النجاح

بعد الانتهاء، يجب أن يكون:

- [ ] الرد على الرسالة يعمل بسلاسة (Swipe + عرض)
- [ ] إعادة الإرسال تدعم 10+ جهات في آن واحد
- [ ] 3 أدوار واضحة (Owner/Admin/Moderator) مع صلاحيات مختلفة
- [ ] الحظر يعمل + تدوير مفتاح تلقائي
- [ ] تثبيت رسالة واحدة في كل مجموعة
- [ ] Slow mode يمنع الإرسال السريع
- [ ] استطلاع يدعم 10 خيارات + 100+ مصوت
- [ ] فعالية مع RSVP (حضور/ربما/لن أحضر)
- [ ] تعديل الرسائل خلال 24 ساعة

---

## ⚠️ المخاطر والتخفيف

| المخطر | التأثير | التخفيف |
|--------|---------|---------|
| تعقيد الـ UI | متوسط | تدريجي التنفيذ + اختبار مستمر |
| Sync مشاكل | عالٍ | Conflict resolution strategy |
| Key rotation فشل | عالٍ | Backup keys + recovery mechanism |
| Battery drain | متوسط | Optimization + batch operations |
| Mesh saturation | متوسط | Priority queue + compression |

---

**البدء:** فوراً
**المدة:** 4-6 أسابيع
**الفريق:** 2-3 مطورين
**الأولوية:** قصوى

