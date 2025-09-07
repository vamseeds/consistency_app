import 'package:flutter/material.dart';

class Category {
  String? id;
  String name;
  IconData icon;
  Color color;

  Category({
    this.id,
    required this.name,
    required this.icon,
    required this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String?,
      name: json['name'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: json['iconFontFamily'] as String),
      color: json['colorValue'] != null ? hexToColor(json['colorValue'] as String) : Colors.grey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'colorValue': colorToHex(color),
    };
  }

  static Color hexToColor(String hex) {
    try {
      // Normalize: Remove '0x' or '#' prefix, ensure uppercase
      String normalized = hex.replaceFirst(RegExp(r'^0x|#'), '').toUpperCase();
      // Validate: Must be 8 digits (AARRGGBB)
      if (normalized.length != 8 || !RegExp(r'^[0-9A-F]{8}$').hasMatch(normalized)) {
        return Colors.grey; // Fallback for invalid format
      }
      // Parse hex to int and create Color
      return Color(int.parse(normalized, radix: 16));
    } catch (e) {
      // Handle FormatException or other errors
      return Colors.grey; // Fallback for any parsing error
    }
  }

  static String colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}