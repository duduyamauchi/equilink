import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:quarto_core/quarto_core.dart';
import '../core/tema.dart';
import '../escopo.dart';
import '../rotas.dart';
import '../widgets/comuns.dart';

/// Tela "Gestão das Baias (Haras)": visão das baias, manejo consolidado do dia
/// e relatórios gerenciais.
class TelaBaias extends StatefulWidget {
  const TelaBaias({super.key});

  @override
  State<TelaBaias> createState() => _TelaBaiasState();
}

class _TelaBaiasState extends State<TelaBaias> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final repositorio = RepositorioEscopo.de(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestão das Baias (Haras)'),
        leading: IconButton(
          tooltip: 'Placa de identificação',
          icon: const Icon(Icons.qr_code_2, size: 24),
          onPressed: () => context.push(Rotas.placa),
        ),
        actions: [
          IconButton(
            tooltip: 'Adicionar nova baia',
            icon: const Icon(Icons.add),
            onPressed: () => _adicionarBaia(context, repositorio),
          ),
        ],
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
                    Expanded(
                      child: ResumoItem(
                        valor: '${repositorio.baias.length}',
                        rotulo: 'Baias ativas',
                        icone: Icons.home_work_outlined,
                      ),
                    ),
                    const SizedBox(width: Espacos.x2),
                    Expanded(
                      child: ResumoItem(
                        valor: '${repositorio.manejoPendenteTotal}',
                        rotulo: 'Manejo pendente',
                        icone: Icons.checklist_outlined,
                        destaque: true,
                      ),
                    ),
                    const SizedBox(width: Espacos.x2),
                    Expanded(
                      child: ResumoItem(
                        valor: '${repositorio.ocorrenciasAbertasTotal}',
                        rotulo: 'Ocorrências abertas',
                        icone: Icons.report_problem_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.x4),
                AbasPilula(
                  abas: const ['Baias', 'Manejo', 'Relatórios'],
                  selecionada: _aba,
                  aoSelecionar: (i) {
                    repositorio.analytics.registrar(
                      'aba_alterada',
                      propriedades: {
                        'tela': '/baias',
                        'aba': const ['Baias', 'Manejo', 'Relatórios'][i],
                      },
                    );
                    setState(() => _aba = i);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: Espacos.x4),
          switch (_aba) {
            0 => _AbaBaias(repositorio: repositorio),
            1 => _AbaManejo(repositorio: repositorio),
            _ => _AbaRelatorios(repositorio: repositorio),
          },
          const SizedBox(height: Espacos.x4),
          BotaoDourado(
            rotulo: 'Adicionar nova baia',
            icone: Icons.add,
            aoTocar: () => _adicionarBaia(context, repositorio),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarBaia(BuildContext context, Repositorio repositorio) async {
    final ocupados = repositorio.baias.map((b) => b.cavaloId).toSet();
    final disponiveis = _plantel.where((c) => !ocupados.contains(c.id)).toList();
    if (disponiveis.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos os animais do plantel já possuem baia.')),
      );
      return;
    }
    var cavaloId = disponiveis.first.id;
    var status = StatusBaia.emDia;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => AlertDialog(
          title: const Text('Nova baia'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione o animal e a situação inicial da baia.',
                  style: TextStyle(fontSize: 13, color: Cores.textoSecundario),
                ),
                const SizedBox(height: Espacos.x4),
                DropdownButtonFormField<String>(
                  initialValue: cavaloId,
                  decoration: const InputDecoration(labelText: 'Animal'),
                  items: [
                    for (final c in disponiveis)
                      DropdownMenuItem(value: c.id, child: Text(c.nome)),
                  ],
                  onChanged: (v) => atualizar(() => cavaloId = v ?? cavaloId),
                ),
                const SizedBox(height: Espacos.x3),
                DropdownButtonFormField<StatusBaia>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Situação'),
                  items: [
                    for (final s in StatusBaia.values)
                      DropdownMenuItem(value: s, child: Text(s.rotulo)),
                  ],
                  onChanged: (v) => atualizar(() => status = v ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true) return;
    await repositorio.adicionarBaia(cavaloId: cavaloId, status: status);
    if (!context.mounted) return;
    final numero = repositorio.baias.last.numero;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baia $numero criada com a rotina de manejo padrão.')),
    );
  }
}

const _plantel = <({String id, String nome})>[
  (id: 'isabel-toro-leo', nome: 'ISABEL TORO LEO'),
  (id: 'tornado-do-vale', nome: 'TORNADO DO VALE'),
  (id: 'luna-badger', nome: 'LUNA BADGER'),
  (id: 'relampago-star', nome: 'RELÂMPAGO STAR'),
  (id: 'boneca-freckles', nome: 'BONECA FRECKLES'),
  (id: 'estrela-guia', nome: 'ESTRELA GUIA'),
  (id: 'vento-norte', nome: 'VENTO NORTE'),
];

/// Aba "Baias": lista das baias com animal, situação e ações.
class _AbaBaias extends StatelessWidget {
  const _AbaBaias({required this.repositorio});

  final Repositorio repositorio;

  @override
  Widget build(BuildContext context) {
    final baias = repositorio.baiasOrdenadas;
    return Column(
      children: [
        for (final baia in baias)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x3),
            child: InkWell(
              onTap: () {
                repositorio.analytics.registrar(
                  'baia_aberta',
                  entidade: 'baia',
                  entidadeId: baia.numero,
                  propriedades: {'status': baia.status.name},
                );
                context.push(Rotas.baia(baia.numero));
              },
              borderRadius: BorderRadius.circular(Raios.medio),
              child: Painel(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Raios.pequeno),
                      child: Image.asset(
                        repositorio.fotoCavalo(baia.cavaloId),
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Espacos.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Baia ${baia.numero}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: Cores.dourado,
                                ),
                              ),
                              const SizedBox(width: Espacos.x2),
                              Expanded(
                                child: Text(
                                  repositorio.nomeCavalo(baia.cavaloId),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${repositorio.registroCavalo(baia.cavaloId)} • '
                            '${repositorio.pelagemCavalo(baia.cavaloId)} • '
                            'Limpeza ${dataCurta(baia.ultimaLimpeza)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Cores.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Etiqueta.status(baia.status.rotulo),
                              Etiqueta(
                                plural(baia.manejo.where((t) => !t.concluida).length,
                                    'pendente', 'pendentes'),
                                cor: Cores.textoSecundario,
                                fundo: Cores.trilho,
                                compacta: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Cores.textoSecundario),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Aba "Manejo": rotina consolidada de todas as baias, com marcação de tarefas.
class _AbaManejo extends StatelessWidget {
  const _AbaManejo({required this.repositorio});

  final Repositorio repositorio;

  @override
  Widget build(BuildContext context) {
    final baias = repositorio.baiasOrdenadas;
    return Column(
      children: [
        for (final baia in baias)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x3),
            child: Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Baia ${baia.numero} • ${repositorio.nomeCavalo(baia.cavaloId)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        '${baia.manejo.where((t) => t.concluida).length}/${baia.manejo.length}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Cores.dourado,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Espacos.x2),
                  BarraProporcao(
                    valor: baia.manejo.isEmpty
                        ? 0
                        : baia.manejo.where((t) => t.concluida).length / baia.manejo.length,
                    cor: baia.manejo.every((t) => t.concluida) ? Cores.verde : Cores.dourado,
                  ),
                  const SizedBox(height: Espacos.x2),
                  for (final tarefa in baia.manejo)
                    _ItemManejo(
                      tarefa: tarefa,
                      aoAlternar: () async {
                        final novo = await repositorio.alternarManejo(baia.numero, tarefa.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                novo
                                    ? '${tarefa.descricao} registrada como concluída.'
                                    : '${tarefa.descricao} marcada como pendente.',
                              ),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                      },
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ItemManejo extends StatelessWidget {
  const _ItemManejo({required this.tarefa, required this.aoAlternar});

  final TarefaManejo tarefa;
  final VoidCallback aoAlternar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: aoAlternar,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: tarefa.concluida,
                onChanged: (_) => aoAlternar(),
                activeColor: Cores.verde,
                side: const BorderSide(color: Cores.borda),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: Espacos.x3),
            Expanded(
              child: Text(
                tarefa.descricao,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: tarefa.concluida ? Cores.textoSecundario : Cores.texto,
                  decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
            Text(
              tarefa.horario,
              style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
            ),
            const SizedBox(width: Espacos.x3),
            SizedBox(
              width: 56,
              child: Text(
                tarefa.quantidade,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aba "Relatórios": indicadores do haras, consumo estimado e ocupação.
class _AbaRelatorios extends StatelessWidget {
  const _AbaRelatorios({required this.repositorio});

  final Repositorio repositorio;

  @override
  Widget build(BuildContext context) {
    final baias = repositorio.baiasOrdenadas;
    final consumo = repositorio.consumoDiario;
    final maiorConsumo = consumo.isEmpty
        ? 1.0
        : Analise.maiorValor(consumo.map((c) => c.quilos));
    final totalTarefas = repositorio.tarefasConcluidasTotal + repositorio.manejoPendenteTotal;
    final fracaoConcluida = totalTarefas == 0
        ? 0.0
        : repositorio.tarefasConcluidasTotal / totalTarefas;

    return Column(
      children: [
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao(
                'Situação das baias',
                subtitulo: 'Distribuição por estado de conservação',
              ),
              const SizedBox(height: Espacos.x4),
              for (final status in StatusBaia.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacos.x3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Text(
                          status.rotulo,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: BarraProporcao(
                          valor: baias.isEmpty
                              ? 0
                              : baias.where((b) => b.status == status).length / baias.length,
                          cor: switch (status) {
                            StatusBaia.emDia => Cores.verde,
                            StatusBaia.manutencao => Cores.ambar,
                            StatusBaia.atencao => Cores.vermelho,
                          },
                        ),
                      ),
                      const SizedBox(width: Espacos.x3),
                      SizedBox(
                        width: 74,
                        child: Text(
                          '${baias.where((b) => b.status == status).length} de '
                          '${baias.length}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Espacos.x3),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao(
                'Consumo diário estimado',
                subtitulo: 'Somatório da rotina de manejo de todas as baias',
              ),
              const SizedBox(height: Espacos.x4),
              if (consumo.isEmpty)
                const Vazio(
                  icone: Icons.inventory_2_outlined,
                  titulo: 'Sem dados de consumo',
                ),
              for (final item in consumo)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacos.x3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text(
                          item.insumo,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: BarraProporcao(
                          valor: item.quilos / maiorConsumo,
                          cor: Cores.dourado,
                        ),
                      ),
                      const SizedBox(width: Espacos.x3),
                      SizedBox(
                        width: 86,
                        child: Text(
                          '${item.quilos.toStringAsFixed(1).replaceAll('.', ',')} kg/dia',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: Espacos.x3),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Execução do manejo do dia'),
              const SizedBox(height: Espacos.x4),
              Row(
                children: [
                  Expanded(
                    child: ResumoItem(
                      valor: '${repositorio.tarefasConcluidasTotal}',
                      rotulo: 'Tarefas concluídas',
                      icone: Icons.task_alt,
                    ),
                  ),
                  const SizedBox(width: Espacos.x2),
                  Expanded(
                    child: ResumoItem(
                      valor: '${repositorio.manejoPendenteTotal}',
                      rotulo: 'Tarefas pendentes',
                      icone: Icons.schedule,
                      destaque: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacos.x3),
              BarraProporcao(valor: fracaoConcluida, cor: Cores.verde, altura: 10),
              const SizedBox(height: Espacos.x2),
              Text(
                '${percentual(fracaoConcluida, casas: 0)} da rotina diária concluída.',
                style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
              ),
            ],
          ),
        ),
        const SizedBox(height: Espacos.x3),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Indicadores do haras'),
              const SizedBox(height: Espacos.x4),
              Wrap(
                spacing: Espacos.x4,
                runSpacing: Espacos.x4,
                children: [
                  SizedBox(
                    width: 148,
                    child: CampoInfo(
                      rotulo: 'Baias em manutenção',
                      valor: '${repositorio.baiasEmManutencao}',
                      icone: Icons.build_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    child: CampoInfo(
                      rotulo: 'Ocorrências abertas',
                      valor: '${repositorio.ocorrenciasAbertasTotal}',
                      icone: Icons.report_problem_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    child: CampoInfo(
                      rotulo: 'Animais alojados',
                      valor: '${baias.length}',
                      icone: Icons.pets_outlined,
                    ),
                  ),
                  SizedBox(
                    width: 148,
                    child: CampoInfo(
                      rotulo: 'Última atualização',
                      valor: dataCurta(repositorio.hoje),
                      icone: Icons.update,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacos.x4),
              const NotaRodape(
                'Os relatórios consideram a rotina cadastrada em cada baia e são '
                'atualizados automaticamente conforme o manejo é registrado.',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
