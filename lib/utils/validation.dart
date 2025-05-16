import 'package:flutter/material.dart';

class Validator {
  // Email validation
  static bool isValidEmail(String email) {
    final emailRegExp = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegExp.hasMatch(email);
  }

  // Password validation (min 8 chars, at least one letter and one number)
  static bool isValidPassword(String password) {
    final passwordRegExp = RegExp(
      r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  // Phone number validation
  static bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegExp = RegExp(r'^\+?[0-9]{10,14}$');
    return phoneRegExp.hasMatch(phoneNumber);
  }

  // Username validation (alphanumeric and underscore, 3-20 chars)
  static bool isValidUsername(String username) {
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegExp.hasMatch(username);
  }

  // Check if string is empty or whitespace only
  static bool isEmptyOrWhitespace(String? text) {
    return text == null || text.trim().isEmpty;
  }
  
  // Message content validation
  static bool isValidMessageContent(String content) {
    return content.trim().isNotEmpty && content.length <= 2000;
  }
  
  // URL validation
  static bool isValidUrl(String url) {
    final urlRegExp = RegExp(r'^(http|https)://[\w.-]+\.[a-zA-Z]{2,}(/.*)?$');
    return urlRegExp.hasMatch(url);
  }
  
  // Room name validation
  static bool isValidRoomName(String name) {
    return name.trim().isNotEmpty && name.length >= 3 && name.length <= 50;
  }

  // Form field validators
  static String? validateEmail(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Email is required';
    }
    if (!isValidEmail(value!)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Password is required';
    }
    if (!isValidPassword(value!)) {
      return 'Password must be at least 8 characters with at least one letter and one number';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Username is required';
    }
    if (!isValidUsername(value!)) {
      return 'Username must be 3-20 characters using only letters, numbers, and underscores';
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Phone number is required';
    }
    if (!isValidPhoneNumber(value!)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? validateMessageContent(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Message cannot be empty';
    }
    if (value!.length > 2000) {
      return 'Message is too long (max 2000 characters)';
    }
    return null;
  }
  
  static String? validateRoomName(String? value) {
    if (isEmptyOrWhitespace(value)) {
      return 'Room name is required';
    }
    if (value!.length < 3) {
      return 'Room name must be at least 3 characters';
    }
    if (value.length > 50) {
      return 'Room name must be less than 50 characters';
    }
    return null;
  }
} 