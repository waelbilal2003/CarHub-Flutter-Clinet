# CarHub AI — العقود المشتركة (نسخة الهيكل v0)

> هذا الملف **متطابق حرفياً** في كل المستودعات (carhub-ai، Laravel، Flutter).
> لا يعدّله أي وكيل. أي تغيير يقرّه وائل ويحدّث كل النسخ معاً.
> البنود الموسومة بـ **[إضافة v0]** ليست في التقرير الأصلي وأُضيفت بموافقة وائل.

---

## 1. التطبيق ← Laravel: `POST /api/v1/ai/ask`

Header: `Authorization: Bearer <sanctum token>`

### Request
```json
{
  "message": "بدي ضو لكيا سبورتاج",
  "conversation_id": "c_8f2a91",
  "context": {"city": "الرياض"}
}
```
- `message`: نص، من 1 إلى 300 حرف (**[تعديل v1]** كان 500؛ `AI_MESSAGE_MAX_CHARS`).
- `conversation_id`: `null` لبدء محادثة جديدة.
- `context.city`: اختياري.

### Response 200
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "conversation_id": "c_8f2a91",
    "answer": "أكيد! شو سنة صنع سيارتك؟",
    "followup": {"question": "شو سنة صنع السيارة؟",
                 "suggestions": ["2016", "2017", "2018", "2019", "2020"]},
    "products": [{"id": 152, "title": "...", "price": "350.00", "currency": "SAR",
                  "image_url": "...", "merchant_name": "متجر الأمان",
                  "city": "الرياض", "compatibility": "exact"}],
    "cards": [{"type": "open_product", "label": "عرض المصابيح المتوافقة",
               "payload": {"product_ids": [152, 160]}}],
    "usage": {"used_today": 3, "daily_limit": 15, "used_month": 41, "monthly_limit": 200,
              "bonus_remaining": 0}
  }
}
```
- `followup`: كائن أو `null`.
- `products`: يملؤها Laravel من قاعدة البيانات فقط. لا يأتي أي سعر من خدمة الذكاء.
- `compatibility`: `exact` | `partial`.
- **[إضافة v1]** `usage`:
  - `used_today` و`used_month`: الأسئلة المُجابة، اليوم والشهر التقويمي بتوقيت `AI_LIMIT_TIMEZONE`.
  - `daily_limit` و`monthly_limit`: `null` = بلا حد.
  - `bonus_remaining`: أسئلة إضافية من الإعلانات متبقية **لليوم فقط**، تُستهلك بعد نفاد الحد اليومي.
  - `used_month` لا يحسب أسئلة الإعلانات إن كان `AI_AD_COUNTS_TOWARD_MONTHLY=false`.

### Errors
```json
429 {"success": false, "message": "وصلت للحد اليومي للمساعد", "errors": {"code": ["AI_LIMIT_REACHED"]},
     "data": {"limit": "daily", "can_watch_ad": true, "ads_remaining_today": 5,
              "usage": {"used_today": 15, "daily_limit": 15, "used_month": 41, "monthly_limit": 200, "bonus_remaining": 0}}}
429 {"success": false, "message": "انتظر لحظة قبل سؤالك التالي", "errors": {"code": ["AI_TOO_FAST"]},
     "data": {"retry_after_s": 2}}
503 {"success": false, "message": "المساعد غير متاح حالياً", "errors": {"code": ["AI_UNAVAILABLE"]}}
422 validation (empty / too long message)
```
- **[إضافة v1] `AI_LIMIT_REACHED`:**
  - `data.limit` يكون `daily` أو `monthly`. الرسالة: «وصلت للحد الشهري للمساعد» للشهري.
  - `can_watch_ad=true` يعني أن مشاهدة إعلان تفتح أسئلة. يكون `false` في الشهري ما دامت أسئلة الإعلانات تُحسب ضمنه، أو بعد 5 إعلانات اليوم، أو لغير الباقة المجانية.
  - السؤال المحجوب لا يصل إلى carhub-ai ولا يُحسب.
- **[إضافة v1] `AI_TOO_FAST`:**
  - أقل من `AI_MIN_SECONDS_BETWEEN` (ثانيتان) منذ سؤال المستخدم السابق، مع header `Retry-After`.
  - لا يُحسب من الحد. التطبيق يعرض «انتظر لحظة».
- قد يصل **429 آخر من `throttle:api`** بشكل Laravel الافتراضي (`{"message": "Too Many Attempts."}`)، بلا `errors.code`. يُعامل كرسالة عامة.

### [إضافة v1] إعلانات المكافآت: `GET /api/v1/ai/ads/reward`
- **callback** التحقق من جهة الخادم (SSV) من Google AdMob، لا يستدعيه التطبيق.
- **بلا توكن:** توقيع ECDSA من Google هو المصادقة. التوقيع غير الصالح يعطي 403 `AI_AD_SIGNATURE_INVALID`، ولا يُحفظ شيء.
- **ربط المستخدم:** معامل `user_id` في الـ callback = `users.id`، ويضبطه التطبيق عبر `ServerSideVerificationOptions.userId`.
- **المكافأة:** إعلان مكتمل = `AI_AD_REWARD_QUESTIONS` (3) أسئلة لليوم نفسه، بحد `AI_AD_DAILY_MAX` (5) إعلانات في اليوم.
- **عدم التكرار:** `transaction_id` فريد، فلا يُحسب مرتين.

---

## 2. بطاقات الإجراء (`cards`)

| type | متى | payload |
|---|---|---|
| `open_product` | وُجدت منتجات متوافقة | `{"product_ids": [152, 160]}` |
| `open_marketplace_search` | نتائج كثيرة أو جزئية، أو السيارة غير محددة | `{"query": "فحمات فرامل", "filters": {"car_make": "Kia", "car_model": "Sportage", "year": 2018}}` |
| `create_tender` | طلب إصلاح أو دهان، أو القطعة غير موجودة | `{"category": "paint_body", "title": "رش مصد أمامي", "city": "الرياض"}` |
| `open_policy` | سؤال عن الإرجاع والاستبدال | **مؤجّل (لا يُبنى في v0)** |

- البطاقات تُبنى **بالكود** في carhub-ai، لا من نص حر يكتبه النموذج.
- مفاتيح `filters` في `open_marketplace_search` هي أسماء معاملات API السوق نفسها: `car_make` و`car_model` و`year`. يكتبها carhub-ai بهذه الأسماء، ويُحذف أي مفتاح غير معروف القيمة. `filters` قد يكون `{}`.
- `category` في `create_tender` مفتاح من `App\Enums\TenderCategory`. يتحقق Laravel فقط من أن المفتاح ضمن هذه القائمة.

---

## 3. Laravel ← carhub-ai: `POST http://carhub-ai:8001/v1/answer`

