# CLAUDE.md — المساعد الذكي CarHub (جهاز الويندوز، تنفيذ متتالٍ)

> ضع نسخة **متطابقة** من هذا الملف ومن `CONTRACTS.md` في جذر كل من المجلدات الثلاثة:
> 1. `carhub-ai/` (مجلد جديد لخدمة الذكاء)
> 2. مستودع Laravel
> 3. مشروع Flutter
>
> كل خطوة أدناه مكتوب بجانبها المجلد الذي تُنفَّذ فيه. **إن لم تكن في المجلد الصحيح للخطوة المطلوبة، توقف وأخبر وائل.**

## من أنت ولمن تعمل
أنت تعمل لـ م. وائل، المسؤول عن طبقة LLM والتكامل في المساعد الذكي لمنصة CarHub (سوق قطع غيار سيارات + مناقصات إصلاح للورش). وائل مسؤول عن مستودعي Laravel وFlutter.
- **كلّم وائل بالعربية دائماً.** الكود وأسماء المتغيرات والتعليقات بالإنجليزية.
- وائل يعمل على أمر آخر بالتوازي، لكنه **يريد أن يفهم ما يُبنى**. اشرح قراراتك ببساطة في كل تقرير.

## الهدف الحالي: «هيكل يمشي» (Walking Skeleton) للعرض على الزبون
مساعد حقيقي يعمل من تطبيق العميل على هاتف أندرويد، بأقل وقت ممكن. بعدها يُطوَّر حسب المراحل W0–W9.

**سيناريوهات العرض الثلاثة (معيار النجاح الأساسي):**
1. «بدي ضو لكيا سبورتاج» ← يسأل عن سنة الصنع مع أزرار سنوات.
2. ثم «2018» ← يدمجها مع السؤال السابق ← بطاقات المنتجات المتوافقة + بطاقة `open_product`.
3. «عندي صوت بالفرامل وبدي أرش المصد» ← نيّتان ← بطاقة `open_marketplace_search` (فحمات فرامل) + بطاقة `create_tender` (دهان وسمكرة، بعنوان مقترح).

## البنية (تحديث)
```
Android phone
   │  HTTPS (نطاق ngrok ثابت)
   ▼
Laravel  :8000   POST /api/v1/ai/ask     (Sanctum + role:client + throttle:api, AI_TIMEOUT_S=30)
   │  HTTP + X-API-Key
   ▼
carhub-ai :8001  POST /v1/answer, GET /health   (FastAPI، بلا حالة)
   │
   ├── FakeAnalyzer / FakeRetriever   (عقد أحمد حرفياً، يُستبدل بـ carhub-rag في W7)
   │
   ▼
get_provider()  ← LLM_PROVIDER في .env
   ├── anthropic           → AnthropicProvider  → Claude API (Messages API، SDK الرسمي)   ← المعتمد
   └── openai_compatible   → OpenAICompatibleProvider  (احتياط لأي مزوّد مستقبلي)
```

## القواعد غير القابلة للتجاوز (v1)
1. **التطبيق لا يتصل بـ carhub-ai مباشرة أبداً.** Laravel هو البوابة الوحيدة.
2. **السعر والصورة والمخزون واسم المتجر من قاعدة البيانات فقط.** لا أسعار في سياق النموذج ولا في مخرجاته.
3. **كل `product_id` في الرد ضمن المسترجَع، ويُفرض بالكود في `validate.py`.** هذه الحماية لا تعتمد على مخطط JSON.
4. **البطاقات تُبنى بالكود** من النوايا ونتائج الاسترجاع.
5. **لا يُستدعى النموذج إلا عبر `get_provider()`.** تبديل المزوّد أو النموذج أو الحساب = تغيير `.env` ثم إعادة تشغيل، بلا تعديل كود.
6. **المزوّد المعتمد للعرض: Gemma 4 26B عبر Google AI Studio بواجهة متوافقة مع OpenAI** (`OpenAICompatibleProvider`). **للإنتاج:** يُقرَّر لاحقاً (المرشح DeepInfra بطبقة مدفوعة). **Claude API** (`AnthropicProvider`) يبقى بديلاً جاهزاً. **أي مزوّد آخر بموافقة وائل.**
   - **ممنوع:** Fine-tuning، وAI للتاجر أو الورشة أو الإدارة.
7. **`ANTHROPIC_API_KEY` و`GEMINI_API_KEY` (وأي متغير يسمّيه `LLM_API_KEY_ENV`) في `carhub-ai/.env` فقط.**
   - لا يوجد في Laravel، ولا في Flutter، ولا في git.
   - لا يظهر في أي log، أو تقرير، أو رسالة خطأ، أو `/health`، أو `trace`.
   - في `.env.example` يبقى فارغاً.
   - **وائل يضعه في `.env` بنفسه.** لا يُطلب منه لصقه في المحادثة.
