import 'package:flutter_test/flutter_test.dart';
import 'package:equilink_core/equilink_core.dart';

/// Coletor que sempre explode, para provar que telemetria não derruba o app.
class _ColetorExplosivo implements ColetorAnalytics {
  @override
  String get descricao => 'explosivo';
  @override
  String? get ultimoErro => null;
  @override
  void registrar(EventoAnalitico evento) => throw StateError('destino indisponível');
  @override
  void registrarVarios(Iterable<EventoAnalitico> eventos) => throw StateError('destino indisponível');
  @override
  Future<void> encerrar() async {}
}

void main() {
  group('evento analítico', () {
    test('sobrevive à ida e volta em JSON', () {
      final original = EventoAnalitico(
        nome: 'pagamento_aprovado',
        quando: DateTime(2026, 10, 16, 14, 30),
        sessao: 'ses-1',
        usuario: 'joao',
        tela: '/perfil',
        propriedades: const {'descricao': 'mensalidade', 'moeda': 'BRL'},
        valor: 149.9,
        entidade: 'cobranca',
        entidadeId: 'cob-42',
      );
      final volta = EventoAnalitico.fromJson(original.toJson());

      expect(volta.nome, original.nome);
      expect(volta.quando, original.quando);
      expect(volta.sessao, original.sessao);
      expect(volta.valor, 149.9);
      expect(volta.texto('moeda'), 'BRL');
      expect(volta.entidadeId, 'cob-42');
      expect(volta.dia, '2026-10-16');
      expect(volta.hora, '2026-10-1614');
    });

    test('aceita propriedades de tipos variados', () {
      final evento = EventoAnalitico(
        nome: 'teste',
        quando: DateTime.now(),
        sessao: 's',
        propriedades: const {'texto': 'abc', 'numero': 42, 'booleano': true, 'nulo': null},
      );
      expect(evento.texto('texto'), 'abc');
      expect(evento.numero('numero'), 42);
      expect(evento.booleano('booleano'), isTrue);
      expect(evento.texto('inexistente'), isNull);
    });

    test('converte número em texto brasileiro com vírgula', () {
      final evento = EventoAnalitico(
        nome: 'teste',
        quando: DateTime.now(),
        sessao: 's',
        propriedades: const {'peso': '1,5'},
      );
      expect(evento.numero('peso'), 1.5);
    });
  });

  group('coletor em memória', () {
    test('guarda eventos e respeita o limite', () {
      final coletor = ColetorMemoria(limite: 3);
      for (var i = 0; i < 5; i++) {
        coletor.registrar(
          EventoAnalitico(nome: 'e$i', quando: DateTime.now(), sessao: 's'),
        );
      }
      expect(coletor.eventos.length, 3);
      expect(coletor.eventos.first.nome, 'e2', reason: 'os mais antigos saem');
      expect(coletor.descricao, contains('3 eventos'));
    });
  });

  group('fachada Analytics', () {
    test('anexa sessão, tela e usuário automaticamente', () {
      final coletor = ColetorMemoria();
      final analytics = Analytics(coletor, usuario: 'maria');

      analytics.visitar('/baias');
      analytics.registrar('manejo_concluido');

      expect(coletor.eventos.length, 2);
      final evento = coletor.eventos.last;
      expect(evento.sessao, analytics.sessao);
      expect(evento.tela, '/baias');
      expect(evento.usuario, 'maria');
    });

    test('atalho de funil nomeia o evento e preserva a etapa', () {
      final coletor = ColetorMemoria();
      final analytics = Analytics(coletor);

      analytics.funil('cadastro', 'email_informado', propriedades: {'origem': 'anuncio'});

      final evento = coletor.eventos.single;
      expect(evento.nome, 'funil_cadastro');
      expect(evento.texto('etapa'), 'email_informado');
      expect(evento.texto('origem'), 'anuncio');
    });

    test('atalho de pagamento converte centavos em valor', () {
      final coletor = ColetorMemoria();
      final analytics = Analytics(coletor);

      analytics.pagamento('mensalidade', 14990, status: 'aprovado', cobrancaId: 'cob-1');

      final evento = coletor.eventos.single;
      expect(evento.nome, 'pagamento_aprovado');
      expect(evento.valor, 149.9);
      expect(evento.entidade, 'cobranca');
      expect(evento.entidadeId, 'cob-1');
      expect(evento.texto('moeda'), 'BRL');
    });

    test('atalho de erro registra origem e mensagem', () {
      final coletor = ColetorMemoria();
      Analytics(coletor).erro('carregar_acervo', 'tempo esgotado');

      final evento = coletor.eventos.single;
      expect(evento.nome, 'erro');
      expect(evento.texto('origem'), 'carregar_acervo');
      expect(evento.texto('mensagem'), 'tempo esgotado');
    });

    test('nunca lança quando o destino falha', () {
      final analytics = Analytics(_ColetorExplosivo());

      // O contrato: telemetria não pode derrubar a ação do usuário.
      expect(() => analytics.registrar('qualquer_coisa'), returnsNormally);
      expect(() => analytics.visitar('/x'), returnsNormally);
      expect(() => analytics.pagamento('x', 100, status: 'recusado'), returnsNormally);
    });

    test('exporta a sessão em JSON legível', () {
      final analytics = Analytics(ColetorMemoria(), usuario: 'ana');
      analytics.registrar('a');
      analytics.registrar('b');

      final json = analytics.exportarJson();
      expect(json['usuario'], 'ana');
      expect(json['sessao'], analytics.sessao);
      expect((json['eventos'] as List).length, 2);
    });
  });

  group('análise', () {
    EventoAnalitico e(
      String nome, {
      String sessao = 's1',
      String? usuario,
      DateTime? quando,
      num? valor,
      String? tela,
      Map<String, Object?> props = const {},
    }) => EventoAnalitico(
      nome: nome,
      quando: quando ?? DateTime(2026, 10, 16, 10),
      sessao: sessao,
      usuario: usuario,
      tela: tela,
      valor: valor,
      propriedades: props,
    );

    test('conta por nome e ordena do mais frequente', () {
      final eventos = [e('a'), e('a'), e('b')];
      final contagem = Analise.porNome(eventos);
      expect(contagem.first.nome, 'a');
      expect(contagem.first.total, 2);
      expect(contagem.last.nome, 'b');
    });

    test('monta série por dia e por hora', () {
      final eventos = [
        e('x', quando: DateTime(2026, 10, 15, 9)),
        e('x', quando: DateTime(2026, 10, 15, 18)),
        e('x', quando: DateTime(2026, 10, 16, 9)),
      ];
      final dias = Analise.seriePorDia(eventos);
      expect(dias.length, 2);
      expect(dias.first, (dia: '2026-10-15', total: 2));

      final horas = Analise.seriePorHora(eventos);
      expect(horas.length, 3);
      expect(horas.first.hora, '2026-10-1509');
    });

    test('resume sessões, eventos e usuários distintos', () {
      final eventos = [
        e('a', sessao: 's1', usuario: 'joao'),
        e('b', sessao: 's1', usuario: 'joao'),
        e('c', sessao: 's2', usuario: 'maria'),
      ];
      final resumo = Analise.resumo(eventos);
      expect(resumo.sessoes, 2);
      expect(resumo.eventos, 3);
      expect(resumo.usuarios, 2);
    });

    test('soma valores por nome, base para receita', () {
      final eventos = [
        e('pagamento_aprovado', valor: 100),
        e('pagamento_aprovado', valor: 50),
        e('pagamento_recusado', valor: 30),
      ];
      final soma = Analise.somaPorNome(eventos);
      expect(soma.first.nome, 'pagamento_aprovado');
      expect(soma.first.total, 150);
      expect(soma.first.quantidade, 2);
    });

    test('calcula duração da sessão', () {
      final eventos = [
        e('a', sessao: 's1', quando: DateTime(2026, 10, 16, 10, 0)),
        e('b', sessao: 's1', quando: DateTime(2026, 10, 16, 10, 12)),
      ];
      expect(Analise.duracaoSessao(eventos, 's1'), const Duration(minutes: 12));
    });

    test('funil conta conversão e perda entre etapas, por sessão', () {
      final eventos = [
        // s1 completa as três etapas
        e('funil_cadastro', sessao: 's1', quando: DateTime(2026, 10, 16, 9), props: {'etapa': 'visita'}),
        e('funil_cadastro', sessao: 's1', quando: DateTime(2026, 10, 16, 9, 1), props: {'etapa': 'email'}),
        e('funil_cadastro', sessao: 's1', quando: DateTime(2026, 10, 16, 9, 2), props: {'etapa': 'pago'}),
        // s2 para no e-mail
        e('funil_cadastro', sessao: 's2', quando: DateTime(2026, 10, 16, 10), props: {'etapa': 'visita'}),
        e('funil_cadastro', sessao: 's2', quando: DateTime(2026, 10, 16, 10, 1), props: {'etapa': 'email'}),
        // s3 só visita
        e('funil_cadastro', sessao: 's3', quando: DateTime(2026, 10, 16, 11), props: {'etapa': 'visita'}),
      ];

      final passos = Analise.funil(
        eventos,
        funil: 'cadastro',
        etapas: ['visita', 'email', 'pago'],
      );

      expect(passos[0].sessoes, 3);
      expect(passos[1].sessoes, 2);
      expect(passos[1].conversao, closeTo(2 / 3, 0.0001));
      expect(passos[2].sessoes, 1);
      expect(passos[2].conversao, 0.5);
      expect(passos[2].perda, 0.5);
    });

    test('descobre funis e etapas sem conhecer o domínio', () {
      final eventos = [
        e('funil_assinatura', quando: DateTime(2026, 10, 16, 8), props: {'etapa': 'plano_escolhido'}),
        e('funil_assinatura', quando: DateTime(2026, 10, 16, 9), props: {'etapa': 'pagamento'}),
        e('outro_evento'),
      ];

      expect(Analise.funisDisponiveis(eventos), ['assinatura']);
      expect(Analise.etapasDisponiveis(eventos, 'assinatura'), ['plano_escolhido', 'pagamento']);
    });

    test('retenção agrupa por coorte de primeiro uso', () {
      final eventos = [
        // s1 e s2 começam em 15/10
        e('uso', sessao: 's1', quando: DateTime(2026, 10, 15, 9)),
        e('uso', sessao: 's2', quando: DateTime(2026, 10, 15, 10)),
        // s1 volta no dia seguinte
        e('uso', sessao: 's1', quando: DateTime(2026, 10, 16, 9)),
        // s3 só em 16/10
        e('uso', sessao: 's3', quando: DateTime(2026, 10, 16, 11)),
      ];

      final coortes = Analise.retencao(eventos, dias: 1);
      expect(coortes.length, 2);

      final primeira = coortes.first;
      expect(primeira.coorte, '2026-10-15');
      expect(primeira.tamanho, 2);
      expect(primeira.retencao[0], 1.0, reason: 'dia 0 é sempre 100%');
      expect(primeira.retencao[1], 0.5, reason: 'apenas s1 voltou');
    });

    test('filtra por nome, tela, sessão e busca livre', () {
      final eventos = [
        e('cavalo_criado', tela: '/cavalos', props: {'registro': 'P1'}),
        e('baia_criada', tela: '/baias', sessao: 's2'),
      ];

      expect(Analise.filtrar(eventos, nome: 'cavalo_criado').length, 1);
      expect(Analise.filtrar(eventos, tela: '/baias').single.nome, 'baia_criada');
      expect(Analise.filtrar(eventos, sessao: 's2').length, 1);
      expect(Analise.filtrar(eventos, busca: 'p1').length, 1, reason: 'busca em propriedades');
      expect(Analise.filtrar(eventos, busca: 'baia').length, 1);
    });

    test('lista nomes e propriedades para alimentar filtros', () {
      final eventos = [
        e('cavalo_criado', props: {'registro': 'P1', 'sexo': 'femea'}),
        e('cavalo_criado', props: {'registro': 'P2'}),
        e('baia_criada'),
      ];

      expect(Analise.nomesDisponiveis(eventos), ['baia_criada', 'cavalo_criado']);
      expect(Analise.propriedadesDe(eventos, 'cavalo_criado'), ['registro', 'sexo']);
    });
  });

  group('repositório instrumentado', () {
    test('registra eventos das escritas com entidade e valor', () async {
      final coletor = ColetorMemoria();
      final repo = Repositorio(FonteMemoria(), analytics: Analytics(coletor));
      await repo.carregar();

      await repo.definirPrincipal('tornado-do-vale');
      await repo.salvarProva(
        'isabel-toro-leo',
        Prova(
          id: 'p-nova',
          data: DateTime(2026, 12, 1),
          nome: 'Três Tambores',
          local: 'Barretos - SP',
          categoria: 'Aberta',
          colocacao: 1,
          tempoSegundos: 16.4,
          inscritos: 30,
        ),
      );
      await repo.adicionarBaia(cavaloId: 'estrela-guia', status: StatusBaia.emDia);

      final nomes = Analise.porNome(coletor.eventos).map((e) => e.nome).toList();
      expect(nomes, contains('acervo_carregado'));
      expect(nomes, contains('cavalo_destacado'));
      expect(nomes, contains('prova_registrada'));
      expect(nomes, contains('baia_criada'));

      final prova = coletor.eventos.firstWhere((e) => e.nome == 'prova_registrada');
      expect(prova.valor, 16.4, reason: 'o tempo vira medida analisável');
      expect(prova.entidade, 'prova');
      expect(prova.booleano('vitoria'), isTrue);
    });

    test('não registra evento quando a gravação falha', () async {
      final coletor = ColetorMemoria();
      final repo = Repositorio(_FonteQueRecusa(), analytics: Analytics(coletor));
      await repo.carregar();

      final ok = await repo.definirPrincipal('tornado-do-vale');

      expect(ok, isFalse);
      expect(
        coletor.eventos.any((e) => e.nome == 'cavalo_destacado'),
        isFalse,
        reason: 'telemetria deve refletir o estado real, não a intenção',
      );
      expect(coletor.eventos.any((e) => e.nome == 'erro'), isTrue);
    });

    test('erro de gravação vira evento de erro com contexto', () async {
      final coletor = ColetorMemoria();
      final repo = Repositorio(_FonteQueRecusa(), analytics: Analytics(coletor));
      await repo.carregar();

      await repo.definirPrincipal('tornado-do-vale');

      final erro = coletor.eventos.firstWhere((e) => e.nome == 'erro');
      expect(erro.texto('origem'), 'gravar_acervo');
      expect(erro.texto('evento'), 'cavalo_destacado');
    });
  });
}

/// Fonte que lê normalmente mas recusa toda gravação.
class _FonteQueRecusa with GravacaoGranular implements FonteDeDados {
  final _acervo = FonteMemoria.acervoDeDemonstracao();

  @override
  Acervo get acervoAtual => _acervo;

  @override
  set acervoAtual(Acervo valor) {}

  @override
  String get descricao => 'recusa gravação';
  @override
  bool get permiteEscrita => true;
  @override
  Future<Acervo> carregar() async => _acervo;
  @override
  Future<Acervo> salvar(Acervo acervo) async => throw const ErroFonte('Servidor fora do ar.');
}
