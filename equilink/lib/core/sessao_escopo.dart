import 'package:flutter/widgets.dart';

import 'package:equilink_core/equilink_core.dart';

/// Disponibiliza a sessão do usuário e as ações de entrada/saída para a árvore.
///
/// O aplicativo é público: o visitante vê a vitrine sem entrar. O login existe
/// para o proprietário ver o manejo das baias, que a API só entrega a quem tem
/// acesso ao haras.
class SessaoEscopo extends InheritedWidget {
  const SessaoEscopo({
    super.key,
    required this.sessao,
    required this.sessaoApi,
    required this.entrar,
    required this.sair,
    required super.child,
  });

  /// `null` = visitante anônimo.
  final Sessao? sessao;

  /// `null` quando não há backend (demonstração em memória).
  final SessaoApi? sessaoApi;

  final ValueChanged<Sessao> entrar;
  final Future<void> Function() sair;

  bool get autenticado => sessao != null;
  bool get podeVerManejo => sessao?.podeEscrever ?? false;

  static SessaoEscopo de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<SessaoEscopo>();
    assert(escopo != null, 'SessaoEscopo ausente na árvore de widgets.');
    return escopo!;
  }

  @override
  bool updateShouldNotify(SessaoEscopo oldWidget) =>
      sessao?.usuario != oldWidget.sessao?.usuario ||
      sessao?.papel != oldWidget.sessao?.papel ||
      sessaoApi != oldWidget.sessaoApi;
}
