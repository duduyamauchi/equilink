import 'package:flutter/material.dart';

/// Paleta que cada aplicativo injeta nas primitivas compartilhadas.
///
/// O app do usuário e o painel administrativo têm identidades distintas — o
/// usuário vê creme e dourado, o operador vê branco e verde-petróleo. O que se
/// compartilha é a **estrutura** dos widgets, não a aparência: cada app passa a
/// sua paleta e mantém a sua linguagem visual.
class PaletaUi {
  const PaletaUi({
    required this.superficie,
    required this.superficieSuave,
    required this.borda,
    required this.texto,
    required this.textoSecundario,
    required this.destaque,
    required this.verde,
    required this.verdeFundo,
    required this.ambar,
    required this.ambarFundo,
    required this.vermelho,
    required this.vermelhoFundo,
    required this.raioMedio,
    required this.raioPequeno,
  });

  final Color superficie;
  final Color superficieSuave;
  final Color borda;
  final Color texto;
  final Color textoSecundario;

  /// Cor de ênfase da marca (dourado no app, dourado no painel).
  final Color destaque;

  final Color verde;
  final Color verdeFundo;
  final Color ambar;
  final Color ambarFundo;
  final Color vermelho;
  final Color vermelhoFundo;

  final double raioMedio;
  final double raioPequeno;
}

/// Disponibiliza a [PaletaUi] para as primitivas compartilhadas.
class EscopoUi extends InheritedWidget {
  const EscopoUi({super.key, required this.paleta, required super.child});

  final PaletaUi paleta;

  static PaletaUi de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<EscopoUi>();
    assert(escopo != null, 'EscopoUi ausente: envolva a árvore com EscopoUi.');
    return escopo!.paleta;
  }

  @override
  bool updateShouldNotify(EscopoUi antigo) => antigo.paleta != paleta;
}
