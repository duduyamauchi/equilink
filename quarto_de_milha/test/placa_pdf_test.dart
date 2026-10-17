import 'package:flutter_test/flutter_test.dart';

import 'package:quarto_core/quarto_core.dart';
import 'package:quarto_de_milha/servicos/compartilhar.dart';
import 'package:quarto_de_milha/servicos/placa_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('placa de identificação', () {
    test('gera PDF válido em todos os formatos, com tamanho de página próprio', () async {
      final cavalo = FonteMemoria.acervoDeDemonstracao().principal!;
      final url = ContextoPerfil(cavalo: cavalo).urlPublica;

      final tamanhos = <FormatoPlaca, int>{};
      for (final formato in FormatoPlaca.values) {
        final bytes = await PlacaPdf.gerar(cavalo: cavalo, url: url, formato: formato);

        // Assinatura de arquivo PDF.
        expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
        // A placa embute o QR Code rasterizado, então tem tamanho relevante.
        expect(bytes.length, greaterThan(4000));

        tamanhos[formato] = bytes.length;
      }

      // Cada formato gera uma página com dimensões físicas diferentes.
      expect(tamanhos.values.toSet().length, FormatoPlaca.values.length);
    });

    test('o QR Code aponta para o perfil público do animal', () {
      final cavalo = FonteMemoria.acervoDeDemonstracao().principal!;
      final perfil = ContextoPerfil(cavalo: cavalo);

      expect(perfil.urlPublica, 'https://quartodemilha.app.br/cavalo/p341234');

      final texto = IdentidadeCavalo.texto(cavalo);
      expect(texto, contains('ISABEL TORO LEO'));
      expect(texto, contains('Registro P341234'));
      expect(texto, contains('18/08/2018'));
      expect(texto, contains('12 provas, 5 vitórias'));
    });

    test('os formatos declaram as dimensões físicas esperadas', () {
      expect(FormatoPlaca.pequena.dimensoes, '10 × 7 cm');
      expect(FormatoPlaca.media.dimensoes, '20 × 14 cm');
      expect(FormatoPlaca.grande.dimensoes, '30 × 21 cm');
      expect(FormatoPlaca.media.proporcao, closeTo(10 / 7, 0.0001));
    });
  });
}
