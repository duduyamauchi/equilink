import 'package:flutter/material.dart';

import '../core/formatos.dart';
import '../core/tema.dart';
import 'package:quarto_core/quarto_core.dart';
import '../escopo.dart';
import '../widgets/comuns.dart';

/// Tela "Genealogia": árvore de ascendentes, lista de ancestrais e resumo
/// dos avós e bisavós.
class TelaGenealogia extends StatefulWidget {
  const TelaGenealogia({super.key});

  @override
  State<TelaGenealogia> createState() => _TelaGenealogiaState();
}

class _TelaGenealogiaState extends State<TelaGenealogia> {
  int _aba = 0;

  /// Profundidade exibida na árvore: 1 = pais, 2 = avós, 3 = bisavós.
  int _geracoes = 3;

  @override
  Widget build(BuildContext context) {
    final repositorio = RepositorioEscopo.de(context);
    final cavalo = repositorio.cavaloObrigatorio;
    final ancestrais = cavalo.genealogia.emLargura().skip(1).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genealogia'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(Espacos.x4),
        children: [
          Painel(
            cor: Cores.superficieSuave,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SeloIniciais('GN', tamanho: 42),
                    const SizedBox(width: Espacos.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cavalo.nome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Cores.texto,
                            ),
                          ),
                          Text(
                            'Registro ${cavalo.registro} • ${cavalo.raca}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Cores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Etiqueta(
                      '${ancestrais.length} ancestrais',
                      cor: Cores.dourado,
                      fundo: Cores.dourado.withValues(alpha: 0.14),
                      compacta: true,
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.x4),
                AbasPilula(
                  abas: const ['Árvore', 'Lista', 'Ancestrais'],
                  selecionada: _aba,
                  aoSelecionar: (i) => setState(() => _aba = i),
                ),
              ],
            ),
          ),
          const SizedBox(height: Espacos.x4),
          switch (_aba) {
            0 => _PainelArvore(cavalo: cavalo, limite: _geracoes),
            1 => _PainelLista(cavalo: cavalo, ancestrais: ancestrais),
            _ => _PainelAncestrais(cavalo: cavalo),
          },
          const SizedBox(height: Espacos.x4),
          Painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TituloSecao('Profundidade da árvore'),
                const SizedBox(height: Espacos.x3),
                AbasPilula(
                  abas: const ['Pais', 'Avós', 'Bisavós'],
                  selecionada: _geracoes - 1,
                  aoSelecionar: (i) => setState(() => _geracoes = i + 1),
                ),
                const SizedBox(height: Espacos.x3),
                NotaRodape(
                  '${resumoGenealogia(cavalo)} Exibindo até os '
                  '${_rotuloGeracao(_geracoes)}.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rotuloGeracao(int g) => switch (g) {
    1 => 'pais',
    2 => 'avós',
    _ => 'bisavós',
  };
}

/// Árvore de ascendentes desenhada com linhas de ligação.
class _PainelArvore extends StatelessWidget {
  const _PainelArvore({required this.cavalo, required this.limite});

  final Cavalo cavalo;
  final int limite;

  @override
  Widget build(BuildContext context) {
    return Painel(
      padding: const EdgeInsets.fromLTRB(Espacos.x4, Espacos.x4, Espacos.x4, Espacos.x3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ÁRVORE DE ASCENDENTES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Cores.textoSecundario,
            ),
          ),
          const SizedBox(height: Espacos.x4),
          _NoArvore(
            ancestral: cavalo.genealogia,
            rotulo: 'Animal',
            profundidade: 0,
            destacado: true,
          ),
          _Ramo(
            ancestral: cavalo.pai,
            rotulo: 'Pai',
            profundidade: 1,
            ultimo: false,
            limite: limite,
          ),
          _Ramo(
            ancestral: cavalo.mae,
            rotulo: 'Mãe',
            profundidade: 1,
            ultimo: true,
            limite: limite,
          ),
        ],
      ),
    );
  }
}

