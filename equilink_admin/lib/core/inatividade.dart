import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Encerra a sessão depois de um período sem atividade.
///
/// Duas coisas acontecem juntas:
///
/// * o **servidor** recusa a sessão depois de 1 h sem nenhuma requisição
///   (`INATIVIDADE_MAXIMA` no Worker);
/// * a **interface** encerra antes, para o operador não perder trabalho: avisa
///   faltando 2 minutos e desloga no prazo.
///
/// A contagem é reiniciada por interação real: tecla, clique, rolagem com
/// dedo/mouse, toque. Movimento de mouse sozinho não conta — mouse parado em
/// cima da mesa não é alguém trabalhando, e contar movimento anularia o
/// bloqueio em qualquer máquina com mouse.
class VigiaInatividade extends ChangeNotifier {
  VigiaInatividade({
    this.limite = limitePadrao,
    this.avisoAntes = avisoPadrao,
    DateTime Function()? relogio,
  }) : _relogio = relogio ?? DateTime.now;

  /// Limite configurável em tempo de compilação, em segundos.
  ///
  /// O padrão é 1 hora. Valores menores servem para exercitar o aviso e o
  /// encerramento sem esperar 60 minutos:
  /// `--dart-define=EQUILINK_INATIVIDADE_SEGUNDOS=20`.
  static const limitePadrao = Duration(
    seconds: int.fromEnvironment('EQUILINK_INATIVIDADE_SEGUNDOS', defaultValue: 3600),
  );

  /// Aviso nos últimos 2 minutos.
  static const avisoPadrao = Duration(seconds: 120);

  /// Tempo total sem atividade até encerrar.
  final Duration limite;

  /// Quanto tempo antes do fim o aviso aparece.
  final Duration avisoAntes;

  final DateTime Function() _relogio;

  DateTime? _ultimaAtividade;
  Timer? _verificador;
  bool _ativo = false;
  bool _avisando = false;

  /// Chamado quando o prazo estoura.
  VoidCallback? aoExpirar;

  /// Chamado uma vez quando entra na janela de aviso.
  VoidCallback? aoAvisar;

  /// Chamado quando o operador reage ao aviso e continua conectado.
  VoidCallback? aoProrrogar;

  /// Prazo em texto curto ("1 hora", "25 segundos"), para as mensagens.
  String get limiteEmTexto {
    if (limite.inHours >= 1 && limite.inMinutes % 60 == 0) {
      return limite.inHours == 1 ? '1 hora' : '${limite.inHours} horas';
    }
    if (limite.inMinutes >= 1 && limite.inSeconds % 60 == 0) {
      return limite.inMinutes == 1 ? '1 minuto' : '${limite.inMinutes} minutos';
    }
    return limite.inSeconds == 1 ? '1 segundo' : '${limite.inSeconds} segundos';
  }

  bool get ativo => _ativo;
  bool get avisando => _avisando;

  /// Tempo restante até o encerramento.
  Duration get restante {
    final ultima = _ultimaAtividade;
    if (ultima == null) return limite;
    final passou = _relogio().difference(ultima);
    final falta = limite - passou;
    return falta.isNegative ? Duration.zero : falta;
  }

  /// Começa a contar. Chamar depois de autenticar.
  void iniciar() {
    _ultimaAtividade = _relogio();
    _ativo = true;
    _avisando = false;
    _verificador?.cancel();
    // Um tique por segundo é barato e mantém o aviso preciso.
    _verificador = Timer.periodic(const Duration(seconds: 1), (_) => _verificar());
    notifyListeners();
  }

  /// Para de contar (logout ou sessão encerrada).
  void parar() {
    _verificador?.cancel();
    _verificador = null;
    _ativo = false;
    _avisando = false;
    _ultimaAtividade = null;
    notifyListeners();
  }

  /// Registra atividade do operador.
  ///
  /// Ignorada enquanto o aviso está aberto: ali o "uso" é ambíguo, e um clique
  /// acidental na tela não deve prorrogar sem intenção. Quem prorroga é
  /// [prorrogar], chamado pelo botão do aviso.
  void registrarAtividade() {
    if (!_ativo || _avisando) return;
    _ultimaAtividade = _relogio();
  }

  /// O operador confirmou que continua: reinicia a contagem.
  void prorrogar() {
    _avisando = false;
    _ultimaAtividade = _relogio();
    aoProrrogar?.call();
    notifyListeners();
  }

  /// Janela real de aviso: nunca maior que um quarto do próprio limite.
  ///
  /// Com prazo de 20 s, "avisar 2 min antes" significaria avisar sempre.
  Duration get _janelaAviso {
    final proporcional = limite * 0.25;
    return proporcional < avisoAntes ? proporcional : avisoAntes;
  }

  void _verificar() {
    if (!_ativo) return;
    final falta = restante;

    if (falta == Duration.zero) {
      parar();
      aoExpirar?.call();
      return;
    }
    if (!_avisando && falta <= _janelaAviso) {
      _avisando = true;
      aoAvisar?.call();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _verificador?.cancel();
    super.dispose();
  }
}

/// Captura a interação do operador e repassa ao [VigiaInatividade].
///
/// Fica em volta do painel inteiro. Só conta o que exige intenção: clique,
/// toque, tecla e rolagem. Movimento de mouse fica de fora — mouse parado em
/// cima da mesa não é alguém trabalhando.
class AreaDeAtividade extends StatelessWidget {
  const AreaDeAtividade({super.key, required this.vigia, required this.child});

  final VigiaInatividade vigia;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => vigia.registrarAtividade(),
      onPointerSignal: (_) => vigia.registrarAtividade(),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: (_, evento) {
          if (evento is KeyDownEvent || evento is KeyRepeatEvent) {
            vigia.registrarAtividade();
          }
          return KeyEventResult.ignored;
        },
        child: child,
      ),
    );
  }
}
