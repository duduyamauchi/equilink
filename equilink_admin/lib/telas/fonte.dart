import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:equilink_core/equilink_core.dart';

import '../core/escopo.dart';
import '../core/tema.dart';
import '../widgets/comuns.dart';

/// Inspeção da fonte de dados: mostra qual origem está ativa, permite exportar
/// e importar o acervo em JSON e recarregar do servidor.
///
/// É a tela que sustenta a troca de mock por banco de dados: com a mesma
/// estrutura exportada, subir um backend é servir e aceitar este JSON.
class TelaFonte extends StatefulWidget {
  const TelaFonte({super.key});

  @override
  State<TelaFonte> createState() => _TelaFonteState();
}

class _TelaFonteState extends State<TelaFonte> {
  final _controlador = TextEditingController();
  bool _mostrarEditor = false;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);
    final json = const JsonEncoder.withIndent('  ').convert(rep.acervo.toJson());

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const CabecalhoSecao(
          titulo: 'Fonte de dados',
          subtitulo: 'Origem atual do acervo e ferramentas de migração',
          icone: Icons.storage_outlined,
        ),
        const SizedBox(height: 16),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CabecalhoSecao(titulo: 'Origem ativa', icone: Icons.hub_outlined),
              const SizedBox(height: 16),
              Wrap(
                spacing: 28,
                runSpacing: 18,
                children: [
                  SizedBox(
                    width: 260,
                    child: Campo(rotulo: 'Implementação', valor: rep.fonte.descricao),
                  ),
                  SizedBox(
                    width: 150,
                    child: Campo(
                      rotulo: 'Escrita',
                      valor: rep.permiteEscrita ? 'Habilitada' : 'Somente leitura',
                    ),
                  ),
                  SizedBox(width: 120, child: Campo(rotulo: 'Versão', valor: '${rep.acervo.versao}')),
                  SizedBox(width: 130, child: Campo(rotulo: 'Cavalos', valor: '${rep.cavalos.length}')),
                  SizedBox(width: 110, child: Campo(rotulo: 'Baias', valor: '${rep.baias.length}')),
                ],
              ),
              const SizedBox(height: 18),
              const NotaRodape(
                'Para plugar um backend, compile com '
                '--dart-define=EQUILINK_FONTE=http --dart-define=EQUILINK_API=<endereço>. '
                'A API precisa responder GET /acervo e aceitar PUT /acervo com o mesmo JSON '
                'exportado abaixo. Nenhuma tela muda.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Painel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CabecalhoSecao(
                titulo: 'Ferramentas',
                subtitulo: 'Exportar, importar e recarregar o acervo',
                icone: Icons.build_outlined,
                acao: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => rep.carregar(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Recarregar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: json));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Acervo copiado como JSON.')),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined, size: 16),
                    label: const Text('Copiar JSON do acervo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _mostrarEditor = !_mostrarEditor),
                    icon: Icon(_mostrarEditor ? Icons.visibility_off : Icons.visibility, size: 16),
                    label: Text(_mostrarEditor ? 'Ocultar JSON' : 'Visualizar JSON'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const CabecalhoSecao(
                titulo: 'Importar acervo',
                subtitulo:
                    'Cole um JSON no mesmo formato para substituir todo o acervo — útil para '
                    'migrar de um backend para outro',
                icone: Icons.upload_file_outlined,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controlador,
                maxLines: 8,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '{ "versao": 1, "cavalos": [...], "baias": [...] }',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: () => _importar(context, rep),
                    icon: const Icon(Icons.save_alt, size: 16),
                    label: const Text('Importar e gravar'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => _controlador.clear(),
                    child: const Text('Limpar campo'),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_mostrarEditor) ...[
          const SizedBox(height: 16),
          Painel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CabecalhoSecao(titulo: 'Acervo atual em JSON', icone: Icons.code),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 420),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminCores.superficieSuave,
                    borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                    border: Border.all(color: AdminCores.borda),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5, height: 1.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _importar(BuildContext context, Repositorio rep) async {
    final texto = _controlador.text.trim();
    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cole um JSON antes de importar.')),
      );
      return;
    }

    final Acervo novo;
    try {
      novo = Acervo.fromJson(jsonDecode(texto) as Map<String, dynamic>);
    } catch (erro) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON inválido: $erro')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Substituir o acervo'),
        content: Text(
          'O acervo atual será trocado por ${novo.cavalos.length} cavalos e '
          '${novo.baias.length} baias. A alteração é gravada na fonte ativa.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Substituir')),
        ],
      ),
    );
    if (confirmar != true) return;

    final ok = await rep.substituirAcervo(novo);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Acervo substituído: ${novo.cavalos.length} cavalos, ${novo.baias.length} baias.'
              : rep.erro ?? 'Não foi possível gravar.',
        ),
      ),
    );
  }
}

/// Faixa discreta de explicação reutilizada nas telas do painel.
class NotaRodape extends StatelessWidget {
  const NotaRodape(this.texto, {super.key});

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
