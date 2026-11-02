import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:endocare/core/firebase/firebase_providers.dart';
import 'package:endocare/features/auth/presentation/providers/auth_providers.dart';
import 'package:endocare/features/calculators/data/repositories/firestore_calculator_repository.dart';
import 'package:endocare/features/calculators/domain/models/calculator_category.dart';
import 'package:endocare/features/calculators/domain/models/calculator_result.dart';
import 'package:endocare/features/calculators/domain/repositories/calculator_repository.dart';

/// Provider do repositório de calculadoras clínicas (sobregravável em testes).
final calculatorRepositoryProvider = Provider<CalculatorRepository>((ref) {
  return FirestoreCalculatorRepository(ref.watch(firestoreProvider));
});

/// Stream em tempo real de todos os resultados de calculadoras da usuária autenticada.
final calculatorResultsStreamProvider =
    StreamProvider<List<CalculatorResult>>((ref) {
  final authUser = ref.watch(authStateChangesProvider).asData?.value;
  if (authUser == null) {
    return Stream<List<CalculatorResult>>.value(const []);
  }
  return ref
      .watch(calculatorRepositoryProvider)
      .watchResults(uid: authUser.uid);
});

/// Mapa que armazena a avaliação mais recente para cada calculadora.
final calculatorLatestResultsMapProvider =
    Provider<Map<String, CalculatorResult>>((ref) {
  final all = ref.watch(calculatorResultsStreamProvider).asData?.value ??
      const <CalculatorResult>[];
  final map = <String, CalculatorResult>{};
  for (final res in all) {
    // Como a stream já vem ordenada por data descrescente, a primeira inserção é a mais recente.
    map.putIfAbsent(res.calculadora, () => res);
  }
  return map;
});

/// Notifier para filtro de categorias na tela de listagem de calculadoras.
class CalculatorCategoryFilterNotifier extends Notifier<CalculatorCategory?> {
  @override
  CalculatorCategory? build() => null;

  void select(CalculatorCategory? category) {
    state = category;
  }
}

final calculatorCategoryFilterProvider =
    NotifierProvider<CalculatorCategoryFilterNotifier, CalculatorCategory?>(
  CalculatorCategoryFilterNotifier.new,
);

