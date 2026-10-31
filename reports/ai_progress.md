# Flutter — تقدّم المساعد الذكي (S4)

## 4a — فحص المشروع ⛔ توقف (2026-10-31)

### ⚠️ تعارض مع نص المرحلة (يحتاج قرارك)
المرحلة 4a تفترض بداية من الصفر (`git init`، ثم commit أول، ثم الفرع، ثم بناء الشاشة). الواقع مختلف:

| المطلوب | الموجود فعلاً |
|---|---|
| `git init` + `.gitignore` | ✅ موجود: مستودع git بـ `.gitignore` قياسي لـ Flutter |
| commit «Initial snapshot before AI assistant» | ✅ موجود: `435d0e0` (عملته أنت قبل جلسة سابقة) |
| الفرع `feature/ai-skeleton` | ✅ موجود، وهو الحالي |
| شاشة المساعد | ✅ **مبنية في جلسة سابقة** (`24e02fb`) وجرّبتها على الهاتف (`3cd9626`) |

**لم أُعِد إنشاء أي شيء.** الخطة أدناه هي **الفروقات فقط** بين الموجود ومواصفات 4b.

---

### البيئة والحزم
- **Flutter 3.44.4** (stable) · **Dart 3.12.2** · SDK constraint `>=3.3.0 <4.0.0`.
- **الحزم الأساسية:** `flutter_riverpod ^2.5.1` · `go_router ^14.2.0` · `dio ^5.5.0` · `flutter_secure_storage ^9.2.2` · `image_picker ^1.1.2` · `intl` · `flutter_localizations`.
- **لا حزم جديدة أُضيفت للمساعد**، ولن تُضاف في 4b.

### البنية
| الموضوع | الموجود |
|---|---|
| إدارة الحالة | Riverpod 2 (`StateNotifier` + `Provider`) |
| التوجيه | go_router 14: `lib/core/router/app_router.dart` و`app_routes.dart` |
| عميل HTTP | Dio داخل `DioClient` (`lib/core/network/dio_client.dart`). يضيف التوكن، ويحوّل الأخطاء إلى `Failure` في `mapError`، و401 يُخرج المستخدم |
| تخزين التوكن | `flutter_secure_storage` عبر `lib/core/storage/token_storage.dart` |
| `ClientScaffold` | `lib/shared/widgets/client_scaffold.dart`، وفيه `FloatingAiButton` (`lib/shared/widgets/floating_ai_button.dart`) |
| عنوان الـ API | `lib/core/config/app_config.dart`، في `AppConfig.apiBaseUrl` = `String.fromEnvironment('API_BASE_URL', defaultValue: <نطاق ngrok الثابت>/api/v1)`. **يُتجاوز بـ `--dart-define=API_BASE_URL=...`** ✅ |
| مهلة المساعد | `AppConfig.aiReceiveTimeout` = **120 ثانية** ← المطلوب 40 |

### الشاشات التي تفتحها البطاقات
| البطاقة | الشاشة | المسار | يقبل التعبئة؟ |
|---|---|---|---|
| `open_product` (منتج واحد) | تفاصيل المنتج | `/market/product/:id` (`AppRoutes.productDetails(id)`) | ✅ بالمعرّف |
| `open_product` (عدة منتجات) | ورقة سفلية داخل المساعد، كل منتج يفتح تفاصيله | — | ✅ لا يوجد في الـ API فلتر `ids` (بند ماهر M4)، فهذا الأنسب |
| `open_marketplace_search` | السوق | `/market?search=&car_make=&car_model=&year=` (`AppRoutes.marketplaceSearch`) | ✅ البحث وفلتر السيارة |
| `create_tender` | نموذج المناقصة | `/tenders/create?category=&title=&city=` (`AppRoutes.createTenderPrefilled`) | ✅ الفئة والعنوان والمدينة. **العميل يُكمل الوصف والموعد النهائي** (مطلوبان في `StoreTenderRequest`) |
| `open_policy` أو نوع غير معروف | — | — | يُتجاهل بأمان (`AiCard.fromJson` يُرجع `null`) ✅ |

### تصميم Stitch للشاشة 23
✅ **موجود:** `CarHub_v2/client_app/23_ai_assistant.html` و`.png`، مع `CarHub_v2/_design/DESIGN.md`. الشاشة الحالية مبنية عليه.

### هل يبني ويعمل الآن؟
- `flutter analyze`: **0 أخطاء و0 تحذيرات**. فيه 15 ملاحظة `info` قديمة (`prefer_const_constructors`) في ملفات خارج المساعد.
- `flutter test`: **25/25 تنجح**، منها 8 للمساعد.
- **لم أبنِ APK في 4a.** البناء الكامل ثقيل على 8GB، وسيُبنى في 4b للتجربة على الهاتف. آخر بناء وتجربة ناجحة على الهاتف كانت في الجلسة السابقة.

