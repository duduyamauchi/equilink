import 'package:flutter/foundation.dart';

/// Sugestão do cliente sobre uma página do painel.
///
/// O objetivo é virar trabalho: o cliente anota o que quer em cada tela e quem
/// implementa (pessoa ou agente) encontra ali a página, o texto e uma dica de
/// onde mexer no código.
@immutable
class Sugestao {
  const Sugestao({
    required this.id,
    required this.rota,
    required this.titulo,
    required this.texto,
    required this.status,
    required this.prioridade,
    required this.versao,
    required this.criadoEm,
    required this.atualizadoEm,
    this.referencia,
    this.usuario,
  });

  final String id;

  /// Página do painel a que a sugestão se refere (`/cavalos`, `/provas`).
  final String rota;

  /// Dica para quem implementa: `arquivo#Símbolo`.
  final String? referencia;

  final String titulo;
  final String texto;
  final StatusSugestao status;
  final PrioridadeSugestao prioridade;

  /// Começa em 1 e cresce a cada edição.
  final int versao;

  final DateTime criadoEm;
  final DateTime atualizadoEm;

  /// Quem sugeriu. Preenchido nas leituras; ignorado nas gravações.
  final String? usuario;

  bool get apagada => status == StatusSugestao.apagada;
  bool get implementada => status == StatusSugestao.implementada;

  /// Trecho do texto para listas e para o commit gerado.
  String get resumo {
    final limpo = texto.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (limpo.length <= 120) return limpo;
    return '${limpo.substring(0, 117)}...';
  }

  Sugestao copiarCom({
    String? rota,
    String? referencia,
    String? titulo,
    String? texto,
    StatusSugestao? status,
    PrioridadeSugestao? prioridade,
    int? versao,
    DateTime? atualizadoEm,
  }) => Sugestao(
    id: id,
    rota: rota ?? this.rota,
    referencia: referencia ?? this.referencia,
    titulo: titulo ?? this.titulo,
    texto: texto ?? this.texto,
    status: status ?? this.status,
    prioridade: prioridade ?? this.prioridade,
    versao: versao ?? this.versao,
    criadoEm: criadoEm,
    atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    usuario: usuario,
  );

  factory Sugestao.fromJson(Map<String, dynamic> j) => Sugestao(
    id: j['id'] as String? ?? '',
    rota: j['rota'] as String? ?? '/',
    referencia: j['referencia'] as String?,
    titulo: j['titulo'] as String? ?? '',
    texto: j['texto'] as String? ?? '',
    status: StatusSugestao.porNome(j['status'] as String?),
    prioridade: PrioridadeSugestao.porNome(j['prioridade'] as String?),
    versao: (j['versao'] as num?)?.toInt() ?? 1,
    criadoEm: DateTime.tryParse('${j['criadoEm']}')?.toLocal() ?? DateTime.now(),
    atualizadoEm: DateTime.tryParse('${j['atualizadoEm']}')?.toLocal() ?? DateTime.now(),
    usuario: j['usuario'] as String?,
  );
}

/// Situação de uma sugestão.
enum StatusSugestao {
  aberta('aberta', 'Aberta'),
  emAndamento('em_andamento', 'Em andamento'),
  implementada('implementada', 'Implementada'),
  recusada('recusada', 'Recusada'),

  /// Só existe no histórico: a linha foi apagada pelo cliente.
  apagada('apagada', 'Apagada');

  const StatusSugestao(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;

  static StatusSugestao porNome(String? nome) => StatusSugestao.values.firstWhere(
    (v) => v.codigo == nome,
    orElse: () => StatusSugestao.aberta,
  );
}

enum PrioridadeSugestao {
  baixa('baixa', 'Baixa'),
  normal('normal', 'Normal'),
  alta('alta', 'Alta');

  const PrioridadeSugestao(this.codigo, this.rotulo);

  final String codigo;
  final String rotulo;

  static PrioridadeSugestao porNome(String? nome) => PrioridadeSugestao.values.firstWhere(
    (v) => v.codigo == nome,
    orElse: () => PrioridadeSugestao.normal,
  );
}

/// Uma versão anterior de uma sugestão, para o histórico.
@immutable
class VersaoSugestao {
  const VersaoSugestao({
    required this.versao,
    required this.acao,
    required this.titulo,
    required this.texto,
    required this.status,
    required this.prioridade,
    required this.autor,
    required this.quando,
    this.referencia,
    this.rota,
  });

  final int versao;

  /// `criada`, `editada`, `status` ou `apagada`.
  final String acao;

  final String titulo;
  final String texto;
  final String status;
  final String prioridade;
  final String? referencia;
  final String? rota;
  final String autor;
  final DateTime quando;

  String get acaoRotulo => switch (acao) {
    'criada' => 'Criada',
    'editada' => 'Editada',
    'status' => 'Situação alterada',
    'apagada' => 'Apagada',
    _ => acao,
  };

  factory VersaoSugestao.fromJson(Map<String, dynamic> j) => VersaoSugestao(
    versao: (j['versao'] as num?)?.toInt() ?? 1,
    acao: j['acao'] as String? ?? 'editada',
    titulo: j['titulo'] as String? ?? '',
    texto: j['texto'] as String? ?? '',
    status: j['status'] as String? ?? 'aberta',
    prioridade: j['prioridade'] as String? ?? 'normal',
    referencia: j['referencia'] as String?,
    rota: j['rota'] as String?,
    autor: j['autor'] as String? ?? '',
    quando: DateTime.tryParse('${j['quando']}')?.toLocal() ?? DateTime.now(),
  );
}
