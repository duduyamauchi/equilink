/// Núcleo compartilhado do EquiLink.
///
/// Reúne o que o aplicativo do usuário e o painel administrativo precisam
/// compartilhar: modelos de domínio, o contrato de fonte de dados e a fachada
/// que as telas consomem.
///
/// Trocar a origem dos dados (memória, arquivo, API REST) não exige mudar
/// nenhuma tela — basta implementar `FonteDeDados` e apontar
/// `--dart-define=EQUILINK_FONTE`.
library;

export 'src/ambiente.dart';
export 'src/analytics/analise.dart';
export 'src/analytics/analytics.dart';
export 'src/analytics/coletor.dart';
export 'src/analytics/evento.dart';
export 'src/dados_semente.dart'
    show caminhoImagens, caminhoVideos, construirBaias, construirCavaloPrincipal;
export 'src/fonte_dados.dart';
export 'src/fonte_http.dart';
export 'src/formatos.dart';
export 'src/fonte_memoria.dart';
export 'src/modelos.dart';
export 'src/sessao.dart';
export 'src/sugestoes/modelos.dart';
export 'src/sugestoes/sugestoes_api.dart';
export 'src/repositorio.dart';
