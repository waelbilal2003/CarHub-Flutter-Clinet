/// قراءة رقم الشاسيه (VIN) من نص صورة.
///
/// نفس قواعد carhub-ai (app/vin.py): 17 خانة، بلا I وO وQ، وفيه رقم وحرف على الأقل.
/// قراءة النص من الصور تخلط O بـ 0 وI بـ 1، وقد تقسم الرقم بمسافات، فنصلح ذلك هنا.
/// الدالة نقية (بلا كاميرا ولا شبكة)، فتُختبر كاملة.
library;

const _vinLength = 17;
const _vinChars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789';

/// O وQ لا يوجدان في رقم شاسيه، فهما صفر قرأته الكاميرا خطأً. وI هو واحد.
const _ocrFixes = {'O': '0', 'Q': '0', 'I': '1'};

/// ISO 3779: قيمة كل حرف لحساب خانة التحقق (الخانة التاسعة، إلزامية في أمريكا الشمالية فقط).
const _values = {
  'A': 1, 'B': 2, 'C': 3, 'D': 4, 'E': 5, 'F': 6, 'G': 7, 'H': 8,
  'J': 1, 'K': 2, 'L': 3, 'M': 4, 'N': 5, 'P': 7, 'R': 9,
  'S': 2, 'T': 3, 'U': 4, 'V': 5, 'W': 6, 'X': 7, 'Y': 8, 'Z': 9,
};
const _weights = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

/// أرقام الشاسيه الممكنة في النص، الأرجح أولاً (من يطابق خانة التحقق يتقدّم).
List<String> extractVins(String text) {
  final ascii = _toAsciiDigits(text).toUpperCase();
  final tokens = RegExp(r'[A-Z0-9]+').allMatches(ascii).map((m) => m.group(0)!).toList();

  final candidates = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    // رقم كامل، أو مقسوم إلى أجزاء متتالية بمسافات أو شرطات (حتى 4 أجزاء).
    var joined = '';
    for (var j = i; j < tokens.length && j < i + 4; j++) {
      joined += tokens[j];
      if (joined.length == _vinLength) {
        final vin = _fix(joined);
        if (vin != null && !candidates.contains(vin)) candidates.add(vin);
        break;
      }
      if (joined.length > _vinLength) break;
    }
  }
  // ثابت الترتيب: من يطابق خانة التحقق أولاً، ثم بترتيب الظهور في الصورة.
  final checked = candidates.where(hasValidCheckDigit).toList();
  return [...checked, ...candidates.where((v) => !checked.contains(v))];
}

/// خانة التحقق صحيحة؟ (غير إلزامية في أوروبا: رقم لا يطابقها قد يكون صحيحاً).
bool hasValidCheckDigit(String vin) {
  if (vin.length != _vinLength) return false;
  var sum = 0;
  for (var i = 0; i < _vinLength; i++) {
    final c = vin[i];
    final v = int.tryParse(c) ?? _values[c];
    if (v == null) return false;
    sum += v * _weights[i];
  }
  final r = sum % 11;
  return vin[8] == (r == 10 ? 'X' : '$r');
}

String? _fix(String raw) {
  final vin = raw.split('').map((c) => _ocrFixes[c] ?? c).join();
  if (!vin.split('').every(_vinChars.contains)) return null;
  final hasDigit = vin.contains(RegExp(r'[0-9]'));
  final hasLetter = vin.contains(RegExp(r'[A-Z]'));
  return hasDigit && hasLetter ? vin : null;
}

String _toAsciiDigits(String s) {
  final b = StringBuffer();
  for (final ch in s.split('')) {
    final i = _arabicDigits.indexOf(ch);
    b.write(i >= 0 ? '$i' : ch);
  }
  return b.toString();
}
