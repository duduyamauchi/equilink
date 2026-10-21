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

/// Sessão e ação de sair, disponíveis para a moldura do painel.
///
/// O selo de sessão e o botão de sugestões dividem o canto inferior direito;
/// para não se sobreporem, os dois precisam ser desenhados pelo mesmo dono.
class SessaoAdminEscopo extends InheritedWidget {
  const SessaoAdminEscopo({
    super.key,
    required this.sessao,
    required this.aoSair,
    required super.child,
  });

  final Sessao? sessao;
  final Future<void> Function()? aoSair;

  static SessaoAdminEscopo? talvezDe(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SessaoAdminEscopo>();

  @override
  bool updateShouldNotify(SessaoAdminEscopo oldWidget) =>
      sessao?.usuario != oldWidget.sessao?.usuario ||
      sessao?.papel != oldWidget.sessao?.papel ||
      aoSair != oldWidget.aoSair;
}