Header: `X-API-Key: <AI_SERVICE_KEY>`

### Request
```json
{
  "user_id": 42,
  "plan": "free",
  "message": "2018",
  "history": [
    {"role": "user", "content": "بدي ضو لكيا سبورتاج"},
    {"role": "assistant", "content": "أكيد! شو سنة صنع سيارتك؟"}
  ],
  "context": {"city": "الرياض"},
  "llm_enabled": true
}
```
`history`: آخر 6 أدوار، الأقدم أولاً، ولا يتضمن الرسالة الحالية.

**[إضافة v1]** `llm_enabled`:
- اختياري، والافتراضي `true`.
- يرسله Laravel بقيمة `false` عند بلوغ حد الكلفة (`AI_MONTHLY_COST_LIMIT_USD` أو `AI_DAILY_COST_LIMIT_USD`).
- عندها تجيب الخدمة بلا استدعاء النموذج: الاسترجاع + الرد الاحتياطي، و`trace.attempts=0` و`fallback_used=true`.

### Response 200
```json
{
  "answer": "...",
  "followup": null,
  "product_ids": [152, 160],
  "compatibility": {"152": "exact", "160": "partial"},
  "cards": [],
  "trace": {
    "query_standalone": "مصباح امامي كيا سبورتاج 2018",
    "intents": ["product_search"],
    "retrieved_ids": [152, 160, 171],
    "no_good_match": false,
    "retrieve_ms": 120,
    "llm_ms": 2400,
    "model": "qwen:8b",
    "index_version": "fake@v0",
    "fallback_used": false,
    "provider": "anthropic",
    "input_tokens": 1450,
    "output_tokens": 120,
    "cache_read_tokens": 0,
    "est_cost_usd": 0.0021,
    "attempts": 1
  }
}
```
- **[إضافة v0]** `compatibility`: خريطة من id المنتج إلى حالة التوافق، يستخدمها Laravel لملء `products[].compatibility`.
- **[إضافة v0]** `trace.fallback_used`: هل استُخدم الرد الاحتياطي المبني بالكود.
- **[إضافة v1]** `trace.provider` و`input_tokens` و`output_tokens` و`cache_read_tokens` و`est_cost_usd` و`attempts`:
  - `provider` قيمة `LLM_PROVIDER` (`anthropic` | `openai_compatible`).
  - الـ tokens والكلفة **مجموع كل محاولات** الطلب (1 أو 2).
  - `est_cost_usd` تقديرية من أسعار `.env`، و`null` إن لم تُضبط الأسعار.
  - `attempts` عدد استدعاءات النموذج الفعلية (0 إذا لم يُستدعَ).
- `followup`: نفس شكل البند 1 (`{question, suggestions}`) أو `null`.
- عند فشل مخرجات النموذج تُرجع الخدمة **200** مع رد احتياطي، لا خطأ.

### Errors
- `401`: مفتاح خاطئ.
- `422`: طلب غير صالح.
- `503 {"detail": "LLM_UNAVAILABLE"}`: خلل في إعداد المزوّد (مفتاح أو نموذج أو فوترة). الانقطاع المؤقت يعطي 200 برد احتياطي. يحوّله Laravel إلى 503 `AI_UNAVAILABLE`.

