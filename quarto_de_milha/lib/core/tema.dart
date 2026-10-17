import 'package:flutter/material.dart';

/// Paleta extraída do guia visual do aplicativo (verde-petróleo, dourado e creme).
abstract final class Cores {
  static const escuro = Color(0xFF0A1A19);
  static const escuroSuave = Color(0xFF142A28);
  static const dourado = Color(0xFFA6834B);
  static const douradoClaro = Color(0xFFD8BE8F);
  static const fundo = Color(0xFFF0EFEB);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieSuave = Color(0xFFF8F7F3);
  static const trilho = Color(0xFFEAE9E4);
  static const borda = Color(0xFFE4E2DA);
  static const texto = Color(0xFF16211F);
  static const textoSecundario = Color(0xFF6E7B78);
  static const verde = Color(0xFF6FA047);
  static const verdeFundo = Color(0xFFE8F2DC);
  static const ambar = Color(0xFFEAA40E);
  static const ambarFundo = Color(0xFFFCF1D8);
  static const vermelho = Color(0xFFBE4A3F);
  static const vermelhoFundo = Color(0xFFF9E4E1);
  static const azul = Color(0xFF3F6FB0);
  static const azulFundo = Color(0xFFE3EBF7);
  static const placa = Color(0xFF1B1B1B);
  static const placaBorda = Color(0xFF333333);
}

abstract final class Raios {
  static const pequeno = 10.0;
  static const medio = 14.0;
  static const grande = 20.0;
  static const total = 999.0;
}

abstract final class Espacos {
  static const x1 = 4.0;
  static const x2 = 8.0;
  static const x3 = 12.0;
  static const x4 = 16.0;
  static const x5 = 20.0;
  static const x6 = 24.0;
}

ThemeData construirTema() {
  final esquema = ColorScheme.fromSeed(
    seedColor: Cores.dourado,
    brightness: Brightness.light,
  ).copyWith(
    primary: Cores.escuro,
    onPrimary: Colors.white,
    secondary: Cores.dourado,
    onSecondary: Colors.white,
    surface: Cores.superficie,
    onSurface: Cores.texto,
    error: Cores.vermelho,
  );

  final base = ThemeData(colorScheme: esquema, useMaterial3: true);
  const familia = 'Poppins';

  return base.copyWith(
    scaffoldBackgroundColor: Cores.fundo,
    splashFactory: InkSparkle.splashFactory,
    textTheme: base.textTheme.apply(
      fontFamily: familia,
      bodyColor: Cores.texto,
      displayColor: Cores.texto,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: familia),
    appBarTheme: const AppBarTheme(
      backgroundColor: Cores.escuro,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: familia,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.1,
      ),
      iconTheme: IconThemeData(color: Colors.white, size: 22),
    ),
    cardTheme: CardThemeData(
      color: Cores.superficie,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Raios.medio),
        side: const BorderSide(color: Cores.borda),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Cores.borda, thickness: 1, space: 1),
    chipTheme: base.chipTheme.copyWith(
      labelStyle: const TextStyle(
        fontFamily: familia,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.total)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Cores.superficieSuave,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: const TextStyle(color: Cores.textoSecundario, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Raios.pequeno),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Raios.pequeno),
        borderSide: const BorderSide(color: Cores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(Raios.pequeno),
        borderSide: const BorderSide(color: Cores.dourado, width: 1.5),
      ),
      labelStyle: const TextStyle(color: Cores.textoSecundario, fontSize: 14),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Cores.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.grande)),
      titleTextStyle: const TextStyle(
        fontFamily: familia,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Cores.texto,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: familia,
        fontSize: 14,
        color: Cores.textoSecundario,
        height: 1.45,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Cores.escuro,
      contentTextStyle: const TextStyle(fontFamily: familia, color: Colors.white, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.pequeno)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Cores.dourado,
        foregroundColor: Cores.escuro,
        textStyle: const TextStyle(fontFamily: familia, fontSize: 15, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.pequeno)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Cores.texto,
        side: const BorderSide(color: Cores.borda),
        textStyle: const TextStyle(fontFamily: familia, fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Raios.pequeno)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Cores.escuro,
      indicatorColor: Cores.dourado.withValues(alpha: 0.22),
      elevation: 0,
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (estados) => IconThemeData(
          size: 22,
          color: estados.contains(WidgetState.selected) ? Cores.douradoClaro : Colors.white70,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (estados) => TextStyle(
          fontFamily: familia,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: estados.contains(WidgetState.selected) ? Cores.douradoClaro : Colors.white70,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: Cores.escuro,
      unselectedLabelColor: Cores.textoSecundario,
      indicatorColor: Cores.dourado,
      dividerColor: Cores.borda,
    ),
  );
}
