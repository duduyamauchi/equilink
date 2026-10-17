import 'package:flutter/material.dart';

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

/// Cartão branco padrão do painel.
class Painel extends StatelessWidget {
  const Painel({super.key, required this.child, this.padding = const EdgeInsets.all(18)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AdminCores.superficie,
        borderRadius: BorderRadius.circular(AdminRaios.medio),
        border: Border.all(color: AdminCores.borda),
      ),
      child: child,
    );
  }
}

/// Rótulo de estado, com cor por significado.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, required this.cor, required this.fundo, this.icone});

  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;

  factory Etiqueta.status(String status) => switch (status) {
    'Em dia' => const Etiqueta(
      'Em dia',
      cor: AdminCores.verde,
      fundo: AdminCores.verdeFundo,
      icone: Icons.check_circle,
    ),
    'Manutenção' => const Etiqueta(
      'Manutenção',
      cor: AdminCores.ambar,
      fundo: AdminCores.ambarFundo,
      icone: Icons.build_circle,
    ),
    _ => const Etiqueta(
      'Atenção',
      cor: AdminCores.vermelho,
      fundo: AdminCores.vermelhoFundo,
      icone: Icons.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(AdminRaios.total)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: 12, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: cor),
          ),
        ],
      ),
    );
  }
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

/// Estado vazio padronizado.
class Vazio extends StatelessWidget {
  const Vazio({super.key, required this.icone, required this.titulo, this.descricao, this.acao});

  final IconData icone;
  final String titulo;
  final String? descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          Icon(icone, size: 32, color: AdminCores.textoSecundario.withValues(alpha: 0.55)),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AdminCores.texto),
          ),
          if (descricao != null) ...[
            const SizedBox(height: 4),
            Text(
              descricao!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AdminCores.textoSecundario,
                height: 1.45,
              ),
            ),
          ],
          if (acao != null) ...[const SizedBox(height: 16), acao!],
        ],
      ),
    );
  }
}

/// Rótulo curto em caixa alta com o valor abaixo.
class Campo extends StatelessWidget {
  const Campo({super.key, required this.rotulo, required this.valor, this.icone});

  final String rotulo;
  final String valor;
  final IconData? icone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icone != null) ...[
              Icon(icone, size: 12, color: AdminCores.textoSecundario),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                rotulo.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AdminCores.textoSecundario,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, height: 1.25),
        ),
      ],
    );
  }
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
