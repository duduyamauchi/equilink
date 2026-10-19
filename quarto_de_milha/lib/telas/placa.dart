import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import 'package:quarto_core/quarto_core.dart';
import '../core/tema.dart';
import '../escopo.dart';
import '../servicos/compartilhar.dart';
import '../servicos/placa_pdf.dart';
import '../widgets/comuns.dart';

/// Tela da placa de identificação: QR Code, ficha resumida, formatos de
/// impressão e exportação em PDF.
class TelaPlaca extends StatefulWidget {
  const TelaPlaca({super.key});

  @override
  State<TelaPlaca> createState() => _TelaPlacaState();
}

class _TelaPlacaState extends State<TelaPlaca> {
  FormatoPlaca _formato = FormatoPlaca.media;
  bool _gerando = false;

  @override
  Widget build(BuildContext context) {
    final repositorio = RepositorioEscopo.de(context);
    final cavalo = repositorio.cavaloObrigatorio;
    final perfil = ContextoPerfil(cavalo: cavalo);
    final url = perfil.urlPublica;

    return Scaffold(
      backgroundColor: Cores.fundo,
      appBar: AppBar(
        title: const Text('Placa de identificação'),
        leading: IconButton(
          tooltip: 'Voltar',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Copiar endereço do perfil',
            icon: const Icon(Icons.link),
            onPressed: () async {
              await AreaTransferencia.copiar(url);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Endereço do perfil copiado.')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(Espacos.x4),
            children: [
              _CartaoPlaca(cavalo: cavalo, formato: _formato, url: url),
              const SizedBox(height: Espacos.x2),
              Center(
                child: Text(
                  'Pré-visualização • ${_formato.dimensoes}',
                  style: const TextStyle(fontSize: 12, color: Cores.textoSecundario),
                ),
              ),
              const SizedBox(height: Espacos.x4),
              Painel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TituloSecao('Formato da placa'),
                    const SizedBox(height: Espacos.x3),
                    Row(
                      children: [
                        for (final formato in FormatoPlaca.values) ...[
                          Expanded(
                            child: _OpcaoFormato(
                              formato: formato,
                              ativo: formato == _formato,
                              aoTocar: () => setState(() => _formato = formato),
                            ),
                          ),
                          if (formato != FormatoPlaca.values.last)
                            const SizedBox(width: Espacos.x2),
                        ],
                      ],
                    ),
                    const SizedBox(height: Espacos.x3),
                    const NotaRodape(
                      'A placa é impressa com a ficha do animal de um lado e o QR Code '
                      'de identificação digital do outro.',
                      icone: Icons.print_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Espacos.x3),
              Painel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TituloSecao(
                      'Ficha impressa',
                      subtitulo: 'Dados reproduzidos na placa física',
                    ),
                    const SizedBox(height: Espacos.x4),
                    Wrap(
                      spacing: Espacos.x4,
                      runSpacing: Espacos.x4,
                      children: [
                        SizedBox(
                          width: 150,
                          child: CampoInfo(rotulo: 'Animal', valor: cavalo.nome),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(rotulo: 'Registro', valor: cavalo.registro),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(rotulo: 'Sexo', valor: cavalo.sexo.rotulo),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(
                            rotulo: 'Nascimento',
                            valor: dataCurta(cavalo.nascimento),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(rotulo: 'Pelagem', valor: cavalo.pelagem),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(rotulo: 'Raça', valor: cavalo.raca),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(
                            rotulo: 'Proprietário',
                            valor: cavalo.proprietario.nome,
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: CampoInfo(
                            rotulo: 'Fazenda',
                            valor: cavalo.proprietario.fazenda,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Espacos.x3),
              Painel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TituloSecao(
                      'Destino do QR Code',
                      subtitulo: 'Endereço aberto ao escanear a placa',
                    ),
                    const SizedBox(height: Espacos.x3),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(Espacos.x3),
                      decoration: BoxDecoration(
                        color: Cores.superficieSuave,
                        borderRadius: BorderRadius.circular(Raios.pequeno),
                        border: Border.all(color: Cores.borda),
                      ),
                      child: Text(
                        url,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: Cores.texto,
                        ),
                      ),
                    ),
                    const SizedBox(height: Espacos.x3),
                    const NotaRodape(
                      'Ao escanear, o destinatário acessa a identidade digital do animal '
                      'com genealogia, histórico esportivo e galeria de mídias.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Espacos.x5),
              BotaoDourado(
                rotulo: _gerando ? 'Gerando PDF...' : 'Gerar PDF da placa',
                icone: Icons.picture_as_pdf_outlined,
                aoTocar: _gerando ? () {} : () => _gerarPdf(context, cavalo, url),
              ),
              const SizedBox(height: Espacos.x3),
              BotaoDourado(
                rotulo: 'Imprimir placa',
                icone: Icons.print,
                escuro: true,
                aoTocar: _gerando ? () {} : () => _gerarPdf(context, cavalo, url, imprimir: true),
              ),
            ],
          ),
          if (_gerando)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.28),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(Espacos.x5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          ),
                          SizedBox(height: Espacos.x3),
                          Text('Gerando a placa...', style: TextStyle(fontSize: 13.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _gerarPdf(
    BuildContext context,
    Cavalo cavalo,
    String url, {
    bool imprimir = false,
  }) async {
    final repo = RepositorioEscopo.de(context);
    repo.analytics.registrar(
      imprimir ? 'placa_impressa' : 'placa_pdf_gerada',
      entidade: 'cavalo',
      entidadeId: cavalo.id,
      propriedades: {'formato': _formato.name, 'dimensoes': _formato.dimensoes},
    );
    setState(() => _gerando = true);
    try {
      final bytes = await PlacaPdf.gerar(cavalo: cavalo, url: url, formato: _formato);
      if (!context.mounted) return;
      if (imprimir) {
        await Printing.layoutPdf(
          name: 'Placa ${cavalo.registro}',
          onLayout: (_) async => bytes,
        );
      } else {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'placa-${cavalo.registro.toLowerCase()}.pdf',
        );
      }
    } on Object catch (erro) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar a placa: $erro')),
      );
    } finally {
      if (mounted) setState(() => _gerando = false);
    }
  }
}

/// Cartão da placa, com QR Code sobre fundo escuro.
class _CartaoPlaca extends StatelessWidget {
  const _CartaoPlaca({required this.cavalo, required this.formato, required this.url});

  final Cavalo cavalo;
  final FormatoPlaca formato;
  final String url;

  @override
  Widget build(BuildContext context) {
    // A placa é desenhada em um quadro de tamanho fixo e reduzida conforme a
    // largura disponível, preservando proporções e evitando estouros de layout.
    const larguraProjeto = 560.0;
    final alturaProjeto = larguraProjeto / formato.proporcao;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: larguraProjeto),
        child: LayoutBuilder(
          builder: (context, restricoes) {
            final escala = (restricoes.maxWidth / larguraProjeto).clamp(0.5, 1.0);
            return SizedBox(
              height: alturaProjeto * escala,
              width: larguraProjeto * escala,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: larguraProjeto,
                  height: alturaProjeto,
                  child: _PlacaImpressa(cavalo: cavalo, url: url),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Desenho da placa física em tamanho de projeto (560 × altura).
class _PlacaImpressa extends StatelessWidget {
  const _PlacaImpressa({required this.cavalo, required this.url});

  final Cavalo cavalo;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Cores.placa,
        borderRadius: BorderRadius.circular(Raios.medio),
        border: Border.all(color: Cores.dourado, width: 1.6),
      ),
      padding: const EdgeInsets.all(Espacos.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'QUARTO DE MILHA',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: Cores.douradoClaro,
                      ),
                    ),
                    const SizedBox(height: Espacos.x2),
                    Text(
                      cavalo.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registro ABQM ${cavalo.registro}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: Cores.douradoClaro),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LinhaPlaca(rotulo: 'Sexo', valor: cavalo.sexo.rotulo),
                    _LinhaPlaca(rotulo: 'Nascimento', valor: dataCurta(cavalo.nascimento)),
                    _LinhaPlaca(rotulo: 'Pelagem', valor: cavalo.pelagem),
                    _LinhaPlaca(rotulo: 'Raça', valor: cavalo.raca),
                    const SizedBox(height: Espacos.x2),
                    Text(
                      cavalo.proprietario.fazenda,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Cores.douradoClaro,
                      ),
                    ),
                    Text(
                      '${cavalo.proprietario.nome} • '
                      '${telefone(cavalo.proprietario.telefone)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Espacos.x3),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(Espacos.x2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(Raios.pequeno),
                    ),
                    child: Center(
                      child: QrDoCavalo(dados: url, tamanho: 150, padding: 0),
                    ),
                  ),
                ),
                const SizedBox(height: Espacos.x2),
                Text(
                  url.replaceFirst('https://', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 10, color: Colors.white60),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinhaPlaca extends StatelessWidget {
  const _LinhaPlaca({required this.rotulo, required this.valor});

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '${rotulo.toUpperCase()} ',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Cores.dourado,
              ),
            ),
            TextSpan(
              text: valor,
              style: const TextStyle(fontSize: 11.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcaoFormato extends StatelessWidget {
  const _OpcaoFormato({required this.formato, required this.ativo, required this.aoTocar});

  final FormatoPlaca formato;
  final bool ativo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ativo ? Cores.escuro : Cores.superficieSuave,
      borderRadius: BorderRadius.circular(Raios.pequeno),
      child: InkWell(
        onTap: aoTocar,
        borderRadius: BorderRadius.circular(Raios.pequeno),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Espacos.x3, horizontal: Espacos.x2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Raios.pequeno),
            border: Border.all(color: ativo ? Cores.escuro : Cores.borda),
          ),
          child: Column(
            children: [
              Icon(
                Icons.crop_16_9,
                size: 18,
                color: ativo ? Cores.douradoClaro : Cores.textoSecundario,
              ),
              const SizedBox(height: 6),
              Text(
                formato.rotulo,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: ativo ? Colors.white : Cores.texto,
                ),
              ),
              Text(
                formato.dimensoes,
                style: TextStyle(
                  fontSize: 10.5,
                  color: ativo ? Colors.white60 : Cores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
