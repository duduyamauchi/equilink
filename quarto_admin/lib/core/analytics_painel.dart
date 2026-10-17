import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:quarto_core/quarto_core.dart';

/// Fonte de eventos do painel administrativo.
///
/// Guarda os eventos em memória e aceita importar lotes em JSON — o mesmo
/// formato que o aplicativo exporta e que o `ColetorHttp` envia. Assim o painel
/// funciona tanto para inspecionar a própria sessão quanto para analisar dados
/// vindos de outro dispositivo ou de um backend.
///
/// Quando houver um serviço central, basta carregar os eventos dele: toda a
/// análise trabalha sobre `List<EventoAnalitico>`, sem conhecer a origem.
class ColetorAnaliticoPainel extends ChangeNotifier {
  ColetorAnaliticoPainel({this.limite = 20000});

  final int limite;
  final List<EventoAnalitico> _eventos = [];
  String? _ultimoErro;
  String _origem = 'sessão local';

  List<EventoAnalitico> get eventos => List.unmodifiable(_eventos);
  String? get ultimoErro => _ultimoErro;
  String get origem => _origem;

  String get descricao => 'origem: $_origem';

  /// Registra um evento local (ações feitas no próprio painel).
  void registrar(EventoAnalitico evento) {
    _eventos.add(evento);
    _podar();
    notifyListeners();
  }

  /// Importa eventos de um JSON exportado pelo aplicativo ou por outro painel.
  ///
  /// Aceita três formatos: `{"eventos": [...]}`, uma lista solta `[...]` ou um
  /// único evento `{...}`. Devolve quantos foram aceitos.
  int importarJson(String texto) {
    try {
      final decodificado = jsonDecode(texto.trim());
      final lista = switch (decodificado) {
        {'eventos': final List<dynamic> itens} => itens,
        final List<dynamic> itens => itens,
        final Map<String, dynamic> unico when unico.containsKey('nome') => [unico],
        _ => const <dynamic>[],
      };

      var aceitos = 0;
      for (final item in lista) {
        if (item is! Map<String, dynamic>) continue;
        if ((item['nome'] as String?)?.isEmpty ?? true) continue;
        _eventos.add(EventoAnalitico.fromJson(item));
        aceitos++;
      }
      if (aceitos > 0) {
        _origem = 'importado (${_eventos.length} eventos)';
        _ultimoErro = null;
        _podar();
        // Mantém a ordem cronológica, útil para funil e retenção.
        _eventos.sort((a, b) => a.quando.compareTo(b.quando));
      }
      notifyListeners();
      return aceitos;
    } catch (erro) {
      _ultimoErro = 'JSON inválido: $erro';
      notifyListeners();
      return 0;
    }
  }

  /// Carrega eventos de uma função assíncrona (ex.: API de eventos).
  Future<int> carregarDe(Future<List<EventoAnalitico>> Function() buscar, {String? rotulo}) async {
    try {
      final recebidos = await buscar();
      _eventos
        ..clear()
        ..addAll(recebidos)
        ..sort((a, b) => a.quando.compareTo(b.quando));
      _origem = rotulo ?? 'serviço';
      _ultimoErro = null;
      _podar();
      notifyListeners();
      return recebidos.length;
    } catch (erro) {
      _ultimoErro = 'Falha ao carregar eventos: $erro';
      notifyListeners();
      return 0;
    }
  }

  void limpar() {
    _eventos.clear();
    _origem = 'sessão local';
    _ultimoErro = null;
    notifyListeners();
  }

  void limparErro() {
    if (_ultimoErro == null) return;
    _ultimoErro = null;
    notifyListeners();
  }

  void _podar() {
    if (_eventos.length > limite) {
      _eventos.removeRange(0, _eventos.length - limite);
    }
  }

  /// Exporta os eventos no mesmo formato que o aplicativo usa.
  String exportarJson() => jsonEncode({
    'origem': _origem,
    'eventos': [for (final e in _eventos) e.toJson()],
  });
}

/// Disponibiliza o coletor de analytics para a árvore do painel.
class AnalyticsPainelEscopo extends InheritedNotifier<ColetorAnaliticoPainel> {
  const AnalyticsPainelEscopo({
    super.key,
    required ColetorAnaliticoPainel super.notifier,
    required super.child,
  });

  static ColetorAnaliticoPainel de(BuildContext context) {
    final escopo = context.dependOnInheritedWidgetOfExactType<AnalyticsPainelEscopo>();
    assert(escopo != null, 'AnalyticsPainelEscopo ausente na árvore de widgets.');
    return escopo!.notifier!;
  }
}
