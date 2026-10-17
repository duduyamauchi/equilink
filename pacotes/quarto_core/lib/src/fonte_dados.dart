import 'modelos.dart';

/// Fotografia completa dos dados do haras.
///
/// É a unidade de leitura e escrita: qualquer fonte de dados devolve e recebe
/// este agregado, então trocar memória por banco de dados não muda a interface
/// das telas.
class Acervo {
  const Acervo({required this.cavalos, required this.baias, this.versao = 1});

  final List<Cavalo> cavalos;
  final List<Baia> baias;

  /// Incrementada a cada gravação; permite detectar conflitos no backend.
  final int versao;

  /// Cavalo em destaque, usado pelo aplicativo do usuário.
  Cavalo? get principal {
    if (cavalos.isEmpty) return null;
    for (final c in cavalos) {
      if (c.principal) return c;
    }
    return cavalos.first;
  }

  Cavalo? cavaloPorId(String id) {
    for (final c in cavalos) {
      if (c.id == id) return c;
    }
    return null;
  }

  Baia? baia(String numero) {
    for (final b in baias) {
      if (b.numero == numero) return b;
    }
    return null;
  }

  Acervo copiarCom({List<Cavalo>? cavalos, List<Baia>? baias, int? versao}) => Acervo(
    cavalos: cavalos ?? this.cavalos,
    baias: baias ?? this.baias,
    versao: versao ?? this.versao,
  );

  factory Acervo.fromJson(Map<String, dynamic> j) => Acervo(
    cavalos: [
      for (final c in (j['cavalos'] as List? ?? const []))
        Cavalo.fromJson(c as Map<String, dynamic>),
    ],
    baias: [
      for (final b in (j['baias'] as List? ?? const []))
        Baia.fromJson(b as Map<String, dynamic>),
    ],
    versao: (j['versao'] as num?)?.toInt() ?? 1,
  );

  Map<String, dynamic> toJson() => {
    'versao': versao,
    'cavalos': [for (final c in cavalos) c.toJson()],
    'baias': [for (final b in baias) b.toJson()],
  };
}

/// Erro de comunicação com a fonte de dados, já com mensagem em português.
class ErroFonte implements Exception {
  const ErroFonte(this.mensagem, {this.causa, this.status});

  final String mensagem;
  final Object? causa;
  final int? status;

  @override
  String toString() => mensagem;
}

/// Contrato de qualquer origem de dados do aplicativo.
///
/// Implementações previstas:
/// - `FonteMemoria`  — dados de demonstração em memória (padrão hoje).
/// - `FonteHttp`     — API REST (`/acervo`, `PUT /acervo`).
/// - `FonteAsset`    — JSON empacotado no aplicativo, somente leitura.
///
/// Para plugar um backend novo, basta implementar estes quatro métodos e
/// apontar `--dart-define=QUARTO_FONTE=http`.
abstract interface class FonteDeDados {
  /// Nome curto exibido no painel administrativo (ex.: `memória`, `http`).
  String get descricao;

  /// Indica se a fonte aceita alterações. Fontes somente leitura fazem o
  /// painel administrativo operar em modo de visualização.
  bool get permiteEscrita;

  /// Lê o acervo completo. Deve lançar [ErroFonte] em caso de falha.
  Future<Acervo> carregar();

  /// Persiste o acervo completo e devolve o estado efetivamente gravado
  /// (o backend pode normalizar identificadores e incrementar a versão).
  Future<Acervo> salvar(Acervo acervo);
}
