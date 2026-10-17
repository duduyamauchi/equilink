import 'analytics/coletor.dart';
import 'fonte_dados.dart';
import 'fonte_http.dart';
import 'fonte_memoria.dart';

/// Configuração de ambiente do aplicativo.
///
/// Valores definidos em tempo de compilação:
///
/// ```bash
/// # Demonstração (padrão): dados em memória
/// flutter build web --release
///
/// # Backend real
/// flutter build web --release \
///   --dart-define=QUARTO_FONTE=http \
///   --dart-define=QUARTO_API=https://api.haras.app \
///   --dart-define=QUARTO_TOKEN=...
/// ```
abstract final class Ambiente {
  /// `memoria` (padrão) ou `http`.
  static const fonte = String.fromEnvironment('QUARTO_FONTE', defaultValue: 'memoria');

  /// Raiz da API quando [fonte] é `http`.
  static const api = String.fromEnvironment('QUARTO_API', defaultValue: '');

  /// Token enviado no cabeçalho `Authorization` das chamadas à API.
  static const token = String.fromEnvironment('QUARTO_TOKEN', defaultValue: '');

  /// Endereço público exibido no QR Code da placa de identificação.
  static const sitePublico = String.fromEnvironment(
    'QUARTO_SITE',
    defaultValue: 'https://quartodemilha.app.br',
  );

  /// Destino dos eventos analíticos: `memoria` (padrão), `http`, `console`, `nulo`.
  static const analytics = String.fromEnvironment(
    'QUARTO_ANALYTICS',
    defaultValue: 'memoria',
  );

  /// Raiz da API de eventos quando [analytics] é `http`.
  static const apiEventos = String.fromEnvironment('QUARTO_API_EVENTOS', defaultValue: '');

  /// Monta o destino dos eventos conforme a configuração acima.
  ///
  /// Quando `http` é pedido sem endereço, cai no coletor em memória em vez de
  /// falhar: telemetria não deve impedir o aplicativo de subir.
  static ColetorAnalytics criarColetor() {
    switch (analytics) {
      case 'http':
        if (apiEventos.isEmpty) return ColetorMemoria();
        return ColetorHttp(
          base: apiEventos,
          cabecalhos: token.isEmpty ? const {} : {'Authorization': 'Bearer $token'},
        );
      case 'console':
        return ColetorConsole();
      case 'nulo':
        return const ColetorNulo();
      default:
        return ColetorMemoria();
    }
  }

  /// Monta a fonte de dados conforme a configuração acima.
  static FonteDeDados criarFonte() {
    switch (fonte) {
      case 'http':
        if (api.isEmpty) {
          throw StateError(
            'QUARTO_FONTE=http exige QUARTO_API definido. '
            'Ex.: --dart-define=QUARTO_API=https://api.exemplo.app',
          );
        }
        return FonteHttp(
          base: api,
          cabecalhos: token.isEmpty ? const {} : {'Authorization': 'Bearer $token'},
        );
      default:
        return FonteMemoria();
    }
  }
}
