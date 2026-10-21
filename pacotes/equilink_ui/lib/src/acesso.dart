import 'package:flutter/material.dart';
import 'package:equilink_core/equilink_core.dart';

import 'paleta.dart';

/// Formulário de acesso, compartilhado pelo aplicativo e pelo painel.
///
/// A aparência vem de [PaletaUi], então cada aplicativo mantém sua identidade
/// visual. A lógica de sessão é a mesma nos dois: o cookie é `HttpOnly` e quem
/// guarda o token é o navegador — nada de senha ou token em memória do Dart.
class FormularioAcesso extends StatefulWidget {
  const FormularioAcesso({
    super.key,
    required this.sessaoApi,
    required this.paleta,
    required this.fundo,
    required this.aoEntrar,
    this.titulo = 'Painel administrativo',
    this.subtitulo = 'Acesso restrito ao haras.',
    this.motivo,
    this.aoVoltar,
  });

  final SessaoApi sessaoApi;
  final PaletaUi paleta;
  final Color fundo;
  final ValueChanged<Sessao> aoEntrar;
  final String titulo;
  final String subtitulo;

  /// Explica por que o acesso foi pedido (ex.: sessão expirada).
  final String? motivo;

  /// Quando informado, mostra a opção de continuar sem entrar.
  final VoidCallback? aoVoltar;

  @override
  State<FormularioAcesso> createState() => _FormularioAcessoState();
}

class _FormularioAcessoState extends State<FormularioAcesso> {
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  String? _erro;
  bool _enviando = false;
  bool _senhaVisivel = false;

  @override
  void dispose() {
    _usuario.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (_enviando) return;
    final usuario = _usuario.text.trim();
    final senha = _senha.text;
    if (usuario.isEmpty || senha.isEmpty) {
      setState(() => _erro = 'Informe usuário e senha.');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final sessao = await widget.sessaoApi.entrar(usuario, senha);
      if (!mounted) return;
      widget.aoEntrar(sessao);
    } on ErroLogin catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.mensagem;
        _enviando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.paleta;

    return Scaffold(
      backgroundColor: widget.fundo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: p.superficie,
                borderRadius: BorderRadius.circular(p.raioMedio),
                border: Border.all(color: p.borda),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.lock_outline, size: 30, color: p.destaque),
                  const SizedBox(height: 16),
                  Text(
                    widget.titulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: p.texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.subtitulo,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: p.textoSecundario),
                  ),
                  if (widget.motivo != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.ambarFundo,
                        borderRadius: BorderRadius.circular(p.raioPequeno),
                      ),
                      child: Text(
                        widget.motivo!,
                        style: TextStyle(fontSize: 12, color: p.texto),
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  TextField(
                    controller: _usuario,
                    autofocus: true,
                    enabled: !_enviando,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _senha,
                    enabled: !_enviando,
                    obscureText: !_senhaVisivel,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _senhaVisivel ? 'Ocultar senha' : 'Mostrar senha',
                        icon: Icon(
                          _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                      ),
                    ),
                  ),
                  if (_erro != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: p.vermelhoFundo,
                        borderRadius: BorderRadius.circular(p.raioPequeno),
                      ),
                      child: Text(
                        _erro!,
                        style: TextStyle(fontSize: 12, color: p.vermelho),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _enviando ? null : _entrar,
                    child: _enviando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Entrar'),
                  ),
                  if (widget.aoVoltar != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _enviando ? null : widget.aoVoltar,
                      child: const Text('Continuar sem entrar'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
