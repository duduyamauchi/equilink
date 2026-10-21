import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quarto_core/quarto_core.dart';

import '../core/escopo.dart';
import '../core/tema.dart';
import '../rotas.dart';
import '../widgets/comuns.dart';

/// Lista de animais do acervo, com busca e ações de criar, duplicar e remover.
class TelaCavalos extends StatefulWidget {
  const TelaCavalos({super.key});

  @override
  State<TelaCavalos> createState() => _TelaCavalosState();
}

class _TelaCavalosState extends State<TelaCavalos> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);
    final termo = _busca.trim().toLowerCase();
    final lista = termo.isEmpty
        ? rep.cavalos
        : [
            for (final c in rep.cavalos)
              if (c.nome.toLowerCase().contains(termo) ||
                  c.registro.toLowerCase().contains(termo) ||
                  c.pelagem.toLowerCase().contains(termo))
                c,
          ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CabecalhoSecao(
          titulo: 'Cavalos',
          subtitulo: plural(rep.cavalos.length, 'animal cadastrado', 'animais cadastrados'),
          icone: Icons.pets_outlined,
          acao: FilledButton.icon(
            onPressed: () => _novo(context, rep),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Novo cavalo'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (v) => setState(() => _busca = v),
          decoration: const InputDecoration(
            hintText: 'Buscar por nome, registro ou pelagem',
            prefixIcon: Icon(Icons.search, size: 18),
          ),
        ),
        const SizedBox(height: 16),
        if (lista.isEmpty)
          Painel(
            child: Vazio(
              icone: Icons.search_off,
              titulo: termo.isEmpty ? 'Nenhum animal cadastrado' : 'Nada encontrado',
              descricao: termo.isEmpty
                  ? 'Cadastre o primeiro cavalo para começar a preencher o acervo.'
                  : 'Nenhum animal corresponde a "$_busca".',
              acao: termo.isEmpty
                  ? FilledButton.icon(
                      onPressed: () => _novo(context, rep),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Novo cavalo'),
                    )
                  : null,
            ),
          ),
        for (final cavalo in lista)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _CartaoCavalo(cavalo: cavalo),
          ),
      ],
    );
  }

  /// Cria um animal em branco a partir do modelo do principal e abre o editor.
  Future<void> _novo(BuildContext context, Repositorio rep) async {
    final base = rep.cavalo;
    if (base == null) return;

    final nome = TextEditingController();
    final registro = TextEditingController();
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Novo cavalo'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nome,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: registro,
                decoration: const InputDecoration(labelText: 'Registro ABQM'),
              ),
              const SizedBox(height: 12),
              const Text(
                'O animal é criado com a ficha do haras já preenchida e abre no editor '
                'para completar os dados.',
                style: TextStyle(fontSize: 12, color: AdminCores.textoSecundario, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Criar')),
        ],
      ),
    );
    if (confirmar != true || nome.text.trim().isEmpty) return;

    final id = nome.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final novo = base.copiarCom(
      id: id.isEmpty ? rep.novoId('cavalo') : id,
      nome: nome.text.trim().toUpperCase(),
      registro: registro.text.trim().isEmpty ? 'SEM REGISTRO' : registro.text.trim().toUpperCase(),
      principal: false,
      provas: const [],
      midias: const [],
      descricao: 'Animal cadastrado pelo painel administrativo.',
    );

    final ok = await rep.salvarCavalo(novo);
    if (!context.mounted) return;
    if (ok) {
      context.go(RotasAdmin.cavalo(novo.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(rep.erro ?? 'Não foi possível salvar.')),
      );
    }
  }
}

class _CartaoCavalo extends StatelessWidget {
  const _CartaoCavalo({required this.cavalo});

  final Cavalo cavalo;

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);
    final baia = rep.baias.where((b) => b.cavaloId == cavalo.id).firstOrNull;

    return Painel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AdminRaios.pequeno),
            child: SizedBox(
              width: 52,
              height: 52,
              child: Image.asset(
                cavalo.fotoPerfil,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AdminCores.superficieSuave,
                  child: Icon(Icons.pets, color: AdminCores.textoSecundario),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        cavalo.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (cavalo.principal) ...[
                      const SizedBox(width: 8),
                      const Etiqueta(
                        'Em destaque no app',
                        cor: AdminCores.verde,
                        fundo: AdminCores.verdeFundo,
                        icone: Icons.star,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${cavalo.registro} • ${cavalo.sexo.rotulo} • ${cavalo.pelagem} • '
                  '${cavalo.provas.length} provas • ${cavalo.midias.length} mídias',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, color: AdminCores.textoSecundario),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Etiqueta(
                      baia == null ? 'Sem baia' : 'Baia ${baia.numero}',
                      cor: baia == null ? AdminCores.textoSecundario : AdminCores.azul,
                      fundo: baia == null ? AdminCores.superficieSuave : AdminCores.azulFundo,
                    ),
                    if (baia != null) ...[
                      const SizedBox(width: 6),
                      Etiqueta.status(baia.status.rotulo),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!cavalo.principal)
            IconButton(
              tooltip: 'Definir como destaque do app',
              onPressed: () async {
                await rep.definirPrincipal(cavalo.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${cavalo.nome} agora é o destaque do aplicativo.')),
                );
              },
              icon: const Icon(Icons.star_border, size: 19),
            ),
          IconButton(
            tooltip: 'Editar',
            onPressed: () => context.go(RotasAdmin.cavalo(cavalo.id)),
            icon: const Icon(Icons.edit_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Duplicar',
            onPressed: () async {
              final copia = cavalo.copiarCom(
                id: rep.novoId('copia'),
                nome: '${cavalo.nome} (CÓPIA)',
                principal: false,
              );
              await rep.salvarCavalo(copia);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cópia de ${cavalo.nome} criada.')),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 19),
          ),
          IconButton(
            tooltip: 'Remover',
            onPressed: () => _remover(context, rep),
            icon: const Icon(Icons.delete_outline, size: 19, color: AdminCores.vermelho),
          ),
        ],
      ),
    );
  }

  Future<void> _remover(BuildContext context, Repositorio rep) async {
    final baia = rep.baias.where((b) => b.cavaloId == cavalo.id).firstOrNull;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover cavalo'),
        content: Text(
          '${cavalo.nome} será removido do acervo'
          '${baia != null ? ', junto com a baia ${baia.numero} que o abriga' : ''}. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AdminCores.vermelho),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await rep.removerCavalo(cavalo.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${cavalo.nome} removido.')),
    );
  }
}
