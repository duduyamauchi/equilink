import 'package:flutter/material.dart';
import 'package:equilink_core/equilink_core.dart';

import '../core/tema.dart';

/// Sugestões do cliente sobre a página aberta.
///
/// Fica em todas as páginas do painel, ancorado no canto: o cliente anota o que
/// quer naquela tela sem sair dela. A sugestão nasce com a rota atual, então
/// quem implementa sabe exatamente onde mexer.
class PainelSugestoes extends StatefulWidget {
  const PainelSugestoes({super.key, required this.rota, required this.aberto, required this.aoAlternar});

  /// Página atual (`/cavalos`, `/provas`).
  final String rota;

  final bool aberto;
  final VoidCallback aoAlternar;

  @override
  State<PainelSugestoes> createState() => _PainelSugestoesState();
}

class _PainelSugestoesState extends State<PainelSugestoes> {
  final _titulo = TextEditingController();
  final _texto = TextEditingController();
  final _referencia = TextEditingController();

  List<Sugestao> _sugestoes = const [];
  bool _carregando = false;
  bool _enviando = false;
  String? _erro;
  String? _editandoId;

  /// Histórico aberto no momento (null = nenhum).
  String? _historicoId;
  List<VersaoSugestao> _versoes = const [];

  SugestoesApi? get _api => Ambiente.criarSugestoes();

  @override
  void initState() {
    super.initState();
    if (widget.aberto) _carregar();
  }

  @override
  void didUpdateWidget(PainelSugestoes oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ao abrir, ou ao trocar de página com o painel aberto, recarrega.
    if (widget.aberto && (!oldWidget.aberto || oldWidget.rota != widget.rota)) {
      _carregar();
    }
  }

