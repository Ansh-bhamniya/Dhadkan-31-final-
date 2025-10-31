import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MyTextTheme {
  MyTextTheme._();

  static TextTheme textTheme = TextTheme(
      // headline___ for Bold Texts
      headlineLarge: const TextStyle().copyWith(
          fontSize: 20.0, fontWeight: FontWeight.w600, color: MyColors.primary),
      headlineMedium: const TextStyle().copyWith(
          fontSize: 18.0, fontWeight: FontWeight.w600, color: MyColors.primary),
      headlineSmall: const TextStyle().copyWith(
          fontSize: 15.0, fontWeight: FontWeight.w600, color: MyColors.primary),

      // body___ for Normal Texts
      bodyLarge: const TextStyle().copyWith(
          fontSize: 18.0, fontWeight: FontWeight.w400, color: MyColors.primary),
      bodyMedium: const TextStyle().copyWith(
          fontSize: 15.0, fontWeight: FontWeight.w400, color: MyColors.primary),
      bodySmall: const TextStyle().copyWith(
          fontSize: 10.0, fontWeight: FontWeight.w600, color: MyColors.primary),

      // title___ for White Texts
      titleMedium: const TextStyle().copyWith(
          fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      titleSmall: const TextStyle().copyWith(
          fontSize: 14, fontWeight: FontWeight.w500, color: MyColors.primary));
}
