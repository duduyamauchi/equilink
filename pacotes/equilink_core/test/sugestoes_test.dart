import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:equilink_core/equilink_core.dart';

Map<String, dynamic> _jsonSugestao({
  String id = 'abc',
  int versao = 1,
  String status = 'aberta',
  String texto = 'texto original',
}) => {
  'id': id,
  'rota': '/cavalos',
  'referencia': 'equilink_admin/lib/telas/cavalos.dart#TelaCavalos',
  'titulo': 'Exportar CSV',
  'texto': texto,
  'status': status,
  'prioridade': 'normal',
  'versao': versao,
  'criadoEm': '2026-10-21T10:00:00.000Z',
  'atualizadoEm': '2026-10-21T11:00:00.000Z',
  'usuario': 'eduardo',
};

void main() {
  group('modelo de sugestão', () {
    test('lê o JSON da API', () {
      final s = Sugestao.fromJson(_jsonSugestao());
      expect(s.id, 'abc');
      expect(s.rota, '/cavalos');
      expect(s.titulo, 'Exportar CSV');
      expect(s.status, StatusSugestao.aberta);
      expect(s.prioridade, PrioridadeSugestao.normal);
      expect(s.versao, 1);
      expect(s.usuario, 'eduardo');
      expect(s.apagada, isFalse);
    });

    test('status e prioridade desconhecidos caem no padrão', () {
      final s = Sugestao.fromJson({..._jsonSugestao(), 'status': 'inventado', 'prioridade': 'urgente'});
      expect(s.status, StatusSugestao.aberta);
      expect(s.prioridade, PrioridadeSugestao.normal);
    });

    test('estado apagado é reconhecido', () {
      final s = Sugestao.fromJson(_jsonSugestao(status: 'apagada'));
      expect(s.apagada, isTrue);
    });

    test('resumo corta textos longos sem quebrar palavra ao meio', () {
      final longo = Sugestao.fromJson(_jsonSugestao(texto: 'a' * 400));
      expect(longo.resumo.length, lessThanOrEqualTo(120));
      expect(longo.resumo.endsWith('...'), isTrue);

      final curto = Sugestao.fromJson(_jsonSugestao(texto: 'curto'));
      expect(curto.resumo, 'curto');
    });

    test('copiarCom preserva identidade e data de criação', () {
      final s = Sugestao.fromJson(_jsonSugestao());
      final copia = s.copiarCom(texto: 'novo', versao: 2);
      expect(copia.id, s.id);
      expect(copia.criadoEm, s.criadoEm);
      expect(copia.texto, 'novo');
      expect(copia.versao, 2);
      expect(copia.rota, s.rota);
    });

    test('versão do histórico tem rótulo legível', () {
      final v = VersaoSugestao.fromJson({
        'versao': 2, 'acao': 'editada', 'titulo': 't', 'texto': 'x',
        'status': 'aberta', 'prioridade': 'normal', 'autor': 'eduardo',
        'quando': '2026-10-21T11:00:00.000Z',
      });
      expect(v.acaoRotulo, 'Editada');
      expect(v.autor, 'eduardo');
    });
  });

  group('cliente de sugestões', () {
    test('criar envia a rota e a referência e devolve a versão gravada', () async {
      Map<String, dynamic>? enviado;
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_jsonSugestao()), 201,
              headers: {'content-type': 'application/json'});
        }),
      );

      final s = await api.criar(
        rota: '/cavalos',
        titulo: 'Exportar CSV',
        texto: 'texto original',
        referencia: 'equilink_admin/lib/telas/cavalos.dart#TelaCavalos',
      );

      expect(enviado!['rota'], '/cavalos');
      expect(enviado!['referencia'], 'equilink_admin/lib/telas/cavalos.dart#TelaCavalos');
      expect(enviado!['prioridade'], 'normal');
      expect(s.id, 'abc');
    });

    test('listar pede a rota e inclui apagadas quando pedido', () async {
      Uri? pedida;
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((req) async {
          pedida = req.url;
          return http.Response(jsonEncode({'sugestoes': [_jsonSugestao()]}), 200,
              headers: {'content-type': 'application/json'});
        }),
      );

      await api.listar(rota: '/provas', incluirApagadas: true);
      expect(pedida!.queryParameters['rota'], '/provas');
      expect(pedida!.queryParameters['apagadas'], '1');
    });

    test('editar manda só o que mudou', () async {
      Map<String, dynamic>? enviado;
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_jsonSugestao(versao: 2)), 200,
              headers: {'content-type': 'application/json'});
        }),
      );

      final s = await api.editar('abc', texto: 'novo texto');
      expect(enviado!.keys, ['texto']);
      expect(enviado!['texto'], 'novo texto');
      expect(s.versao, 2);
    });

    test('erro da API vira ErroFonte com a mensagem do servidor', () async {
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((_) async => http.Response(
              '{"erro":"Sugestão não encontrada."}',
              404,
              headers: {'content-type': 'application/json'},
            )),
      );

      expect(
        () => api.editar('abc', texto: 'x'),
        throwsA(isA<ErroFonte>().having((e) => e.mensagem, 'mensagem', contains('não encontrada'))),
      );
    });

    test('sessão expirada vira ErroAutenticacao', () async {
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((_) async => http.Response('{"erro":"sessão"}', 401,
            headers: {'content-type': 'application/json'})),
      );

      expect(() => api.listar(), throwsA(isA<ErroAutenticacao>()));
    });

    test('histórico devolve as versões na ordem do servidor', () async {
      final api = SugestoesApi(
        base: '/api',
        cliente: MockClient((_) async => http.Response(
              jsonEncode({
                'versoes': [
                  {'versao': 2, 'acao': 'editada', 'titulo': 't', 'texto': 'b', 'status': 'aberta', 'prioridade': 'normal', 'autor': 'eduardo', 'quando': '2026-10-21T11:00:00.000Z'},
                  {'versao': 1, 'acao': 'criada', 'titulo': 't', 'texto': 'a', 'status': 'aberta', 'prioridade': 'normal', 'autor': 'eduardo', 'quando': '2026-10-21T10:00:00.000Z'},
                ],
              }),
              200,
              headers: {'content-type': 'application/json'},
            )),
      );

      final versoes = await api.historico('abc');
      expect(versoes.map((v) => v.versao), [2, 1]);
      expect(versoes.first.acaoRotulo, 'Editada');
    });
  });
}
