import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quarto_core/quarto_core.dart';

import '../core/analytics_painel.dart';
import '../core/tema.dart';
import '../widgets/comuns.dart';

/// Visão geral: volume, sessões, série temporal e eventos mais frequentes.
class AbaVisaoGeral extends StatelessWidget {
  const AbaVisaoGeral({super.key, required this.eventos, required this.escopo});

  final List<EventoAnalitico> eventos;
  final ColetorAnaliticoPainel escopo;

  @override
  Widget build(BuildContext context) {
    final resumo = Analise.resumo(eventos);
    final porNome = Analise.porNome(eventos);
    final serie = Analise.seriePorDia(eventos);
    final receita = Analise.somaPorNome(eventos, comEntidade: 'cobranca');
    final sessoes = {for (final e in eventos) e.sessao};
    final duracaoMedia = sessoes.isEmpty
        ? Duration.zero
        : Duration(
            seconds:
                sessoes.map((s) => Analise.duracaoSessao(eventos, s).inSeconds).reduce((a, b) => a + b) ~/
                sessoes.length,
          );

    if (eventos.isEmpty) {
      return Painel(
        child: Vazio(
          icone: Icons.insights_outlined,
          titulo: 'Nenhum evento registrado',
          descricao:
              'Use o aplicativo para gerar eventos, ou importe um lote em JSON '
              'na aba Origem. Os eventos desta sessão aparecem aqui automaticamente.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, restricoes) {
            final colunas = restricoes.maxWidth > 1000 ? 4 : (restricoes.maxWidth > 620 ? 2 : 1);
            return GridView.count(
              crossAxisCount: colunas,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: colunas == 1 ? 4 : 2.6,
              children: [
                Indicador(valor: '${resumo.eventos}', rotulo: 'Eventos', icone: Icons.bolt_outlined),
                Indicador(
                  valor: '${resumo.sessoes}',
                  rotulo: 'Sessões',
                  icone: Icons.people_outline,
                  destaque: true,
                ),
                Indicador(
                  valor: '${resumo.usuarios}',
                  rotulo: 'Usuários identificados',
                  icone: Icons.person_outline,
                ),
                Indicador(
                  valor: _duracao(duracaoMedia),
                  rotulo: 'Duração média de sessão',
                  icone: Icons.timer_outlined,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Eventos por dia',
                subtitulo: 'Volume diário de toda a telemetria',
                icone: Icons.show_chart,
              ),
              const SizedBox(height: 16),
              _GraficoBarras(
                dados: [for (final s in serie) (rotulo: _curto(s.dia), valor: s.total.toDouble())],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Eventos mais frequentes',
                subtitulo: 'O que mais acontece no sistema',
                icone: Icons.leaderboard_outlined,
              ),
              const SizedBox(height: 16),
              _ListaBarras(
                itens: [
                  for (final e in porNome.take(12))
                    (rotulo: e.nome, valor: e.total.toDouble(), sufixo: '${e.total}'),
                ],
              ),
            ],
          ),
        ),
        if (receita.isNotEmpty) ...[
          const SizedBox(height: 16),
          Painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CabecalhoSecao(
                  titulo: 'Valores somados',
                  subtitulo: 'Eventos com valor numérico — base para receita',
                  icone: Icons.payments_outlined,
                ),
                const SizedBox(height: 16),
                _ListaBarras(
                  itens: [
                    for (final r in receita)
                      (
                        rotulo: r.nome,
                        valor: r.total,
                        sufixo: '${r.total.toStringAsFixed(2).replaceAll('.', ',')} '
                            '(${r.quantidade}x)',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  static String _duracao(Duration d) {
    if (d.inSeconds < 60) return '${d.inSeconds}s';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }

  static String _curto(String dia) {
    final partes = dia.split('-');
    return partes.length == 3 ? '${partes[2]}/${partes[1]}' : dia;
  }
}

/// Lista de eventos com filtros, busca e inspeção de propriedades.
class AbaEventos extends StatefulWidget {
  const AbaEventos({super.key, required this.eventos});

  final List<EventoAnalitico> eventos;

  @override
  State<AbaEventos> createState() => _AbaEventosState();
}

class _AbaEventosState extends State<AbaEventos> {
  String? _nome;
  String _busca = '';
  int _pagina = 0;
  static const _porPagina = 40;

  @override
  Widget build(BuildContext context) {
    final disponiveis = Analise.nomesDisponiveis(widget.eventos);
    final filtrados = Analise.filtrar(widget.eventos, nome: _nome, busca: _busca);
    final ordenados = [...filtrados]..sort((a, b) => b.quando.compareTo(a.quando));
    final paginas = (ordenados.length / _porPagina).ceil().clamp(1, 9999);
    final pagina = _pagina.clamp(0, paginas - 1);
    final recorte = ordenados.skip(pagina * _porPagina).take(_porPagina).toList();

    return Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoSecao(
            titulo: 'Eventos',
            subtitulo: '${filtrados.length} de ${widget.eventos.length} • '
                'toque em uma linha para ver as propriedades',
            icone: Icons.list_alt_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() {
                    _busca = v;
                    _pagina = 0;
                  }),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome, tela, entidade ou valor de propriedade',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                child: DropdownButtonFormField<String?>(
                  initialValue: _nome,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tipo de evento'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    for (final n in disponiveis) DropdownMenuItem(value: n, child: Text(n)),
                  ],
                  onChanged: (v) => setState(() {
                    _nome = v;
                    _pagina = 0;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recorte.isEmpty)
            const Vazio(
              icone: Icons.search_off,
              titulo: 'Nenhum evento corresponde ao filtro',
            ),
          for (final evento in recorte)
            _LinhaEvento(evento: evento, eventos: widget.eventos),
          if (paginas > 1) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Página anterior',
                  onPressed: pagina == 0 ? null : () => setState(() => _pagina = pagina - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  'Página ${pagina + 1} de $paginas',
                  style: const TextStyle(fontSize: 12.5, color: AdminCores.textoSecundario),
                ),
                IconButton(
                  tooltip: 'Próxima página',
                  onPressed: pagina >= paginas - 1 ? null : () => setState(() => _pagina = pagina + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LinhaEvento extends StatelessWidget {
  const _LinhaEvento({required this.evento, required this.eventos});

  final EventoAnalitico evento;
  final List<EventoAnalitico> eventos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => _DialogoEvento(evento: evento),
        ),
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AdminCores.superficieSuave,
            borderRadius: BorderRadius.circular(AdminRaios.pequeno),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 148,
                child: Text(
                  _hora(evento.quando),
                  style: const TextStyle(fontSize: 11.5, color: AdminCores.textoSecundario),
                ),
              ),
              Expanded(
                child: Text(
                  evento.nome,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (evento.tela != null)
                _Marca(texto: evento.tela!, cor: AdminCores.azul, fundo: AdminCores.azulFundo),
              if (evento.entidade != null) ...[
                const SizedBox(width: 6),
                _Marca(
                  texto: evento.entidade!,
                  cor: AdminCores.dourado,
                  fundo: AdminCores.superficie,
                ),
              ],
              if (evento.valor != null) ...[
                const SizedBox(width: 10),
                Text(
                  evento.valor!.toStringAsFixed(2).replaceAll('.', ','),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AdminCores.verde,
                  ),
                ),
              ],
              const SizedBox(width: 10),
              Text(
                evento.sessao,
                style: const TextStyle(fontSize: 11, color: AdminCores.textoSecundario),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _hora(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';
}

class _Marca extends StatelessWidget {
  const _Marca({required this.texto, required this.cor, required this.fundo});

  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) => Etiqueta(texto, cor: cor, fundo: fundo);
}

class _DialogoEvento extends StatelessWidget {
  const _DialogoEvento({required this.evento});

  final EventoAnalitico evento;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(evento.nome),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 14,
                children: [
                  SizedBox(width: 200, child: Campo(rotulo: 'Quando', valor: _hora(evento.quando))),
                  SizedBox(width: 160, child: Campo(rotulo: 'Sessão', valor: evento.sessao)),
                  SizedBox(width: 160, child: Campo(rotulo: 'Usuário', valor: evento.usuario ?? '—')),
                  SizedBox(width: 160, child: Campo(rotulo: 'Tela', valor: evento.tela ?? '—')),
                  SizedBox(
                    width: 190,
                    child: Campo(
                      rotulo: 'Entidade',
                      valor: evento.entidade == null
                          ? '—'
                          : '${evento.entidade} ${evento.entidadeId ?? ''}',
                    ),
                  ),
                  SizedBox(
                    width: 130,
                    child: Campo(
                      rotulo: 'Valor',
                      valor: evento.valor?.toString() ?? '—',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'PROPRIEDADES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AdminCores.textoSecundario,
                ),
              ),
              const SizedBox(height: 8),
              if (evento.propriedades.isEmpty)
                const Text('Sem propriedades.', style: TextStyle(fontSize: 12.5))
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminCores.superficieSuave,
                    borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                    border: Border.all(color: AdminCores.borda),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final p in evento.propriedades.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  p.key,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${p.value}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'JSON do evento',
                style: TextStyle(fontSize: 11, color: AdminCores.textoSecundario.withValues(alpha: 0.9)),
              ),
              const SizedBox(height: 6),
              SelectableText(
                evento.toJson().toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Fechar')),
      ],
    );
  }

  static String _hora(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}';
}

/// Funil genérico: o usuário escolhe o funil e as etapas, na ordem.
class AbaFunil extends StatefulWidget {
  const AbaFunil({super.key, required this.eventos});

  final List<EventoAnalitico> eventos;

  @override
  State<AbaFunil> createState() => _AbaFunilState();
}

class _AbaFunilState extends State<AbaFunil> {
  String? _funil;
  List<String> _etapasEscolhidas = [];

  @override
  Widget build(BuildContext context) {
    final funis = Analise.funisDisponiveis(widget.eventos);
    // Sem funil escolhido, usa o primeiro disponível e todas as suas etapas.
    final funilAtivo = _funil ?? (funis.isEmpty ? null : funis.first);
    final etapasDisponiveis = funilAtivo == null
        ? const <String>[]
        : Analise.etapasDisponiveis(widget.eventos, funilAtivo);
    final etapas = _etapasEscolhidas.isEmpty ? etapasDisponiveis : _etapasEscolhidas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Funil',
                subtitulo:
                    'Escolha o funil e a ordem das etapas. Funciona para cadastro, assinatura, '
                    'compra — qualquer sequência instrumentada com analytics.funil(...)',
                icone: Icons.filter_alt_outlined,
              ),
              const SizedBox(height: 16),
              if (funis.isEmpty)
                const Vazio(
                  icone: Icons.filter_alt_outlined,
                  titulo: 'Nenhum funil instrumentado',
                  descricao:
                      'Registre etapas com analytics.funil("nome", "etapa") para vê-las aqui.',
                ),
              if (funis.isNotEmpty) ...[
                Row(
                  children: [
                    SizedBox(
                      width: 260,
                      child: DropdownButtonFormField<String>(
                        initialValue: funilAtivo,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Funil'),
                        items: [
                          for (final f in funis) DropdownMenuItem(value: f, child: Text(f)),
                        ],
                        onChanged: (v) => setState(() {
                          _funil = v;
                          _etapasEscolhidas = [];
                        }),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${etapas.length} etapas detectadas',
                        style: const TextStyle(fontSize: 12.5, color: AdminCores.textoSecundario),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final etapa in etapasDisponiveis)
                      FilterChip(
                        label: Text(etapa),
                        selected: etapas.contains(etapa),
                        onSelected: (marcado) => setState(() {
                          final atual = [...etapas];
                          if (marcado) {
                            atual.add(etapa);
                          } else {
                            atual.remove(etapa);
                          }
                          _etapasEscolhidas = atual;
                        }),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (funilAtivo != null && etapas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ResultadoFunil(eventos: widget.eventos, funil: funilAtivo, etapas: etapas),
        ],
      ],
    );
  }
}

class _ResultadoFunil extends StatelessWidget {
  const _ResultadoFunil({required this.eventos, required this.funil, required this.etapas});

  final List<EventoAnalitico> eventos;
  final String funil;
  final List<String> etapas;

  @override
  Widget build(BuildContext context) {
    final passos = Analise.funil(eventos, funil: funil, etapas: etapas);
    final inicial = passos.isEmpty ? 0 : passos.first.sessoes;
    final final_ = passos.isEmpty ? 0 : passos.last.sessoes;
    final total = inicial == 0 ? 0.0 : final_ / inicial;

    return Painel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CabecalhoSecao(
            titulo: 'Conversão do funil "$funil"',
            subtitulo: '$inicial sessões entraram • $final_ concluíram • '
                '${(total * 100).toStringAsFixed(1).replaceAll('.', ',')}% de conversão total',
            icone: Icons.insights_outlined,
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < passos.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Text(
                          '${i + 1}. ${passos[i].etapa}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AdminRaios.total),
                          child: SizedBox(
                            height: 22,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: (passos[i].conversao * 1000).round().clamp(1, 1000),
                                  child: ColoredBox(
                                    color: i == 0 ? AdminCores.verde : AdminCores.dourado,
                                  ),
                                ),
                                Expanded(
                                  flex: 1000 - (passos[i].conversao * 1000).round().clamp(1, 1000),
                                  child: const ColoredBox(color: AdminCores.superficieSuave),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: Text(
                          '${passos[i].sessoes} sessões '
                          '(${(passos[i].conversao * 100).toStringAsFixed(0)}%)',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i > 0 && passos[i].perda > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 200, top: 4),
                      child: Text(
                        'perda de ${(passos[i].perda * 100).toStringAsFixed(0)}% nesta etapa',
                        style: const TextStyle(fontSize: 11, color: AdminCores.vermelho),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Retenção por coorte, com seleção de evento e janela de dias.
class AbaRetencao extends StatefulWidget {
  const AbaRetencao({super.key, required this.eventos});

  final List<EventoAnalitico> eventos;

  @override
  State<AbaRetencao> createState() => _AbaRetencaoState();
}

class _AbaRetencaoState extends State<AbaRetencao> {
  String? _nome;
  int _dias = 7;

  @override
  Widget build(BuildContext context) {
    final coortes = Analise.retencao(widget.eventos, dias: _dias, nome: _nome);
    final nomes = Analise.nomesDisponiveis(widget.eventos);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Retenção',
                subtitulo:
                    'Coortes por dia de primeiro uso. Funciona para uso do aplicativo, '
                    'recompra ou qualquer evento repetível.',
                icone: Icons.autorenew_outlined,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String?>(
                      initialValue: _nome,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Evento considerado'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Qualquer evento')),
                        for (final n in nomes) DropdownMenuItem(value: n, child: Text(n)),
                      ],
                      onChanged: (v) => setState(() => _nome = v),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<int>(
                      initialValue: _dias,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Janela'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 dia')),
                        DropdownMenuItem(value: 3, child: Text('3 dias')),
                        DropdownMenuItem(value: 7, child: Text('7 dias')),
                        DropdownMenuItem(value: 14, child: Text('14 dias')),
                        DropdownMenuItem(value: 30, child: Text('30 dias')),
                      ],
                      onChanged: (v) => setState(() => _dias = v ?? 7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (coortes.isEmpty)
          const Painel(
            child: Vazio(
              icone: Icons.autorenew_outlined,
              titulo: 'Sem dados de retenção',
              descricao: 'São necessárias sessões em pelo menos um dia para montar as coortes.',
            ),
          )
        else
          Painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CabecalhoSecao(
                  titulo: 'Coortes',
                  subtitulo: '${coortes.length} coortes • dia 0 é o primeiro uso',
                  icone: Icons.grid_on_outlined,
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(58),
                    children: [
                      TableRow(
                        children: [
                          const SizedBox(
                            width: 110,
                            child: Text(
                              'COORTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AdminCores.textoSecundario,
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 70,
                            child: Text(
                              'SESSÕES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AdminCores.textoSecundario,
                              ),
                            ),
                          ),
                          for (var d = 0; d <= _dias; d++)
                            Center(
                              child: Text(
                                'D$d',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AdminCores.textoSecundario,
                                ),
                              ),
                            ),
                        ],
                      ),
                      for (final c in coortes)
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                c.coorte,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text('${c.tamanho}', style: const TextStyle(fontSize: 12)),
                            ),
                            for (var d = 0; d <= _dias; d++)
                              Padding(
                                padding: const EdgeInsets.all(2),
                                child: Container(
                                  height: 26,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _cor(c.retencao[d]),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${(c.retencao[d] * 100).round()}',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: c.retencao[d] > 0.55
                                          ? Colors.white
                                          : AdminCores.texto,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final nivel in [0.0, 0.25, 0.5, 0.75, 1.0])
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _cor(nivel),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(nivel * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 10.5,
                                color: AdminCores.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Color _cor(double taxa) {
    if (taxa <= 0) return AdminCores.superficieSuave;
    // Interpola de dourado claro a verde conforme a retenção cresce.
    return Color.lerp(AdminCores.ambarFundo, AdminCores.verde, taxa.clamp(0.0, 1.0))!;
  }
}

/// Origem dos dados de analytics: coletor ativo, importação e exportação.
class AbaOrigem extends StatelessWidget {
  const AbaOrigem({super.key, required this.escopo, required this.repositorio});

  final ColetorAnaliticoPainel escopo;
  final Repositorio repositorio;

  @override
  Widget build(BuildContext context) {
    final resumo = Analise.resumo(escopo.eventos);
    final sessoes = {for (final e in escopo.eventos) e.sessao};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Origem dos eventos',
                subtitulo: 'De onde vêm os dados analisados nesta tela',
                icone: Icons.hub_outlined,
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 28,
                runSpacing: 18,
                children: [
                  SizedBox(width: 260, child: Campo(rotulo: 'Origem', valor: escopo.origem)),
                  SizedBox(width: 130, child: Campo(rotulo: 'Eventos', valor: '${resumo.eventos}')),
                  SizedBox(width: 130, child: Campo(rotulo: 'Sessões', valor: '${resumo.sessoes}')),
                  SizedBox(
                    width: 180,
                    child: Campo(rotulo: 'Usuários', valor: '${resumo.usuarios}'),
                  ),
                  SizedBox(
                    width: 260,
                    child: Campo(
                      rotulo: 'Coletor do aplicativo',
                      valor: repositorio.analytics.descricaoColetor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _NotaRodape(
                'O aplicativo registra eventos no coletor configurado. Para analisá-los aqui, '
                'exporte do app e importe nesta tela, ou aponte os dois para o mesmo serviço '
                'com --dart-define=QUARTO_ANALYTICS=http --dart-define=QUARTO_API_EVENTOS=<endereço>.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(
                titulo: 'Sessões observadas',
                subtitulo: 'Agrupamento por sessão, para inspeção da jornada',
                icone: Icons.timeline_outlined,
              ),
              const SizedBox(height: 16),
              if (sessoes.isEmpty)
                const Vazio(icone: Icons.timeline_outlined, titulo: 'Nenhuma sessão registrada'),
              for (final s in sessoes.take(30))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AdminCores.superficieSuave,
                      borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${_eventosDaSessao(s)} eventos • '
                              '${_duracaoSessao(s)}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AdminCores.textoSecundario,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final e in _jornada(s).take(14))
                              Etiqueta(
                                e.nome,
                                cor: AdminCores.azul,
                                fundo: AdminCores.azulFundo,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Painel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CabecalhoSecao(
                      titulo: 'Exportar',
                      subtitulo: 'Gera o mesmo JSON aceito pelo serviço de eventos',
                      icone: Icons.download_outlined,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final json = escopo.exportarJson();
                        await Clipboard.setData(ClipboardData(text: json));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${escopo.eventos.length} eventos copiados como JSON.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_all_outlined, size: 16),
                      label: const Text('Copiar eventos em JSON'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _eventosDaSessao(String s) => escopo.eventos.where((e) => e.sessao == s).length;

  String _duracaoSessao(String s) {
    final d = Analise.duracaoSessao(escopo.eventos, s);
    return d.inSeconds < 60 ? '${d.inSeconds}s' : '${d.inMinutes}m';
  }

  List<EventoAnalitico> _jornada(String s) {
    final daSessao = [for (final e in escopo.eventos) if (e.sessao == s) e]
      ..sort((a, b) => a.quando.compareTo(b.quando));
    return daSessao;
  }
}

// -----------------------------------------------------------------------------
// Gráficos simples
// -----------------------------------------------------------------------------

class _GraficoBarras extends StatelessWidget {
  const _GraficoBarras({required this.dados});

  final List<({String rotulo, double valor})> dados;

  @override
  Widget build(BuildContext context) {
    if (dados.isEmpty) {
      return const Vazio(icone: Icons.show_chart, titulo: 'Sem dados para exibir');
    }
    final maior = Analise.maiorValor(dados.map((d) => d.valor));
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in dados)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${d.valor.toInt()}',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AdminCores.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: maior == 0 ? 0.05 : (d.valor / maior).clamp(0.05, 1.0),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AdminCores.dourado,
                              borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      d.rotulo,
                      style: const TextStyle(fontSize: 10, color: AdminCores.textoSecundario),
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

class _ListaBarras extends StatelessWidget {
  const _ListaBarras({required this.itens});

  final List<({String rotulo, double valor, String sufixo})> itens;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return const Vazio(icone: Icons.leaderboard_outlined, titulo: 'Sem dados');
    }
    final maior = Analise.maiorValor(itens.map((i) => i.valor));
    return Column(
      children: [
        for (final item in itens)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 230,
                  child: Text(
                    item.rotulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AdminRaios.total),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: maior == 0
                                ? 1
                                : ((item.valor / maior) * 1000).round().clamp(1, 1000),
                            child: const ColoredBox(color: AdminCores.dourado),
                          ),
                          Expanded(
                            flex: maior == 0
                                ? 999
                                : 1000 - ((item.valor / maior) * 1000).round().clamp(1, 1000),
                            child: const ColoredBox(color: AdminCores.superficieSuave),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 150,
                  child: Text(
                    item.sufixo,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12, color: AdminCores.textoSecundario),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Faixa discreta de explicação reutilizada nas telas do painel.
class _NotaRodape extends StatelessWidget {
  const _NotaRodape(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 14, color: AdminCores.textoSecundario),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 11.5, color: AdminCores.textoSecundario, height: 1.45),
          ),
        ),
      ],
    );
  }
}
