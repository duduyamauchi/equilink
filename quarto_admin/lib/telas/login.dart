import 'package:flutter/material.dart';
import 'package:quarto_core/quarto_core.dart';

import '../core/tema.dart';

/// Portão de acesso do painel.
///
/// O acervo não é servido a visitante: o painel só existe com sessão. Enquanto
/// não há login, esta tela aparece no lugar de qualquer rota — inclusive ao
/// abrir uma URL direta, então conhecer o endereço não basta.
class TelaLogin extends StatefulWidget {
  const TelaLogin({
    super.key,
    required this.sessaoApi,
    required this.aoEntrar,
    this.motivo,
  });

  final SessaoApi sessaoApi;

  /// Chamado com a sessão resolvida; o pai recarrega o acervo.
  final ValueChanged<Sessao> aoEntrar;

  /// Explica por que o painel pediu login (ex.: sessão expirada).
  final String? motivo;

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
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
    return Scaffold(
      backgroundColor: AdminCores.fundo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AdminCores.superficie,
                borderRadius: BorderRadius.circular(AdminRaios.medio),
                border: Border.all(color: AdminCores.borda),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_outline, size: 30, color: AdminCores.dourado),
                  const SizedBox(height: 16),
                  const Text(
                    'Painel administrativo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AdminCores.texto,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Acesso restrito ao haras.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: AdminCores.textoSecundario),
                  ),
                  if (widget.motivo != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AdminCores.ambarFundo,
                        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                      ),
                      child: Text(
                        widget.motivo!,
                        style: const TextStyle(fontSize: 12, color: AdminCores.texto),
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
                        color: AdminCores.vermelhoFundo,
                        borderRadius: BorderRadius.circular(AdminRaios.pequeno),
                      ),
                      child: Text(
                        _erro!,
                        style: const TextStyle(fontSize: 12, color: AdminCores.vermelho),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
