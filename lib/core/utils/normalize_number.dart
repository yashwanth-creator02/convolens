String normalizePhoneNumber(String? number) {
  if (number == null) return '';
  final digitsOnly = number.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.length <= 10) return digitsOnly;
  return digitsOnly.substring(digitsOnly.length - 10);
}