/// Um nó da árvore, com seus ascendentes desenhados recursivamente.
class _Ramo extends StatelessWidget {
  const _Ramo({
    required this.ancestral,
    required this.rotulo,
    required this.profundidade,
    required this.ultimo,
    required this.limite,
  });

  final Ancestral ancestral;
  final String rotulo;
  final int profundidade;
  final bool ultimo;
  final int limite;

  @override
  Widget build(BuildContext context) {
    final ascendentes = <({Ancestral animal, String papel})>[
      if (ancestral.pai != null) (animal: ancestral.pai!, papel: _papel(true)),
      if (ancestral.mae != null) (animal: ancestral.mae!, papel: _papel(false)),
    ];
    final expandir = profundidade < limite && ascendentes.isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Conector(ultimo: ultimo),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: profundidade == 1 ? Espacos.x3 : Espacos.x2),
                  child: _NoArvore(
                    ancestral: ancestral,
                    rotulo: rotulo,
                    profundidade: profundidade,
                  ),
                ),
                if (expandir)
                  for (var i = 0; i < ascendentes.length; i++)
                    _Ramo(
                      ancestral: ascendentes[i].animal,
                      rotulo: ascendentes[i].papel,
                      profundidade: profundidade + 1,
                      ultimo: i == ascendentes.length - 1,
                      limite: limite,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _papel(bool macho) => switch (profundidade) {
    1 => macho ? 'Avô' : 'Avó',
    _ => macho ? 'Bisavô' : 'Bisavó',
  };
}

/// Linhas verticais e horizontais que ligam os nós da árvore.
class _Conector extends StatelessWidget {
  const _Conector({required this.ultimo});

  final bool ultimo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: CustomPaint(painter: _PinturaConector(cor: Cores.borda, ultimo: ultimo)),
    );
  }
}

class _PinturaConector extends CustomPainter {
  const _PinturaConector({required this.cor, required this.ultimo});

  final Color cor;
  final bool ultimo;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = cor
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final meio = size.height / 2;
    final fim = size.width - 4;

    // Traço vertical: desce até o próximo irmão ou apenas até o meio quando
    // este é o último ramo da lista.
    canvas.drawLine(Offset(1.5, 0), Offset(1.5, ultimo ? meio : size.height), pincel);
    // Traço horizontal que encontra a caixa do ancestral.
    canvas.drawLine(Offset(1.5, meio), Offset(fim, meio), pincel);
  }

  @override
  bool shouldRepaint(_PinturaConector antigo) => antigo.cor != cor || antigo.ultimo != ultimo;
}

/// Caixa de um ancestral na árvore.
class _NoArvore extends StatelessWidget {
  const _NoArvore({
    required this.ancestral,
    required this.rotulo,
    required this.profundidade,
    this.destacado = false,
  });

  final Ancestral ancestral;
  final String rotulo;
  final int profundidade;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final cor = switch (profundidade) {
      0 => Cores.dourado,
      1 => Cores.escuro,
      _ => Cores.verde,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: Espacos.x3, vertical: Espacos.x3),
      decoration: BoxDecoration(
        color: destacado ? Cores.escuro : Cores.superficieSuave,
        borderRadius: BorderRadius.circular(Raios.pequeno),
        border: Border.all(
          color: destacado ? Cores.escuro : cor.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: destacado ? Cores.dourado : cor,
              borderRadius: BorderRadius.circular(Raios.total),
            ),
          ),
          const SizedBox(width: Espacos.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    color: destacado ? Colors.white54 : Cores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  ancestral.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: destacado ? Colors.white : Cores.texto,
                  ),
                ),
                if (!destacado)
                  Text(
                    '${ancestral.registro}${ancestral.pelagem != null ? ' • ${ancestral.pelagem}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Cores.textoSecundario),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista hierárquica de todos os ancestrais.
