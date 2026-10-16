/// تعريب رسائل الخادم.
///
/// سبب وجود هذا الملف: الـ Backend يعمل بـ `APP_LOCALE=en` ولا يحوي
/// مجلد `lang/` عربي، فرسائل التحقق في Laravel تعود بالإنجليزية
/// («The email has already been taken.»). أربعة نماذج فقط تعرّبها
/// بنفسها عبر `messages()`؛ الباقي — ومنه شاشتا الدخول وإنشاء الحساب —
/// يصل إنجليزياً.
///
/// لذلك نعرّب هنا في التطبيق بدل انتظار الـ Backend: نطابق قوالب Laravel
/// القياسية، ونستبدل اسم الحقل بمسمّاه العربي كما يعرفه المستخدم
/// (`password_confirmation` ← «تأكيد كلمة المرور»).
///
/// قاعدتان تحكمان هذا الملف:
///  1. **لا يرى المستخدم نصاً إنجليزياً أبداً.** أي رسالة إنجليزية لم
///     نتعرّف عليها تُستبدل برسالة عربية عامة مهذّبة.
///  2. **العربية سليمة نحوياً.** كل حقل يحمل جنسه، فلا تظهر عبارات
///     ركيكة مثل «كلمة المرور مطلوب» بدل «كلمة المرور مطلوبة».
library;

/// اسم حقل معروض للمستخدم مع جنسه النحوي.
///
/// [isFeminine] يحدّد صيغة الخبر المرافق: «مطلوبة» لا «مطلوب»،
/// «يجب ألّا تقلّ» لا «يجب ألّا يقلّ». الجمع غير العاقل (صور، تفاصيل،
/// ملاحظات) يأخذ حكم المؤنث المفرد في العربية.
class _Field {
  final String name;
  final bool isFeminine;

  const _Field(this.name, {this.isFeminine = false});

  /// يختار بين صيغتي المذكّر والمؤنث.
  String agree(String masculine, String feminine) =>
      isFeminine ? feminine : masculine;
}

/// أسماء الحقول كما يفهمها المستخدم العادي، لا كما تسمّيها قاعدة البيانات.
///
/// Laravel يحوّل `password_confirmation` إلى «password confirmation»
/// قبل وضعها في الرسالة، لذلك المفاتيح هنا بمسافات لا بشرطات سفلية،
/// ونقبل الشكلين احتياطاً.
const Map<String, _Field> _fields = {
  // الحساب
  'email': _Field('البريد الإلكتروني'),
  'password': _Field('كلمة المرور', isFeminine: true),
  'password confirmation': _Field('تأكيد كلمة المرور'),
  'current password': _Field('كلمة المرور الحالية', isFeminine: true),
  'name': _Field('الاسم'),
  'phone': _Field('رقم الهاتف'),
  'type': _Field('نوع الحساب'),
  'avatar': _Field('الصورة الشخصية', isFeminine: true),

  // العناوين
  'title': _Field('العنوان'),
  'recipient name': _Field('اسم المستلم'),
  'city': _Field('المدينة', isFeminine: true),
  'address line': _Field('تفاصيل العنوان', isFeminine: true),
  'address id': _Field('عنوان الشحن'),
  'is default': _Field('العنوان الافتراضي'),

  // المنتجات والسلة
  'product id': _Field('المنتج'),
  'quantity': _Field('الكمية', isFeminine: true),
  'description': _Field('الوصف'),
  'price': _Field('السعر'),
  'stock': _Field('الكمية المتاحة', isFeminine: true),
  'images': _Field('صور القطعة', isFeminine: true),
  'category id': _Field('التصنيف'),
  'brand id': _Field('الماركة', isFeminine: true),
  'rating': _Field('التقييم'),
  'comment': _Field('التعليق'),

  // الطلبات
  'status': _Field('حالة الطلب', isFeminine: true),
  'notes': _Field('الملاحظات', isFeminine: true),

  // المناقصات والعروض (المرحلة 2)
  'budget': _Field('الميزانية', isFeminine: true),
  'deadline': _Field('الموعد النهائي'),
  'tender id': _Field('المناقصة', isFeminine: true),
  'amount': _Field('المبلغ'),
  'message': _Field('الرسالة', isFeminine: true),
  'receiver id': _Field('المستلم'),
};

