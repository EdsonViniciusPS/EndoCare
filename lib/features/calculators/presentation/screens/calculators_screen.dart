import 'package:flutter/material.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/features/calculators/presentation/screens/calculators_list_screen.dart';

/// Tela completa com a lista de calculadoras clínicas organizadas por categoria.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadoras clínicas'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: const CalculatorsListView(),
            ),
          ),
        ),
      ),
    );
  }
}

