import 'evento.dart';

/// Consultas e agregações sobre uma lista de eventos.
///
/// São funções puras: qualquer coleção de [EventoAnalitico] pode ser analisada,
/// venha ela da memória, de um arquivo importado ou de uma API. Isso mantém o
/// painel independente da origem dos dados.
abstract final class Analise {
  /// Conta eventos por nome, do mais frequente para o menos.
  static List<({String nome, int total})> porNome(List<EventoAnalitico> eventos) {
    final contagem = <String, int>{};
    for (final e in eventos) {
      contagem[e.nome] = (contagem[e.nome] ?? 0) + 1;
    }
    return [
      for (final e in contagem.entries) (nome: e.key, total: e.value),
    ]..sort((a, b) => b.total.compareTo(a.total));
  }

  /// Série temporal por dia, opcionalmente filtrada por nome de evento.
  static List<({String dia, int total})> seriePorDia(
    List<EventoAnalitico> eventos, {
    String? nome,
  }) {
    final contagem = <String, int>{};
    for (final e in eventos) {
      if (nome != null && e.nome != nome) continue;
      contagem[e.dia] = (contagem[e.dia] ?? 0) + 1;
    }
    final dias = contagem.keys.toList()..sort();
    return [for (final d in dias) (dia: d, total: contagem[d]!)];
  }

  /// Série temporal por hora, útil para ver picos de uso no dia.
  static List<({String hora, int total})> seriePorHora(
    List<EventoAnalitico> eventos, {
    String? nome,
  }) {
    final contagem = <String, int>{};
    for (final e in eventos) {
      if (nome != null && e.nome != nome) continue;
      contagem[e.hora] = (contagem[e.hora] ?? 0) + 1;
    }
    final horas = contagem.keys.toList()..sort();
    return [for (final h in horas) (hora: h, total: contagem[h]!)];
  }

  /// Totais de sessões, eventos e usuários distintos.
  static ({int sessoes, int eventos, int usuarios}) resumo(List<EventoAnalitico> eventos) => (
    sessoes: {for (final e in eventos) e.sessao}.length,
    eventos: eventos.length,
    usuarios: {for (final e in eventos) if (e.usuario != null) e.usuario!}.length,
  );

  /// Duração de uma sessão: diferença entre o primeiro e o último evento.
  static Duration duracaoSessao(List<EventoAnalitico> eventos, String sessao) {
    final daSessao = [for (final e in eventos) if (e.sessao == sessao) e.quando]..sort();
    if (daSessao.length < 2) return Duration.zero;
    return daSessao.last.difference(daSessao.first);
  }

  /// Soma de [EventoAnalitico.valor] por nome de evento.
  ///
  /// É o que transforma eventos de pagamento em receita.
  static List<({String nome, double total, int quantidade})> somaPorNome(
    List<EventoAnalitico> eventos, {
    String? comEntidade,
  }) {
    final soma = <String, ({double total, int quantidade})>{};
    for (final e in eventos) {
      final valor = e.valor;
      if (valor == null) continue;
      if (comEntidade != null && e.entidade != comEntidade) continue;
      final atual = soma[e.nome] ?? (total: 0.0, quantidade: 0);
      soma[e.nome] = (total: atual.total + valor.toDouble(), quantidade: atual.quantidade + 1);
    }
    return [
      for (final e in soma.entries)
        (nome: e.key, total: e.value.total, quantidade: e.value.quantidade),
    ]..sort((a, b) => b.total.compareTo(a.total));
  }

  // ---------------------------------------------------------------------------
  // Funil
  // ---------------------------------------------------------------------------

  /// Resultado de um funil: quantos chegaram a cada etapa, na ordem definida.
  static List<({String etapa, int sessoes, double conversao, double perda})> funil(
    List<EventoAnalitico> eventos, {
    required String funil,
    required List<String> etapas,
  }) {
    // Para cada sessão, a primeira vez em que alcançou cada etapa.
    final alcance = <String, Map<String, DateTime>>{};
    for (final e in eventos) {
      if (e.nome != 'funil_$funil') continue;
      final etapa = e.texto('etapa');
      if (etapa == null || !etapas.contains(etapa)) continue;
      final daSessao = alcance.putIfAbsent(e.sessao, () => {});
      final atual = daSessao[etapa];
      if (atual == null || e.quando.isBefore(atual)) {
        daSessao[etapa] = e.quando;
      }
    }

    final resultado = <({String etapa, int sessoes, double conversao, double perda})>[];
    var anterior = 0;
    for (var i = 0; i < etapas.length; i++) {
      final etapa = etapas[i];
      // Só conta quem também passou por todas as etapas anteriores, na ordem.
      final quantos = alcance.values.where((passos) {
        for (var j = 0; j <= i; j++) {
          if (!passos.containsKey(etapas[j])) return false;
        }
        return passos[etapa] != null;
      }).length;

      final base = i == 0 ? quantos : anterior;
      resultado.add((
        etapa: etapa,
        sessoes: quantos,
        conversao: base == 0 ? 0 : quantos / base,
        perda: base == 0 ? 0 : (base - quantos) / base,
      ));
      anterior = quantos;
    }
    return resultado;
  }

