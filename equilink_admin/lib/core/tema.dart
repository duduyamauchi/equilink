import 'package:flutter/material.dart';
import 'package:equilink_ui/equilink_ui.dart';

/// Paleta do painel administrativo: mesma família visual do aplicativo do
/// usuário, com fundo mais neutro para leitura intensa de dados.
abstract final class AdminCores {
  static const barra = Color(0xFF0A1A19);
  static const barraSuave = Color(0xFF142A28);
  static const dourado = Color(0xFFA6834B);
  static const douradoClaro = Color(0xFFD8BE8F);
  static const fundo = Color(0xFFF5F5F3);
  static const superficie = Color(0xFFFFFFFF);
  static const superficieSuave = Color(0xFFF8F8F6);
  static const borda = Color(0xFFE3E2DC);
  static const texto = Color(0xFF16211F);
  static const textoSecundario = Color(0xFF6E7B78);
  static const verde = Color(0xFF3F8F4F);
  static const verdeFundo = Color(0xFFE6F2E8);
  static const ambar = Color(0xFFC98A0E);
  static const ambarFundo = Color(0xFFFBF0D8);
  static const vermelho = Color(0xFFBE4A3F);
  static const vermelhoFundo = Color(0xFFF9E4E1);
  static const azul = Color(0xFF3F6FB0);
  static const azulFundo = Color(0xFFE3EBF7);
}

abstract final class AdminRaios {
  static const pequeno = 8.0;
  static const medio = 12.0;
  static const total = 999.0;
}

ThemeData construirTemaAdmin() {
  const familia = 'Poppins';
  final esquema = ColorScheme.fromSeed(
    seedColor: AdminCores.dourado,
    brightness: Brightness.light,
  ).copyWith(
    primary: const Color(0xFF0F2E2B),
    onPrimary: Colors.white,
    secondary: AdminCores.dourado,
    surface: AdminCores.superficie,
    onSurface: AdminCores.texto,
  );

  final base = ThemeData(colorScheme: esquema, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AdminCores.fundo,
    textTheme: base.textTheme.apply(fontFamily: familia),
    appBarTheme: const AppBarTheme(
      backgroundColor: AdminCores.barra,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: familia,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    dividerTheme: const DividerThemeData(color: AdminCores.borda, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AdminCores.superficieSuave,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: const TextStyle(fontSize: 13, color: AdminCores.textoSecundario),
      labelStyle: const TextStyle(fontSize: 13, color: AdminCores.textoSecundario),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        borderSide: const BorderSide(color: AdminCores.borda),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        borderSide: const BorderSide(color: AdminCores.borda),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        borderSide: const BorderSide(color: AdminCores.dourado, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF0F2E2B),
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontFamily: familia, fontSize: 13.5, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRaios.pequeno)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AdminCores.texto,
        side: const BorderSide(color: AdminCores.borda),
        textStyle: const TextStyle(fontFamily: familia, fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRaios.pequeno)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AdminCores.barra,
      contentTextStyle: const TextStyle(fontFamily: familia, fontSize: 13.5, color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRaios.pequeno)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AdminCores.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AdminRaios.medio)),
      titleTextStyle: const TextStyle(
        fontFamily: familia,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AdminCores.texto,
      ),
    ),
  );
}


/// Paleta do painel administrativo, no formato das primitivas compartilhadas.
const paletaDoPainel = PaletaUi(
  superficie: AdminCores.superficie,
  superficieSuave: AdminCores.superficieSuave,
  borda: AdminCores.borda,
  texto: AdminCores.texto,
  textoSecundario: AdminCores.textoSecundario,
  destaque: AdminCores.dourado,
  verde: AdminCores.verde,
  verdeFundo: AdminCores.verdeFundo,
  ambar: AdminCores.ambar,
  ambarFundo: AdminCores.ambarFundo,
  vermelho: AdminCores.vermelho,
  vermelhoFundo: AdminCores.vermelhoFundo,
  raioMedio: AdminRaios.medio,
  raioPequeno: AdminRaios.pequeno,
);
