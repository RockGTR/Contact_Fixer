import 'package:flutter/material.dart';

enum SortOption { name, phone, lastModified, dateAdded }

// Alphabet-based color palette
Color getColorForName(String? name) {
  if (name == null || name.isEmpty) return const Color(0xFF667eea);
  final letter = name[0].toUpperCase();
  final colors = [
    const Color(0xFFef4444), // A - Red
    const Color(0xFFf97316), // B - Orange
    const Color(0xFFf59e0b), // C - Amber
    const Color(0xFFeab308), // D - Yellow
    const Color(0xFF84cc16), // E - Lime
    const Color(0xFF22c55e), // F - Green
    const Color(0xFF10b981), // G - Emerald
    const Color(0xFF14b8a6), // H - Teal
    const Color(0xFF06b6d4), // I - Cyan
    const Color(0xFF0ea5e9), // J - Sky
    const Color(0xFF3b82f6), // K - Blue
    const Color(0xFF6366f1), // L - Indigo
    const Color(0xFF8b5cf6), // M - Violet
    const Color(0xFFa855f7), // N - Purple
    const Color(0xFFd946ef), // O - Fuchsia
    const Color(0xFFec4899), // P - Pink
    const Color(0xFFf43f5e), // Q - Rose
    const Color(0xFF78716c), // R - Stone
    const Color(0xFF64748b), // S - Slate
    const Color(0xFF6b7280), // T - Gray
    const Color(0xFFef4444), // U
    const Color(0xFFf97316), // V
    const Color(0xFFf59e0b), // W
    const Color(0xFF84cc16), // X
    const Color(0xFF22c55e), // Y
    const Color(0xFF3b82f6), // Z
  ];
  final index = letter.codeUnitAt(0) - 65;
  if (index >= 0 && index < 26) return colors[index];
  return const Color(0xFF667eea);
}
