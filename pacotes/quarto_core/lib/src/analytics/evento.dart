/// Modelo de evento analítico.
///
/// O evento é deliberadamente genérico: `nome` é texto livre e as informações
/// específicas vão em [propriedades]. Isso permite instrumentar domínios novos
/// — pagamentos, funil de cadastro, retenção — sem alterar o núcleo.
library;

/// Um evento registrado por qualquer ponto do sistema.
class EventoAnalitico {
  const EventoAnalitico({
    required this.nome,
    required this.quando,
    required this.sessao,
    this.usuario,
    this.tela,
    this.propriedades = const {},
    this.valor,
    this.entidade,
    this.entidadeId,
  });

  /// Identificador do acontecimento, em `snake_case`.
  ///
  /// Exemplos: `cavalo_criado`, `manejo_concluido`, `pagamento_aprovado`.
  final String nome;

  /// Momento em que ocorreu (UTC no transporte, local na exibição).
  final DateTime quando;

  /// Identificador da sessão de uso, usado em funil e retenção.
  final String sessao;

  /// Identificador do usuário, quando conhecido. Nulo em uso anônimo.
  final String? usuario;

  /// Rota ou tela em que o evento ocorreu (ex.: `/perfil`).
  final String? tela;

  /// Dados específicos do evento. Aceita texto, número, booleano ou nulo.
  final Map<String, Object?> propriedades;

  /// Medida numérica do evento: preço de um pagamento, segundos de uma prova,
  /// quantidade de itens. É o que permite somar e comparar.
  final num? valor;

  /// Tipo da entidade afetada (ex.: `cavalo`, `baia`, `cobranca`).
  final String? entidade;

  /// Identificador da entidade afetada.
  final String? entidadeId;

  /// Lê uma propriedade convertendo para texto.
  String? texto(String chave) {
    final v = propriedades[chave];
    return v?.toString();
  }

  /// Lê uma propriedade convertendo para número.
  num? numero(String chave) {
    final v = propriedades[chave];
    if (v is num) return v;
    if (v is String) return num.tryParse(v.replaceAll(',', '.'));
    return null;
  }

  /// Lê uma propriedade convertendo para booleano.
  bool? booleano(String chave) {
    final v = propriedades[chave];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return null;
  }

  /// Chave de agrupamento por dia (`2026-10-16`), usada em séries e coortes.
  String get dia =>
      '${quando.year.toString().padLeft(4, '0')}-'
      '${quando.month.toString().padLeft(2, '0')}-'
      '${quando.day.toString().padLeft(2, '0')}';

  /// Chave de agrupamento por hora (`2026-10-16T14`).
  String get hora => '$dia${quando.hour.toString().padLeft(2, '0')}';

  EventoAnalitico copiarCom({
    String? nome,
    DateTime? quando,
    String? sessao,
    String? usuario,
    String? tela,
    Map<String, Object?>? propriedades,
    num? valor,
    String? entidade,
    String? entidadeId,
  }) => EventoAnalitico(
    nome: nome ?? this.nome,
    quando: quando ?? this.quando,
    sessao: sessao ?? this.sessao,
    usuario: usuario ?? this.usuario,
    tela: tela ?? this.tela,
    propriedades: propriedades ?? this.propriedades,
    valor: valor ?? this.valor,
    entidade: entidade ?? this.entidade,
    entidadeId: entidadeId ?? this.entidadeId,
  );

  factory EventoAnalitico.fromJson(Map<String, dynamic> j) => EventoAnalitico(
    nome: j['nome'] as String? ?? 'desconhecido',
    quando: _data(j['quando']),
    sessao: j['sessao'] as String? ?? 'sem-sessao',
    usuario: j['usuario'] as String?,
    tela: j['tela'] as String?,
    propriedades: {
      for (final e in ((j['propriedades'] as Map?) ?? const {}).entries)
        e.key.toString(): e.value,
    },
    valor: j['valor'] as num?,
    entidade: j['entidade'] as String?,
    entidadeId: j['entidadeId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'quando': quando.toUtc().toIso8601String(),
    'sessao': sessao,
    if (usuario != null) 'usuario': usuario,
    if (tela != null) 'tela': tela,
    if (propriedades.isNotEmpty) 'propriedades': propriedades,
    if (valor != null) 'valor': valor,
    if (entidade != null) 'entidade': entidade,
    if (entidadeId != null) 'entidadeId': entidadeId,
  };

  static DateTime _data(Object? valor) {
    if (valor is DateTime) return valor;
    if (valor is String) {
      final lido = DateTime.tryParse(valor);
      if (lido != null) return lido.toLocal();
    }
    return DateTime.now();
  }

  @override
  String toString() =>
      'EventoAnalitico($nome em $quando${valor != null ? ', valor: $valor' : ''})';
}
