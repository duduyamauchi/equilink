import 'dart:convert';

import 'package:http/http.dart' as http;

/// Quem está autenticado no backend.
///
/// O token de sessão **não** aparece aqui: no web ele vive num cookie
/// `HttpOnly`, invisível para Dart e para qualquer script da página. Este
/// objeto só carrega o que a interface precisa para se apresentar.
class Sessao {
  const Sessao({
    required this.usuario,
    required this.harasId,
    required this.papel,
  });

  final String usuario;
  final String? harasId;
  final String papel;

  /// Papéis que podem gravar. `leitor` só consulta.
  bool get podeEscrever => papel == 'proprietario' || papel == 'operador';

  /// Só o proprietário remove registros.
  bool get podeRemover => papel == 'proprietario';

  String get papelRotulo => switch (papel) {
    'proprietario' => 'Proprietário',
    'operador' => 'Operador',
    'leitor' => 'Leitor',
    _ => papel,
  };

  static Sessao? doJson(Map<String, dynamic>? json) {
    if (json == null || json['autenticado'] != true) return null;
    final usuario = json['usuario'];
    if (usuario is! String || usuario.isEmpty) return null;
    return Sessao(
      usuario: usuario,
      harasId: json['harasId'] as String?,
      papel: (json['papel'] as String?) ?? 'leitor',
    );
  }
}

/// Erro de login com mensagem pronta para a tela.
class ErroLogin implements Exception {
  const ErroLogin(this.mensagem, {this.status});

  final String mensagem;
  final int? status;

  @override
  String toString() => mensagem;
}

/// Cliente de sessão da API: login, logout e consulta de identidade.
///
/// Usa o mesmo [http.Client] do resto do app; no navegador o cookie de sessão
/// é anexado pelo próprio browser, então nada de token em memória.
class SessaoApi {
  SessaoApi({
    required this.base,
    this.tempoLimite = const Duration(seconds: 30),
    http.Client? cliente,
  }) : _cliente = cliente ?? http.Client();

  final String base;
  final Duration tempoLimite;
  final http.Client _cliente;

  Map<String, String> get _cabecalhos => const {
    'Accept': 'application/json',
    'Content-Type': 'application/json; charset=utf-8',
  };

  Uri _rota(String caminho) => Uri.parse('$base$caminho');

  /// Entra com usuário e senha. Devolve a sessão em caso de sucesso.
  Future<Sessao> entrar(String usuario, String senha) async {
    try {
      final resposta = await _cliente
          .post(
            _rota('/sessao'),
            headers: _cabecalhos,
            body: jsonEncode({'usuario': usuario, 'senha': senha}),
          )
          .timeout(tempoLimite);

      if (resposta.statusCode == 401) {
        throw const ErroLogin('Usuário ou senha inválidos.', status: 401);
      }
      if (resposta.statusCode == 429) {
        throw const ErroLogin(
          'Muitas tentativas. Aguarde 15 minutos e tente de novo.',
          status: 429,
        );
      }
      if (resposta.statusCode >= 400) {
        throw ErroLogin(
          _mensagemDeErro(resposta) ?? 'Não foi possível entrar (${resposta.statusCode}).',
          status: resposta.statusCode,
        );
      }

      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>;
      final sessao = Sessao.doJson({...corpo, 'autenticado': true});
      if (sessao == null) throw const ErroLogin('Resposta de login inválida.');
      return sessao;
    } on ErroLogin {
      rethrow;
    } catch (erro) {
      throw ErroLogin('Falha ao conectar com o servidor: $erro');
    }
  }

  /// Consulta a sessão atual. `null` quando não há ninguém autenticado.
  Future<Sessao?> atual() async {
    try {
      final resposta = await _cliente.get(_rota('/sessao'), headers: _cabecalhos).timeout(tempoLimite);
      if (resposta.statusCode != 200) return null;
      return Sessao.doJson(jsonDecode(utf8.decode(resposta.bodyBytes)) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Encerra a sessão no servidor (o cookie é invalidado lá também).
  Future<void> sair() async {
    try {
      await _cliente.delete(_rota('/sessao'), headers: _cabecalhos).timeout(tempoLimite);
    } catch (_) {
      // Sair nunca deve falhar para o usuário; o cookie expira sozinho.
    }
  }

  String? _mensagemDeErro(http.Response resposta) {
    try {
      final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));
      if (corpo is Map && corpo['erro'] is String) return corpo['erro'] as String;
    } catch (_) {}
    return null;
  }

  void encerrar() => _cliente.close();
}
