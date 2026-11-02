import 'package:flutter/material.dart';

/// Paleta oficial do EndoCare inspirada nos logos (malva, rosa blush e pêssego)
/// e pensada para conforto visual de usuárias com dor ou fadiga.
abstract final class AppColors {
  // Identidade da marca (extraída de logo_horizontal.jpg e wordmark.jpg)
  static const Color primary = Color(0xFF8E5568); // Malva acolhedor (bom contraste AA)
  static const Color primaryLight = Color(0xFFB57F91); // Malva suave do logotipo
  static const Color primaryDark = Color(0xFF693A4A); // Malva profundo
  static const Color primaryContainer = Color(0xFFF6E7EC);
  static const Color onPrimaryContainer = Color(0xFF3E1D28);

  static const Color secondary = Color(0xFFE58C96); // Rosa blush "Care"
  static const Color secondaryLight = Color(0xFFF2B2B8);
  static const Color secondaryContainer = Color(0xFFFDECEF);
  static const Color onSecondaryContainer = Color(0xFF4A1E24);

  static const Color tertiary = Color(0xFFE89E7E); // Pêssego botânico
  static const Color tertiaryLight = Color(0xFFFAC6AA);
  static const Color tertiaryContainer = Color(0xFFFFEFE7);
  static const Color onTertiaryContainer = Color(0xFF4B2515);

  // Superfícies claras e suaves (bastante espaço em branco)
  static const Color background = Color(0xFFFCF8F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF7EFF2);
  static const Color surfaceMuted = Color(0xFFF2E7EB);
  static const Color outline = Color(0xFFE3D2D8);
  static const Color outlineStrong = Color(0xFFC9B0B9);

  // Tipografia
  static const Color textPrimary = Color(0xFF2F2026);
  static const Color textSecondary = Color(0xFF6B555E);
  static const Color textMuted = Color(0xFF98828B);

  // Semânticas e fases do ciclo
  static const Color success = Color(0xFF56A886); // Verde menta suave
  static const Color successContainer = Color(0xFFE6F5EE);
  static const Color warning = Color(0xFFE09F48); // Âmbar acolhedor
  static const Color warningContainer = Color(0xFFFEF4E4);
  static const Color error = Color(0xFFC44757); // Vermelho suave mas nítido
  static const Color errorContainer = Color(0xFFFCE9EC);
  static const Color info = Color(0xFF5A8EC8); // Azul Storyset rafiki
  static const Color infoContainer = Color(0xFFEAF2FB);

  static const Color cycleMenstruation = Color(0xFFC53F4F);
  static const Color cycleOvulation = Color(0xFF5A8EC8);
  static const Color cycleLuteal = Color(0xFFA876BA);

  // Escala progressiva de intensidade de dor (0 a 10)
  static const Color painNone = Color(0xFF66B896); // 0
  static const Color painMild = Color(0xFF8CC47F); // 1–3
  static const Color painModerate = Color(0xFFE5A952); // 4–6
  static const Color painStrong = Color(0xFFE27862); // 7–8
  static const Color painSevere = Color(0xFFC44757); // 9–10

  /// Retorna a cor correspondente à intensidade da dor (0–10).
  static Color forPainLevel(num value) {
    final clamped = value.clamp(0, 10).toDouble();
    if (clamped <= 0) return painNone;
    if (clamped <= 3) return painMild;
    if (clamped <= 6) return painModerate;
    if (clamped <= 8) return painStrong;
    return painSevere;
  }

  /// Rótulo descritivo curto em português para escala 0–10.
  static String painLabel(num value) {
    final level = value.round().clamp(0, 10);
    if (level == 0) return 'Sem dor';
    if (level <= 3) return 'Leve';
    if (level <= 6) return 'Moderada';
    if (level <= 8) return 'Intensa';
    return 'Muito intensa';
  }
}

