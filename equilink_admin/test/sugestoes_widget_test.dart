import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:equilink_admin/core/paginas.dart';
import 'package:equilink_admin/widgets/sugestoes.dart';

void main() {
  group('painel de sugestões', () {
    testWidgets('sem backend, explica em vez de mostrar formulário inútil', (tester) async {
      // `Ambiente.criarSugestoes()` devolve null quando não há EQUILINK_API,
      // que é o caso padrão dos testes.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PainelSugestoes(rota: '/cavalos', aberto: true, aoAlternar: _nada),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sugestões'), findsOneWidget);
      expect(find.textContaining('precisam de backend'), findsOneWidget);
      // Não oferece campos que não salvariam nada.
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('mostra o nome da página, não a rota crua', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PainelSugestoes(rota: '/cavalos/novo', aberto: true, aoAlternar: _nada),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cadastro de cavalo'), findsOneWidget);
      expect(find.text('/cavalos/novo'), findsNothing);
    });

    testWidgets('não pede caminho de código ao cliente', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PainelSugestoes(rota: '/provas', aberto: true, aoAlternar: _nada),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Onde no código'), findsNothing);
      expect(find.textContaining('arquivo.dart'), findsNothing);
    });
  });

  group('mapa de páginas', () {
    test('toda página do painel tem nome legível', () {
      for (final rota in ['/', '/cavalos', '/cavalos/novo', '/provas', '/analytics', '/fonte']) {
        final p = PaginaDoPainel.de(rota);
        expect(p.rotulo, isNotEmpty);
        // Nome de tela, não caminho.
        expect(p.rotulo.startsWith('/'), isFalse, reason: 'rota $rota mostrou caminho cru');
      }
    });
  });

  group('sugestões apagadas', () {
    test('a listagem da interface não pede sugestões apagadas', () {
      // Regressão: o painel pedia `incluirApagadas: true` e o cliente via de
      // volta o que tinha apagado, riscado na lista.
      final fonte = File('lib/widgets/sugestoes.dart').readAsStringSync();
      expect(
        fonte,
        contains('api.listar(rota: widget.rota)'),
        reason: 'a tela deve listar só as sugestões vivas',
      );
      expect(
        fonte.contains('incluirApagadas: true'),
        isFalse,
        reason: 'a tela não deve pedir as apagadas',
      );
    });

    test('o aviso de apagar não promete histórico visível', () {
      final fonte = File('lib/widgets/sugestoes.dart').readAsStringSync();
      // A exclusão é lógica no banco, mas o cliente não recupera pela tela.
      expect(fonte.contains('O histórico continua guardado'), isFalse);
      expect(fonte.contains('não pode ser recuperada por aqui'), isTrue);
    });
  });
}

void _nada() {}
