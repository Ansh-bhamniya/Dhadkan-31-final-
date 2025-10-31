
import 'package:dhadkan/utils/theme/text_theme.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class MyTheme {
  MyTheme._();

  static ThemeData myTheme = ThemeData(
      useMaterial3: true,
      fontFamily: 'Poppins',
      primaryColor: MyColors.primary,
      scaffoldBackgroundColor: MyColors.bgColor,
      textTheme: MyTextTheme.textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: MyColors.primary,
        elevation: 0.5, // Add elevation to show a shadow
        shadowColor: MyColors.textWhite, // Set shadow color to white for border effect

        iconTheme: IconThemeData(

          color: Colors.white,
          size: 18
        ),
      ));
}
