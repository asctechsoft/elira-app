/// Pure functions with no Flutter imports so they can be unit tested directly.
/// Each returns `null` when valid, or a message key from `AppStrings`.
library;

final RegExp _emailPattern = RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");

const int kMinPasswordLength = 6;
const int kMinDisplayNameLength = 2;
const int kMaxDisplayNameLength = 40;

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'emailRequired';
  if (!_emailPattern.hasMatch(v)) return 'emailInvalid';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'passwordRequired';
  if (v.length < kMinPasswordLength) return 'passwordTooShort';
  return null;
}

String? validateConfirmPassword(String? value, String original) {
  final v = value ?? '';
  if (v.isEmpty) return 'confirmRequired';
  if (v != original) return 'confirmMismatch';
  return null;
}

String? validateDisplayName(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'nameRequired';
  if (v.length < kMinDisplayNameLength) return 'nameTooShort';
  if (v.length > kMaxDisplayNameLength) return 'nameTooLong';
  return null;
}
