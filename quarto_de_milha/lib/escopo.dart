import 'package:flutter/widgets.dart';

import 'package:quarto_core/quarto_core.dart';

export 'package:quarto_core/quarto_core.dart' show Repositorio;

/// Disponibiliza o [Repositorio] para toda a árvore de widgets, sem pacotes
/// externos de gerenciamento de estado.
class RepositorioEscopo extends InheritedNotifier<Repositorio> {
  const RepositorioEscopo({super.key, required Repositorio repositorio, required super.child})
    : super(notifier: repositorio);

  static Repositorio de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<RepositorioEscopo>();
    assert(escopo != null, 'RepositorioEscopo ausente na árvore de widgets.');
    return escopo!.notifier!;
  }
}
