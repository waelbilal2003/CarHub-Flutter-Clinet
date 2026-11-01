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
- `message`: نص، من 1 إلى 500 حرف.
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
    "usage": {"used_today": 3, "daily_limit": 10}
  }
}
```
- `followup`: كائن أو `null`.
- `products`: يملؤها Laravel من قاعدة البيانات فقط. لا يأتي أي سعر من خدمة الذكاء.
- `compatibility`: `exact` | `partial`.

### Errors
```json
429 {"success": false, "message": "وصلت للحد اليومي للمساعد", "errors": {"code": ["AI_LIMIT_REACHED"]}}
503 {"success": false, "message": "المساعد غير متاح حالياً", "errors": {"code": ["AI_UNAVAILABLE"]}}
422 validation (empty / too long message)
```
في الهيكل v0 لا يُفعَّل 429. يُرجَع `usage` بنفس الشكل دون فرض الحد (يأتي في W5).

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
  "context": {"city": "الرياض"}
}
```
`history`: آخر 6 أدوار، الأقدم أولاً، ولا يتضمن الرسالة الحالية.

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

### `tender_categories.json`
```json
[{"key": "paint_body", "name_ar": "دهان وسمكرة",
  "keywords": ["رش", "دهان", "سمكرة", "صبغ", "خدش"]}]
```
`key` ثابت ومتفق عليه، ويطابق قيم `App\Enums\TenderCategory` في Laravel.
