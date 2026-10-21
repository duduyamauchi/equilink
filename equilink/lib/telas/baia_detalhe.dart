import 'package:flutter/material.dart';

import 'package:equilink_core/equilink_core.dart';
import '../core/tema.dart';
import '../escopo.dart';
import '../widgets/comuns.dart';

/// Tela "Detalhes da baia": rotina de manejo, ocorrências e observações de
/// um animal específico.
class TelaBaiaDetalhe extends StatefulWidget {
  const TelaBaiaDetalhe({super.key, required this.numero});

  final String numero;

  @override
  State<TelaBaiaDetalhe> createState() => _TelaBaiaDetalheState();
}

class _TelaBaiaDetalheState extends State<TelaBaiaDetalhe> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final repositorio = RepositorioEscopo.de(context);
    final baia = repositorio.baia(widget.numero);

    if (baia == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Baia')),
        body: const Vazio(
          icone: Icons.home_work_outlined,
          titulo: 'Baia não encontrada',
          descricao: 'A baia pode ter sido removida da gestão do haras.',
        ),
      );
    }

    final nome = repositorio.nomeCavalo(baia.cavaloId);
    final pendentes = baia.manejo.where((t) => !t.concluida).length;
    final abertas = baia.ocorrencias.where((o) => !o.resolvida).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Baia ${baia.numero} - $nome'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Ações',
            icon: const Icon(Icons.more_vert),
            onSelected: (valor) {
              switch (valor) {
                case 'em_dia':
                  repositorio.alterarStatusBaia(baia.numero, StatusBaia.emDia);
                  _aviso('Baia ${baia.numero} marcada como Em dia.');
                case 'manutencao':
                  repositorio.alterarStatusBaia(baia.numero, StatusBaia.manutencao);
                  _aviso('Baia ${baia.numero} marcada como Manutenção.');
                case 'remover':
                  _confirmarRemocao(context, repositorio, baia.numero, nome);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'em_dia', child: Text('Marcar como Em dia')),
              const PopupMenuItem(value: 'manutencao', child: Text('Marcar como Manutenção')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'remover', child: Text('Remover baia')),
            ],
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(Raios.pequeno),
                      child: Image.asset(
                        repositorio.fotoCavalo(baia.cavaloId),
                        width: 62,
                        height: 62,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: Espacos.x3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Registro ${repositorio.registroCavalo(baia.cavaloId)} • '
                            '${repositorio.pelagemCavalo(baia.cavaloId)}',
                            style: const TextStyle(
                              fontSize: 12,
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
                                baia.area,
                                cor: Cores.textoSecundario,
                                fundo: Cores.trilho,
                                compacta: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.x4),
                Wrap(
                  spacing: Espacos.x4,
                  runSpacing: Espacos.x4,
                  children: [
                    SizedBox(
                      width: 148,
                      child: CampoInfo(
                        rotulo: 'Última limpeza',
                        valor: dataHora(baia.ultimaLimpeza),
                        icone: Icons.cleaning_services_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 148,
                      child: CampoInfo(
                        rotulo: 'Manejo pendente',
                        valor: '$pendentes de ${baia.manejo.length}',
                        icone: Icons.checklist_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 148,
                      child: CampoInfo(
                        rotulo: 'Ocorrências abertas',
                        valor: '$abertas',
                        icone: Icons.report_problem_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Espacos.x4),
                AbasPilula(
                  abas: const ['Manejo', 'Ocorrências', 'Observações'],
                  contagens: [baia.manejo.length, baia.ocorrencias.length, baia.observacoes.length],
                  selecionada: _aba,
                  aoSelecionar: (i) {
                    repositorio.analytics.registrar(
                      'aba_alterada',
                      propriedades: {
                        'tela': '/baias/${baia.numero}',
                        'aba': const ['Manejo', 'Ocorrências', 'Observações'][i],
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
            0 => _AbaManejo(repositorio: repositorio, baia: baia),
            1 => _AbaOcorrencias(repositorio: repositorio, baia: baia),
            _ => _AbaObservacoes(repositorio: repositorio, baia: baia),
          },
        ],
      ),
    );
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto)));
  }

  Future<void> _confirmarRemocao(
    BuildContext context,
    Repositorio repositorio,
    String numero,
    String nome,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover baia'),
        content: Text(
          'A baia $numero ($nome) será removida da gestão do haras. '
          'O cadastro do animal permanece no aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Cores.vermelho),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    repositorio.removerBaia(numero);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Baia $numero removida.')),
    );
  }
}

/// Aba "Manejo": tabela de rotina com horários e quantidades.
class _AbaManejo extends StatelessWidget {
  const _AbaManejo({required this.repositorio, required this.baia});

