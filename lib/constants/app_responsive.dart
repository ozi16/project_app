import 'package:flutter/material.dart';

class AppSizes {
  // 🔲 PADDING & MARGIN (FIXED)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  // 📏 HEIGHT (FIXED)
  static const double heightXs = 20.0;
  static const double heightSm = 40.0;
  static const double heightMd = 60.0;
  static const double heightLg = 80.0;
  static const double heightXl = 120.0;

  // 📐 WIDTH (FIXED)
  static const double widthXs = 20.0;
  static const double widthSm = 40.0;
  static const double widthMd = 60.0;
  static const double widthLg = 80.0;
  static const double widthXl = 120.0;

  // 🔘 RADIUS
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 20.0;

  // 🔳 ICON SIZE
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // 🔤 FONT SIZE
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 18.0;
  static const double fontXl = 22.0;

  // =====================================================
  // 🔥 RESPONSIVE SECTION (DINAMIS)
  // =====================================================

  /// 📱 Lebar layar
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// 📱 Tinggi layar
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  /// 📐 Width berdasarkan persen (0.0 - 1.0)
  static double wp(BuildContext context, double percent) =>
      screenWidth(context) * percent;

  /// 📏 Height berdasarkan persen (0.0 - 1.0)
  static double hp(BuildContext context, double percent,)=>
      screenHeight(context) * percent;

  /// 🔤 Font responsive (ikut lebar layar)
  static double sp(BuildContext context, double size) =>
      size * (screenWidth(context) / 375);

  /// 📦 Padding responsive
  static EdgeInsets paddingAll(BuildContext context, double value) =>
      EdgeInsets.all(sp(context, value));

  /// 📦 Margin responsive
  static EdgeInsets marginAll(BuildContext context, double value) =>
      EdgeInsets.all(sp(context, value));
}