  @override
  void dispose() {
    _titulo.dispose();
    _texto.dispose();
    _referencia.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final api = _api;
    if (api == null) return;
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista = await api.listar(rota: widget.rota, incluirApagadas: true);
      if (!mounted) return;
      setState(() {
        _sugestoes = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e is ErroFonte ? e.mensagem : '$e';
        _carregando = false;
      });
    }
  }

  Future<void> _salvar() async {
    final api = _api;
    if (api == null || _enviando) return;
    final titulo = _titulo.text.trim();
    final texto = _texto.text.trim();
    if (titulo.isEmpty || texto.isEmpty) {
      setState(() => _erro = 'Preencha o título e a sugestão.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      if (_editandoId == null) {
        await api.criar(
          rota: widget.rota,
          titulo: titulo,
          texto: texto,
          referencia: _referencia.text.trim(),
        );
      } else {
        await api.editar(
          _editandoId!,
          titulo: titulo,
          texto: texto,
          referencia: _referencia.text.trim(),
        );
      }
      _limparFormulario();
      await _carregar();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_editandoId == null ? 'Sugestão registrada.' : 'Sugestão atualizada.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroFonte ? e.mensagem : '$e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _limparFormulario() {
    _titulo.clear();
    _texto.clear();
    _referencia.clear();
    setState(() {
      _editandoId = null;
      _historicoId = null;
      _versoes = const [];
    });
  }

  void _editar(Sugestao s) {
    setState(() {
      _editandoId = s.id;
      _historicoId = null;
      _titulo.text = s.titulo;
      _texto.text = s.texto;
      _referencia.text = s.referencia ?? '';
    });
  }

  Future<void> _apagar(Sugestao s) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar sugestão'),
        content: Text('"${s.titulo}" sai da sua lista. O histórico continua guardado.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminCores.vermelho),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await _api?.apagar(s.id);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroFonte ? e.mensagem : '$e');
    }
  }

  Future<void> _verHistorico(Sugestao s) async {
    if (_historicoId == s.id) {
      setState(() {
        _historicoId = null;
        _versoes = const [];
      });
      return;
    }
    setState(() {
      _historicoId = s.id;
      _versoes = const [];
    });
    try {
      final versoes = await _api?.historico(s.id) ?? const [];
      if (!mounted || _historicoId != s.id) return;
      setState(() => _versoes = versoes);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = e is ErroFonte ? e.mensagem : '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = _api;

    return Material(
      color: AdminCores.superficie,
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AdminRaios.medio)),
      child: SizedBox(
        width: 400,
        height: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AdminCores.borda)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, size: 18, color: AdminCores.dourado),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sugestões',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sobre a página aberta',
                          style: TextStyle(fontSize: 11, color: AdminCores.textoSecundario),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: widget.aoAlternar,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),

            if (api == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Sugestões precisam de backend. Compile com EQUILINK_API.',
                  style: TextStyle(fontSize: 12, color: AdminCores.textoSecundario),
                ),
              )
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _RotaAtual(rota: widget.rota),
                    const SizedBox(height: 12),
                    _Formulario(
                      titulo: _titulo,
                      texto: _texto,
                      referencia: _referencia,
                      editando: _editandoId != null,
                      enviando: _enviando,
                      aoSalvar: _salvar,
                      aoCancelar: _editandoId == null ? null : _limparFormulario,
                    ),
                    if (_erro != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AdminCores.vermelhoFundo,
                          borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                        ),
                        child: Text(
                          _erro!,
                          style: const TextStyle(fontSize: 11.5, color: AdminCores.vermelho),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'NESTA PÁGINA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: AdminCores.dourado,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_sugestoes.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AdminCores.textoSecundario,
                          ),
                        ),
                        const Spacer(),
                        if (_carregando)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (!_carregando && _sugestoes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Nenhuma sugestão nesta página ainda.',
                          style: TextStyle(fontSize: 12, color: AdminCores.textoSecundario),
                        ),
                      ),
                    for (final s in _sugestoes)
                      _CartaoSugestao(
                        sugestao: s,
                        historicoAberto: _historicoId == s.id,
                        versoes: _historicoId == s.id ? _versoes : const [],
                        aoEditar: () => _editar(s),
                        aoApagar: () => _apagar(s),
                        aoVerHistorico: () => _verHistorico(s),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RotaAtual extends StatelessWidget {
  const _RotaAtual({required this.rota});

  final String rota;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AdminCores.superficieSuave,
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        border: Border.all(color: AdminCores.borda),
      ),
      child: Row(
        children: [
          const Icon(Icons.link, size: 13, color: AdminCores.textoSecundario),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              rota,
              style: const TextStyle(
                fontSize: 11.5,
                fontFamily: 'monospace',
                color: AdminCores.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Formulario extends StatelessWidget {
  const _Formulario({
    required this.titulo,
    required this.texto,
    required this.referencia,
    required this.editando,
    required this.enviando,
    required this.aoSalvar,
    this.aoCancelar,
  });

  final TextEditingController titulo;
  final TextEditingController texto;
  final TextEditingController referencia;
  final bool editando;
  final bool enviando;
  final VoidCallback aoSalvar;
  final VoidCallback? aoCancelar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (editando)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Editando uma sugestão existente',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AdminCores.ambar,
              ),
            ),
          ),
        TextField(
          controller: titulo,
          decoration: const InputDecoration(
            labelText: 'Título',
            hintText: 'Ex.: exportar a lista em CSV',
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: texto,
          maxLines: 4,
          minLines: 3,
          decoration: const InputDecoration(
            labelText: 'Sugestão',
            hintText: 'O que você gostaria que esta página fizesse?',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: referencia,
          decoration: const InputDecoration(
            labelText: 'Onde no código (opcional)',
            hintText: 'arquivo.dart#Widget',
            helperText: 'Ajuda quem implementa a achar o ponto exato.',
            helperStyle: TextStyle(fontSize: 10.5),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (aoCancelar != null)
              TextButton(
                onPressed: enviando ? null : aoCancelar,
                child: const Text('Cancelar'),
              ),
            const Spacer(),
            FilledButton.icon(
              onPressed: enviando ? null : aoSalvar,
              icon: enviando
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(editando ? Icons.save_outlined : Icons.add, size: 15),
              label: Text(editando ? 'Salvar' : 'Adicionar'),
            ),
          ],
        ),
      ],
    );
  }
}

