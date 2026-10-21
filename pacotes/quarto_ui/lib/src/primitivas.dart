import 'package:flutter/material.dart';

import 'paleta.dart';

/// Cartão de superfície usado nas listas dos dois aplicativos.
///
/// Aceita cor e borda próprias: o app do usuário usa creme, o painel usa branco.
class PainelUi extends StatelessWidget {
  const PainelUi({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.cor,
    this.corBorda,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? cor;
  final Color? corBorda;

  @override
  Widget build(BuildContext context) {
    final paleta = EscopoUi.de(context);
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: cor ?? paleta.superficie,
        borderRadius: BorderRadius.circular(paleta.raioMedio),
        border: Border.all(color: corBorda ?? paleta.borda),
      ),
      child: child,
    );
  }
}

/// Rótulo compacto com cor e ícone, usado para status e metadados.
class EtiquetaUi extends StatelessWidget {
  const EtiquetaUi(
    this.texto, {
    super.key,
    required this.cor,
    required this.fundo,
    this.icone,
    this.compacta = false,
  });

  final String texto;
  final Color cor;
  final Color fundo;
  final IconData? icone;
  final bool compacta;

  /// Etiqueta de situação padrão a partir do rótulo do domínio.
  ///
  /// Recebe a paleta porque as cores vêm do app, não do pacote.
  factory EtiquetaUi.status(String status, PaletaUi paleta) => switch (status) {
    'Em dia' => EtiquetaUi(
      'Em dia',
      cor: paleta.verde,
      fundo: paleta.verdeFundo,
      icone: Icons.check_circle,
    ),
    'Manutenção' => EtiquetaUi(
      'Manutenção',
      cor: paleta.ambar,
      fundo: paleta.ambarFundo,
      icone: Icons.build_circle,
    ),
    _ => EtiquetaUi(
      'Atenção',
      cor: paleta.vermelho,
      fundo: paleta.vermelhoFundo,
      icone: Icons.error,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final paleta = EscopoUi.de(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? 8 : 10,
        vertical: compacta ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(paleta.raioMedio * 10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icone != null) ...[
            Icon(icone, size: compacta ? 11 : 13, color: cor),
            const SizedBox(width: 4),
          ],
          Text(
            texto,
            style: TextStyle(
              fontSize: compacta ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: cor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado vazio padronizado, com ação opcional.
class VazioUi extends StatelessWidget {
  const VazioUi({
    super.key,
    required this.icone,
    required this.titulo,
    this.descricao,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String? descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    final paleta = EscopoUi.de(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      child: Column(
        children: [
          Icon(icone, size: 32, color: paleta.textoSecundario.withValues(alpha: 0.6)),
          const SizedBox(height: 12),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: paleta.texto),
          ),
          if (descricao != null) ...[
            const SizedBox(height: 4),
            Text(
              descricao!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: paleta.textoSecundario,
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

/// Rótulo em caixa alta com o valor abaixo — ficha de dados.
class CampoUi extends StatelessWidget {
  const CampoUi({
    super.key,
    required this.rotulo,
    required this.valor,
    this.icone,
    this.corValor,
  });

  final String rotulo;
  final String valor;
  final IconData? icone;
  final Color? corValor;

  @override
  Widget build(BuildContext context) {
    final paleta = EscopoUi.de(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icone != null) ...[
              Icon(icone, size: 12, color: paleta.textoSecundario),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                rotulo.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: paleta.textoSecundario,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            height: 1.25,
            color: corValor ?? paleta.texto,
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho de seção com ação e ícone opcionais.
class SecaoUi extends StatelessWidget {
  const SecaoUi({
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
    final paleta = EscopoUi.de(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icone != null) ...[
          Icon(icone, size: 18, color: paleta.destaque),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: paleta.texto,
                ),
              ),
              if (subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    subtitulo!,
                    style: TextStyle(fontSize: 12.5, color: paleta.textoSecundario),
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
