import 'package:carhub/features/ai_assistant/domain/vin_extract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 1M8GDM9AXKP042788: the textbook VIN whose check digit (position 9) is X.
  const checked = '1M8GDM9AXKP042788';
  const european = 'WVWZZZ1KZ6W123456'; // made up; check digit not used in Europe

  test('finds a VIN in noisy OCR text and checks the check digit', () {
    expect(hasValidCheckDigit(checked), isTrue);
    expect(hasValidCheckDigit(european), isFalse);
    expect(extractVins('VIN: $checked\nMADE IN USA'), [checked]);
  });

  test('a VIN without a valid check digit is still accepted (Europe)', () {
    expect(extractVins('Fahrzeug-Ident.-Nr. $european'), [european]);
  });

  test('fixes OCR confusions: O and Q are 0, I is 1', () {
    expect(extractVins('WVWZZZIKZ6WI23456'), ['WVWZZZ1KZ6W123456']);
    expect(extractVins('1M8GDM9AXKPO42788'), [checked]);
  });

  test('joins a VIN split by spaces or dashes', () {
    expect(extractVins('WVW ZZZ 1KZ6W 123456'), [european]);
    expect(extractVins('1M8-GDM9AXK-P042788'), [checked]);
  });

  test('reads Arabic-Indic digits and lower case', () {
    expect(extractVins('رقم الشاسيه wvwzzz١kz٦w١٢٣٤٥٦'), [european]);
  });

  test('rejects things that are not a VIN', () {
    expect(extractVins('12345678901234567'), isEmpty); // digits only
    expect(extractVins('ABCDEFGHJKLMNPRST'), isEmpty); // letters only
    expect(extractVins('04465-33450 فحمات'), isEmpty); // a part number
    expect(extractVins(''), isEmpty);
  });

  test('several candidates: the one with a valid check digit comes first', () {
    expect(extractVins('$european ... $checked'), [checked, european]);
  });
}
