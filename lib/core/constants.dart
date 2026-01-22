import 'package:flutter/material.dart';

const String kBaseUrl = 'https://www.themealdb.com/api/json/v1/1';
const Color kPrimaryColor = Colors.orangeAccent;
const Color kBackgroundColor = Color(0xFFFAFAFA);

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kBackgroundColor,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kPrimaryColor,
    surface: kBackgroundColor,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: kBackgroundColor,
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 24,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
  ),
  cardTheme: CardTheme(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    clipBehavior: Clip.antiAlias,
  ),
  chipTheme: ChipThemeData(
    backgroundColor: Colors.white,
    side: BorderSide(color: Colors.grey.shade300),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    labelStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  ),
);