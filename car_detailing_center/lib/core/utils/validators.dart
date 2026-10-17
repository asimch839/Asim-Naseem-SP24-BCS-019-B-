class Validators {
  static String? required(String? value, [String message = 'This field is required']) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.trim().length < 7) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String message = 'Must be greater than 0']) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return message;
    }
    return null;
  }

  static String? nonNegativeNumber(String? value, [String message = 'Must be 0 or greater']) {
    if (value == null || value.trim().isEmpty) {
      return 'Field is required';
    }
    final num? parsed = num.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return message;
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }
}
