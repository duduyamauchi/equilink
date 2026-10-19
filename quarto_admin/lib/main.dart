import 'package:flutter/material.dart';
import 'package:quarto_core/quarto_core.dart';

import 'core/analytics_painel.dart';
import 'core/escopo.dart';
import 'core/tema.dart';
import 'package:quarto_ui/quarto_ui.dart';
import 'rotas.dart';

void main() {
  runApp(const PainelApp());
}

/// Painel administrativo do Quarto de Milha.
///
/// Compartilha o mesmo núcleo de dados do aplicativo do usuário: ler e gravar
/// aqui reflete no app, porque ambos conversam com a mesma [FonteDeDados].
class PainelApp extends StatefulWidget {
  const PainelApp({super.key, this.fonte, this.coletorAnalitico});

  /// Permite injetar uma fonte nos testes; em produção vem de [Ambiente].
  final FonteDeDados? fonte;

  /// Permite injetar o coletor de analytics nos testes.
  final ColetorAnaliticoPainel? coletorAnalitico;

  @override
  State<PainelApp> createState() => _PainelAppState();
}

class _PainelAppState extends State<PainelApp> {
  late final Repositorio _repositorio;
  late final ColetorAnaliticoPainel _analytics;
  late final _roteador = criarRoteadorAdmin();

  @override
  void initState() {
    super.initState();
    // O painel tem o próprio coletor: registra as ações feitas aqui e aceita
    // importar os eventos vindos do aplicativo.
    _analytics = widget.coletorAnalitico ?? ColetorAnaliticoPainel();
    _repositorio = Repositorio(
      widget.fonte ?? Ambiente.criarFonte(),
      analytics: Analytics(
        _ColetorDoPainel(_analytics),
        usuario: 'painel',
      ),
    );
    _repositorio.carregar();
  }

  @override
  void dispose() {
    _roteador.dispose();
    _analytics.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Quarto de Milha — Administração',
      debugShowCheckedModeBanner: false,
      theme: construirTemaAdmin(),
      routerConfig: _roteador,
      locale: const Locale('pt', 'BR'),
      builder: (context, child) {
        return EscopoUi(
          paleta: paletaDoPainel,
          child: AnalyticsPainelEscopo(
          notifier: _analytics,
          child: AdminEscopo(
            repositorio: _repositorio,
            child: ListenableBuilder(
              listenable: _repositorio,
              builder: (context, _) => _Portao(
                rep: _repositorio,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}

/// Só libera o painel quando o acervo está disponível.
class _Portao extends StatelessWidget {
  const _Portao({required this.rep, required this.child});

  final Repositorio rep;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    switch (rep.estado) {
      case EstadoCarga.pronto:
        return child;
      case EstadoCarga.erro:
        return Scaffold(
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 38, color: AdminCores.vermelho),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível carregar o acervo',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rep.erro ?? 'Erro desconhecido.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AdminCores.textoSecundario,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fonte: ${rep.fonte.descricao}',
                      style: const TextStyle(fontSize: 11.5, color: AdminCores.textoSecundario),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: rep.carregar,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      case EstadoCarga.inicial:
      case EstadoCarga.carregando:
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(strokeWidth: 2.4),
                SizedBox(height: 16),
                Text(
                  'Carregando o acervo...',
                  style: TextStyle(fontSize: 13.5, color: AdminCores.textoSecundario),
                ),
              ],
            ),
          ),
        );
    }
  }
}


/// Faz o coletor do painel funcionar como destino de telemetria do núcleo.
class _ColetorDoPainel implements ColetorAnalytics {
  _ColetorDoPainel(this._painel);

  final ColetorAnaliticoPainel _painel;

  @override
  String get descricao => 'painel administrativo';
  @override
  String? get ultimoErro => _painel.ultimoErro;
  @override
  void registrar(EventoAnalitico evento) => _painel.registrar(evento);
  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {
    for (final e in eventos) {
      _painel.registrar(e);
    }
  }
  @override
  Future<void> encerrar() async {}
}
