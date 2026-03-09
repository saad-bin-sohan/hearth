class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailPattern.hasMatch(value.trim())) {
      return 'Enter a valid email address.';
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required.';
    }
    if (value.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Add at least one uppercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Add at least one number.';
    }
    return null;
  }

  static String? householdName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Household name is required.';
    }
    if (value.trim().length < 3) {
      return 'Use at least 3 characters.';
    }
    return null;
  }

  static String? inviteCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Invite code is required.';
    }
    if (!RegExp(r'^[A-Z0-9]{8}$').hasMatch(value.trim().toUpperCase())) {
      return 'Invite codes are 8 letters or numbers.';
    }
    return null;
  }
}