/// يحوّل اسم حقل إنجليزياً إلى [_Field]. الحقول غير المعروفة تُعرض
/// باسمها كما ورد، وتُعامَل معاملة المذكّر (الحالة الأعمّ).
_Field _fieldOf(String raw) {
  final key = raw.trim().replaceAll('_', ' ').toLowerCase();
  return _fields[key] ?? _Field(key);
}

/// قوالب Laravel القياسية ← صياغتها العربية.
///
/// الترتيب مهم: الأنماط الأكثر تحديداً أولاً، وإلا ابتلعها نمط أعم.
///
/// ملاحظة على الأرقام: نستخدم `(\d+(?:\.\d+)?)` لا `([\d.]+)` حتى لا
/// تبتلع المجموعةُ النقطةَ الختامية فتظهر «... عن 1..».
final List<(RegExp, String Function(Match))> _patterns = [
  // ── مطلوب ──
  (
    RegExp(r'^The (.+?) field is required\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('مطلوب', 'مطلوبة')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field is required when .+$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('مطلوب', 'مطلوبة')}.';
    },
  ),

  // ── بريد إلكتروني ──
  (
    RegExp(r'^The (.+?) field must be a valid email address\.?$',
        caseSensitive: false),
    (m) => 'صيغة ${_fieldOf(m[1]!).name} غير صحيحة.',
  ),
  (
    RegExp(r'^The (.+?) must be a valid email address\.?$',
        caseSensitive: false),
    (m) => 'صيغة ${_fieldOf(m[1]!).name} غير صحيحة.',
  ),

  // ── مستخدم مسبقاً ──
  (
    RegExp(r'^The (.+?) has already been taken\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('مستخدم', 'مستخدمة')} بالفعل. '
          'جرّب غيره أو سجّل الدخول.';
    },
  ),

  // ── تطابق التأكيد ──
  (
    RegExp(r'^The (.+?) field confirmation does not match\.?$',
        caseSensitive: false),
    (m) => 'حقلا ${_fieldOf(m[1]!).name} غير متطابقين.',
  ),
  (
    RegExp(r'^The (.+?) confirmation does not match\.?$', caseSensitive: false),
    (m) => 'حقلا ${_fieldOf(m[1]!).name} غير متطابقين.',
  ),

  // ── الطول بالمحارف ──
  (
    RegExp(r'^The (.+?) field must be at least (\d+) characters\.?$',
        caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب ألّا يقلّ', 'يجب ألّا تقلّ')} '
          'عن ${m[2]} محارف.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must not be greater than (\d+) characters\.?$',
        caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب ألّا يتجاوز', 'يجب ألّا تتجاوز')} '
          '${m[2]} محرفاً.';
    },
  ),

  // ── حجم الملف ──
  (
    RegExp(r'^The (.+?) field must not be greater than (\d+) kilobytes\.?$',
        caseSensitive: false),
    (m) {
      final kb = int.parse(m[2]!);
      final size = kb >= 1024
          ? '${(kb / 1024).toStringAsFixed(kb % 1024 == 0 ? 0 : 1)} ميغابايت'
          : '$kb كيلوبايت';
      return '${_fieldOf(m[1]!).name} يجب ألّا يتجاوز حجمها $size.';
    },
  ),

  // ── الأرقام ──
  (
    RegExp(r'^The (.+?) field must be at least (\d+(?:\.\d+)?)\.?$',
        caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب ألّا يقلّ', 'يجب ألّا تقلّ')} '
          'عن ${m[2]}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must not be greater than (\d+(?:\.\d+)?)\.?$',
        caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب ألّا يتجاوز', 'يجب ألّا تتجاوز')} '
          '${m[2]}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be a number\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب أن يكون', 'يجب أن تكون')} رقماً.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be an integer\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب أن يكون', 'يجب أن تكون')} عدداً صحيحاً.';
    },
  ),

  // ── الملفات والصور ──
  (
    RegExp(r'^The (.+?) field must be an image\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب أن يكون صورة صالحة', 'يجب أن تكون صورة صالحة')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be a file of type: (.+?)\.?$',
        caseSensitive: false),
    (m) => 'صيغة ${_fieldOf(m[1]!).name} غير مدعومة. '
        'الصيغ المقبولة: ${m[2]}.',
  ),
  (
    RegExp(r'^The (.+?) field must be an array\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('غير صالح', 'غير صالحة')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must have at least (\d+) items\.?$',
        caseSensitive: false),
    (m) => '${_fieldOf(m[1]!).name}: أضف ${m[2]} على الأقل.',
  ),

  // ── قيمة غير موجودة أو غير مسموحة ──
  (
    RegExp(r'^The selected (.+?) is invalid\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('المحدّد غير موجود أو غير مسموح', 'المحدّدة غير موجودة أو غير مسموحة')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be a string\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('غير صالح', 'غير صالحة')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be a valid date\.?$', caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب أن يكون تاريخاً صالحاً', 'يجب أن تكون تاريخاً صالحاً')}.';
    },
  ),
  (
    RegExp(r'^The (.+?) field must be a date after (.+?)\.?$',
        caseSensitive: false),
    (m) {
      final f = _fieldOf(m[1]!);
      return '${f.name} ${f.agree('يجب أن يكون', 'يجب أن تكون')} بعد ${m[2]}.';
    },
  ),
];

