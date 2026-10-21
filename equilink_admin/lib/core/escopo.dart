import 'package:flutter/widgets.dart';
import 'package:equilink_core/equilink_core.dart';

/// Disponibiliza o [Repositorio] para a árvore do painel.
class AdminEscopo extends InheritedNotifier<Repositorio> {
  const AdminEscopo({super.key, required Repositorio repositorio, required super.child})
    : super(notifier: repositorio);

  static Repositorio de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<AdminEscopo>();
    assert(escopo != null, 'AdminEscopo ausente na árvore de widgets.');
    return escopo!.notifier!;
  }
}
