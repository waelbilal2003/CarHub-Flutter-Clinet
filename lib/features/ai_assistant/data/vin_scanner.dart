import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/vin_extract.dart';

/// مصدر صورة رقم الشاسيه.
enum VinImageSource { camera, gallery }

/// يصوّر رقم الشاسيه ويقرأه على الهاتف نفسه (Google ML Kit، بلا إنترنت).
/// الصورة لا تُرسل لأي خادم، وتُحذف بعد القراءة؛ يُرسل الرقم وحده، والعميل يراه ويعدّله قبل الإرسال.
abstract class VinScanner {
  /// أرقام الشاسيه المقروءة (الأرجح أولاً)، أو قائمة فارغة إن لم يُقرأ رقم واضح، أو null إن ألغى العميل.
  Future<List<String>?> scan(VinImageSource source);
}

class MlKitVinScanner implements VinScanner {
  final ImagePicker _picker;

  MlKitVinScanner({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  @override
  Future<List<String>?> scan(VinImageSource source) async {
    final image = await _picker.pickImage(
      source: source == VinImageSource.camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2000, // يكفي لقراءة 17 خانة، ويقلل الذاكرة والوقت
      imageQuality: 90,
    );
    if (image == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(image.path));
      return extractVins(result.text);
    } finally {
      await recognizer.close();
      // image_picker يعطي دائماً نسخة مؤقتة في ذاكرة التطبيق (حتى من المعرض)، لا الصورة الأصلية:
      // حذفها آمن، ولا تبقى صورة لوحة الشاسيه على الهاتف.
      try {
        await File(image.path).delete();
      } catch (_) {}
    }
  }
}

final vinScannerProvider = Provider<VinScanner>((ref) => MlKitVinScanner());