class _CartaoSugestao extends StatelessWidget {
  const _CartaoSugestao({
    required this.sugestao,
    required this.historicoAberto,
    required this.versoes,
    required this.aoEditar,
    required this.aoApagar,
    required this.aoVerHistorico,
  });

  final Sugestao sugestao;
  final bool historicoAberto;
  final List<VersaoSugestao> versoes;
  final VoidCallback aoEditar;
  final VoidCallback aoApagar;
  final VoidCallback aoVerHistorico;

  @override
  Widget build(BuildContext context) {
    final apagada = sugestao.apagada;
    final (cor, fundo) = switch (sugestao.status) {
      StatusSugestao.aberta => (AdminCores.azul, AdminCores.azulFundo),
      StatusSugestao.emAndamento => (AdminCores.ambar, AdminCores.ambarFundo),
      StatusSugestao.implementada => (AdminCores.verde, AdminCores.verdeFundo),
      StatusSugestao.recusada => (AdminCores.vermelho, AdminCores.vermelhoFundo),
      StatusSugestao.apagada => (AdminCores.textoSecundario, AdminCores.superficieSuave),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AdminCores.superficie,
          borderRadius: BorderRadius.circular(AdminRaios.pequeno),
          border: Border.all(color: AdminCores.borda),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    sugestao.titulo,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: apagada ? AdminCores.textoSecundario : AdminCores.texto,
                      decoration: apagada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _Etiqueta(texto: sugestao.status.rotulo, cor: cor, fundo: fundo),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              sugestao.texto,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: apagada ? AdminCores.textoSecundario : AdminCores.texto,
              ),
            ),
            if (sugestao.referencia != null) ...[
              const SizedBox(height: 6),
              Text(
                sugestao.referencia!,
                style: const TextStyle(
                  fontSize: 10.5,
                  fontFamily: 'monospace',
                  color: AdminCores.textoSecundario,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'v${sugestao.versao}',
                  style: const TextStyle(fontSize: 10, color: AdminCores.textoSecundario),
                ),
                const SizedBox(width: 8),
                Text(
                  _quando(sugestao.atualizadoEm),
                  style: const TextStyle(fontSize: 10, color: AdminCores.textoSecundario),
                ),
                const Spacer(),
                if (!apagada) ...[
                  IconButton(
                    tooltip: 'Editar',
                    onPressed: aoEditar,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    visualDensity: VisualDensity.compact,
                  ),
                  IconButton(
                    tooltip: 'Apagar',
                    onPressed: aoApagar,
                    icon: const Icon(Icons.delete_outline, size: 15, color: AdminCores.vermelho),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
                IconButton(
                  tooltip: historicoAberto ? 'Ocultar histórico' : 'Ver histórico',
                  onPressed: aoVerHistorico,
                  icon: Icon(
                    historicoAberto ? Icons.history_toggle_off : Icons.history,
                    size: 15,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            if (historicoAberto)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    if (versoes.isEmpty)
                      const Text(
                        'Carregando histórico...',
                        style: TextStyle(fontSize: 10.5, color: AdminCores.textoSecundario),
                      ),
                    for (final v in versoes) _LinhaVersao(versao: v),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _quando(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

/// Uma linha do histórico: versão, ação, autor e o texto daquela versão.
class _LinhaVersao extends StatelessWidget {
  const _LinhaVersao({required this.versao});

  final VersaoSugestao versao;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              'v${versao.versao}',
              style: const TextStyle(fontSize: 10, color: AdminCores.textoSecundario),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${versao.acaoRotulo} · ${versao.autor}',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  versao.texto,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: AdminCores.textoSecundario, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor, required this.fundo});

  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(999)),
      child: Text(
        texto,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cor),
      ),
    );
  }
}
