import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/brand.dart';

/// A field label on the input forms. Charcoal — the magenta labels are unique
/// to Log-In.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(color: Brand.charcoal, fontSize: 13.5),
      ),
    );
  }
}

/// A read-only field with the grey fill the mockups use for `ID AE`, `IMEI`
/// and `Tipe Modem`.
///
/// These are populated from the signed-in profile or from the server. They must
/// never become editable — see CLAUDE.md §7 rules 1 and 2.
class DisabledField extends StatelessWidget {
  const DisabledField({super.key, required this.value, this.placeholder});

  final String value;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final empty = value.isEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 17),
      decoration: BoxDecoration(
        color: Brand.fieldDisabled,
        borderRadius: BorderRadius.circular(Radii.field),
        border: Border.all(color: Brand.border),
      ),
      child: Text(
        empty ? (placeholder ?? '') : value,
        style: TextStyle(
          color: empty ? Brand.textMuted : Brand.charcoal,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Vertical rhythm between fields on the two input forms.
class FieldGap extends StatelessWidget {
  const FieldGap({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(height: 18);
}
