import 'package:flutter_test/flutter_test.dart';

import 'package:hifiair_sales_app/core/format/msisdn.dart';

void main() {
  group('MSISDN normalisation', () {
    test('converts a leading 0 to 62 form', () {
      // The exact barcode printed on the HiFi AIR box in the scanner mockup.
      expect(Msisdn.normalise('085882724305'), '6285882724305');
    });

    test('leaves an already-normalised number alone', () {
      expect(Msisdn.normalise('6285882724305'), '6285882724305');
    });

    test('accepts +62 and strips separators', () {
      expect(Msisdn.normalise('+62 858-8272-4305'), '6285882724305');
    });

    test('rejects anything that is not an Indonesian mobile number', () {
      // Other codes are printed on the same box label.
      expect(Msisdn.normalise('8962010000203921317'), isNull);
      expect(Msisdn.normalise('110089/DJID/2025'), isNull);
      expect(Msisdn.normalise(''), isNull);
    });
  });
}