  final Repositorio repositorio;
  final Baia baia;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Painel(
          padding: const EdgeInsets.all(Espacos.x3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: Espacos.x1, vertical: Espacos.x2),
                child: TituloSecao(
                  'Rotina de manejo',
                  subtitulo: 'Toque no relógio para ajustar o horário',
                ),
              ),
              const SizedBox(height: Espacos.x3),
              const CabecalhoTabela(
                colunas: ['Tipo', 'Horário', 'Quantidade'],
                flex: [5, 3, 3],
              ),
              const SizedBox(height: Espacos.x2),
              for (var i = 0; i < baia.manejo.length; i++) ...[
                _LinhaManejo(
                  tarefa: baia.manejo[i],
                  aoAlternar: () => repositorio.alternarManejo(baia.numero, baia.manejo[i].id),
                  aoEditarHorario: () => _editarHorario(context, repositorio, baia.manejo[i]),
                ),
                if (i != baia.manejo.length - 1) const Divider(height: Espacos.x3),
              ],
            ],
          ),
        ),
        const SizedBox(height: Espacos.x3),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TituloSecao('Resumo do dia'),
              const SizedBox(height: Espacos.x3),
              Row(
                children: [
                  Expanded(
                    child: ResumoItem(
                      valor: '${baia.manejo.where((t) => t.concluida).length}',
                      rotulo: 'Concluídas',
                      icone: Icons.task_alt,
                    ),
                  ),
                  const SizedBox(width: Espacos.x2),
                  Expanded(
                    child: ResumoItem(
                      valor: '${baia.manejo.where((t) => !t.concluida).length}',
                      rotulo: 'Pendentes',
                      icone: Icons.schedule,
                      destaque: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Espacos.x3),
              const NotaRodape(
                'A rotina considera alimentação, água, exercício, higiene e saúde '
                'de cada animal alojado.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _editarHorario(
    BuildContext context,
    Repositorio repositorio,
    TarefaManejo tarefa,
  ) async {
    final partes = tarefa.horario.split(':');
    final selecionado = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(partes.first) ?? 6,
        minute: int.tryParse(partes.last) ?? 0,
      ),
      helpText: 'Horário do manejo',
      cancelText: 'Cancelar',
      confirmText: 'Confirmar',
    );
    if (selecionado == null) return;
    final horario = '${dois(selecionado.hour)}:${dois(selecionado.minute)}';
    repositorio.atualizarHorarioManejo(baia.numero, tarefa.id, horario);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${tarefa.descricao} agora às $horario.')),
    );
  }
}

class _LinhaManejo extends StatelessWidget {
  const _LinhaManejo({
    required this.tarefa,
    required this.aoAlternar,
    required this.aoEditarHorario,
  });

