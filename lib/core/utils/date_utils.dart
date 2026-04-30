import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

/// Match date/time utilities - Scores11 style
class DateUtils {
  /// Get relative date string like "Today", "Tomorrow", "Yesterday"
  static String relativeDate(DateTime date, {bool capitalize = true}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final matchDay = DateTime(date.year, date.month, date.day);
    
    final difference = matchDay.difference(today).inDays;
    
    String result;
    if (difference == 0) {
      result = 'Today';
    } else if (difference == 1) {
      result = 'Tomorrow';
    } else if (difference == -1) {
      result = 'Yesterday';
    } else if (difference > 1) {
      result = "$difference days later";
    } else {
      result = "$difference${difference > 0 ? 'd ago' : 'd later'}";
    }
    
    return capitalize ? result[0].toUpperCase() + result.substring(1) : result;
  }
  
  /// Get formatted time string "7:30 PM"
  static String formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
  
  /// Get full match date "Today • 7:30 PM" 
  static String matchDateTime(DateTime date) {
    return '${relativeDate(date)} • ${formatTime(date)}';
  }
  
  /// Countdown for upcoming matches "Starts in 2h 15m"
  static String countdown(DateTime scheduledDate) {
    final now = DateTime.now();
    final difference = scheduledDate.difference(now);
    
    if (difference.isNegative) return 'Started';
    
    final hours = difference.inHours;
    final minutes = (difference.inMinutes % 60);
    
    if (hours > 0) {
      return 'Starts in ${hours}h ${minutes}m';
    } else {
      return 'Starts in ${minutes}min';
    }
  }
  
  /// Get status-based display text
  static String statusDateTime(DateTime date, String status) {
    switch (status.toUpperCase()) {
      case 'LIVE':
        return 'Live Now';
      case 'COMPLETED':
        return DateFormat('MMM dd, yyyy').format(date);
      default:
        return matchDateTime(date);
    }
  }
  
  /// Month names for compact display
  static String formatMonth(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}

