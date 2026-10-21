import 'dart:convert';

import 'dados_semente.dart';
import 'fonte_dados.dart';

/// Fonte de dados em memória, semeada com o acervo de demonstração.
///
/// É a fonte padrão do aplicativo: não exige backend e mantém as alterações
/// apenas durante a sessão. Serve de referência de comportamento para as
/// demais implementações.
class FonteMemoria with GravacaoGranular implements FonteDeDados {
  FonteMemoria({Acervo? inicial, this.atraso = Duration.zero})
    : _acervo = inicial ?? acervoDeDemonstracao();

  Acervo _acervo;

  /// Atraso simulado, útil para exercitar estados de carregamento.
  final Duration atraso;

  @override
  Acervo get acervoAtual => _acervo;

  @override
  set acervoAtual(Acervo valor) => _acervo = valor;

  @override
  String get descricao => 'memória (demonstração)';

  @override
  bool get permiteEscrita => true;

  /// Acervo de demonstração usado quando não há backend configurado.
  static Acervo acervoDeDemonstracao() {
    final principal = construirCavaloPrincipal();
    return Acervo(
      cavalos: [...plantelDeDemonstracao(principal), principal],
      baias: construirBaias(),
    );
  }

  @override
  Future<Acervo> carregar() async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    return _acervo;
  }

  @override
  Future<Acervo> salvar(Acervo acervo) async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    _acervo = acervo.copiarCom(versao: _acervo.versao + 1);
    return _acervo;
  }

  /// Exporta o acervo em JSON — usado pelo painel para baixar um instantâneo
  /// e por testes de ida e volta.
  String exportarJson({bool identado = true}) =>
      identado ? const JsonEncoder.withIndent('  ').convert(_acervo.toJson()) : jsonEncode(_acervo.toJson());

  /// Reconstrói um acervo a partir do JSON exportado.
  static Acervo importarJson(String texto) =>
      Acervo.fromJson(jsonDecode(texto) as Map<String, dynamic>);
}