8. **لا بيانات شخصية للمزوّد.**
   - **لا يُرسل:** `user_id`، أو `plan`، أو الاسم، أو الهاتف، أو `context.city`. المدينة يستخدمها الكود لبطاقة المناقصة فقط.
   - **يُرسل فقط:** نص السؤال المستقل، ونتائج الاسترجاع بلا أسعار، و`missing`، ومفاتيح فئات المناقصات.
9. **لا اتصال حقيقي بالـ API في الاختبارات الآلية.** كل الاختبارات بـ mock وبلا شبكة. الاتصال الحقيقي فقط في سكربتات تُشغَّل عمداً (`run_scenarios*.py` و`run_bench.py`)، وكل تشغيل يذكر كلفته في التقرير.
10. **`CONTRACTS.md` لا يعدّله الوكيل دون موافقة وائل.** النسخ الثلاث متطابقة.
11. **في Laravel وFlutter:** فرع `feature/ai-skeleton`، ولا push إلا بطلب، والـ migrations على القاعدة المحلية فقط.

## الإعدادات (`.env.example` لـ carhub-ai، v1)
```
API_KEY=change-me

# --- LLM provider ---
LLM_PROVIDER=anthropic            # anthropic | openai_compatible
ANTHROPIC_API_KEY=                # set by Wael in .env only — never printed
LLM_MODEL=                        # chosen in P2
LLM_TIMEOUT_S=15                  # per API call
LLM_MAX_RETRIES=2                 # SDK-level retries only (429/529/5xx/connection)
LLM_TOTAL_DEADLINE_S=25           # whole /v1/answer budget; must stay < Laravel AI_TIMEOUT_S (30)
LLM_MAX_TOKENS=600
LLM_TEMPERATURE=0.2               # openai_compatible only; never sent to the Claude API (400)
LLM_THINKING_TYPE=disabled        # disabled | between_tools | adaptive | omit (model-specific: Haiku 5.5 disabled, Sonnet 5.5 between_tools, Opus 5.5 omit)
LLM_CACHE_SYSTEM=false            # prompt caching on `system`; true only if it exceeds the model's documented minimum

# --- Cost estimation (USD per 1M tokens; from official pricing page, with date) ---
LLM_PRICE_INPUT_PER_MTOK=
LLM_PRICE_OUTPUT_PER_MTOK=
LLM_PRICE_CACHE_READ_PER_MTOK=
LLM_PRICE_CACHE_WRITE_PER_MTOK=

# --- openai_compatible only (demo: Gemma 4 on Google AI Studio) ---
LLM_BASE_URL=                     # https://generativelanguage.googleapis.com/v1beta/openai/
LLM_API_KEY_ENV=                  # NAME of the key variable, e.g. GEMINI_API_KEY
GEMINI_API_KEY=                   # set by Wael in .env only — never printed
LLM_RESPONSE_FORMAT=json_schema   # json_schema | json_object
LLM_EXTRA_BODY=                   # JSON merged into each request, e.g. {"reasoning_effort":"minimal"}
LLM_DISABLE_THINKING=false        # true only for llama.cpp/vLLM Qwen3 (sends chat_template_kwargs; Google: 400)

# --- Retrieval & pipeline ---
RETRIEVER=fake
FAKE_DATA_DIR=./data
HISTORY_TURNS=6
PROMPTS_DIR=./prompts/v1
INTENT_POLICY=model               # model | analyzer | union
HOST=127.0.0.1
PORT=8001
```
**حُذف:** `LLAMA_*`. (`LLM_DISABLE_THINKING` عاد اختيارياً، وافتراضيه `false`.)

**`LLM_DAILY_TOKEN_BUDGET` مؤجّل:** مكانه قرار مفتوح (N5)، لأن carhub-ai بلا حالة.

## الخطوات (v1)
```
P1 (carhub-ai + سطر في Laravel) → P2 (قياس) → S3-check (Laravel/ngrok) → S4 (Flutter) → العرض → W3…W9
```

### P1 — `AnthropicProvider` `[carhub-ai/]` + سطر في Laravel
1. **تحقّق من الوثائق الرسمية قبل الكتابة،** وسجّل الروابط في التقرير:
   - Structured outputs.
   - رموز الأخطاء (400، و401، و403، و429، و529، و5xx).
   - إعادة المحاولة الافتراضية في Python SDK وكيف تُضبط.
   - الحد الأدنى لطول الـ prompt caching لكل نموذج.
   - أقل إصدار من SDK يدعم `output_config`.
