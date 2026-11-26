import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

/// Display text turned into plain ASCII for the clipboard.
///
/// `×`, `÷` and superscript powers are not ASCII, and some Linux apps
/// receive them garbled (`×` as `\C3\97`) or not at all. ASCII pastes
/// cleanly everywhere and pastes back into the calculator as the same value
/// (`TextTyper` types `*`, `/` and `^` with the operator keys).
abstract final class CopiedText {
  /// `8888×979999` -> `8888*979999`, `8÷2` -> `8/2`,
  /// `9.9×10¹⁷` -> `9.9*10^17`, `1.2×10⁻⁷` -> `1.2*10^-7`,
  /// `(2+3)²` -> `(2+3)^2`. Digits, `+ - . , % ( )` are kept.
  static String fromDisplay(String text) => text
      .replaceAllMapped(
        Superscript.typedPowerPattern,
        (power) => '^${Superscript.toPlain(power[0]!)}',
      )
      .replaceAll('×', '*')
      .replaceAll('÷', '/');
}
