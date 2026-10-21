import 'package:flutter/material.dart';

import 'package:quarto_ui/quarto_ui.dart';

import '../core/tema.dart';

/// Cabeçalho de uma seção do painel, com ação opcional à direita.
class CabecalhoSecao extends StatelessWidget {
  const CabecalhoSecao({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.acao,
    this.icone,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? acao;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 18, color: AdminCores.dourado),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AdminCores.texto,
                ),
              ),
              if (subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitulo!,
                    style: const TextStyle(fontSize: 12.5, color: AdminCores.textoSecundario),
                  ),
                ),
            ],
          ),
        ),
        ?acao,
      ],
    );
  }
}

/// Cartão branco padrão do painel (estrutura compartilhada em [PainelUi]).
class Painel extends StatelessWidget {
  const Painel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => PainelUi(padding: padding, child: child);
}

/// Rótulo de estado, com cor por significado (estrutura em [EtiquetaUi]).
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, required this.cor, required this.fundo, this.icone});

  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;

  factory Etiqueta.status(String status) {
    final base = EtiquetaUi.status(status, paletaDoPainel);
    return Etiqueta(
      base.texto,
      cor: base.cor,
      fundo: base.fundo,
      icone: base.icone,
    );
  }

  @override
  Widget build(BuildContext context) =>
      EtiquetaUi(texto, cor: cor, fundo: fundo, icone: icone);
}

/// Número grande com rótulo — usados no topo do painel.
class Indicador extends StatelessWidget {
  const Indicador({
    super.key,
    required this.valor,
    required this.rotulo,
    this.icone,
    this.cor = AdminCores.texto,
    this.destaque = false,
  });

  final String valor;
  final String rotulo;
  final IconData? icone;
  final Color cor;
  final bool destaque;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: destaque ? AdminCores.barra : AdminCores.superficie,
        borderRadius: BorderRadius.circular(AdminRaios.medio),
        border: Border.all(color: destaque ? AdminCores.barra : AdminCores.borda),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icone != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Icon(
                  icone,
                  size: 17,
                  color: destaque ? AdminCores.douradoClaro : AdminCores.dourado,
                ),
              ),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: destaque ? Colors.white : cor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              rotulo,
              style: TextStyle(
                fontSize: 11.5,
                color: destaque ? Colors.white70 : AdminCores.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio padronizado (estrutura em [VazioUi]).
class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.titulo, this.descricao, this.acao});

  final IconData icone;
  final String titulo;
  final String? descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) => VazioUi(
    icone: icone,
    titulo: titulo,
    descricao: descricao,
    acao: acao,
  );
}

/// Rótulo curto em caixa alta com o valor abaixo (estrutura em [CampoUi]).
class Campo extends StatelessWidget {
  const Campo({super.key, required this.rotulo, required this.valor, this.icone});

  final String rotulo;
  final String valor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) =>
      CampoUi(rotulo: rotulo, valor: valor, icone: icone);
}

/// Faixa de aviso exibida quando a última gravação falhou.
class FaixaErro extends StatelessWidget {
  const FaixaErro({super.key, required this.mensagem, required this.aoFechar});

  final String mensagem;
  final VoidCallback aoFechar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AdminCores.vermelhoFundo,
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        border: Border.all(color: AdminCores.vermelho.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AdminCores.vermelho),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(fontSize: 13, color: AdminCores.vermelho, height: 1.4),
            ),
          ),
          IconButton(
            tooltip: 'Fechar aviso',
            onPressed: aoFechar,
            icon: const Icon(Icons.close, size: 16, color: AdminCores.vermelho),
          ),
        ],
      ),
    );
  }
}
