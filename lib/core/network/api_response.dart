import '../errors/failures.dart';
import '../errors/server_message_ar.dart';

/// الغلاف الموحّد لكل استجابات CarHub API:
/// ```json
/// { "success": true, "message": "...", "data": { ... } }
/// ```
///
/// ملاحظة مهمة: شكل [data] غير موحّد في الـ Backend الحالي —
///  • Auth      → data.user / data.token   (مفتاح مسمّى)
///  • Addresses → data.address (مفرد) و data.data[] (قائمة)
///  • Tenders / Bids / Messages → الكائن مباشرة داخل data عند الإنشاء،
///    و data.data[] للقوائم المصفّحة.
///
/// لذلك لا يفترض هذا الغلاف شكلاً واحداً؛ يوفّر أدوات قراءة صريحة
/// ([objectAt] / [object] / [paginated]) ويختار كل datasource ما يناسبه.
class ApiEnvelope {
  final bool success;
  final String message;
  final dynamic data;

  const ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
  });

  /// يفكّ غلاف الاستجابة ويتحقق من [success].
  /// يرمي [Failure] مباشرة إذا أعاد الخادم success = false.
  factory ApiEnvelope.from(dynamic body) {
    if (body is! Map) {
      throw const ServerFailure('استجابة الخادم غير مفهومة (تنسيق غير متوقّع).');
    }

    final success = body['success'] == true;
    // الرسالة قد تعود إنجليزية (APP_LOCALE=en في الـ Backend)، فنعرّبها
    // قبل أي عرض — لا يصل المستخدم نصٌّ إنجليزي من هنا.
    final message = body['message'] is String
        ? translateServerMessage(body['message'] as String)
        : (success ? 'تمت العملية بنجاح' : 'تعذّر إتمام العملية.');

    if (!success) {
      // الخادم ردّ 200 لكن العملية فشلت منطقياً.
      throw ValidationFailure(message);
    }

    return ApiEnvelope(
      success: success,
      message: message,
      data: body['data'],
    );
  }

  /// [data] نفسه ككائن JSON. يُستخدم عندما يعيد الخادم الكائن مباشرة
  /// داخل data (المناقصات، العروض، إرسال رسالة).
  Map<String, dynamic> get object {
    final d = data;
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    throw const ServerFailure('الحقل data ناقص أو بشكل غير متوقّع.');
  }

  /// كائن داخل مفتاح محدّد، مثل data.user أو data.address.
  Map<String, dynamic> objectAt(String key) {
    final d = object[key];
    if (d is Map<String, dynamic>) return d;
    if (d is Map) return Map<String, dynamic>.from(d);
    throw ServerFailure('الحقل data.$key مفقود في استجابة الخادم.');
  }

  /// قيمة بسيطة داخل data (مثل data.token).
  T valueAt<T>(String key) {
    final v = object[key];
    if (v is T) return v;
    throw ServerFailure('الحقل data.$key مفقود أو بنوع غير متوقّع.');
  }

  /// قائمة مصفّحة: data.data[] مع data.meta.
  PaginatedList<T> paginated<T>(T Function(Map<String, dynamic>) parse) {
    final d = object;
    final rawList = d['data'];
    if (rawList is! List) {
      throw const ServerFailure('الحقل data.data ليس قائمة كما هو متوقّع.');
    }

    final items = rawList
        .whereType<Map>()
        .map((e) => parse(Map<String, dynamic>.from(e)))
        .toList();

    return PaginatedList<T>(
      items: items,
      meta: d['meta'] is Map
          ? PageMeta.fromJson(Map<String, dynamic>.from(d['meta'] as Map))
          : PageMeta.single(items.length),
    );
  }
}

/// قائمة مع معلومات التصفّح.
class PaginatedList<T> {
  final List<T> items;
  final PageMeta meta;

  const PaginatedList({required this.items, required this.meta});

  bool get hasMore => meta.currentPage < meta.lastPage;
  int get nextPage => meta.currentPage + 1;
  bool get isEmpty => items.isEmpty;
}

/// بيانات التصفّح القادمة من Laravel (data.meta).
class PageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const PageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  /// للاستجابات التي لا تحوي meta أصلاً (مثل قائمة العناوين).
  factory PageMeta.single(int count) => PageMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: count,
        total: count,
      );

  factory PageMeta.fromJson(Map<String, dynamic> json) => PageMeta(
        currentPage: _toInt(json['current_page']) ?? 1,
        lastPage: _toInt(json['last_page']) ?? 1,
        perPage: _toInt(json['per_page']) ?? 15,
        total: _toInt(json['total']) ?? 0,
      );
}

/// يحوّل قيمة قد تأتي رقماً أو نصاً إلى int.
/// ضروري لأن الـ Backend يعيد بعض الحقول كنص أحياناً
/// (مثال: tender_id يعود "1" عند إنشاء عرض و 1 عند قراءة القائمة).
int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
