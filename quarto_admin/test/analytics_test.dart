import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quarto_core/quarto_core.dart';

import 'package:quarto_admin/core/analytics_painel.dart';
import 'package:quarto_admin/main.dart';

void main() {
  Future<void> abrirPainel(WidgetTester tester, {ColetorAnaliticoPainel? coletor}) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      PainelApp(fonte: FonteMemoria(), coletorAnalitico: coletor),
    );
    await tester.pumpAndSettle();
  }

  Future<void> irParaAnalytics(WidgetTester tester) async {
    await tester.tap(find.text('Analytics'));
    await tester.pumpAndSettle();
  }

  group('coletor do painel', () {
    test('importa os três formatos aceitos', () {
      final coletor = ColetorAnaliticoPainel();

      // Formato exportado pelo aplicativo.
      final enviado = jsonEncode({
        'sessao': 'ses-1',
        'eventos': [
          {
            'nome': 'tela_visualizada',
            'quando': '2026-10-16T10:00:00.000Z',
            'sessao': 'ses-1',
            'tela': '/perfil',
          },
          {
            'nome': 'manejo_alternado',
            'quando': '2026-10-16T10:01:00.000Z',
            'sessao': 'ses-1',
            'valor': 1,
          },
        ],
      });
      expect(coletor.importarJson(enviado), 2);

      // Lista solta.
      expect(
        coletor.importarJson('[{"nome":"a","quando":"2026-10-16T11:00:00.000Z","sessao":"s"}]'),
        1,
      );

      // Evento único.
      expect(
        coletor.importarJson('{"nome":"b","quando":"2026-10-16T12:00:00.000Z","sessao":"s"}'),
        1,
      );

      expect(coletor.eventos.length, 4);
      expect(coletor.eventos.first.nome, 'tela_visualizada', reason: 'ordena por data');
    });

    test('recusa JSON inválido sem quebrar e explica o motivo', () {
      final coletor = ColetorAnaliticoPainel();

      expect(coletor.importarJson('{isso não é json'), 0);
      expect(coletor.ultimoErro, contains('JSON inválido'));

      // Evento sem nome é ignorado silenciosamente.
      expect(coletor.importarJson('[{"quando":"2026-10-16T10:00:00.000Z"}]'), 0);
      expect(coletor.eventos, isEmpty);
    });

    test('registra eventos locais e exporta no mesmo formato', () {
      final coletor = ColetorAnaliticoPainel();
      coletor.registrar(
        EventoAnalitico(nome: 'x', quando: DateTime(2026, 10, 16), sessao: 's'),
      );

      final devolvido = jsonDecode(coletor.exportarJson()) as Map<String, dynamic>;
      expect((devolvido['eventos'] as List).length, 1);
      expect(devolvido['origem'], isNotNull);
    });

    test('carrega de um serviço e reporta falha sem derrubar', () async {
      final coletor = ColetorAnaliticoPainel();

      final quantos = await coletor.carregarDe(
        () async => [EventoAnalitico(nome: 'a', quando: DateTime(2026, 10, 16), sessao: 's')],
        rotulo: 'API',
      );
      expect(quantos, 1);
      expect(coletor.origem, 'API');

      final falhou = await coletor.carregarDe(() async => throw StateError('fora do ar'));
      expect(falhou, 0);
      expect(coletor.ultimoErro, contains('fora do ar'));
    });
  });

  group('painel de analytics', () {
    testWidgets('abre a aba de analytics com o cabeçalho e as seções', (tester) async {
      await abrirPainel(tester);
      await irParaAnalytics(tester);

      expect(find.text('Analytics'), findsWidgets);
      expect(find.text('Eventos'), findsWidgets);
      // O próprio painel já registra o carregamento do acervo, então a visão
      // geral nunca fica vazia.
      expect(find.text('Eventos por dia'), findsOneWidget);
      expect(find.text('Eventos mais frequentes'), findsOneWidget);
    });

    testWidgets('resume eventos importados na visão geral', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      coletor.importarJson(jsonEncode({
        'eventos': [
          {'nome': 'tela_visualizada', 'quando': '2026-10-15T10:00:00.000Z', 'sessao': 's1', 'tela': '/perfil'},
          {'nome': 'tela_visualizada', 'quando': '2026-10-15T10:05:00.000Z', 'sessao': 's1', 'tela': '/baias'},
          {'nome': 'manejo_alternado', 'quando': '2026-10-16T09:00:00.000Z', 'sessao': 's2', 'tela': '/baias'},
        ],
      }));

      await abrirPainel(tester, coletor: coletor);
      await irParaAnalytics(tester);

      expect(find.text('Eventos por dia'), findsOneWidget);
      expect(find.text('Eventos mais frequentes'), findsOneWidget);
      // 3 eventos, 2 sessões.
      expect(find.text('3'), findsWidgets);
      expect(find.text('2'), findsWidgets);
    });

    testWidgets('aba Eventos filtra por tipo e abre o detalhe', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      coletor.importarJson(jsonEncode({
        'eventos': [
          {'nome': 'cavalo_criado', 'quando': '2026-10-16T10:00:00.000Z', 'sessao': 's1',
           'propriedades': {'registro': 'P123'}},
          {'nome': 'baia_criada', 'quando': '2026-10-16T11:00:00.000Z', 'sessao': 's1'},
        ],
      }));

      await abrirPainel(tester, coletor: coletor);
      await irParaAnalytics(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Eventos').first);
      await tester.pumpAndSettle();

      expect(find.text('cavalo_criado'), findsWidgets);
      expect(find.text('baia_criada'), findsWidgets);

      // Busca por valor de propriedade.
      await tester.enterText(find.byType(TextField).first, 'P123');
      await tester.pumpAndSettle();
      expect(find.text('baia_criada'), findsNothing);
      expect(find.text('cavalo_criado'), findsWidgets);

      // Abre o detalhe do evento.
      await tester.tap(find.text('cavalo_criado').last);
      await tester.pumpAndSettle();
      expect(find.text('PROPRIEDADES'), findsOneWidget);
      expect(find.text('registro'), findsOneWidget);
      expect(find.text('JSON do evento'), findsOneWidget);
    });

    testWidgets('funil calcula conversão entre etapas', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      final eventos = <Map<String, Object?>>[];
      // 3 sessões: todas visitam, 2 avançam, 1 conclui.
      for (final (sessao, etapas) in [
        ('s1', ['visita', 'email', 'pago']),
        ('s2', ['visita', 'email']),
        ('s3', ['visita']),
      ]) {
        var minuto = 0;
        for (final etapa in etapas) {
          eventos.add({
            'nome': 'funil_cadastro',
            'quando': '2026-10-16T10:${minuto.toString().padLeft(2, '0')}:00.000Z',
            'sessao': sessao,
            'propriedades': {'etapa': etapa, 'funil': 'cadastro'},
          });
          minuto += 1;
        }
      }
      coletor.importarJson(jsonEncode({'eventos': eventos}));

      await abrirPainel(tester, coletor: coletor);
      await irParaAnalytics(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Funil').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Conversão do funil'), findsOneWidget);
      expect(find.textContaining('cadastro'), findsWidgets);
      expect(find.textContaining('3 sessões'), findsWidgets);
      expect(find.textContaining('1 sessões'), findsWidgets);
      expect(find.textContaining('perda de'), findsWidgets);
    });

    testWidgets('retenção mostra a matriz de coortes', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      coletor.importarJson(jsonEncode({
        'eventos': [
          {'nome': 'uso', 'quando': '2026-10-15T09:00:00.000Z', 'sessao': 's1'},
          {'nome': 'uso', 'quando': '2026-10-15T10:00:00.000Z', 'sessao': 's2'},
          {'nome': 'uso', 'quando': '2026-10-16T09:00:00.000Z', 'sessao': 's1'},
        ],
      }));

      await abrirPainel(tester, coletor: coletor);
      await irParaAnalytics(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Retenção').first);
      await tester.pumpAndSettle();

      expect(find.text('Coortes'), findsOneWidget);
      expect(find.textContaining('2026-10-15'), findsWidgets);
      expect(find.text('D0'), findsOneWidget);
      expect(find.text('D1'), findsOneWidget);
    });

    testWidgets('origem mostra sessões e o coletor do aplicativo', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      coletor.importarJson(jsonEncode({
        'eventos': [
          {'nome': 'a', 'quando': '2026-10-16T10:00:00.000Z', 'sessao': 'ses-abc'},
        ],
      }));

      await abrirPainel(tester, coletor: coletor);
      await irParaAnalytics(tester);
      await tester.tap(find.widgetWithText(InkWell, 'Origem').first);
      await tester.pumpAndSettle();

      expect(find.text('Origem dos eventos'), findsOneWidget);
      expect(find.text('Sessões observadas'), findsOneWidget);
      expect(find.text('ses-abc'), findsOneWidget);
    });

    testWidgets('importa eventos pelo botão e reflete nas abas', (tester) async {
      await abrirPainel(tester);
      await irParaAnalytics(tester);
      final antes = find.text('Eventos por dia').evaluate().isNotEmpty;
      expect(antes, isTrue, reason: 'o painel já registra o carregamento do acervo');

      await tester.tap(find.text('Importar eventos'));
      await tester.pumpAndSettle();

      const json = '{"eventos": [{"nome": "tela_visualizada", '
          '"quando": "2026-10-16T10:00:00.000Z", "sessao": "ses-1", "tela": "/perfil"}]}';
      await tester.enterText(find.byType(TextField).last, json);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.text('Eventos por dia'), findsOneWidget);
      expect(find.text('1 eventos importados.'), findsOneWidget);
    });

    testWidgets('ações do painel geram eventos de telemetria', (tester) async {
      final coletor = ColetorAnaliticoPainel();
      await abrirPainel(tester, coletor: coletor);

      // Uma ação no painel: destacar outro animal.
      await tester.tap(find.text('Cavalos'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Definir como destaque do app').first);
      await tester.pumpAndSettle();

      expect(
        coletor.eventos.any((e) => e.nome == 'cavalo_destacado'),
        isTrue,
        reason: 'as ações do painel também precisam ser observáveis',
      );
      expect(
        coletor.eventos.any((e) => e.nome == 'acervo_carregado'),
        isTrue,
      );
    });
  });
}
