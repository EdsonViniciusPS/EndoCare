import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';

/// Categorias temáticas das calculadoras clínicas (seção 07 do EndoCare.md).
enum CalculatorCategory {
  symptoms(
    'sintomas',
    'Avaliação de sintomas',
    Icons.healing_outlined,
    AppColors.primary,
  ),
  qualityOfLife(
    'qualidade_vida',
    'Qualidade de vida e bem-estar',
    Icons.favorite_outline_rounded,
    AppColors.secondary,
  ),
  reproductiveHealth(
    'saude_reprodutiva',
    'Saúde reprodutiva e fertilidade',
    Icons.water_drop_outlined,
    AppColors.cycleMenstruation,
  ),
  professionalStaging(
    'estadiamento_medico',
    'Apoio diagnóstico e estadiamento',
    Icons.medical_services_outlined,
    AppColors.tertiary,
  );

  const CalculatorCategory(this.code, this.label, this.icon, this.color);

  final String code;
  final String label;
  final IconData icon;
  final Color color;
}

