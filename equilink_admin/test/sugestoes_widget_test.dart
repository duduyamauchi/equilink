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
}

void _nada() {}
