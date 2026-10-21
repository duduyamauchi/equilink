import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:equilink_core/equilink_core.dart';

import 'package:equilink_admin/main.dart';

void main() {
  Future<void> abrirPainel(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(PainelApp(fonte: FonteMemoria()));
    await tester.pumpAndSettle();
  }

  testWidgets('abre na visão geral com os indicadores do haras', (tester) async {
    await abrirPainel(tester);

    // O rótulo aparece no menu e no título da seção.
    expect(find.text('Visão geral'), findsWidgets);
    expect(find.text('Animais no acervo'), findsOneWidget);
    expect(find.text('Tarefas pendentes'), findsOneWidget);
    expect(find.text('Ocupação das baias'), findsOneWidget);
  });

  testWidgets('lista os animais e permite buscar', (tester) async {
    await abrirPainel(tester);

    await tester.tap(find.text('Cavalos'));
    await tester.pumpAndSettle();

    expect(find.text('ISABEL TORO LEO'), findsOneWidget);
    expect(find.text('TORNADO DO VALE'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'LUNA');
    await tester.pumpAndSettle();
    expect(find.text('LUNA BADGER'), findsOneWidget);
    expect(find.text('ISABEL TORO LEO'), findsNothing);
  });

  testWidgets('abre o editor do animal com as abas de edição', (tester) async {
    await abrirPainel(tester);

    await tester.tap(find.text('Cavalos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar').first);
    await tester.pumpAndSettle();

    expect(find.text('Ficha'), findsOneWidget);
    expect(find.text('Genealogia'), findsOneWidget);
    expect(find.text('Provas'), findsWidgets);
    expect(find.text('Mídias'), findsWidgets);
    expect(find.text('Baia'), findsOneWidget);
    expect(find.text('Identificação'), findsOneWidget);
  });

  testWidgets('mostra a fonte de dados ativa e o JSON do acervo', (tester) async {
    await abrirPainel(tester);

    await tester.tap(find.text('Fonte de dados'));
    await tester.pumpAndSettle();

    expect(find.textContaining('memória'), findsWidgets);
    expect(find.text('Copiar JSON do acervo'), findsOneWidget);

    await tester.tap(find.text('Visualizar JSON'));
    await tester.pumpAndSettle();
    // O painel de inspeção mostra o acervo serializado.
    expect(find.text('Acervo atual em JSON'), findsOneWidget);
    expect(find.textContaining('ISABEL TORO LEO'), findsWidgets);
  });

  _importacao();

  testWidgets('histórico consolidado mostra as provas do plantel', (tester) async {
    await abrirPainel(tester);

    await tester.tap(find.text('Provas'));
    await tester.pumpAndSettle();

    expect(find.text('Provas registradas'), findsOneWidget);
    expect(find.text('Melhor tempo do plantel'), findsOneWidget);
    expect(find.text('Três Tambores | Aberta'), findsWidgets);
  });
}

/// Verifica a importação de acervo — o caminho usado para migrar entre
/// backends (exportar de um, importar no outro).
void _importacao() {
  testWidgets('importa um acervo colado e grava na fonte', (tester) async {
    final fonte = FonteMemoria();
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(PainelApp(fonte: fonte));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Fonte de dados'));
    await tester.pumpAndSettle();

    // Acervo mínimo, no mesmo formato exportado pelo painel.
    const json = '''
{"versao": 7, "cavalos": [{"id": "animal-teste", "nome": "ANIMAL DE TESTE",
"registro": "P000001", "sexo": "macho", "nascimento": "2020-05-05T00:00:00.000",
"pelagem": "Tordilha", "raca": "Quarto de Milha", "altura": "1,50 m", "peso": "500 kg",
"descricao": "Importado.", "proprietario": {"nome": "Teste", "fazenda": "Fazenda Teste",
"telefone": "(11) 90000-0000", "cidade": "Sao Paulo - SP"}, "criador": {"nome": "Criador",
"cidade": "Sorocaba - SP"}, "pai": {"nome": "PAI", "registro": "P1"},
"mae": {"nome": "MAE", "registro": "P2"}, "fotoPerfil": "assets/img/hero.jpg",
"midias": [], "provas": [], "principal": true}], "baias": []}
''';
    await tester.enterText(find.byType(TextField).last, json);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Importar e gravar'));
    await tester.pumpAndSettle();

    // Confirma a substituição.
    await tester.tap(find.text('Substituir'));
    await tester.pumpAndSettle();

    // O acervo foi trocado na fonte: 1 animal, 0 baias, versão gravada.
    final gravado = await fonte.carregar();
    expect(gravado.cavalos.length, 1);
    expect(gravado.cavalos.first.nome, 'ANIMAL DE TESTE');
    expect(gravado.baias, isEmpty);
    expect(gravado.cavalos.first.genealogia.geracoes, 2);
  });
}
