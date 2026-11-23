/// Clipboard text in the calculator's spelling, ready for `TextTyper`.
///
/// Only spelling is changed here; what the text types is decided by the
/// input rules (`ExpressionEditor`) and the input limits.
abstract final class PastedText {
  static final _whitespace = RegExp(r'\s+');
  static final _times = RegExp('[xX·∗]');
  static final _equals = RegExp(r'^=+|=+$');

  /// `2 x 3 =` -> `2×3`, `− 5` -> `-5`. Thousands separators (`1,024`) and
  /// `*` / `/` are left as they are; `TextTyper` accepts them.
  static String normalize(String text) => text
      .replaceAll(_whitespace, '')
      .replaceAll(_equals, '')
      .replaceAll('−', '-')
      .replaceAll(_times, '×');
}
