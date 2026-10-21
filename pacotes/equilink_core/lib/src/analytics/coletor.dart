import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'evento.dart';

/// Destino dos eventos analíticos.
///
/// O aplicativo nunca fala com um banco ou serviço diretamente: ele entrega
/// eventos a um [ColetorAnalytics]. Trocar o destino (memória, arquivo local,
/// HTTP, BigQuery) é trocar a implementação — nenhuma tela muda.
///
/// Implementações devem ser tolerantes a falha: [registrar] nunca lança. Um
/// erro de telemetria não pode derrubar a ação que o usuário pediu.
abstract interface class ColetorAnalytics {
  /// Nome curto exibido no painel (ex.: `memória`, `HTTP`).
  String get descricao;

  /// Envia um evento. Não lança; falhas são reportadas em [ultimoErro].
  void registrar(EventoAnalitico evento);

  /// Envia vários eventos de uma vez (útil em lote e ao trocar de tela).
  void registrarVarios(Iterable<EventoAnalitico> eventos);

  /// Última falha observada, para diagnóstico no painel.
  String? get ultimoErro;

  /// Libera recursos.
  Future<void> encerrar();
}

/// Coletor que guarda eventos em memória, com limite de retenção.
///
/// É o destino padrão: permite que o painel administrativo leia o que o
/// aplicativo registrou sem nenhum servidor. Os eventos vivem apenas na
/// sessão do processo.
class ColetorMemoria implements ColetorAnalytics {
  ColetorMemoria({this.limite = 5000});

  /// Quantidade máxima de eventos mantidos; os mais antigos são descartados.
  final int limite;

  final List<EventoAnalitico> _eventos = [];
  String? _ultimoErro;

  /// Eventos registrados, do mais antigo para o mais recente.
  List<EventoAnalitico> get eventos => List.unmodifiable(_eventos);

  @override
  String get descricao => 'memória (${_eventos.length} eventos)';

  @override
  String? get ultimoErro => _ultimoErro;

  @override
  void registrar(EventoAnalitico evento) {
    try {
      _eventos.add(evento);
      if (_eventos.length > limite) {
        _eventos.removeRange(0, _eventos.length - limite);
      }
    } catch (erro) {
      _ultimoErro = 'Falha ao registrar evento: $erro';
    }
  }

  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {
    for (final e in eventos) {
      registrar(e);
    }
  }

  /// Remove todos os eventos (usado nos testes e no painel).
  void limpar() {
    _eventos.clear();
  }

  @override
  Future<void> encerrar() async {}
}

/// Coletor que envia eventos para uma API em lotes.
///
/// Contrato esperado do backend:
///
/// | Método | Rota       | Corpo                        |
/// |--------|------------|------------------------------|
/// | POST   | `/eventos` | `{ "eventos": [Evento, ...] }` |
///
/// Os eventos são acumulados e enviados em lotes para reduzir requisições; o
/// envio é assíncrono e uma falha apenas repõe os eventos na fila.
class ColetorHttp implements ColetorAnalytics {
  ColetorHttp({
    required this.base,
    this.cabecalhos = const {},
    this.tamanhoLote = 20,
    this.intervalo = const Duration(seconds: 10),
    this.tempoLimite = const Duration(seconds: 15),
    http.Client? cliente,
  }) : _cliente = cliente ?? http.Client();

  /// Raiz da API (ex.: `https://api.haras.app`).
  final String base;
  final Map<String, String> cabecalhos;
  final int tamanhoLote;
  final Duration intervalo;
  final Duration tempoLimite;
  final http.Client _cliente;

  final List<EventoAnalitico> _fila = [];
  Timer? _agendador;
  String? _ultimoErro;
  bool _enviando = false;

  @override
  String get descricao => 'HTTP ($base)';

  @override
  String? get ultimoErro => _ultimoErro;

  @override
  void registrar(EventoAnalitico evento) {
    try {
      _fila.add(evento);
      if (_fila.length >= tamanhoLote) {
        unawaited(_enviar());
      } else {
        _agendar();
      }
    } catch (erro) {
      _ultimoErro = 'Falha ao enfileirar evento: $erro';
    }
  }

  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {
    for (final e in eventos) {
      registrar(e);
    }
  }

  void _agendar() {
    _agendador?.cancel();
    _agendador = Timer(intervalo, () => unawaited(_enviar()));
  }

  /// Envia o lote pendente. Nunca lança.
  Future<void> _enviar() async {
    if (_enviando || _fila.isEmpty) return;
    _enviando = true;
    final lote = List<EventoAnalitico>.from(_fila);
    _fila.clear();
    try {
      final resposta = await _cliente
          .post(
            Uri.parse('$base/eventos'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              ...cabecalhos,
            },
            body: jsonEncode({'eventos': [for (final e in lote) e.toJson()]}),
          )
          .timeout(tempoLimite);
      if (resposta.statusCode >= 400) {
        throw StateError('HTTP ${resposta.statusCode}');
      }
      _ultimoErro = null;
    } catch (erro) {
      // Devolve o lote para a fila: perder telemetria por indisponibilidade
      // momentânea seria pior do que reenviar.
      _fila.insertAll(0, lote);
      _ultimoErro = 'Falha ao enviar eventos: $erro';
      debugPrint('[analytics] $_ultimoErro');
      _agendar();
    } finally {
      _enviando = false;
    }
  }

  @override
  Future<void> encerrar() async {
    _agendador?.cancel();
    await _enviar();
    _cliente.close();
  }
}

/// Coletor que apenas imprime no console de depuração.
///
/// Útil durante o desenvolvimento para ver o que está sendo instrumentado.
class ColetorConsole implements ColetorAnalytics {
  ColetorConsole({void Function(String)? imprimir})
    : imprimir = imprimir ?? debugPrint;

  final void Function(String) imprimir;
  String? _ultimoErro;

  @override
  String get descricao => 'console (depuração)';

  @override
  String? get ultimoErro => _ultimoErro;

  @override
  void registrar(EventoAnalitico evento) {
    try {
      imprimir('[analytics] ${evento.toJson()}');
    } catch (erro) {
      _ultimoErro = 'Falha ao imprimir evento: $erro';
    }
  }

  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {
    for (final e in eventos) {
      registrar(e);
    }
  }

  @override
  Future<void> encerrar() async {}
}

/// Coletor que não faz nada, usado quando a telemetria está desligada.
class ColetorNulo implements ColetorAnalytics {
  const ColetorNulo();

  @override
  String get descricao => 'desligado';

  @override
  String? get ultimoErro => null;

  @override
  void registrar(EventoAnalitico evento) {}

  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {}

  @override
  Future<void> encerrar() async {}
}

/// Encaminha cada evento para vários coletores.
///
/// Permite, por exemplo, gravar em memória para o painel local **e** enviar
/// para a API ao mesmo tempo.
class ColetorComposto implements ColetorAnalytics {
  ColetorComposto(this.coletores);

  final List<ColetorAnalytics> coletores;

  @override
  String get descricao => coletores.map((c) => c.descricao).join(' + ');

  @override
  String? get ultimoErro {
    for (final c in coletores) {
      if (c.ultimoErro != null) return c.ultimoErro;
    }
    return null;
  }

  @override
  void registrar(EventoAnalitico evento) {
    for (final c in coletores) {
      c.registrar(evento);
    }
  }

  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) {
    final lista = eventos.toList();
    for (final c in coletores) {
      c.registrarVarios(lista);
    }
  }

  @override
  Future<void> encerrar() async {
    for (final c in coletores) {
      await c.encerrar();
    }
  }
}