2. **أضف SDK `anthropic`** بإصدار مثبّت في `requirements.txt`.
3. **`AnthropicProvider`** يطبّق `LLMProvider`:
   - التعليمات في معامل `system`، والسياق في `messages`.
   - المخطط عبر `output_config={"format": {"type": "json_schema", "schema": ...}}`.
   - إعادة المحاولة **في طبقة واحدة فقط**: `max_retries` في SDK = `LLM_MAX_RETRIES`، و`timeout` = `LLM_TIMEOUT_S`. لا حلقة إعادة إضافية فوقه.
   - **لا Extended Thinking.**
4. **نتيجة الاستدعاء (يحتاج موافقة وائل):** `chat()` تُرجع `ChatResult(text, input_tokens, output_tokens, cache_read_tokens, cache_write_tokens, stop_reason)` بدل `str`. يُحدَّث `OpenAICompatibleProvider` بنفس الشكل، مع tokens من حقل `usage` إن وُجد.
5. **ربط الأخطاء** في دالة واحدة معزولة:

   | الحالة | المعاملة |
   |---|---|
   | `stop_reason` = `max_tokens` | المحاولة الثانية بضعف `max_tokens` (حد أعلى 1200) ← الرد الاحتياطي |
   | مخرجات غير صالحة، أو `product_id` خارج المسترجَع | المحاولة الثانية مرة واحدة بنفس الطلب ← الرد الاحتياطي |
   | `stop_reason` = `refusal` | الرد الاحتياطي مباشرة، بلا محاولة ثانية |
   | 400 | الرد الاحتياطي مباشرة، بلا محاولة ثانية |
   | 401 / 403 / 404 / 402 | خلل إعداد: يُسجَّل كـ error (بلا المفتاح) ← 503 `LLM_UNAVAILABLE` |
   | 429 / 529 / 5xx / اتصال / timeout بعد استنفاد إعادة SDK | **الرد الاحتياطي بالكود** (N1 محسوم)، بلا محاولة ثانية |
   | تجاوز `LLM_TOTAL_DEADLINE_S` | **الرد الاحتياطي بالكود**، بلا محاولة ثانية |

   في كل حالات الرد الاحتياطي: `trace.fallback_used=true`، والرد 200.

6. **المخطط الثابت (`prompts/v1/output_schema.json`):**
   - ثابت لكل الطلبات.
   - `product_ids`: مصفوفة `integer` بلا `enum` وبلا `maxItems`.
   - `tender_suggestion.category`: `enum` ثابت بمفاتيح `TenderCategory`.
   - **كل الخصائص `required`**، والقيم الاختيارية بنوع يقبل `null`.
   - `additionalProperties: false` في كل `object`.
   - يُحذف بناء المخطط المشدّد لكل طلب.
7. **`validate.py`:**
   - مقارنة `category` دون حساسية لحالة الأحرف.
   - `product_ids ⊆ retrieved_ids`.
   - قصّ العدد بنفس الحد الحالي.
   - باقي التحقق كما هو.
8. **Prompt caching:** فعّله على `system` فقط إذا تجاوز الحد الأدنى الموثّق للنموذج. لا تُطوَّل التعليمات لأجله. سجّل القرار.
9. **`trace` ([إضافة v1]، بموافقة وائل):** يُضاف `provider` و`input_tokens` و`output_tokens` و`cache_read_tokens` و`est_cost_usd` و`attempts`.
   - الكلفة من أسعار `.env`، ويُجمع فيها كل المحاولات.
   - يُحدَّث `CONTRACTS.md` §3 في النسخ الثلاث.
10. **`/health`:** لا يستدعي النموذج، لأن ذلك كلفة. يُرجع `provider` و`model` و`key_configured` (true/false).
11. **حذف وتنظيف:** `scripts/run_llm_local.ps1` و`s1_*` تُنقل إلى `legacy/`. يُحذف `LLM_DISABLE_THINKING` و`LLAMA_*` من `.env.example`. ويُحدَّث `README.md`.
12. **Laravel:** `AI_TIMEOUT_S=30`، في `.env` المحلي، والقيمة الافتراضية في `config/ai.php`، و`.env.example`. لا تغيير آخر.

**القبول:**
1. **اختبارات mock جديدة:**
   - نجاح، مع tokens وكلفة في `trace`.
   - `stop_reason=max_tokens`.
   - `refusal`.
   - 400.
   - 401.
   - 429 ثم نجاح.
   - 429 دائم.
   - timeout.
   - تجاوز المهلة الكلية.
   - `category` بحالة أحرف مختلفة.
   - `product_id` خارج المسترجَع.
