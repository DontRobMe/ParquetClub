import 'package:flutter/material.dart';

/// Seul fichier qui connaît les couleurs et les polices (cours 5) :
/// les écrans lisent Theme.of(context), ils ne répètent jamais une valeur.
abstract final class AppColors {
  static const rouge = Color(0xFFE30613); // action principale ; texte blanc dessus = 4,9:1
  static const noir = Color(0xFF000000); // barres, lancement
  static const blanc = Color(0xFFFFFFFF); // cartes, texte sur rouge ou noir
  static const fond = Color(0xFFF6F4F0);
  static const encre = Color(0xFF111112);
  static const texteSecondaire = Color(0xFF626064);
  static const contour = Color(0xFFE6E3DF);
}

abstract final class AppTheme {
  static const _titres = 'BarlowCondensed';
  static const _texte = 'DMSans';

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: AppColors.rouge,
      onPrimary: AppColors.blanc,
      secondary: AppColors.noir,
      onSecondary: AppColors.blanc,
      surface: AppColors.blanc,
      onSurface: AppColors.encre,
      onSurfaceVariant: AppColors.texteSecondaire,
      outline: AppColors.contour,
      error: AppColors.rouge,
      onError: AppColors.blanc,
    );

    final base = ThemeData(colorScheme: scheme, fontFamily: _texte, useMaterial3: true);
    const titre = TextStyle(fontFamily: _titres, fontWeight: FontWeight.w700);
    final radius = BorderRadius.circular(10);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.fond,
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.merge(titre),
        headlineLarge: base.textTheme.headlineLarge?.merge(titre),
        headlineMedium: base.textTheme.headlineMedium?.merge(titre),
        headlineSmall: base.textTheme.headlineSmall?.merge(titre),
        titleLarge: base.textTheme.titleLarge?.merge(titre),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.noir,
        foregroundColor: AppColors.blanc,
        titleTextStyle: TextStyle(fontFamily: _titres, fontWeight: FontWeight.w700, fontSize: 22),
      ),
      // Barre noire : icône active rouge (3:1 suffit pour une icône), libellé blanc en gras.
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.noir,
        indicatorColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.rouge : AppColors.blanc),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: _texte,
            fontSize: 12,
            color: AppColors.blanc,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      // Action principale : pleine largeur, 48 dp minimum (zone du pouce).
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontFamily: _texte, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: AppColors.encre,
          side: const BorderSide(color: AppColors.contour),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.blanc,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: radius, side: const BorderSide(color: AppColors.contour)),
      ),
      // Formulaire lisible : libellé toujours visible au-dessus du champ.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanc,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.contour)),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: const BorderSide(color: AppColors.contour)),
      ),
    );
  }
}
