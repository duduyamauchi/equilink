import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';

import '../core/formatos.dart';
import 'package:quarto_core/quarto_core.dart';

/// Tamanhos disponíveis para a placa física de identificação.
enum FormatoPlaca {
  pequena('Pequena', '10 × 7 cm', 10, 7, 10 / 7),
  media('Média', '20 × 14 cm', 20, 14, 20 / 14),
  grande('Grande', '30 × 21 cm', 30, 21, 30 / 21);

  const FormatoPlaca(this.rotulo, this.dimensoes, this.larguraCm, this.alturaCm, this.proporcao);

  final String rotulo;
  final String dimensoes;
  final double larguraCm;
  final double alturaCm;
  final double proporcao;
}

/// Gera a placa de identificação em PDF, pronta para impressão.
///
/// O PDF é montado no dispositivo, sem servidor: o QR Code é rasterizado a
/// partir do mesmo dado exibido na tela e a ficha é desenhada em código.
abstract final class PlacaPdf {
  static Future<Uint8List> gerar({
    required Cavalo cavalo,
    required String url,
    required FormatoPlaca formato,
  }) async {
    final qrBytes = await _qrPng(url, 640);
    final fontes = await _fontes();

    // A fonte padrão do PDF não cobre acentuação portuguesa; a Poppins é
    // embarcada no arquivo para preservar todos os caracteres da ficha.
    final estiloTitulo = pw.TextStyle(font: fontes.negrito);
    final estiloCorpo = pw.TextStyle(font: fontes.regular);

    final documento = pw.Document(
      title: 'Placa de identificação - ${cavalo.nome}',
      theme: pw.ThemeData.withFont(base: fontes.regular, bold: fontes.negrito),
    );

    final larguraPagina = _pontos(formato.larguraCm + 2);
    final alturaPagina = _pontos(formato.alturaCm + 2);

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          larguraPagina,
          alturaPagina,
          marginAll: _pontos(1),
        ),
        build: (contexto) {
          final escuro = PdfColor.fromInt(0xFF1B1B1B);
          final dourado = PdfColor.fromInt(0xFFD8BE8F);
          final claro = PdfColor.fromInt(0xFFF0EFEB);

          return pw.Container(
            decoration: pw.BoxDecoration(
              color: escuro,
              borderRadius: pw.BorderRadius.circular(_pontos(0.6)),
              border: pw.Border.all(color: PdfColor.fromInt(0xFFA6834B), width: 1.4),
            ),
            padding: pw.EdgeInsets.all(_pontos(0.8)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  flex: 3,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'QUARTO DE MILHA',
                            style: estiloTitulo.copyWith(
                              color: dourado,
                              fontSize: _pontos(0.42),
                              fontWeight: pw.FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          pw.SizedBox(height: _pontos(0.25)),
                          pw.Text(
                            cavalo.nome,
                            style: estiloTitulo.copyWith(
                              color: PdfColors.white,
                              fontSize: _pontos(0.95),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: _pontos(0.15)),
                          pw.Text(
                            'Registro ABQM ${cavalo.registro}',
                            style: estiloCorpo.copyWith(color: dourado, fontSize: _pontos(0.48)),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _linha('Sexo', cavalo.sexo.rotulo, claro, estiloCorpo, estiloTitulo),
                          _linha(
                            'Nascimento',
                            dataCurta(cavalo.nascimento),
                            claro,
                            estiloCorpo,
                            estiloTitulo,
                          ),
                          _linha('Pelagem', cavalo.pelagem, claro, estiloCorpo, estiloTitulo),
                          _linha('Raça', cavalo.raca, claro, estiloCorpo, estiloTitulo),
                          _linha(
                            'Proprietário',
                            cavalo.proprietario.nome,
                            claro,
                            estiloCorpo,
                            estiloTitulo,
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            cavalo.proprietario.fazenda.toUpperCase(),
                            style: estiloTitulo.copyWith(
                              color: dourado,
                              fontSize: _pontos(0.5),
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '${cavalo.proprietario.cidade} • ${cavalo.proprietario.telefone}',
                            style: estiloCorpo.copyWith(color: claro, fontSize: _pontos(0.4)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(width: _pontos(0.7)),
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Container(
                        padding: pw.EdgeInsets.all(_pontos(0.3)),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.circular(_pontos(0.3)),
                        ),
                        child: pw.SizedBox(
                          width: _pontos(formato.alturaCm * 0.36),
                          height: _pontos(formato.alturaCm * 0.36),
                          child: pw.Image(pw.MemoryImage(qrBytes), fit: pw.BoxFit.contain),
                        ),
                      ),
                      pw.SizedBox(height: _pontos(0.4)),
                      pw.Column(
                        children: [
                          pw.Text(
                            'Aponte a câmera para o QR Code',
                            textAlign: pw.TextAlign.center,
                            style: estiloCorpo.copyWith(color: claro, fontSize: _pontos(0.36)),
                          ),
                          pw.SizedBox(height: _pontos(0.1)),
                          pw.Text(
                            url.replaceFirst('https://', ''),
                            textAlign: pw.TextAlign.center,
                            style: estiloCorpo.copyWith(color: dourado, fontSize: _pontos(0.34)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return documento.save();
  }

  /// Carrega as fontes embarcadas usadas no PDF.
  static Future<({pw.Font regular, pw.Font negrito})> _fontes() async {
    final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Regular.ttf'));
    final negrito = pw.Font.ttf(await rootBundle.load('assets/fonts/Poppins-Bold.ttf'));
    return (regular: regular, negrito: negrito);
  }

  static pw.Widget _linha(
    String rotulo,
    String valor,
    PdfColor cor,
    pw.TextStyle base,
    pw.TextStyle destaque,
  ) => pw.Padding(
    padding: pw.EdgeInsets.only(bottom: _pontos(0.1)),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '${rotulo.toUpperCase()} ',
            style: destaque.copyWith(
              color: PdfColor.fromInt(0xFFA6834B),
              fontSize: _pontos(0.34),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.TextSpan(
            text: valor,
            style: base.copyWith(color: cor, fontSize: _pontos(0.4)),
          ),
        ],
      ),
    ),
  );

  static double _pontos(double cm) => cm * PdfPageFormat.cm;

  /// Rasteriza o QR Code em PNG para inserir no PDF.
  static Future<Uint8List> _qrPng(String dados, double lado) async {
    final pintor = QrPainter(
      data: dados,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: ui.Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: ui.Color(0xFF000000),
      ),
    );
    final bytes = await pintor.toImageData(lado, format: ui.ImageByteFormat.png);
    if (bytes == null) {
      throw StateError('Não foi possível gerar o QR Code da placa.');
    }
    return bytes.buffer.asUint8List();
  }
}

/// Ações de área de transferência usadas na tela da placa.
abstract final class AreaTransferencia {
  static Future<void> copiar(String texto) => Clipboard.setData(ClipboardData(text: texto));
}
