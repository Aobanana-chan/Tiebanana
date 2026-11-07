import 'package:flutter/material.dart';

class QuoteTheme extends ThemeExtension<QuoteTheme> {
  static QuoteTheme bright = QuoteTheme(
      backgorund: const Color(0xFFF0F3F5), textColor: Colors.grey.shade600);
  static QuoteTheme dark = QuoteTheme(
      backgorund: const Color.fromARGB(255, 65, 66, 66),
      textColor: Colors.white);
  final Color? backgorund;
  final Color? textColor;
  QuoteTheme({required this.backgorund, required this.textColor});
  @override
  ThemeExtension<QuoteTheme> copyWith({Color? backgorund, Color? textColor}) {
    return QuoteTheme(
        backgorund: backgorund ?? this.backgorund,
        textColor: textColor ?? this.textColor);
  }

  @override
  ThemeExtension<QuoteTheme> lerp(ThemeExtension<QuoteTheme>? other, double t) {
    if (other is! QuoteTheme) {
      return this;
    }
    return QuoteTheme(
        backgorund: Color.lerp(backgorund, other.backgorund, t),
        textColor: Color.lerp(textColor, other.textColor, t));
  }
}