### `GET /health`
```json
{"status": "ok", "model": "claude-haiku-5-5", "llm_ok": true, "retriever": "fake",
 "provider": "anthropic", "key_configured": true}
```
- **[إضافة v1]** `provider` قيمة `LLM_PROVIDER`. و`key_configured` هل `ANTHROPIC_API_KEY` موجود (`null` لمزوّد `openai_compatible`). لا يُرجع المفتاح نفسه أبداً.
- `/health` لا يستدعي النموذج (لا كلفة). مع `anthropic`: `llm_ok` = `key_configured`، أي أن المفتاح موجود، لا أنه صحيح.

---

## 3b. [إضافة R4] Laravel ← carhub-ai: فهرس المنتجات

Header: `X-API-Key: <AI_SERVICE_KEY>` على كل المسارات. بلا مفتاح صحيح: `401`.

| المسار | الطلب | يفعل |
|---|---|---|
| `POST /v1/index/upsert` | `{"products": [<وثيقة §6>]}`، حتى 1000 لكل طلب | يضيف أو يستبدل المنتجات بنفس `id` |
| `POST /v1/index/delete` | `{"ids": [152, 160]}` | يحذفها من الفهرس |
| `POST /v1/index/sync` | `{"ids": [<كل المعرّفات النشطة>]}` | يحذف من الفهرس **كل ما سواها**، ومنه الصفوف المحذوفة من القاعدة |
| `GET /v1/index/status` | — | الحالة فقط |

### Response 200
```json
{"upserted": 2, "products": 35, "pending": true, "built_at": "2026-11-06T14:40:48+00:00",
 "last_build_s": 0.01, "last_error": null, "index_version": "local@r2c", "retriever": "local"}
```
- المفتاح الأول حسب المسار: `upserted` أو `deleted` أو `removed`. و`GET /v1/index/status` بلا مفتاح أول.
- `pending: true`: التغيير محفوظ ولم يدخل البحث بعد. يدخله خلال `INDEX_REBUILD_DELAY_S` (ثانيتان افتراضياً).
- `last_error` غير `null`: فشلت إعادة البناء، والبحث مستمر بالفهرس السابق.
- **`422`:** طلب غير صالح، ومنه أي حقل في `metadata` غير المذكورة في §6 (`price` مثلاً). **لا سعر في أي حقل** (القاعدة 2)، وأنماط الأسعار في `title` و`text` تُحذف.
- Laravel يرسل عبر `php artisan ai:index-catalog`: `--since=5` كل دقيقة، ومزامنة كاملة (`upsert` + `sync`) كل ليلة.

---

## 4. عقد أحمد (طبقة RAG) — يُطبّقه FakeRetriever حرفياً

```
analyze_query(text) -> {normalized, intent_hint, entities{make, model, year, category, oe_number}, missing[]}
retrieve(text, filters={city, category_id, doc_types, in_stock}, k=8)
  -> {items[{doc_type, id, title, text, score, match{compatibility}, metadata}],
      no_good_match, latency_ms, index_version}
```

---

## 5. مخطط مخرجات النموذج

```json
{
  "intents": ["product_search", "repair_request"],
  "answer": "short Arabic reply for the customer",
  "product_ids": [152, 160],
  "followup_question": null,
  "tender_suggestion": {"category": "paint_body", "title": "رش مصد أمامي"}
}
```
- `intents` في v0: `product_search` | `repair_request` | `other`. القائمة النهائية تُثبَّت في W4.
- `product_ids` يجب أن تكون ضمن `retrieved_ids`.
- `tender_suggestion.category` يجب أن يكون مفتاحاً من `tender_categories.json`، أو تكون القيمة كلها `null`.

---

## 6. ملفات البيانات التي يُصدّرها Laravel إلى carhub-ai (`carhub-ai/data/`)

### `fake_products.json` (نحو 20 منتجاً حقيقياً من قاعدة التطوير)
```json
[{"doc_type": "product", "id": 152,
  "title": "مصباح أمامي كيا سبورتاج",
  "text": "وصف مختصر بدون سعر",
  "metadata": {"make": "Kia", "model": "Sportage", "years": [2016, 2017, 2018],
               "category_key": "lighting",
               "keywords": ["ضو", "ضوء", "مصباح", "فانوس", "سبورتاج", "كيا"]}}]
```
- **[إضافة R4]** نفس الوثيقة تُرسل إلى §3b، ومعها في `metadata`: `oe_number` (نص أو `null`) و`in_stock` (bool). ويُقبل `city` (نص أو `null`).
- `metadata` لا تقبل غير هذه الحقول: `make`، و`model`، و`years`، و`category_key`، و`keywords`، و`oe_number`، و`city`، و`in_stock`.
- تُفهرس المنتجات بحالة `active` فقط.

### `tender_categories.json`
```json
[{"key": "paint_body", "name_ar": "دهان وسمكرة",
  "keywords": ["رش", "دهان", "سمكرة", "صبغ", "خدش"]}]
```
`key` ثابت ومتفق عليه، ويطابق قيم `App\Enums\TenderCategory` في Laravel.
