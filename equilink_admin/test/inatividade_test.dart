import 'package:flutter_test/flutter_test.dart';

import 'package:equilink_admin/core/inatividade.dart';

void main() {
  group('vigia de inatividade', () {
    test('conta a partir do início e expira no limite', () {
      var agora = DateTime(2026, 10, 21, 9, 0);
      final vigia = VigiaInatividade(relogio: () => agora);
      vigia.iniciar();
      expect(vigia.ativo, isTrue);
      expect(vigia.restante, const Duration(hours: 1));

      // 59 minutos: ainda vale.
      agora = agora.add(const Duration(minutes: 59));
      expect(vigia.ativo, isTrue);
      expect(vigia.restante, const Duration(minutes: 1));

      vigia.dispose();
    });

    test('atividade reinicia a contagem', () {
      var agora = DateTime(2026, 10, 21, 9, 0);
      final vigia = VigiaInatividade(relogio: () => agora);
      vigia.iniciar();

      agora = agora.add(const Duration(minutes: 40));
      expect(vigia.restante, const Duration(minutes: 20));

      vigia.registrarAtividade();
      expect(vigia.restante, const Duration(hours: 1));

      vigia.dispose();
    });

    test('avisa antes de expirar, sem repetir o aviso', () async {
      var agora = DateTime(2026, 10, 21, 9, 0);
      var avisos = 0;
      final vigia = VigiaInatividade(relogio: () => agora);
      vigia.aoAvisar = () => avisos += 1;
      vigia.iniciar();

      // 58min30s: ainda fora da janela de 2 minutos.
      agora = agora.add(const Duration(minutes: 58, seconds: 30));
      expect(vigia.avisando, isFalse);

      // 59min: dentro da janela. O tique vem pelo timer real.
      agora = agora.add(const Duration(seconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(vigia.avisando, isTrue);
      expect(avisos, 1);

      // Mais um minuto: continua avisando, mas não avisa de novo.
      agora = agora.add(const Duration(seconds: 30));
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      expect(avisos, 1);

      vigia.dispose();
    });

    test('prorrogar limpa o aviso e recompoe o prazo', () {
      var agora = DateTime(2026, 10, 21, 9, 0);
      final vigia = VigiaInatividade(relogio: () => agora);
      vigia.iniciar();

      agora = agora.add(const Duration(minutes: 59));
      vigia.prorrogar();

      expect(vigia.avisando, isFalse);
      expect(vigia.restante, const Duration(hours: 1));

      vigia.dispose();
    });

    test('parar encerra a contagem e zera o restante', () {
      var agora = DateTime(2026, 10, 21, 9, 0);
      final vigia = VigiaInatividade(relogio: () => agora);
      vigia.iniciar();

      agora = agora.add(const Duration(minutes: 30));
      vigia.parar();

      expect(vigia.ativo, isFalse);
      expect(vigia.restante, const Duration(hours: 1));

      // Registro de atividade depois de parar não reativa.
      vigia.registrarAtividade();
      expect(vigia.ativo, isFalse);

      vigia.dispose();
    });

    testWidgets('expira de fato quando o timer dispara', (tester) async {
      // O relógio avança junto com o tempo simulado: o timer é real, mas a
      // comparação usa `relogio`.
      var agora = DateTime(2026, 10, 21, 9, 0);
      var expirou = false;
      final vigia = VigiaInatividade(
        limite: const Duration(seconds: 3),
        avisoAntes: const Duration(seconds: 1),
        relogio: () => agora,
      );
      vigia.aoExpirar = () => expirou = true;
      vigia.iniciar();

      agora = agora.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(expirou, isFalse);

      agora = agora.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(expirou, isTrue);
      expect(vigia.ativo, isFalse);

      vigia.dispose();
    });

    testWidgets('emite aviso ao entrar na janela', (tester) async {
      var agora = DateTime(2026, 10, 21, 9, 0);
      var avisou = false;
      final vigia = VigiaInatividade(
        limite: const Duration(seconds: 4),
        avisoAntes: const Duration(seconds: 2),
        relogio: () => agora,
      );
      vigia.aoAvisar = () => avisou = true;
      vigia.iniciar();

      agora = agora.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(avisou, isFalse);

      agora = agora.add(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(avisou, isTrue);
      expect(vigia.avisando, isTrue);

      vigia.dispose();
    });

    test('texto do prazo acompanha o limite configurado', () {
      expect(VigiaInatividade().limiteEmTexto, '1 hora');
      expect(
        VigiaInatividade(limite: const Duration(minutes: 30)).limiteEmTexto,
        '30 minutos',
      );
      expect(
        VigiaInatividade(limite: const Duration(seconds: 25)).limiteEmTexto,
        '25 segundos',
      );
      expect(
        VigiaInatividade(limite: const Duration(minutes: 1)).limiteEmTexto,
        '1 minuto',
      );
      expect(
        VigiaInatividade(limite: const Duration(hours: 2)).limiteEmTexto,
        '2 horas',
      );
    });
  });
}
