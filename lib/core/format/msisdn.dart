/// MSISDN normalisation.
///
/// CLAUDE.md §7 rule 3: a barcode may scan as `085882724305` but the API only
/// accepts `6285882724305`. Convert once, at the scan boundary, so nothing
/// downstream has to wonder which form it is holding.
abstract final class Msisdn {
  /// Matches what the API accepts: `^62[0-9]{8,13}$`.
  static final _apiForm = RegExp(r'^62[0-9]{8,13}$');

  /// Extracts the MSISDN from a scanned code and normalises it.
  ///
  /// The label's QR carries two fields, `MSISDN|ICCID`, e.g.
  /// `085882724305|89620100002039213172`. Splitting first matters: [normalise]
  /// strips punctuation, so a raw pipe payload would fuse into one long number
  /// instead of failing. Codes without a pipe pass through unchanged, so the
  /// plain 1-D MSISDN barcode still works, and an ICCID-only code still fails.
  static String? fromScan(String raw) => normalise(raw.split('|').first);

  /// Converts a scanned or typed number to the `62` form the API expects.
  ///
  /// Returns null when the input cannot be a valid Indonesian mobile number,
  /// so callers are forced to handle a bad scan rather than sending junk.
  static String? normalise(String raw) {
    // Barcodes routinely carry spaces, dashes or a leading '+'.
    final digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return null;

    var national = digits;
    if (national.startsWith('+62')) {
      national = national.substring(3);
    } else if (national.startsWith('62')) {
      national = national.substring(2);
    } else if (national.startsWith('0')) {
      national = national.substring(1);
    } else {
      return null;
    }

    if (national.isEmpty || national.contains('+')) return null;

    final candidate = '62$national';
    return _apiForm.hasMatch(candidate) ? candidate : null;
  }

  /// True when [value] is already in the exact form the API accepts.
  static bool isApiForm(String value) => _apiForm.hasMatch(value);
}