### ما يعمل الآن مقابل مواصفات 4b
| المواصفة | الحالة |
|---|---|
| النماذج حسب `CONTRACTS.md` §1 و§2 | ✅ `AiReply` و`AiProduct` و`AiFollowup` و`AiUsage` و`AiCard` (sealed) |
| `FloatingAiButton` ← `AiAssistantScreen` | ✅ |
| RTL، والترحيب، والفقاعات، و«يكتب...» | ✅ |
| `conversation_id` + «محادثة جديدة» | ✅ |
| أزرار `followup.suggestions` ترسل نصها | ✅ |
| بطاقة المنتج: الصورة أو placeholder، والعنوان، والسعر والعملة، والتاجر والمدينة، وشارة التوافق | ✅ `NetworkImageBox` يعرض placeholder عند `null` (كل منتجات العرض بلا صور) |
| البطاقات الثلاث + تجاهل المجهول | ✅ |
| مهلة 40 ثانية | ❌ الآن 120 |
| حالة 403 «المساعد لحسابات العملاء فقط» | ⚠️ تظهر رسالة الخادم العامة («لا تملك الصلاحية المخصصة…») |
| حالة 422 | ⚠️ تظهر «بيانات المدخلات غير صالحة»، والخادم يرسل مفاتيح غير مترجمة (`validation.required`، بند ماهر M1) |
| حالة 429 | ⚠️ رسالة عامة موجودة في `DioClient`. شكل 429 من throttle ليس بشكل المشروع (بند ماهر M2)، والتعامل بالكود فقط يحمي منه |
| انقطاع الشبكة + إعادة المحاولة، و503، وtimeout | ✅ موجودة (`ErrorEntry` قابل لإعادة المحاولة) |
| إرسال `context.city` | ❌ لا يُرسَل الآن، فتصل بطاقة المناقصة بـ `city: null` |
| اختبارات لكل نوع بطاقة (التوجيه) ولكل حالة خطأ | ⚠️ موجودة جزئياً (503 و422 والتحليل والتعبئة) |

### خطة 4b (الفروقات فقط)
**ملفات تتغيّر:**
1. `lib/core/config/app_config.dart`: `aiReceiveTimeout` من 120 إلى **40 ثانية**.
2. `lib/features/ai_assistant/data/datasources/ai_remote_datasource.dart` (`_mapAiError`): رسائل ثابتة خاصة بالمساعد بالكود، لا من نص الخادم:
   - 403: «المساعد متاح لحسابات العملاء فقط»، بلا إعادة محاولة.
   - 422: «الرسالة يجب أن تكون بين 1 و500 حرف»، أو «المحادثة غير موجودة، ابدأ محادثة جديدة» لـ `conversation_id`.
   - 429: «طلبات كثيرة، انتظر قليلاً»، بلا زر ترقية.
   - timeout: رسالة التأخير مع إعادة المحاولة.
   - 503 والشبكة: كما هي.
3. `lib/features/ai_assistant/presentation/providers/ai_chat_provider.dart`: إرسال `context.city` من مدينة المستخدم في ملفه إن وُجدت، وإلا `null`. والقرار «قابل لإعادة المحاولة؟» حسب نوع الخطأ أعلاه.
4. `test/ai_assistant_test.dart`: اختبارات جديدة:
   - التوجيه لكل نوع بطاقة (منتج واحد، وعدة منتجات، والسوق، والمناقصة، و`open_policy` يُتجاهل) عبر `GoRouter` في widget test.
   - كل حالة خطأ: 403، و422 (الثلاث)، و429، و503، وtimeout، والشبكة.
5. `reports/ai_progress.md`: قسم 4b، مع أوامر تشغيل السلسلة كاملة، و`flutter run` على الهاتف، وقائمة الفحص اليدوي.

**لا ملفات جديدة في `lib/`، ولا حزم جديدة.**

### أسئلة قبل 4b
1. **التعارض أعلاه:** هل أكمل بالفروقات فقط (الخطة أعلاه)؟ هذا توصيتي. أم تريد إعادة بناء من الصفر؟
2. **مصدر `context.city`:** مدينة ملف المستخدم (`users.city`)، وهي فارغة لـ `client1`، فستصل البطاقة بلا مدينة ويختارها العميل في النموذج. هل هذا مقبول للعرض؟ أم أضع لـ `client1` مدينة في ملفه (من التطبيق، لا من الكود)؟
3. **المفتاح:** لم يوضع `ANTHROPIC_API_KEY` بعد. اختبارات الهاتف ستعمل بالرد الاحتياطي حتى تضعه.
