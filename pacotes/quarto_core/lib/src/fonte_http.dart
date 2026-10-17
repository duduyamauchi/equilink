import 'dart:convert';

import 'package:http/http.dart' as http;

import 'fonte_dados.dart';

/// Fonte de dados servida por uma API REST.
///
/// Contrato esperado do backend:
///
/// | Método | Rota      | Corpo                 | Resposta            |
/// |--------|-----------|-----------------------|---------------------|
/// | GET    | `/acervo` | —                     | `Acervo` em JSON    |
/// | PUT    | `/acervo` | `Acervo` em JSON      | `Acervo` gravado    |
///
/// O cabeçalho `Authorization` é enviado quando [cabecalhos] traz um token.
/// Para um backend com rotas por recurso (`/cavalos`, `/baias`), basta
/// implementar [FonteDeDados] de novo — nenhuma tela precisa mudar.
class FonteHttp implements FonteDeDados {
  FonteHttp({
    required this.base,
    this.cabecalhos = const {},
    this.tempoLimite = const Duration(seconds: 20),
    http.Client? cliente,
  }) : _cliente = cliente ?? http.Client();

  /// Raiz da API, sem barra final (ex.: `https://api.haras.app`).
  final String base;
  final Map<String, String> cabecalhos;
  final Duration tempoLimite;
  final http.Client _cliente;

  @override
  String get descricao => 'API REST ($base)';

  @override
  bool get permiteEscrita => true;

  Uri get _endpoint => Uri.parse('$base/acervo');

  Map<String, String> get _cabecalhosPadrao => {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
    ...cabecalhos,
  };

  @override
  Future<Acervo> carregar() async {
    try {
      final resposta = await _cliente.get(_endpoint, headers: _cabecalhosPadrao).timeout(tempoLimite);
      if (resposta.statusCode != 200) {
        throw ErroFonte(
          'A API respondeu ${resposta.statusCode} ao carregar o acervo.',
          status: resposta.statusCode,
        );
      }
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      return Acervo.fromJson(corpo);
    } on ErroFonte {
      rethrow;
    } catch (erro) {
      throw ErroFonte('Não foi possível carregar o acervo da API.', causa: erro);
    }
  }

  @override
  Future<Acervo> salvar(Acervo acervo) async {
    try {
      final resposta = await _cliente
          .put(_endpoint, headers: _cabecalhosPadrao, body: jsonEncode(acervo.toJson()))
          .timeout(tempoLimite);
      if (resposta.statusCode != 200 && resposta.statusCode != 201) {
        throw ErroFonte(
          'A API recusou a gravação (${resposta.statusCode}).',
          status: resposta.statusCode,
        );
      }
      if (resposta.bodyBytes.isEmpty) return acervo.copiarCom(versao: acervo.versao + 1);
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      return Acervo.fromJson(corpo);
    } on ErroFonte {
      rethrow;
    } catch (erro) {
      throw ErroFonte('Não foi possível gravar o acervo na API.', causa: erro);
    }
  }

  void encerrar() => _cliente.close();
}
