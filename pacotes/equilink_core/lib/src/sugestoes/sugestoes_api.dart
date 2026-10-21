import 'dart:convert';

import 'package:http/http.dart' as http;

import '../fonte_dados.dart';
import 'modelos.dart';

/// Acesso às sugestões do cliente.
///
/// As sugestões vivem no backend, não no acervo: são anotações de trabalho, não
/// dado do haras. Por isso têm cliente próprio, e não entram em `FonteDeDados`.
class SugestoesApi {
  SugestoesApi({
    required this.base,
    this.tempoLimite = const Duration(seconds: 20),
    http.Client? cliente,
  }) : _cliente = cliente ?? http.Client();

  /// Raiz da API (ex.: `/api`).
  final String base;
  final Duration tempoLimite;
  final http.Client _cliente;

  Map<String, String> get _cabecalhos => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri _rota(String caminho) => Uri.parse('$base$caminho');

  /// Lista as sugestões do usuário, opcionalmente de uma página.
  ///
  /// [incluirApagadas] existe para o histórico: o cliente vê o que apagou.
  Future<List<Sugestao>> listar({
    String? rota,
    bool incluirApagadas = false,
  }) async {
    final params = <String, String>{
      'rota': ?rota,
      if (incluirApagadas) 'apagadas': '1',
    };
    final uri = _rota('/sugestoes').replace(queryParameters: params.isEmpty ? null : params);
    final resposta = await _cliente.get(uri, headers: _cabecalhos).timeout(tempoLimite);
    if (resposta.statusCode != 200) {
      if (resposta.statusCode == 401) {
        throw const ErroAutenticacao('Sessão expirada.', status: 401);
      }
      throw ErroFonte(
        'A API respondeu ${resposta.statusCode} ao listar as sugestões.',
        status: resposta.statusCode,
      );
    }
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final lista = (corpo['sugestoes'] as List?) ?? const [];
    return [
      for (final s in lista)
        if (s is Map<String, dynamic>) Sugestao.fromJson(s),
    ];
  }

  /// Cria uma sugestão e devolve a versão gravada.
  Future<Sugestao> criar({
    required String rota,
    required String titulo,
    required String texto,
    String? referencia,
    PrioridadeSugestao prioridade = PrioridadeSugestao.normal,
  }) async {
    final resposta = await _cliente
        .post(
          _rota('/sugestoes'),
          headers: _cabecalhos,
          body: jsonEncode({
            'rota': rota,
            'titulo': titulo,
            'texto': texto,
            if (referencia != null && referencia.trim().isNotEmpty) 'referencia': referencia,
            'prioridade': prioridade.codigo,
          }),
        )
        .timeout(tempoLimite);
    return _uma(resposta, 201);
  }

  /// Edita o texto, o título, a referência ou a prioridade.
  Future<Sugestao> editar(
    String id, {
    String? titulo,
    String? texto,
    String? referencia,
    PrioridadeSugestao? prioridade,
  }) async {
    final resposta = await _cliente
        .put(
          _rota('/sugestoes/$id'),
          headers: _cabecalhos,
          body: jsonEncode({
            'titulo': ?titulo,
            'texto': ?texto,
            'referencia': ?referencia,
            'prioridade': ?prioridade?.codigo,
          }),
        )
        .timeout(tempoLimite);
    return _uma(resposta, 200);
  }

  /// Muda a situação (aberta, em andamento, implementada, recusada).
  Future<Sugestao> alterarStatus(String id, StatusSugestao status) async {
    final resposta = await _cliente
        .patch(
          _rota('/sugestoes/$id'),
          headers: _cabecalhos,
          body: jsonEncode({'status': status.codigo}),
        )
        .timeout(tempoLimite);
    return _uma(resposta, 200);
  }

  /// Apaga (exclusão lógica: o histórico permanece).
  Future<void> apagar(String id) async {
    final resposta = await _cliente
        .delete(_rota('/sugestoes/$id'), headers: _cabecalhos)
        .timeout(tempoLimite);
    if (resposta.statusCode != 204 && resposta.statusCode != 200) {
      _recusar(resposta);
    }
  }

  /// Versões anteriores de uma sugestão, da mais nova para a mais antiga.
  Future<List<VersaoSugestao>> historico(String id) async {
    final resposta = await _cliente
        .get(_rota('/sugestoes/$id/historico'), headers: _cabecalhos)
        .timeout(tempoLimite);
    if (resposta.statusCode != 200) {
      throw ErroFonte(
        'A API respondeu ${resposta.statusCode} ao ler o histórico.',
        status: resposta.statusCode,
      );
    }
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    final lista = (corpo['versoes'] as List?) ?? const [];
    return [
      for (final v in lista)
        if (v is Map<String, dynamic>) VersaoSugestao.fromJson(v),
    ];
  }

  Sugestao _uma(http.Response resposta, int esperado) {
    if (resposta.statusCode != esperado) _recusar(resposta);
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
    return Sugestao.fromJson(corpo);
  }

  Never _recusar(http.Response resposta) {
    String mensagem = 'A API recusou a operação (${resposta.statusCode}).';
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map && corpo['erro'] is String) mensagem = corpo['erro'] as String;
    } catch (_) {}
    if (resposta.statusCode == 401) {
      throw ErroAutenticacao('Sessão expirada.', status: 401);
    }
    throw ErroFonte(mensagem, status: resposta.statusCode);
  }

  void encerrar() => _cliente.close();
}
