import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/theme/app_colors.dart';
import 'package:endocare/core/theme/app_spacing.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calculators/domain/calculators_registry.dart';
import 'package:endocare/features/calculators/domain/models/calculator_definition.dart';
import 'package:endocare/features/calculators/domain/models/calculator_result.dart';
import 'package:endocare/features/calculators/presentation/providers/calculator_providers.dart';
import 'package:endocare/features/calculators/presentation/screens/calculator_result_screen.dart';
import 'package:endocare/features/calculators/presentation/widgets/question_step_view.dart';
import 'package:endocare/features/home/presentation/providers/home_providers.dart';

/// Tela do questionário clínico que apresenta exatamente uma pergunta por tela.
class CalculatorQuestionnaireScreen extends ConsumerStatefulWidget {
  const CalculatorQuestionnaireScreen({
    super.key,
    required this.calculatorId,
  });

  final String calculatorId;

  @override
  ConsumerState<CalculatorQuestionnaireScreen> createState() =>
      _CalculatorQuestionnaireScreenState();
}

class _CalculatorQuestionnaireScreenState
    extends ConsumerState<CalculatorQuestionnaireScreen> {
  late CalculatorDefinition _definition;
  int _currentIndex = 0;
  final Map<String, dynamic> _answers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final found = CalculatorsRegistry.findById(widget.calculatorId);
    _definition = found ?? CalculatorsRegistry.eva;
  }

  void _onAnswerChanged(dynamic answer) {
    final currentQ = _definition.questions[_currentIndex];
    setState(() {
      _answers[currentQ.id] = answer;
    });
  }

  void _onNext() {
    if (_currentIndex < _definition.questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishAssessment();
    }
  }

  void _onPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _finishAssessment() async {
    final authUser = ref.read(authStateChangesProvider).asData?.value;
    final now = ref.read(homeClockProvider)();

    final interpretation = _definition.compute(_answers);

    final result = CalculatorResult(
      id: '${_definition.id}_${now.millisecondsSinceEpoch}',
      calculadora: _definition.id,
      titulo: _definition.title,
      data: now,
      pontuacao: interpretation.score,
      interpretacao: interpretation.summary,
      respostas: Map<String, dynamic>.from(_answers),
      grau: interpretation.severityLabel,
      isCrisisAlert: interpretation.isCrisisAlert,
    );

    if (authUser != null) {
      setState(() => _isSaving = true);
      try {
        await ref.read(calculatorRepositoryProvider).saveResult(
              uid: authUser.uid,
              result: result,
            );
      } catch (_) {
        // Continua exibindo o resultado mesmo se falhar a persistência offline
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (ctx) => CalculatorResultScreen(
          definition: _definition,
          result: result,
          interpretation: interpretation,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_answers.isEmpty) return true;
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da avaliação?'),
        content: const Text(
          'Suas respostas parciais não serão salvas se você sair agora.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar avaliação'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final currentQ = _definition.questions[_currentIndex];
    final currentAnswer = _answers[currentQ.id];

    return PopScope(
      canPop: _answers.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_definition.shortName),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 580),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _isSaving
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: AppSpacing.md),
                            Text('Calculando resultado...'),
                          ],
                        ),
                      )
                    : QuestionStepView(
                        question: currentQ,
                        currentStepIndex: _currentIndex,
                        totalSteps: _definition.totalQuestions,
                        currentAnswer: currentAnswer,
                        onAnswerChanged: _onAnswerChanged,
                        onNext: _onNext,
                        onPrevious: _currentIndex > 0 ? _onPrevious : null,
                        isLastStep:
                            _currentIndex == _definition.totalQuestions - 1,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
