import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quarto_core/quarto_core.dart';

import '../core/escopo.dart';
import '../core/tema.dart';
import '../rotas.dart';
import '../widgets/comuns.dart';
import 'editor_formularios.dart';

/// Editor completo de um animal: ficha, genealogia, provas, mídias e baia.
class TelaCavaloEditor extends StatefulWidget {
  const TelaCavaloEditor({super.key, required this.id});

  final String id;

  @override
  State<TelaCavaloEditor> createState() => _TelaCavaloEditorState();
}

class _TelaCavaloEditorState extends State<TelaCavaloEditor> {
  int _aba = 0;

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);
    final cavalo = rep.cavaloPorId(widget.id);

    if (cavalo == null) {
      return Center(
        child: Painel(
          child: Vazio(
            icone: Icons.search_off,
            titulo: 'Animal não encontrado',
            descricao: 'Ele pode ter sido removido do acervo.',
            acao: FilledButton(
              onPressed: () => context.go(RotasAdmin.cavalos),
              child: const Text('Voltar para a lista'),
            ),
          ),
        ),
      );
    }

    final baia = rep.baias.where((b) => b.cavaloId == cavalo.id).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            IconButton(
              tooltip: 'Voltar',
              onPressed: () => context.go(RotasAdmin.cavalos),
              icon: const Icon(Icons.arrow_back, size: 20),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CabecalhoSecao(
                titulo: cavalo.nome,
                subtitulo: '${cavalo.registro} • ${cavalo.raca}',
                icone: Icons.pets_outlined,
              ),
            ),
            if (cavalo.principal)
              const Etiqueta(
                'Destaque no app',
                cor: AdminCores.verde,
                fundo: AdminCores.verdeFundo,
                icone: Icons.star,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Painel(
          padding: const EdgeInsets.all(8),
          child: Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < _abas.length; i++)
                _Aba(
                  rotulo: _abas[i].$1,
                  contagem: _abas[i].$2(cavalo, baia),
                  ativo: _aba == i,
                  aoTocar: () => setState(() => _aba = i),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        switch (_aba) {
          0 => AbaFicha(cavalo: cavalo),
          1 => AbaGenealogia(cavalo: cavalo),
          2 => AbaProvas(cavalo: cavalo),
          3 => AbaMidias(cavalo: cavalo),
          _ => AbaBaia(cavalo: cavalo, baia: baia),
        },
      ],
    );
  }

  static final _abas = <(String, int? Function(Cavalo, Baia?))>[
    ('Ficha', (_, _) => null),
    ('Genealogia', (_, _) => null),
    ('Provas', (c, _) => c.provas.length),
    ('Mídias', (c, _) => c.midias.length),
    ('Baia', (_, b) => b?.manejo.length),
  ];
}

class _Aba extends StatelessWidget {
  const _Aba({
    required this.rotulo,
    required this.ativo,
    required this.aoTocar,
    this.contagem,
  });

  final String rotulo;
  final bool ativo;
  final VoidCallback aoTocar;
  final int? contagem;

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rotulo,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
                  color: ativo ? Colors.white : AdminCores.textoSecundario,
                ),
              ),
              if (contagem != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: ativo ? Colors.white24 : AdminCores.superficieSuave,
                    borderRadius: BorderRadius.circular(AdminRaios.total),
                  ),
                  child: Text(
                    '$contagem',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: ativo ? Colors.white : AdminCores.textoSecundario,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
