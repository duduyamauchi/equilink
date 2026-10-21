import 'analytics/coletor.dart';
import 'fonte_dados.dart';
import 'fonte_http.dart';
import 'fonte_memoria.dart';
import 'sessao.dart';
import 'sugestoes/sugestoes_api.dart';

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
///   --dart-define=EQUILINK_FONTE=http \
///   --dart-define=EQUILINK_API=https://api.haras.app \
///   --dart-define=EQUILINK_TOKEN=...
/// ```
abstract final class Ambiente {
  /// `memoria` (padrão) ou `http`.
  static const fonte = String.fromEnvironment('EQUILINK_FONTE', defaultValue: 'memoria');

  /// Raiz da API quando [fonte] é `http`.
  static const api = String.fromEnvironment('EQUILINK_API', defaultValue: '');

  /// Token enviado no cabeçalho `Authorization` das chamadas à API.
  static const token = String.fromEnvironment('EQUILINK_TOKEN', defaultValue: '');

  /// Endereço público exibido no QR Code da placa de identificação.
  ///
  /// O padrão é o host que de fato serve o aplicativo. Um domínio próprio entra
  /// por `--dart-define=EQUILINK_SITE=https://seu-dominio`.
  static const sitePublico = String.fromEnvironment(
    'EQUILINK_SITE',
    defaultValue: 'https://equilink.quarto-de-milha.workers.dev',
  );

  /// Destino dos eventos analíticos: `memoria` (padrão), `http`, `console`, `nulo`.
  static const analytics = String.fromEnvironment(
    'EQUILINK_ANALYTICS',
    defaultValue: 'memoria',
  );

  /// Raiz da API de eventos quando [analytics] é `http`.
  ///
  /// Sem valor próprio, usa a mesma raiz da API de dados: o endpoint `POST
  /// /eventos` vive no mesmo Worker, então exigir uma segunda variável só
  /// criava a chance de esquecer uma delas.
  static const apiEventos = String.fromEnvironment(
    'EQUILINK_API_EVENTOS',
    defaultValue: api,
  );

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

  /// Cliente de sugestões, quando há backend. `null` em demonstração.
  static SugestoesApi? criarSugestoes() {
    if (fonte != 'http' || api.isEmpty) return null;
    return SugestoesApi(base: api);
  }

  /// Cliente de sessão, quando a fonte é `http`. `null` sem backend.
  static SessaoApi? criarSessao() {
    if (fonte != 'http' || api.isEmpty) return null;
    return SessaoApi(base: api);
  }

  /// Monta a fonte de dados conforme a configuração acima.
  static FonteDeDados criarFonte() {
    switch (fonte) {
      case 'http':
        if (api.isEmpty) {
          throw StateError(
            'EQUILINK_FONTE=http exige EQUILINK_API definido. '
            'Ex.: --dart-define=EQUILINK_API=https://api.exemplo.app',
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
