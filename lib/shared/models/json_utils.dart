/// محوّلات متسامحة لقراءة حقول الـ API.
///
/// ضرورية لأن الـ Backend غير متّسق في أنواع بعض الحقول:
///  • tender_id يعود "1" (نص) عند إنشاء عرض، و 1 (رقم) عند قراءة القائمة.
///  • budget و price يعودان نصاً دائماً: "50000.00".
///  • status قد يعود null عند الإنشاء ثم "open" عند القراءة.
library;

/// يقرأ int من قيمة قد تكون int أو num أو String.
int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v.trim());
  return null;
}

/// مثل [asIntOrNull] لكن بقيمة افتراضية عند الفشل.
int asInt(dynamic v, {int fallback = 0}) => asIntOrNull(v) ?? fallback;

/// يقرأ double من قيمة قد تكون رقماً أو نصاً ("48000.00").
double? asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim());
  return null;
}

double asDouble(dynamic v, {double fallback = 0}) =>
    asDoubleOrNull(v) ?? fallback;

/// يقرأ نصاً، ويعيد null للنص الفارغ.
String? asStringOrNull(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

String asString(dynamic v, {String fallback = ''}) =>
    asStringOrNull(v) ?? fallback;

/// يقرأ bool من true/false أو 1/0 أو "true"/"1".
bool asBool(dynamic v, {bool fallback = false}) {
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final s = v.trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

/// يقرأ تاريخاً بصيغة ISO ("2026-09-03T14:35:06+00:00").
DateTime? asDateOrNull(dynamic v) {
  final s = asStringOrNull(v);
  if (s == null) return null;
  return DateTime.tryParse(s);
}

/// يقرأ قائمة نصوص (مثل attachments التي تعود [] في كل الأمثلة).
List<String> asStringList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
}