/// رسائل ثابتة يردّها Laravel/Sanctum خارج نظام التحقق.
const Map<String, String> _exactMessages = {
  'unauthenticated.': 'انتهت جلستك. سجّل الدخول من جديد للمتابعة.',
  'unauthenticated': 'انتهت جلستك. سجّل الدخول من جديد للمتابعة.',
  'unauthorized': 'لا تملك صلاحية تنفيذ هذا الإجراء.',
  'unauthorized.': 'لا تملك صلاحية تنفيذ هذا الإجراء.',
  'forbidden': 'لا تملك صلاحية تنفيذ هذا الإجراء.',
  'not found': 'العنصر المطلوب غير موجود.',
  'server error': 'حدث خطأ في الخادم. حاول مرة أخرى بعد قليل.',
  'too many requests': 'حاولت كثيراً في وقت قصير. انتظر قليلاً ثم أعد المحاولة.',
};

/// هل يحوي النص حرفاً عربياً؟ إن كان كذلك فهو مُعرَّب أصلاً من الخادم
/// (النماذج الأربعة التي تعرّف `messages()`) فنعرضه كما هو.
final RegExp _arabicChar = RegExp(r'[؀-ۿ]');

/// الرسالة العامة التي تحلّ محل أي نص إنجليزي لم نتعرّف عليه.
const String genericServerMessage =
    'تعذّر إتمام العملية. تأكّد من البيانات المُدخلة ثم حاول مرة أخرى.';

/// Laravel يُلحق بالرسالة العامة عدد بقية الأخطاء:
/// `The name field is required. (and 3 more errors)`.
/// نفصل اللاحقة لتُطابَق الجملة الأساسية، ثم نعيدها معرَّبة.
final RegExp _moreErrorsSuffix =
    RegExp(r'\s*\(and (\d+) more errors?\)\s*$', caseSensitive: false);

String _moreErrorsAr(int count) => switch (count) {
      1 => ' وهناك خطأ آخر.',
      2 => ' وهناك خطآن آخران.',
      >= 3 && <= 10 => ' وهناك $count أخطاء أخرى.',
      _ => ' وهناك $count خطأً آخر.',
    };

/// يحوّل رسالة قادمة من الخادم إلى نص عربي صالح للعرض للمستخدم.
///
/// الترتيب:
///  1. عربية أصلاً → كما هي.
///  2. رسالة ثابتة معروفة → ترجمتها.
///  3. قالب تحقق من Laravel → صياغته العربية.
///  4. أي شيء آخر (بما فيه آثار الاستثناءات) → [genericServerMessage].
String translateServerMessage(String? raw) {
  var message = raw?.trim() ?? '';
  if (message.isEmpty) return genericServerMessage;

  if (_arabicChar.hasMatch(message)) return message;

  // نفصل لاحقة «(and N more errors)» لتُطابَق الجملة الأساسية.
  var suffix = '';
  final more = _moreErrorsSuffix.firstMatch(message);
  if (more != null) {
    suffix = _moreErrorsAr(int.parse(more[1]!));
    message = message.replaceFirst(_moreErrorsSuffix, '').trim();
  }

  final exact = _exactMessages[message.toLowerCase()];
  if (exact != null) return exact + suffix;

  for (final (pattern, build) in _patterns) {
    final match = pattern.firstMatch(message);
    if (match != null) return build(match) + suffix;
  }

  // نصّ إنجليزي غير معروف: لا نعرضه للمستخدم مهما كان.
  return genericServerMessage;
}
