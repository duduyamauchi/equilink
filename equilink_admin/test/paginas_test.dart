import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:equilink_admin/core/paginas.dart';

void main() {
  group('mapa de página → código', () {
    test('cada rota conhecida aponta para o arquivo e o widget certos', () {
      const esperado = {
        '/': ('Visão geral', 'equilink_admin/lib/telas/painel.dart', 'TelaPainel'),
        '/cavalos': ('Lista de cavalos', 'equilink_admin/lib/telas/cavalos.dart', 'TelaCavalos'),
        '/cavalos/novo': ('Cadastro de cavalo', 'equilink_admin/lib/telas/novo_cavalo.dart', 'TelaNovoCavalo'),
        '/provas': ('Provas', 'equilink_admin/lib/telas/provas.dart', 'TelaProvas'),
        '/analytics': ('Analytics', 'equilink_admin/lib/telas/analytics.dart', 'TelaAnalytics'),
        '/fonte': ('Fonte de dados', 'equilink_admin/lib/telas/fonte.dart', 'TelaFonte'),
      };

      esperado.forEach((rota, valores) {
        final p = PaginaDoPainel.de(rota);
        expect(p.rotulo, valores.$1, reason: 'rótulo de $rota');
        expect(p.arquivo, valores.$2, reason: 'arquivo de $rota');
        expect(p.widget, valores.$3, reason: 'widget de $rota');
        expect(p.referencia, '${valores.$2}#${valores.$3}', reason: 'referência de $rota');
      });
    });

    test('ficha de cavalo com id usa o editor, não o assistente', () {
      final ficha = PaginaDoPainel.de('/cavalos/tornado-do-vale');
      expect(ficha.rotulo, 'Ficha do cavalo');
      expect(ficha.widget, 'TelaCavaloEditor');
      expect(ficha.referencia, contains('editor.dart'));
    });

    test('rota desconhecida não mente: mostra o caminho e cai em rotas.dart', () {
      final p = PaginaDoPainel.de('/pagina-nova');
      expect(p.rotulo, '/pagina-nova');
      expect(p.arquivo, 'equilink_admin/lib/rotas.dart');
    });

    test('query string não confunde a resolução', () {
      final p = PaginaDoPainel.de('/provas?aba=2');
      expect(p.rotulo, 'Provas');
    });

    test('todo arquivo do mapa existe no repositório', () {
      // Garante que renomear uma tela não deixa a referência apontando para o
      // vazio — quem implementa receberia um caminho inválido.
      //
      // A referência é relativa à raiz do repositório; este teste roda dentro de
      // `equilink_admin`, então o prefixo sai.
      for (final rota in ['/', '/cavalos', '/cavalos/novo', '/provas', '/analytics', '/fonte', '/cavalos/x']) {
        final p = PaginaDoPainel.de(rota);
        final local = p.arquivo.replaceFirst(RegExp(r'^equilink_admin/'), '');
        expect(
          File(local).existsSync(),
          isTrue,
          reason: 'arquivo de $rota não existe: ${p.arquivo}',
        );
      }
    });
  });
}