class _PainelLista extends StatelessWidget {
  const _PainelLista({required this.cavalo, required this.ancestrais});

  final Cavalo cavalo;
  final List<Ancestral> ancestrais;

  @override
  Widget build(BuildContext context) {
    return Painel(
      padding: const EdgeInsets.fromLTRB(Espacos.x4, Espacos.x4, Espacos.x4, Espacos.x4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RELAÇÃO DE ASCENDENTES',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
              color: Cores.textoSecundario,
            ),
          ),
          const SizedBox(height: Espacos.x3),
          for (var i = 0; i < ancestrais.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacos.x2),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Espacos.x3, vertical: 10),
                decoration: BoxDecoration(
                  color: Cores.superficieSuave,
                  borderRadius: BorderRadius.circular(Raios.pequeno),
                ),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}'.padLeft(2, '0'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Cores.dourado,
                      ),
                    ),
                    const SizedBox(width: Espacos.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ancestrais[i].nome,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${ancestrais[i].registro}'
                            '${ancestrais[i].pelagem != null ? ' • ${ancestrais[i].pelagem}' : ''}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Cores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Etiqueta(
                      '${ancestrais[i].geracoes}ª ger.',
                      cor: Cores.textoSecundario,
                      fundo: Cores.trilho,
                      compacta: true,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cartões por geração (avós e bisavós) com contagem e nomes.
class _PainelAncestrais extends StatelessWidget {
  const _PainelAncestrais({required this.cavalo});

  final Cavalo cavalo;

  @override
  Widget build(BuildContext context) {
    final todos = cavalo.genealogia.emLargura().skip(1).toList();
    final porGeracao = <int, List<Ancestral>>{};
    for (final a in todos) {
      final g = _geracaoDe(cavalo.genealogia, a);
      porGeracao.putIfAbsent(g, () => []).add(a);
    }
    final geracoes = porGeracao.keys.toList()..sort();

    return Column(
      children: [
        for (final g in geracoes)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x3),
            child: Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TituloSecao(
                    _tituloGeracao(g),
                    subtitulo: '${porGeracao[g]!.length} animais registrados',
                  ),
                  const SizedBox(height: Espacos.x3),
                  for (final a in porGeracao[g]!)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Espacos.x3),
                      child: Row(
                        children: [
                          SeloIniciais(
                            a.nome
                                .split(' ')
                                .where((p) => p.length > 2)
                                .take(2)
                                .map((p) => p[0])
                                .join()
                                .toUpperCase(),
                            tamanho: 38,
                          ),
                          const SizedBox(width: Espacos.x3),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.nome,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${a.registro}'
                                  '${a.pelagem != null ? ' • ${a.pelagem}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Cores.textoSecundario,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (porGeracao[g]!.isNotEmpty)
                    NotaRodape(
                      'Contribuição genética: '
                      '${percentual(1 / porGeracao[g]!.length, casas: 1)} por animal.',
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _tituloGeracao(int g) => switch (g) {
    1 => 'Pais',
    2 => 'Avós',
    3 => 'Bisavós',
    _ => 'Tetra-avós',
  };

  /// Profundidade (geração) de um ancestral dentro da árvore informada.
  int _geracaoDe(Ancestral raiz, Ancestral alvo, [int atual = 0]) {
    if (identical(raiz, alvo)) return atual;
    for (final filho in [raiz.pai, raiz.mae]) {
      if (filho == null) continue;
      final encontrado = _geracaoDe(filho, alvo, atual + 1);
      if (encontrado > 0) return encontrado;
    }
    return 0;
  }
}

/// Resumo textual usado no rodapé da genealogia.
String resumoGenealogia(Cavalo cavalo) {
  final total = cavalo.genealogia.emLargura().length - 1;
  return '${plural(total, 'ascendente', 'ascendentes')} registrados em '
      '${cavalo.genealogia.geracoes} gerações.';
}
