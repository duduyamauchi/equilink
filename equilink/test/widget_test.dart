import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equilink/app.dart';
import 'package:equilink_core/equilink_core.dart';
import 'package:equilink/telas/acesso.dart';
import 'package:equilink/telas/baias.dart';
import 'package:equilink/core/sessao_escopo.dart';

void main() {
  group('formatação pt-BR', () {
    test('tempo de prova usa vírgula e três milésimos', () {
      expect(tempoProva(16.742), '16,742');
      expect(tempoProva(9.05), '9,050');
      expect(tempoProva(75.4), '1:15,400');
    });

    test('idade considera anos e meses completos', () {
      final hoje = DateTime(2026, 10, 14);
      expect(idade(DateTime(2018, 8, 18), referencia: hoje), '8 anos e 1 mês');
      expect(idade(DateTime(2026, 8, 20), referencia: hoje), '1 mês');
      expect(idade(DateTime(2026, 9, 1), referencia: hoje), '1 mês');
      expect(idade(DateTime(2019, 10, 14), referencia: hoje), '7 anos');
    });

    test('percentual e plural seguem o padrão brasileiro', () {
      expect(percentual(5 / 12), '41,7%');
      expect(percentual(0.5, casas: 0), '50%');
      expect(plural(1, 'prova', 'provas'), '1 prova');
      expect(plural(12, 'prova', 'provas'), '12 provas');
    });

    test('telefone recebe máscara brasileira', () {
      expect(telefone('11999999999'), '(11) 99999-9999');
      expect(telefone('1133334444'), '(11) 3333-4444');
    });
  });

  group('repositório', () {
    test('concluir toda a rotina atualiza a última limpeza', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      final baia = repositorio.baia('01')!;
      final limpezaAnterior = baia.ultimaLimpeza;
      final pendentes = baia.manejo.where((t) => !t.concluida).toList();
      expect(pendentes, isNotEmpty);

      for (final tarefa in pendentes) {
        expect(await repositorio.alternarManejo('01', tarefa.id), isTrue);
      }

      final atualizada = repositorio.baia('01')!;
      expect(atualizada.manejo.every((t) => t.concluida), isTrue);
      expect(atualizada.ultimaLimpeza.isAfter(limpezaAnterior), isTrue);
      // As demais baias mantêm suas pendências.
      expect(repositorio.manejoPendenteTotal, greaterThan(0));
      expect(repositorio.baia('01')!.manejo.where((t) => !t.concluida), isEmpty);
    });

    test('ocorrência estrutural coloca a baia em manutenção e resolvê-la libera', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      expect(repositorio.baia('03')!.status, StatusBaia.emDia);

      await repositorio.adicionarOcorrencia(
        '03',
        tipo: TipoOcorrencia.estrutura,
        descricao: 'Divisória solta.',
        responsavel: 'Manutenção',
      );

      final baia = repositorio.baia('03')!;
      expect(baia.status, StatusBaia.manutencao);
      expect(baia.ocorrencias.first.resolvida, isFalse);

      await repositorio.alternarOcorrenciaResolvida('03', baia.ocorrencias.first.id);

      final resolvida = repositorio.baia('03')!;
      expect(resolvida.ocorrencias.first.resolvida, isTrue);
      expect(resolvida.status, StatusBaia.emDia);
    });

    test('nova baia recebe numeração sequencial e a rotina padrão', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      await repositorio.adicionarBaia(cavaloId: 'estrela-guia', status: StatusBaia.emDia);

      expect(repositorio.baias.length, 6);
      final nova = repositorio.baia('06')!;
      expect(nova.cavaloId, 'estrela-guia');
      expect(nova.manejo.length, repositorio.baia('01')!.manejo.length);
      expect(nova.manejo.every((t) => !t.concluida), isTrue);
    });

    test('consumo diário agrega ração, feno e suplemento', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      final consumo = {for (final c in repositorio.consumoDiario) c.insumo: c.quilos};

      // Ração: 3 refeições de 1,5 kg por baia, em 5 baias.
      expect(consumo['Ração'], closeTo(22.5, 0.001));
      // Feno: 2,0 kg por baia, em 5 baias.
      expect(consumo['Feno'], closeTo(10, 0.001));
      // Suplemento: 30 g por baia, em 5 baias.
      expect(consumo['Suplemento'], closeTo(0.15, 0.001));
    });

    test('estatísticas esportivas derivam das provas cadastradas', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      final cavalo = repositorio.cavalo!;
      expect(cavalo.provas.length, 12);
      expect(cavalo.vitorias, 5);
      expect(cavalo.podios, 9);
      expect(cavalo.melhorTempo, 16.583);
    });

    test('genealogia alcança os bisavós em quatro níveis', () async {
      final repositorio = Repositorio(FonteMemoria());
      await repositorio.carregar();
      final cavalo = repositorio.cavalo!;
      // animal + pais + avós + bisavós
      expect(cavalo.genealogia.geracoes, 4);
      // 2 pais + 4 avós + 8 bisavós, mais o próprio animal.
      expect(cavalo.genealogia.emLargura().length, 15);
      expect(cavalo.pai.nome, 'LEO DO VALE');
      expect(cavalo.pai.pai!.nome, 'Toro Leo');
      expect(cavalo.pai.pai!.pai!.nome, 'Doc Bar');
    });
  });

  group('interface', () {
    /// Navegação inferior é usada apenas em telas estreitas.
    Future<void> usarTelaDeCelular(WidgetTester tester) async {
      tester.view.physicalSize = const Size(430, 940);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    /// Toca em um destino da barra inferior (evita colisão com abas internas).
    Future<void> irPara(WidgetTester tester, String rotulo) async {
      await tester.tap(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(rotulo)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('abre no perfil do cavalo com dados principais', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      expect(find.text('Detalhes do Cavalo'), findsOneWidget);
      expect(find.text('ISABEL TORO LEO'), findsOneWidget);
      expect(find.textContaining('P341234'), findsWidgets);
    });

    testWidgets('navega pelos módulos principais', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      await irPara(tester, 'Genealogia');
      expect(find.text('ÁRVORE DE ASCENDENTES'), findsOneWidget);
      expect(find.textContaining('LEO DO VALE'), findsWidgets);

      await irPara(tester, 'Histórico');
      expect(find.text('Histórico Esportivo'), findsOneWidget);
      expect(find.text('Estatísticas'), findsOneWidget);

      await irPara(tester, 'Baias');
      expect(find.textContaining('Baia 01'), findsWidgets);
      expect(find.text('Em dia'), findsWidgets);
    });

    testWidgets('conclui uma tarefa de manejo pela lista consolidada', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      await irPara(tester, 'Baias');
      expect(find.text('Manejo pendente'), findsOneWidget);

      await tester.tap(find.text('Manejo').first);
      await tester.pumpAndSettle();

      // Primeira tarefa ainda pendente da primeira baia.
      final pendente = tester.widgetList<Checkbox>(find.byType(Checkbox)).firstWhere(
        (c) => c.value == false,
      );
      expect(pendente.value, isFalse);
      await tester.tap(find.byWidget(pendente));
      await tester.pumpAndSettle();

      expect(find.textContaining('registrada como concluída'), findsOneWidget);
    });

    testWidgets('abre a placa de identificação com o QR Code', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Placa de identificação'));
      await tester.pumpAndSettle();


      expect(find.text('Placa de identificação'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(
        find.textContaining('equilink.quarto-de-milha.workers.dev/cavalo/P341234'),
        findsWidgets,
      );
    });

    testWidgets('abre os detalhes da baia com a rotina de manejo', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      await irPara(tester, 'Baias');

      await tester.tap(find.text('Baia 02').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Baia 02 - TORNADO DO VALE'), findsOneWidget);
      expect(find.text('Rotina de manejo'), findsOneWidget);
      expect(find.text('Ração da manhã'), findsOneWidget);
    });

    testWidgets('o visualizador de mídia cobre a navegação principal', (tester) async {
      await usarTelaDeCelular(tester);
      await tester.pumpWidget(EquiLinkApp(fonte: FonteMemoria()));
      await tester.pumpAndSettle();

      await irPara(tester, 'Fotos');

      // Abre o visualizador tocando na foto de capa.
      await tester.tap(find.text('Capa'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsOneWidget);

      // Com o visualizador aberto, a navegação principal fica inacessível:
      // tocar em "Baias" não pode trocar de módulo por baixo da mídia.
      final destinos = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Baias'),
      );
      await tester.tap(destinos, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('Fotos e Vídeos'), findsOneWidget);
      expect(find.text('Gestão das Baias (Haras)'), findsNothing);

      // Fechar o visualizador devolve o controle da navegação.
      await tester.tap(find.byTooltip('Fechar'));
      await tester.pumpAndSettle();
      expect(find.byType(InteractiveViewer), findsNothing);

      await irPara(tester, 'Baias');
      expect(find.text('Gestão das Baias (Haras)'), findsOneWidget);
    });
  });

  group('acesso do proprietário', () {
    testWidgets('visitante vê o aviso de manejo privado e é levado ao login', (tester) async {
      // Fonte em memória: sem backend não haveria aviso nem login, então o
      // cenário usa uma sessão explícita de visitante com backend disponível.
      final sessaoApi = SessaoApi(base: 'https://exemplo.invalid');
      await tester.pumpWidget(
        SessaoEscopo(
          sessao: null,
          sessaoApi: sessaoApi,
          entrar: (_) {},
          sair: () async {},
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Column(
                  children: [
                    const AvisoManejoPrivado(),
                    Builder(
                      builder: (context) => TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TelaAcesso()),
                        ),
                        child: const Text('abrir acesso'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('O manejo das baias é privado'), findsOneWidget);

      await tester.tap(find.text('abrir acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Acesso do proprietário'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Continuar sem entrar'), findsOneWidget);
    });

    testWidgets('quem já entrou não vê o aviso de privacidade', (tester) async {
      final sessaoApi = SessaoApi(base: 'https://exemplo.invalid');
      await tester.pumpWidget(
        SessaoEscopo(
          sessao: const Sessao(usuario: 'eduardo', harasId: 'h1', papel: 'proprietario'),
          sessaoApi: sessaoApi,
          entrar: (_) {},
          sair: () async {},
          child: const MaterialApp(home: Scaffold(body: AvisoManejoPrivado())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('O manejo das baias é privado'), findsNothing);
    });
  });

  group('regressões do e2e', () {
    test('link por registro foca o animal pedido e avisa quando não existe', () async {
      final rep = Repositorio(FonteMemoria());
      await rep.carregar();

      // Sem foco, o app mostra o destaque do haras.
      final destaque = rep.cavalo!.registro;
      expect(rep.erroFoco, isNull);

      // Um registro existente passa a ser o exibido.
      final outro = rep.cavalos.firstWhere((c) => c.registro != destaque);
      expect(rep.focarRegistro(outro.registro.toLowerCase()), isTrue);
      expect(rep.cavalo!.id, outro.id);
      expect(rep.erroFoco, isNull);

      // Registro inexistente explica em vez de mostrar outro animal.
      expect(rep.focarRegistro('NAO-EXISTE'), isFalse);
      expect(rep.erroFoco, contains('NAO-EXISTE'));

      // Limpar volta ao destaque.
      rep.limparFoco();
      expect(rep.erroFoco, isNull);
      expect(rep.cavalo!.registro, destaque);
    });

    test('baia sem animal é reconhecida como vazia', () async {
      final rep = Repositorio(FonteMemoria());
      await rep.carregar();

      expect(rep.baiaOrfa(null), isTrue);
      expect(rep.baiaOrfa(''), isTrue);
      expect(rep.baiaOrfa('cavalo-que-nao-existe'), isTrue);
      final existente = rep.cavalos.first.id;
      expect(rep.baiaOrfa(existente), isFalse);
    });
  });
}
