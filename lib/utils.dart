import 'package:flutter/material.dart';

String formatTime(DateTime time) {
  final now = DateTime.now();
  final timeUtc = time.toUtc();
  final nowUtc = now.toUtc();
  final localTime = timeUtc.toLocal();
  final today = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);
  final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

  if (messageDate == today) {
    return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  } else if (messageDate == today.subtract(const Duration(days: 1))) {
    return 'Yesterday ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  } else {
    return '${localTime.day}/${localTime.month} ${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
  }
}