import '../models/business_hours.dart';

/// Returns true if the business is currently open based on business hours
bool isBusinessOpen(Map<String, BusinessHours>? hours) {
  if (hours == null || hours.isEmpty) return false;

  final now = DateTime.now();
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final todayName = weekdays[now.weekday - 1];
  final todayHours = hours[todayName];

  if (todayHours == null) return false;

  final currentMinutes = now.hour * 100 + now.minute;
  return currentMinutes >= todayHours.open && currentMinutes < todayHours.close;
}

const double businessDetectionRadius = 2000;

/// Returns true if the business is open based on hours
bool isBusinessActuallyOpen(Map<String, BusinessHours>? hours) {
  return isBusinessOpen(hours);
}