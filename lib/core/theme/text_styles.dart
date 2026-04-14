import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

abstract final class AppTextStyles {
  static TextStyle get _base => GoogleFonts.inter();

  // Títulos de página
  static TextStyle get pageTitle => _base.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ctText,
      );

  static TextStyle get pageSubtitle => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ctText2,
      );

  // Títulos de sección / card
  static TextStyle get cardTitle => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText,
      );

  // Topbar
  static TextStyle get topbarTitle => _base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ctText,
      );

  static TextStyle get topbarSubtitle => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: AppColors.ctText2,
      );

  // Sidebar nav item
  static TextStyle get navItem => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText2,
      );

  static TextStyle get navItemActive => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ctTealDark,
      );

  static TextStyle get navSectionLabel => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText3,
        letterSpacing: 0.8,
      );

  // Labels de formulario
  static TextStyle get formLabel => _base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText,
      );

  // Cuerpo / datos
  static TextStyle get body => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.ctText,
      );

  static TextStyle get bodySmall => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.ctText2,
      );

  // Badge / tag
  static TextStyle get badge => _base.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      );

  // Tenant chip label
  static TextStyle get tenantLabel => _base.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText3,
      );

  static TextStyle get tenantName => _base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText,
      );

  // Botón primario
  static TextStyle get btnPrimary => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.ctNavy,
      );

  static TextStyle get btnSecondary => _base.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText,
      );
}
