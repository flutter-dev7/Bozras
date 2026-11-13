String toApiPhone(String input) {
  final trimmed = input.trim();
  final digits = trimmed.replaceAll(RegExp(r'\D'), '');

  if (digits.length == 9) return '+992$digits';
  if (digits.startsWith('992')) return '+$digits';

  return trimmed.startsWith('+') ? '+$digits' : trimmed;
}