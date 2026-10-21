import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/escopo.dart';
import 'core/tema.dart';
import 'telas/analytics.dart';
import 'telas/cavalos.dart';
import 'telas/novo_cavalo.dart';
import 'telas/editor.dart';
import 'telas/fonte.dart';
import 'telas/painel.dart';
import 'telas/provas.dart';
import 'widgets/sugestoes.dart';

/// Rotas do painel administrativo.
abstract final class RotasAdmin {
  static const painel = '/';
  static const cavalos = '/cavalos';
  static const provas = '/provas';
  static const fonte = '/fonte';
  static const analytics = '/analytics';

  /// Editor de um cavalo específico (`/cavalos/<id>`).
  static String cavalo(String id) => '/cavalos/$id';

  /// Assistente de cadastro, fora da lista para não colidir com `/cavalos/:id`.
  static const novoCavalo = '/cavalos/novo';
}

GoRouter criarRoteadorAdmin() {
  return GoRouter(
    initialLocation: RotasAdmin.painel,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _Moldura(rotaAtual: state.uri.path, child: child),
        routes: [
          GoRoute(path: RotasAdmin.painel, builder: (context, state) => const TelaPainel()),
          GoRoute(
            path: RotasAdmin.cavalos,
            builder: (context, state) => const TelaCavalos(),
            routes: [
              GoRoute(
                path: 'novo',
                builder: (context, state) => const TelaNovoCavalo(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    TelaCavaloEditor(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: RotasAdmin.provas, builder: (context, state) => const TelaProvas()),
          GoRoute(path: RotasAdmin.fonte, builder: (context, state) => const TelaFonte()),
          GoRoute(
            path: RotasAdmin.analytics,
            builder: (context, state) => const TelaAnalytics(),
          ),
        ],
      ),
    ],
  );
}

class _Item {
  const _Item(this.rotulo, this.icone, this.rota);

  final String rotulo;
  final IconData icone;
  final String rota;
}

const _itens = <_Item>[
  _Item('Visão geral', Icons.dashboard_outlined, RotasAdmin.painel),
  _Item('Cavalos', Icons.pets_outlined, RotasAdmin.cavalos),
  _Item('Provas', Icons.emoji_events_outlined, RotasAdmin.provas),
  _Item('Analytics', Icons.insights_outlined, RotasAdmin.analytics),
  _Item('Fonte de dados', Icons.storage_outlined, RotasAdmin.fonte),
];

/// Moldura do painel: barra lateral fixa em telas largas, gaveta em telas
/// estreitas.
class _Moldura extends StatefulWidget {
  const _Moldura({required this.rotaAtual, required this.child});

  final String rotaAtual;
  final Widget child;

  @override
  State<_Moldura> createState() => _MolduraState();
}

class _MolduraState extends State<_Moldura> {
  /// Painel de sugestões aberto.
  bool _sugestoesAbertas = false;

  @override
  Widget build(BuildContext context) {
    final rotaAtual = widget.rotaAtual;
    final child = widget.child;
    final rep = AdminEscopo.de(context);
    final largura = MediaQuery.sizeOf(context).width;
    final usarGaveta = largura < 860;

    final conteudo = Column(
      children: [
        if (rep.erro != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: AdminCores.vermelhoFundo,
                  borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                  border: Border.all(color: AdminCores.vermelho.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 17, color: AdminCores.vermelho),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        rep.erro!,
                        style: const TextStyle(fontSize: 12.5, color: AdminCores.vermelho),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Dispensar',
                      onPressed: rep.limparErro,
                      icon: const Icon(Icons.close, size: 16, color: AdminCores.vermelho),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: child),
              if (!_sugestoesAbertas)
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: _BotaoSugestoes(
                    aoTocar: () => setState(() => _sugestoesAbertas = true),
                  ),
                ),
              if (_sugestoesAbertas)
                Positioned(
                  top: 0,
                  right: 0,
                  bottom: 0,
                  child: PainelSugestoes(
                    rota: rotaAtual,
                    aberto: true,
                    aoAlternar: () => setState(() => _sugestoesAbertas = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );

    if (usarGaveta) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Administração'),
          leading: Builder(
            builder: (context) => IconButton(
              tooltip: 'Menu',
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        drawer: Drawer(
          backgroundColor: AdminCores.barra,
          child: SafeArea(
            child: _Menu(rotaAtual: rotaAtual, aoNavegar: (rota) {
              Navigator.of(context).pop();
              context.go(rota);
            }),
          ),
        ),
        body: conteudo,
      );
    }

    return Scaffold(
      backgroundColor: AdminCores.fundo,
      body: Row(
        children: [
          SizedBox(
            width: 248,
            child: ColoredBox(
              color: AdminCores.barra,
              child: SafeArea(
                child: _Menu(rotaAtual: rotaAtual, aoNavegar: (rota) => context.go(rota)),
              ),
            ),
          ),
          Expanded(child: conteudo),
        ],
      ),
    );
  }
}

/// Botão que abre as sugestões da página atual.
///
/// Fica no canto de todas as páginas: o cliente anota a ideia no momento em que
/// ela surge, sem procurar onde escrever.
class _BotaoSugestoes extends StatelessWidget {
  const _BotaoSugestoes({required this.aoTocar});

  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminCores.barra,
      borderRadius: BorderRadius.circular(999),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_outline, size: 17, color: AdminCores.douradoClaro),
              const SizedBox(width: 8),
              const Text(
                'Sugestões',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({required this.rotaAtual, required this.aoNavegar});

  final String rotaAtual;
  final ValueChanged<String> aoNavegar;

  @override
  Widget build(BuildContext context) {
    final rep = AdminEscopo.de(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 26, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EQUILINK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Painel administrativo',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
        ),
        for (final item in _itens)
          _Destino(
            item: item,
            ativo: rotaAtual == item.rota ||
                (item.rota != RotasAdmin.painel && rotaAtual.startsWith(item.rota)),
            aoTocar: () => aoNavegar(item.rota),
          ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FONTE DE DADOS',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rep.fonte.descricao,
                style: const TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 3),
              Text(
                rep.permiteEscrita ? 'Escrita habilitada' : 'Somente leitura',
                style: TextStyle(
                  fontSize: 11,
                  color: rep.permiteEscrita ? AdminCores.douradoClaro : Colors.white38,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Destino extends StatelessWidget {
  const _Destino({required this.item, required this.ativo, required this.aoTocar});

  final _Item item;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: ativo ? Colors.white.withValues(alpha: 0.09) : Colors.transparent,
        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
        child: InkWell(
          onTap: aoTocar,
          borderRadius: BorderRadius.circular(AdminRaios.pequeno),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(item.icone, size: 19, color: ativo ? AdminCores.douradoClaro : Colors.white60),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.rotulo,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: ativo ? FontWeight.w600 : FontWeight.w500,
                      color: ativo ? Colors.white : Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
