import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand
  static const Color primary = Color(0xFF6366F1);      // Indigo
  static const Color primaryLight = Color(0xFF818CF8); // Indigo Light
  static const Color primaryDark = Color(0xFF4F46E5); // Indigo Dark
  static const Color accent = Color(0xFF8B5CF6);      // Violet

  // Semantic
  static const Color success = Color(0xFF10B981);      // Emerald
  static const Color successLight = Color(0xFF34D399); // Emerald Light
  static const Color danger = Color(0xFFEF4444);       // Red
  static const Color dangerLight = Color(0xFFFCA5A5);  // Red Light
  static const Color warning = Color(0xFFF59E0B);     // Amber
  static const Color warningLight = Color(0xFFFCD34D); // Amber Light
  static const Color info = Color(0xFF3B82F6);         // Blue

  // Dark Theme Backgrounds (Now consistent with Obsidian Pro)
  static const Color background = Color(0xFF0A0A0F);   // bgDark
  static const Color surface = Color(0xFF13131A);      // surfaceDark
  static const Color surfaceLight = Color(0xFF1C1C27); // surface2Dark
  static const Color surface2 = Color(0xFF252535);     // surface3Dark
  static const Color border = Color(0xFF2E2E3E);       // borderDark

  // Light Theme Backgrounds
  static const Color lightBackground = Color(0xFFF8F9FF); // bgLight
  static const Color lightSurface = Color(0xFFFFFFFF);   // surfaceLight
  static const Color lightSurface2 = Color(0xFFF1F5F9); // surface2Light
  static const Color lightBorder = Color(0xFFE2E8F0);  // borderLight

  // Text Colors
  static const Color textPrimary = Color(0xFFF8F8FF);      // textPrimary
  static const Color textSecondary = Color(0xFF94A3B8);    // textSecondary
  static const Color textMuted = Color(0xFF475569);         // textMuted
  static const Color textDark = Color(0xFF0F172A);          // textDark

  // Status Badge Colors
  static const Color active = Color(0xFF10B981);            // activeGreen
  static const Color expired = Color(0xFFEF4444);          // expiredRed
  static const Color paused = Color(0xFFF59E0B);           // pausedAmber
  static const Color deleted = Color(0xFF6B7280);           // deletedGrey
}