  final TarefaManejo tarefa;
  final VoidCallback aoAlternar;
  final VoidCallback aoEditarHorario;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacos.x2, horizontal: Espacos.x1),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Checkbox(
                  value: tarefa.concluida,
                  onChanged: (_) => aoAlternar(),
                  activeColor: Cores.verde,
                  side: const BorderSide(color: Cores.borda),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: Espacos.x2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tarefa.descricao,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tarefa.concluida ? Cores.textoSecundario : Cores.texto,
                          decoration: tarefa.concluida ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        tarefa.tipo.rotulo,
                        style: const TextStyle(fontSize: 11, color: Cores.textoSecundario),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: aoEditarHorario,
              borderRadius: BorderRadius.circular(Raios.total),
              child: Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Cores.dourado),
                  const SizedBox(width: 5),
                  Text(
                    tarefa.horario,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Cores.dourado,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              tarefa.quantidade,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aba "Ocorrências": registro de saúde, manejo e estrutura.
class _AbaOcorrencias extends StatelessWidget {
  const _AbaOcorrencias({required this.repositorio, required this.baia});

  final Repositorio repositorio;
  final Baia baia;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (baia.ocorrencias.isEmpty)
          const Painel(
            child: Vazio(
              icone: Icons.check_circle_outline,
              titulo: 'Nenhuma ocorrência registrada',
              descricao: 'A baia está sem registros de saúde, manejo ou estrutura.',
            ),
          ),
        for (final ocorrencia in baia.ocorrencias)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x3),
            child: Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Etiqueta(
                        ocorrencia.tipo.rotulo,
                        cor: switch (ocorrencia.tipo) {
                          TipoOcorrencia.saude => Cores.vermelho,
                          TipoOcorrencia.manejo => Cores.azul,
                          TipoOcorrencia.estrutura => Cores.ambar,
                        },
                        fundo: switch (ocorrencia.tipo) {
                          TipoOcorrencia.saude => Cores.vermelhoFundo,
                          TipoOcorrencia.manejo => Cores.azulFundo,
                          TipoOcorrencia.estrutura => Cores.ambarFundo,
                        },
                        compacta: true,
                      ),
                      const SizedBox(width: Espacos.x2),
                      Expanded(
                        child: Text(
                          dataHora(ocorrencia.data),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Cores.textoSecundario,
                          ),
                        ),
                      ),
                      Etiqueta(
                        ocorrencia.resolvida ? 'Resolvida' : 'Em aberto',
                        cor: ocorrencia.resolvida ? Cores.verde : Cores.vermelho,
                        fundo: ocorrencia.resolvida ? Cores.verdeFundo : Cores.vermelhoFundo,
                        compacta: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: Espacos.x3),
                  Text(
                    ocorrencia.descricao,
                    style: const TextStyle(fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: Espacos.x2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: Cores.textoSecundario),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          ocorrencia.responsavel,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Cores.textoSecundario,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => repositorio.alternarOcorrenciaResolvida(
                          baia.numero,
                          ocorrencia.id,
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Cores.dourado,
                          textStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          ocorrencia.resolvida ? 'Reabrir' : 'Marcar como resolvida',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Espacos.x1),
        BotaoDourado(
          rotulo: 'Registrar ocorrência',
          icone: Icons.add_alert_outlined,
          escuro: true,
          aoTocar: () => _registrar(context, repositorio, baia.numero),
        ),
      ],
    );
  }

  /// Diálogo de registro de ocorrência.
  static Future<void> _registrar(
    BuildContext context,
    Repositorio repositorio,
    String numero,
  ) async {
    var tipo = TipoOcorrencia.saude;
    final descricao = TextEditingController();
    final responsavel = TextEditingController(text: 'João da Silva');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => AlertDialog(
          title: const Text('Registrar ocorrência'),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<TipoOcorrencia>(
                  initialValue: tipo,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: [
                    for (final t in TipoOcorrencia.values)
                      DropdownMenuItem(value: t, child: Text(t.rotulo)),
                  ],
                  onChanged: (v) => atualizar(() => tipo = v ?? tipo),
                ),
                const SizedBox(height: Espacos.x3),
                TextField(
                  controller: descricao,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    hintText: 'Descreva o que foi observado na baia.',
                  ),
                ),
                const SizedBox(height: Espacos.x3),
                TextField(
                  controller: responsavel,
                  decoration: const InputDecoration(labelText: 'Responsável'),
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
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
    if (confirmar != true || descricao.text.trim().isEmpty) return;
    repositorio.adicionarOcorrencia(
      numero,
      tipo: tipo,
      descricao: descricao.text.trim(),
      responsavel: responsavel.text.trim().isEmpty ? 'Não informado' : responsavel.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ocorrência registrada.')),
    );
  }
}

/// Aba "Observações": anotações da equipe sobre a baia e o animal.
class _AbaObservacoes extends StatelessWidget {
  const _AbaObservacoes({required this.repositorio, required this.baia});

  final Repositorio repositorio;
  final Baia baia;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (baia.observacoes.isEmpty)
          const Painel(
            child: Vazio(
              icone: Icons.sticky_note_2_outlined,
              titulo: 'Nenhuma observação registrada',
              descricao: 'Use as observações para alinhar a rotina entre tratadores e '
                  'veterinários.',
            ),
          ),
        for (final observacao in baia.observacoes)
          Padding(
            padding: const EdgeInsets.only(bottom: Espacos.x3),
            child: Painel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeloIniciais(
                        observacao.autor
                            .split(' ')
                            .where((p) => p.length > 2)
                            .take(2)
                            .map((p) => p[0])
                            .join()
                            .toUpperCase(),
                        tamanho: 36,
                      ),
                      const SizedBox(width: Espacos.x3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              observacao.autor,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              dataHora(observacao.data),
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
                  const SizedBox(height: Espacos.x3),
                  Text(
                    observacao.texto,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Cores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Espacos.x1),
        BotaoDourado(
          rotulo: 'Nova observação',
          icone: Icons.note_add_outlined,
          escuro: true,
          aoTocar: () => _adicionar(context, repositorio, baia.numero),
        ),
      ],
    );
  }

  static Future<void> _adicionar(
    BuildContext context,
    Repositorio repositorio,
    String numero,
  ) async {
    final texto = TextEditingController();
    final autor = TextEditingController(text: 'João da Silva');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova observação'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: texto,
                maxLines: 4,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Observação',
                  hintText: 'Ex.: ajustar a ração da noite após a prova.',
                ),
              ),
              const SizedBox(height: Espacos.x3),
              TextField(
                controller: autor,
                decoration: const InputDecoration(labelText: 'Autor'),
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
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (confirmar != true || texto.text.trim().isEmpty) return;
    repositorio.adicionarObservacao(
      numero,
      autor: autor.text.trim().isEmpty ? 'Equipe do haras' : autor.text.trim(),
      texto: texto.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Observação adicionada.')),
    );
  }
}
