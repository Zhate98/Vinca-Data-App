import 'package:flutter/material.dart';

/// Paleta de Vinca Data, extraída del CSS de la plataforma web (`:root`).
/// Tema oscuro = identidad original de la web.
/// Tema claro = adaptación coherente para Material 3.
class AppColors {
  AppColors._();

  // ── Marca (idéntico a la web) ──────────────────────────────────────────
  static const Color teal = Color(0xFF00D4AA); // primario
  static const Color tealDark = Color(0xFF00B894); // hover
  static const Color blue = Color(0xFF4B9EF5);
  static const Color purple = Color(0xFF8B5CF6);
  static const Color pink = Color(0xFFF472B6);
  static const Color green = Color(0xFF10B981);
  static const Color red = Color(0xFFEF4444);
  static const Color yellow = Color(0xFFF59E0B);

  // ── Superficies tema OSCURO (web original) ─────────────────────────────
  static const Color darkBg = Color(0xFF0F1729);
  static const Color darkSidebar = Color(0xFF0D1526);
  static const Color darkCard = Color(0xFF1A2744);
  static const Color darkCard2 = Color(0xFF1E2F4F);
  static const Color darkBorder = Color(0xFF1E3A5F);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkMuted = Color(0xFF64748B);

  // ── Superficies tema CLARO (adaptación) ────────────────────────────────
  static const Color lightBg = Color(0xFFF4F7FB);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCard2 = Color(0xFFEDF2F9);
  static const Color lightBorder = Color(0xFFD8E2EE);
  static const Color lightText = Color(0xFF0F1729);
  static const Color lightMuted = Color(0xFF64748B);

  /// Colores rotativos para gráficos (mismas tintas que la web).
  static const List<Color> chartPalette = [
    teal, blue, purple, pink, yellow, green, red,
  ];
}
