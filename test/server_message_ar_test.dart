import 'package:flutter_test/flutter_test.dart';

import 'package:carhub/core/errors/server_message_ar.dart';

/// اختبارات تعريب رسائل الخادم.
///
/// النصوص الإنجليزية هنا **ملتقطة فعلياً** من خادم CarHub (Laravel 11
/// بـ APP_LOCALE=en) عبر استدعاءات حقيقية بأخطاء مقصودة، لا مؤلَّفة من
/// الذاكرة. إن غيّرت إسراء لغة الخادم أو أضافت `lang/ar` فستمرّ الرسائل
/// العربية كما هي — وهذا مُغطّى أدناه أيضاً.
void main() {
  group('رسائل التحقق الشائعة', () {
    test('حقل مطلوب', () {
      expect(
        translateServerMessage('The email field is required.'),
        'البريد الإلكتروني مطلوب.',
      );
      expect(
        translateServerMessage('The password field is required.'),
        'كلمة المرور مطلوبة.',
      );
    });

    test('صيغة بريد غير صحيحة', () {
      expect(
        translateServerMessage(
            'The email field must be a valid email address.'),
        'صيغة البريد الإلكتروني غير صحيحة.',
      );
    });

    test('بريد مستخدم مسبقاً', () {
      expect(
        translateServerMessage('The email has already been taken.'),
        'البريد الإلكتروني مستخدم بالفعل. جرّب غيره أو سجّل الدخول.',
      );
    });

    test('كلمة مرور قصيرة', () {
      expect(
        translateServerMessage(
            'The password field must be at least 8 characters.'),
        'كلمة المرور يجب ألّا تقلّ عن 8 محارف.',
      );
    });

    test('تأكيد كلمة المرور غير مطابق', () {
      expect(
        translateServerMessage(
            'The password field confirmation does not match.'),
        'حقلا كلمة المرور غير متطابقين.',
      );
    });

    test('قيمة غير مسموحة', () {
      expect(
        translateServerMessage('The selected type is invalid.'),
        'نوع الحساب المحدّد غير موجود أو غير مسموح.',
      );
      expect(
        translateServerMessage('The selected product id is invalid.'),
        'المنتج المحدّد غير موجود أو غير مسموح.',
      );
    });
  });

  group('رسائل المرحلة 3', () {
    test('الصور مطلوبة عند إضافة منتج', () {
      expect(
        translateServerMessage('The images field is required.'),
        'صور القطعة مطلوبة.',
      );
    });

    test('حجم الصورة يتجاوز الحد', () {
      expect(
        translateServerMessage(
            'The images field must not be greater than 2048 kilobytes.'),
        'صور القطعة يجب ألّا يتجاوز حجمها 2 ميغابايت.',
      );
    });

    test('صيغة ملف غير مدعومة', () {
      expect(
        translateServerMessage(
            'The images field must be a file of type: jpeg, png, jpg, gif, webp.'),
        'صيغة صور القطعة غير مدعومة. الصيغ المقبولة: jpeg, png, jpg, gif, webp.',
      );
    });

    test('كمية غير صحيحة', () {
      expect(
        translateServerMessage('The quantity field must be at least 1.'),
        'الكمية يجب ألّا تقلّ عن 1.',
      );
    });
  });

  group('لاحقة «and N more errors»', () {
    test('تُفصل وتُعرَّب', () {
      expect(
        translateServerMessage(
            'The name field is required. (and 3 more errors)'),
        'الاسم مطلوب. وهناك 3 أخطاء أخرى.',
      );
      expect(
        translateServerMessage(
            'The email field is required. (and 1 more error)'),
        'البريد الإلكتروني مطلوب. وهناك خطأ آخر.',
      );
    });
  });

  group('رسائل غير تحقّقية', () {
    test('جلسة منتهية', () {
      expect(
        translateServerMessage('Unauthenticated.'),
        'انتهت جلستك. سجّل الدخول من جديد للمتابعة.',
      );
    });

    test('بلا صلاحية', () {
      expect(
        translateServerMessage('Unauthorized'),
        'لا تملك صلاحية تنفيذ هذا الإجراء.',
      );
    });
  });

  group('حالات حدّية', () {
    test('الرسالة العربية تمرّ كما هي', () {
      const arabic = 'تم إضافة المنتج للسلة بنجاح';
      expect(translateServerMessage(arabic), arabic);
    });

    test('أي نص إنجليزي غير معروف لا يصل المستخدم', () {
      // خطأ حقيقي التقطناه من الخادم (عطل في WishlistResource).
      const raw = '__clone method called on non-object';
      expect(translateServerMessage(raw), genericServerMessage);

      // أثر استثناء تقني — يجب ألّا يُعرض أبداً.
      expect(
        translateServerMessage(
            'SQLSTATE[23000]: Integrity constraint violation: 1062'),
        genericServerMessage,
      );
    });

    test('الفارغ و null', () {
      expect(translateServerMessage(null), genericServerMessage);
      expect(translateServerMessage('   '), genericServerMessage);
    });
  });
}