  /// Nomes de funil conhecidos, inferidos dos eventos `funil_<nome>`.
  static List<String> funisDisponiveis(List<EventoAnalitico> eventos) {
    final nomes = <String>{};
    for (final e in eventos) {
      if (e.nome.startsWith('funil_') && e.nome.length > 6) {
        nomes.add(e.nome.substring(6));
      }
    }
    return nomes.toList()..sort();
  }

  /// Etapas conhecidas de um funil, na ordem em que apareceram.
  static List<String> etapasDisponiveis(List<EventoAnalitico> eventos, String funil) {
    final vistas = <String, DateTime>{};
    for (final e in eventos) {
      if (e.nome != 'funil_$funil') continue;
      final etapa = e.texto('etapa');
      if (etapa == null) continue;
      final atual = vistas[etapa];
      if (atual == null || e.quando.isBefore(atual)) vistas[etapa] = e.quando;
    }
    final ordenadas = vistas.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in ordenadas) e.key];
  }

  // ---------------------------------------------------------------------------
  // Retenção
  // ---------------------------------------------------------------------------

  /// Retenção por coorte de primeiro uso.
  ///
  /// Agrupa as sessões pelo dia em que apareceram pela primeira vez e mede
  /// quantas voltaram em cada dia seguinte. Serve para qualquer domínio — de
  /// uso do aplicativo a recompra.
  static List<({String coorte, int tamanho, List<double> retencao})> retencao(
    List<EventoAnalitico> eventos, {
    int dias = 7,
    String? nome,
  }) {
    final primeiraVez = <String, String>{};
    final diasDaSessao = <String, Set<String>>{};
    for (final e in eventos) {
      if (nome != null && e.nome != nome) continue;
      final atual = primeiraVez[e.sessao];
      if (atual == null || e.dia.compareTo(atual) < 0) primeiraVez[e.sessao] = e.dia;
      diasDaSessao.putIfAbsent(e.sessao, () => {}).add(e.dia);
    }

    final porCoorte = <String, List<String>>{};
    for (final entrada in primeiraVez.entries) {
      porCoorte.putIfAbsent(entrada.value, () => []).add(entrada.key);
    }

    final coortes = porCoorte.keys.toList()..sort();
    return [
      for (final coorte in coortes)
        () {
          final sessoes = porCoorte[coorte]!;
          final inicio = DateTime.parse(coorte);
          final taxas = <double>[];
          for (var d = 0; d <= dias; d++) {
            final alvo = inicio.add(Duration(days: d));
            final chave = '${alvo.year.toString().padLeft(4, '0')}-'
                '${alvo.month.toString().padLeft(2, '0')}-'
                '${alvo.day.toString().padLeft(2, '0')}';
            final voltaram = sessoes.where((s) => diasDaSessao[s]!.contains(chave)).length;
            taxas.add(sessoes.isEmpty ? 0 : voltaram / sessoes.length);
          }
          return (coorte: coorte, tamanho: sessoes.length, retencao: taxas);
        }(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Exploração
  // ---------------------------------------------------------------------------

  /// Todos os nomes de evento distintos, para alimentar filtros.
  static List<String> nomesDisponiveis(List<EventoAnalitico> eventos) {
    final nomes = {for (final e in eventos) e.nome}.toList()..sort();
    return nomes;
  }

  /// Chaves de propriedade observadas em um evento, para inspeção de esquema.
  static List<String> propriedadesDe(List<EventoAnalitico> eventos, String nome) {
    final chaves = <String>{};
    for (final e in eventos) {
      if (e.nome != nome) continue;
      chaves.addAll(e.propriedades.keys);
    }
    return chaves.toList()..sort();
  }

  /// Filtra por nome, sessão, usuário, tela e texto livre nas propriedades.
  static List<EventoAnalitico> filtrar(
    List<EventoAnalitico> eventos, {
    String? nome,
    String? sessao,
    String? usuario,
    String? tela,
    String? busca,
    DateTime? de,
    DateTime? ate,
  }) {
    final termo = busca?.trim().toLowerCase();
    return [
      for (final e in eventos)
        if ((nome == null || e.nome == nome) &&
            (sessao == null || e.sessao == sessao) &&
            (usuario == null || e.usuario == usuario) &&
            (tela == null || e.tela == tela) &&
            (de == null || !e.quando.isBefore(de)) &&
            (ate == null || !e.quando.isAfter(ate)) &&
            (termo == null ||
                termo.isEmpty ||
                e.nome.toLowerCase().contains(termo) ||
                (e.tela ?? '').toLowerCase().contains(termo) ||
                (e.entidadeId ?? '').toLowerCase().contains(termo) ||
                e.propriedades.entries.any(
                  (p) =>
                      p.key.toLowerCase().contains(termo) ||
                      p.value.toString().toLowerCase().contains(termo),
                )))
        e,
    ];
  }
}
