import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics_painel.dart';
import '../core/escopo.dart';
import '../core/tema.dart';
import 'analytics_abas.dart';
import '../widgets/comuns.dart';

/// Painel de analytics: uso do aplicativo, funis, retenção e eventos.
///
/// Os dados vêm do [ColetorAnaliticoPainel], que guarda os eventos desta sessão
/// e aceita importar um lote em JSON — o mesmo formato que o aplicativo exporta.
class TelaAnalytics extends StatefulWidget {
  const TelaAnalytics({super.key});

  @override
  State<TelaAnalytics> createState() => _TelaAnalyticsState();
}

class _TelaAnalyticsState extends State<TelaAnalytics> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final escopo = AnalyticsPainelEscopo.de(context);
    final rep = AdminEscopo.de(context);
    final eventos = escopo.eventos;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CabecalhoSecao(
          titulo: 'Analytics',
          subtitulo: '${escopo.descricao} • ${eventos.length} eventos nesta sessão',
          icone: Icons.insights_outlined,
          acao: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => escopo.limpar(),
                icon: const Icon(Icons.delete_sweep_outlined, size: 16),
                label: const Text('Limpar'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _importar(context, escopo),
                icon: const Icon(Icons.upload_file_outlined, size: 16),
                label: const Text('Importar eventos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Painel(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < _abas.length; i++)
                _Aba(
                  rotulo: _abas[i],
                  ativo: _aba == i,
                  aoTocar: () => setState(() => _aba = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (escopo.ultimoErro != null) ...[
          FaixaErro(mensagem: escopo.ultimoErro!, aoFechar: escopo.limparErro),
          const SizedBox(height: 16),
        ],
        switch (_aba) {
          0 => AbaVisaoGeral(eventos: eventos, escopo: escopo),
          1 => AbaEventos(eventos: eventos),
          2 => AbaFunil(eventos: eventos),
          3 => AbaRetencao(eventos: eventos),
          _ => AbaOrigem(escopo: escopo, repositorio: rep),
        },
      ],
    );
  }

  static const _abas = ['Visão geral', 'Eventos', 'Funil', 'Retenção', 'Origem'];

  Future<void> _importar(BuildContext context, ColetorAnaliticoPainel escopo) async {
    final controlador = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Importar eventos'),
        content: SizedBox(
          width: 560,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Cole o JSON exportado pelo aplicativo (formato '
                '{"sessao": "...", "eventos": [...]}) ou uma lista de eventos.',
                style: TextStyle(fontSize: 12, color: AdminCores.textoSecundario, height: 1.45),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controlador,
                maxLines: 8,
                autofocus: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(hintText: '{"eventos": [ ... ]}'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Importar')),
        ],
      ),
    );
    if (confirmar != true) return;

    final quantos = escopo.importarJson(controlador.text);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          quantos > 0
              ? '$quantos eventos importados.'
              : 'Nenhum evento reconhecido. Verifique o JSON.',
        ),
      ),
    );
  }
}

class _Aba extends StatelessWidget {
  const _Aba({required this.rotulo, required this.ativo, required this.aoTocar});

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? AdminCores.barra : Colors.transparent,
      borderRadius: BorderRadius.circular(AdminRaios.pequeno),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            rotulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
              color: ativo ? Colors.white : AdminCores.textoSecundario,
            ),
          ),
        ),
      ),
    );
  }
}

/// Atalho para o painel de analytics a partir de outras telas.
void abrirAnalytics(BuildContext context) => context.go('/analytics');
