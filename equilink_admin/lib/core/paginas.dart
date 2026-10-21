/// Mapa entre a rota do painel e a página que ela abre.
///
/// Serve a dois públicos ao mesmo tempo:
///
/// * o **cliente** vê o nome da página ("Cadastro de cavalo"), não `/cavalos/novo`;
/// * quem **implementa** recebe de graça o arquivo e o widget daquela tela, então
///   não precisa de um campo de código no formulário.
class PaginaDoPainel {
  const PaginaDoPainel({
    required this.rotulo,
    required this.arquivo,
    required this.widget,
  });

  /// Nome que o cliente reconhece.
  final String rotulo;

  /// Arquivo que implementa a tela, a partir da raiz do repositório.
  final String arquivo;

  /// Símbolo principal do arquivo.
  final String widget;

  /// Referência pronta para quem for implementar.
  String get referencia => '$arquivo#$widget';

  /// Resolve a página a partir da rota atual do painel.
  ///
  /// Rotas com id (`/cavalos/tornado-do-vale`) e a de cadastro
  /// (`/cavalos/novo`) são casos distintos: a primeira é a ficha de um animal,
  /// a segunda é o assistente.
  static PaginaDoPainel de(String rota) {
    final caminho = rota.split('?').first;

    if (caminho == '/cavalos/novo') {
      return const PaginaDoPainel(
        rotulo: 'Cadastro de cavalo',
        arquivo: 'equilink_admin/lib/telas/novo_cavalo.dart',
        widget: 'TelaNovoCavalo',
      );
    }
    if (caminho.startsWith('/cavalos/')) {
      return const PaginaDoPainel(
        rotulo: 'Ficha do cavalo',
        arquivo: 'equilink_admin/lib/telas/editor.dart',
        widget: 'TelaCavaloEditor',
      );
    }

    return switch (caminho) {
      '/' => const PaginaDoPainel(
        rotulo: 'Visão geral',
        arquivo: 'equilink_admin/lib/telas/painel.dart',
        widget: 'TelaPainel',
      ),
      '/cavalos' => const PaginaDoPainel(
        rotulo: 'Lista de cavalos',
        arquivo: 'equilink_admin/lib/telas/cavalos.dart',
        widget: 'TelaCavalos',
      ),
      '/provas' => const PaginaDoPainel(
        rotulo: 'Provas',
        arquivo: 'equilink_admin/lib/telas/provas.dart',
        widget: 'TelaProvas',
      ),
      '/analytics' => const PaginaDoPainel(
        rotulo: 'Analytics',
        arquivo: 'equilink_admin/lib/telas/analytics.dart',
        widget: 'TelaAnalytics',
      ),
      '/fonte' => const PaginaDoPainel(
        rotulo: 'Fonte de dados',
        arquivo: 'equilink_admin/lib/telas/fonte.dart',
        widget: 'TelaFonte',
      ),
      // Página nova sem entrada aqui: a rota ainda serve de pista, e o rótulo
      // mostra o caminho em vez de mentir que é outra tela.
      _ => PaginaDoPainel(rotulo: caminho, arquivo: 'equilink_admin/lib/rotas.dart', widget: 'RotasAdmin'),
    };
  }
}