2. **اختبار الخصوصية:** الطلب الخارج للمزوّد لا يحتوي `user_id` ولا `plan` ولا المدينة.
3. **اختبار سرية المفتاح:** مفتاح وهمي مميّز لا يظهر في السجلات الملتقطة، ولا في رسائل الأخطاء، ولا في `/health`، ولا في `trace`.
4. **الاختبارات القديمة الـ 47** تنجح مع `LLM_PROVIDER=openai_compatible`.
5. **تشغيل حقيقي واحد** بعد أن يضع وائل المفتاح: `run_scenarios.py` على أرخص نموذج متحقَّق منه. السيناريوهات الثلاثة تعمل، والكلفة الإجمالية للتشغيل مذكورة في التقرير.
6. **Laravel:** `php artisan test` ما زال ينجح.

### P2 — القياس على API `[carhub-ai/]`
1. **قبل التشغيل:**
   - تحقّق من أسماء النماذج الحالية وأسعارها: الأرخص (فئة Haiku) والمتوسط (فئة Sonnet).
   - **اعرض القائمة والكلفة التقديرية للقياس كاملاً على وائل، وانتظر موافقته.**
2. **الأسئلة:** الثلاثون الحالية، والعشرة التي يكتبها وائل.
3. **`run_bench.py` يقيس:**
   - p50 وp95 للزمن.
   - JSON الصالح من المحاولة الأولى.
   - دقة النية بالسياسات الثلاث.
   - بديل «أول 4 منتجات».
   - متوسط input وoutput tokens.
   - الكلفة لكل سؤال، وللشهر عند 1,000 و10,000 و50,000 سؤال.
   - أخطاء 429 عند 4 و8 طلبات متزامنة.
4. **اذكر في التقرير** أن حدود الحساب (rate limits) تخص الحساب الشخصي، وقد تختلف لحساب الإنتاج.
5. **القبول:** توصية مكتوبة بالأرقام في `reports/llm_benchmark.md`: قيمة `LLM_MODEL`، وقيمة `INTENT_POLICY`، وهل نحتاج البث، والكلفة الشهرية المتوقعة.

### S3-check — عبر Laravel `[مستودع Laravel]`
- `run_scenarios_laravel.py` عبر النطاق الثابت بالنموذج المختار.
- **القبول:**
  - السيناريوهات الثلاثة تعمل بالبطاقات الصحيحة.
  - `ai_messages.meta.trace` فيه tokens والكلفة.
  - الزمن مسجّل.

### S4 — Flutter `[مشروع Flutter]`
كما في `CLAUDE.md` الحالي، مع تعديلين:
- **الترتيب:** `git init` وcommit أول، ثم الفحص والتقرير، ثم التوقف، ثم الشاشة.
- **مهلة الطلب في التطبيق:** 40 ثانية، أكبر من مهلة Laravel البالغة 30. ملاحظة «أوقف llama-server» لم تعد لازمة.

### العرض
يعمل من اللابتوب مباشرة. يحتاج إنترنت، وLaragon، وcarhub-ai، وLaravel، وngrok. ولا يحتاج أي GPU.

## مؤجَّل — لا تبنِه (v1)
- `open_policy`.
- فرض الحد في Laravel و429.
- `ai_usage` و`ai_logs`.
- صفحات Filament، ومفتاح التشغيل من لوحة الأدمن.
- البث (يُقرَّر في P2).
- إرسال `history` للنموذج (N2).
- حد التوكنات اليومي (N5).
- إخفاء البيانات الشخصية من نص الرسالة (N6).
- دمج المتابعة بالنموذج.
- W8 وW9.
- التكامل مع carhub-rag.
- أي AI في تطبيق الأعمال.

---

## بروتوكول العمل
- **خطوة واحدة في كل مرة.** بعد كل خطوة:
  1. شغّل الاختبارات.
  2. حدّث `reports/progress.md` في المجلد الذي عملت فيه، بالأقسام التالية:
     - **ما أُنجز**، بلغة بسيطة يفهمها وائل دون قراءة الكود.
     - **كيف تشغّله وتختبره:** أوامر PowerShell جاهزة للنسخ (استخدم `curl.exe`).
     - **القرارات التي اتخذتها ولماذا.**
     - **ما تحقّقت منه بالبحث.**
     - **الملفات الأهم للمراجعة،** أقل من 5 ملفات، مع سطر عن كل منها.
     - **الأسئلة المفتوحة.**
  3. commit على الفرع.
  4. **توقّف** وانتظر «تابع» من وائل.
- لا تخترع حلولاً لقرارات مفتوحة. اكتبها كسؤال.
