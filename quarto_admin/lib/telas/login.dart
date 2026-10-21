import 'package:flutter/material.dart';
import 'package:quarto_core/quarto_core.dart';
import 'package:quarto_ui/quarto_ui.dart';

import '../core/tema.dart';

/// Acesso ao painel. Delega ao formulário compartilhado com o aplicativo; o
/// painel só muda a identidade visual e o texto.
class TelaLogin extends StatelessWidget {
  const TelaLogin({
    super.key,
    required this.sessaoApi,
    required this.aoEntrar,
    this.motivo,
  });

  final SessaoApi sessaoApi;
  final ValueChanged<Sessao> aoEntrar;
  final String? motivo;

  @override
  Widget build(BuildContext context) {
    return FormularioAcesso(
      sessaoApi: sessaoApi,
      paleta: paletaDoPainel,
      fundo: AdminCores.fundo,
      aoEntrar: aoEntrar,
      motivo: motivo,
      titulo: 'Painel administrativo',
      subtitulo: 'Acesso restrito ao haras.',
    );
  }
}
