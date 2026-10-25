# carhub (Flutter) — سجل تقدّم المساعد الذكي (فرع `feature/ai-skeleton`)

## S4 — شاشة المساعد الذكي ⏳ (الكود جاهز، والقبول على الهاتف ينتظر وائل) (2026-10-25)

### git
- المستودع كان مُنشأً من قبل: `435d0e0` «Initial snapshot before AI assistant» (2026-10-16، فرع `master`، بلا remote، و`.gitignore` القياسي لـ Flutter الذي يستثني `build/` (3.5GB) و`.dart_tool/`). **لم أُعِد الإنشاء**، وبنيت عليه.
- الفرع `feature/ai-skeleton`: `31c81f6` (الوثائق) ثم `24e02fb` (S4). لا push.
- ملاحظة: `android/app/google-services.json` متتبَّع في git. هذا لا بأس به محلياً، لكن انتبه له قبل أي رفع إلى مستودع عام.

### ما وجدته في المشروع (الخطوة 1)
| البند | الموجود |
|---|---|
| إدارة الحالة | Riverpod 2 (`StateNotifier` / `AsyncNotifier`) |
| التوجيه | go_router 14، والمسارات في `core/router/app_routes.dart` |
| HTTP | Dio عبر `DioClient`: توكن Sanctum، وهيدر ngrok، وتحويل الأخطاء إلى `Failure` عربية |
| عنوان الـ API | `AppConfig.apiBaseUrl` (مكان واحد) |
| `ClientScaffold` | `shared/widgets/client_scaffold.dart`، وفيه `FloatingAiButton` من قبل |
| الشاشات | تفاصيل المنتج `/market/product/:id`، والسوق `/market`، وإنشاء مناقصة `/tenders/create` |
| تصميم الشاشة 23 | **موجود**: `CarHub_v2/client_app/23_ai_assistant.html` و`.png` |
| RTL | مضبوط على مستوى التطبيق كله في `main.dart` |

### ما أُنجز
- **`AiAssistantScreen`** (شاشة كاملة على المسار `/assistant`) مطابقة للتصميم 23:
  - رأس كحلي متدرّج، فيه زر رجوع وأيقونة المساعد. القائمة ⋮ فيها «محادثة جديدة».
  - رسالة ترحيب، وفاصل «اليوم»، وفقاعات العميل خضراء، وردود المساعد بيضاء.
  - مؤشر «المساعد يكتب» بنقاط نابضة.
  - **أزرار الاقتراحات** (`followup.suggestions`) تظهر لآخر رد فقط، والضغط يرسل نصها كرسالة.
  - **بطاقات المنتجات** (شريط أفقي): صورة، عنوان، سعر وعملة، متجر ومدينة، وشارة «متوافق» أو «تأكد من التوافق». الضغط يفتح تفاصيل المنتج.
  - **بطاقات الإجراء** (شريط أفقي كما في التصميم): أيقونة دائرية، وعنوان، وزر.
  - شريط إدخال: حقل نص بحد 500 حرف، وزر إرسال متدرّج.
- `FloatingAiButton` صار يفتح الشاشة الكاملة بدل الورقة السفلية المبدئية.
- **`conversation_id`** محفوظ في `aiChatProvider` (ليس autoDispose)، فتبقى المحادثة إذا أُغلقت الشاشة وفُتحت خلال نفس الجلسة.
- **نماذج البيانات** في `ai_reply.dart` مطابقة لـ `CONTRACTS.md` §1 و§2. البطاقة غير المعروفة (`open_policy`) تُتجاهل بأمان.

### بطاقات الإجراء: ماذا تفتح
| البطاقة | السلوك |
|---|---|
| `open_product` بمنتج واحد | تفاصيل المنتج مباشرة |
| `open_product` بأكثر من منتج | **ورقة سفلية بالمنتجات نفسها**، وكل منتج يفتح تفاصيله. السبب: لا توجد في التطبيق شاشة «قائمة منتجات محددة»، والسوق لا يقبل قائمة معرّفات |
| `open_marketplace_search` | السوق مع البحث (`search`) وفلتر التوافق (`car_make` و`car_model` و`year`). يظهر الفلتر كشريحة «متوافق مع: Kia Sportage 2018» يمكن إزالتها |
| `create_tender` | نموذج المناقصة معبّأ بالفئة والعنوان والمدينة |
| `open_policy` | تُتجاهل (مؤجّلة) |

### حالات الخطأ
| الحالة | ما يظهر |
|---|---|
| أثناء الانتظار | مؤشر «المساعد يكتب»، والإدخال معطّل |
| انقطاع الشبكة | فقاعة خطأ + زر «إعادة المحاولة» (يعيد الإرسال دون تكرار فقاعة العميل) |
| 503 | «المساعد غير متاح حالياً. جرّب بعد قليل، أو تصفّح السوق مباشرة.» + إعادة المحاولة |
| timeout بعد 120 ثانية | «المساعد تأخّر في الرد أكثر من المعتاد…» + إعادة المحاولة. المهلة خاصة بهذا الطلب، وباقي التطبيق يبقى على 30 ثانية |
| 422 | رسالة التحقق المعرّبة، بلا إعادة محاولة |
| 429 | الرسالة العامة الحالية في `DioClient` («حاولت كثيراً…») فقط |
| 401 / 403 | رسائل `DioClient` الحالية (جلسة منتهية / لا صلاحية) |

