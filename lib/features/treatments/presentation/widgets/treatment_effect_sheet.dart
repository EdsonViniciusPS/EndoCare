import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/core/widgets/endocare_button.dart';
import 'package:endocare/core/widgets/endocare_chip.dart';
import 'package:endocare/core/widgets/endocare_slider.dart';
import 'package:endocare/features/symptoms/domain/models/symptom_log.dart';
import 'package:endocare/features/treatments/domain/models/treatment.dart';
import 'package:endocare/features/treatments/domain/models/treatment_effect.dart';

/// Folha modal para registrar efeito percebido (alívio ou reação adversa) de um tratamento.
class TreatmentEffectSheet extends StatefulWidget {
  const TreatmentEffectSheet({
    super.key,
    required this.treatment,
    required this.referenceDate,
  });

  final Treatment treatment;
  final DateTime referenceDate;

  static Future<TreatmentEffect?> show({
    required BuildContext context,
    required Treatment treatment,
    required DateTime referenceDate,
  }) {
    return showModalBottomSheet<TreatmentEffect>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) => TreatmentEffectSheet(
        treatment: treatment,
        referenceDate: referenceDate,
      ),
    );
  }

  @override
  State<TreatmentEffectSheet> createState() => _TreatmentEffectSheetState();
}

class _TreatmentEffectSheetState extends State<TreatmentEffectSheet> {
  final TextEditingController _effectController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  TreatmentEffectKind _kind = TreatmentEffectKind.relief;
  int _intensity = 6;
  String? _validationError;

  @override
  void dispose() {
    _effectController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final text = _effectController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _validationError = 'Selecione ou descreva o efeito percebido.';
      });
      return;
    }

    final effect = TreatmentEffect(
      id: '',
      treatmentId: widget.treatment.id,
      treatmentName: widget.treatment.medicamento,
      data: SymptomLog.normalizeDate(widget.referenceDate),
      efeito: text,
      tipo: _kind,
      intensidade: _intensity,
      notas: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );
    Navigator.of(context).pop(effect);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final suggestions = _kind == TreatmentEffectKind.sideEffect
        ? TreatmentEffectCatalog.sideEffectExamples
        : TreatmentEffectCatalog.reliefExamples;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxl + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.outlineStrong,
                    borderRadius: AppSpacing.borderRadiusPill,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Efeito percebido • ${widget.treatment.medicamento}',
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Tipo de registro', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: TreatmentEffectKind.values.map((kind) {
                  final color = switch (kind) {
                    TreatmentEffectKind.relief => AppColors.success,
                    TreatmentEffectKind.sideEffect => AppColors.warning,
                    TreatmentEffectKind.observation => AppColors.info,
                  };
                  return EndoCareChip(
                    label: kind.label,
                    selected: _kind == kind,
                    activeColor: color,
                    onSelected: (_) => setState(() => _kind = kind),
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              Text('Sugestões rápidas', style: textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: suggestions.map((example) {
                  final isSelected = _effectController.text.trim() == example;
                  return EndoCareChip(
                    label: example,
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _effectController.text = example;
                        _validationError = null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: _effectController,
                onChanged: (_) {
                  if (_validationError != null) {
                    setState(() => _validationError = null);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Descrição do efeito',
                  hintText: 'Ex.: Redução da cólica, escape leve...',
                  errorText: _validationError,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              EndoCareSlider(
                label: 'Intensidade percebida (0–10)',
                value: _intensity.toDouble(),
                usePainScaleColors: _kind == TreatmentEffectKind.sideEffect,
                minCaption: '0 • Muito leve',
                maxCaption: '10 • Muito marcante',
                onChanged: (val) => setState(() => _intensity = val.round()),
              ),
              const SizedBox(height: AppSpacing.md),

              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notas adicionais (opcional)',
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              EndoCareButton(
                label: 'Salvar efeito percebido',
                icon: Icons.check_rounded,
                isExpanded: true,
                onPressed: _save,
              ),
            ],
          ),
        ),
      );
  }
}

