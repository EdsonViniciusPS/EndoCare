import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Relógio injetável para testes determinísticos de rotação diária, sintomas e ciclo.
final homeClockProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