### ⚠️ تعديلات خارج شاشة المساعد (ضرورية)
1. **نموذج إنشاء المناقصة كان معطّلاً أمام الـ Backend الحالي:** `StoreTenderRequest` عند ماهر يطلب `category` (ضمن `TenderCategory`) و`city`، والتطبيق لا يرسلهما، فكان **كل نشر مناقصة من التطبيق سيفشل بـ 422** حتى بدون المساعد. أضفت قائمة «نوع العمل» (ميكانيك / كهرباء وتكييف / سمكرة وبوية) وحقل «المدينة»، وعدّلت datasource وrepository وprovider المناقصات. **يستحق إبلاغ إسراء أو ماهر.**
2. **السوق:** يقبل بحثاً وفلتر سيارة مبدئيين عبر query parameters، والـ datasource يرسل `car_make` و`car_model` و`year` (يدعمها `ProductController` في Laravel أصلاً). التنقّل العادي إلى السوق لا يتأثر.
3. **`AppConfig.apiBaseUrl`** صار يقبل تجاوزاً وقت البناء: `--dart-define=API_BASE_URL=...`. القيمة الافتراضية لم تتغيّر (رابط ngrok عند إسراء)، فلا حاجة لتعديل الكود لتمرير رابطك.

### الاختبارات
- `flutter test`: **25/25** (8 جديدة في `test/ai_assistant_test.dart`: تحليل مثال العقد، وروابط البطاقات، والحفاظ على `conversation_id`، و503 مع إعادة المحاولة، و422 والرسائل الفارغة والطويلة، والمحادثة الجديدة).
- `flutter analyze`: لا أخطاء. الـ 15 ملاحظة `prefer_const` الباقية كانت موجودة قبلي في ملفات أخرى.

### كيف تشغّله على الهاتف (أوامر جاهزة)
**1) الخوادم** (كما في `carhub-laravel/reports/progress.md` §S3)، **لكن أخّر llama-server إلى ما بعد التثبيت** (اتفاق الذاكرة):
```powershell
# نافذة: carhub-ai
powershell -ExecutionPolicy Bypass -File C:\Users\HP\Desktop\carhub-ai\scripts\run_service.ps1
# نافذة: Laravel
cd C:\laragon\www\carhub-laravel
& 'C:\laragon\bin\php\php-8.3.16-Win32-vs16-x64\php.exe' artisan serve --host=0.0.0.0 --port=8000
# نافذة: ngrok
C:\laragon\bin\ngrok\ngrok.exe http 8000
```
**2) الهاتف:** فعّل USB debugging، ثم وصّله، وتأكد أنه ظاهر:
```powershell
C:\src\flutter\bin\flutter.bat devices
```
**3) البناء والتثبيت** برابط ngrok الخاص بك:
```powershell
cd C:\Users\HP\Desktop\carhub
C:\src\flutter\bin\flutter.bat run --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app/api/v1
```
**4) بعد ظهور التطبيق على الهاتف**، شغّل النموذج:
```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\HP\Desktop\carhub-ai\scripts\run_llm_local.ps1
```
**5) سجّل الدخول بحساب العميل:** `client1@carhub.com` / `password` (من `DummyDataSeeder`)، ثم اضغط الزر الأخضر العائم.

**6) قائمة القبول:**
- [ ] «بدي ضو لكيا سبورتاج» ← أزرار سنوات.
- [ ] الضغط على «2018» ← منتجات بشارة «متوافق» + بطاقة «عرض المصابيح المتوافقة» ← ورقة المنتجات ← تفاصيل المنتج.
- [ ] «عندي صوت بالفرامل وبدي أرش المصد» ← بطاقة السوق (تفتح السوق ببحث «فحمات فرامل») + بطاقة المناقصة (تفتح النموذج معبّأً بـ «سمكرة وبوية»).
- [ ] أوقف carhub-ai (Ctrl+C في نافذته) ← أرسل رسالة ← تظهر رسالة «المساعد غير متاح حالياً».

> **مهم:** السيناريوهات تعتمد على `INTENT_POLICY=analyzer` في `carhub-ai/.env` (مضبوطة الآن). مع `model` ونموذج 0.6B لن تظهر البطاقات (موثّق في S2/S3).

### الملفات الأهم للمراجعة
- `lib/features/ai_assistant/presentation/screens/ai_assistant_screen.dart`: الشاشة وسلوك البطاقات.
- `lib/features/ai_assistant/presentation/providers/ai_chat_provider.dart`: حالة المحادثة والأخطاء وإعادة المحاولة.
- `lib/features/ai_assistant/domain/entities/ai_reply.dart`: النماذج حسب العقد.
- `lib/features/tenders/presentation/screens/create_tender_screen.dart`: الفئة والمدينة (إصلاح الـ 422).

### أسئلة مفتوحة
1. **`context.city`:** كيان المستخدم في التطبيق بلا مدينة، فيُرسل `null`، وتأتي بطاقة المناقصة بلا مدينة فيكتبها العميل. هل نضيف `city` إلى `/auth/me` و`User`، أم نتركه للعميل؟
2. **ميزانية المناقصة** إلزامية في الشاشة الحالية، مع أن الـ Backend يقبلها فارغة. لم أغيّرها، لكنها خطوة إضافية على العميل القادم من المساعد.
3. **الصور:** `image_url` من Laravel يستخدم `Storage::url` (مثل `ProductResource`). منتجات العرض بلا صور الآن. عند إضافتها يجب أن يكون `APP_URL` في Laravel هو رابط ngrok، وإلا ظهرت روابط `localhost`.
