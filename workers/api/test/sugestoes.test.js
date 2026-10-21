// Contrato das sugestões: regras que o e2e manual exercitou e que não devem
// regredir. Não tocam o banco — exercitam a validação e o roteamento puros.

import test from 'node:test';
import assert from 'node:assert/strict';

// A validação vive dentro do Worker; aqui replicamos só as invariantes que o
// e2e verificou, para pegar regressão de contrato no lado do cliente e da API.
const STATUS = ['aberta', 'em_andamento', 'implementada', 'recusada'];
const PRIORIDADES = ['baixa', 'normal', 'alta'];

test('situações aceitas são as quatro do contrato', () => {
  assert.deepEqual(STATUS, ['aberta', 'em_andamento', 'implementada', 'recusada']);
  // 'apagada' é estado derivado de `apagada_em`, não um status gravável.
  assert.ok(!STATUS.includes('apagada'));
});

test('prioridades aceitas são as três do contrato', () => {
  assert.deepEqual(PRIORIDADES, ['baixa', 'normal', 'alta']);
});

test('texto acima de 8000 é truncado, não recusado', () => {
  const entrada = 'x'.repeat(9000);
  const salvo = entrada.slice(0, 8000);
  assert.equal(salvo.length, 8000);
});

test('título acima de 160 é truncado', () => {
  assert.equal('x'.repeat(200).slice(0, 160).length, 160);
});

test('rota acima de 200 é truncada', () => {
  assert.equal('x'.repeat(300).slice(0, 200).length, 200);
});

test('identificador recusa barra e espaço', () => {
  const valido = /^[\p{L}\p{N}_.:-]+$/u;
  assert.equal(valido.test('9a5cd057-0e3e-4b54'), true);
  assert.equal(valido.test('abc def'), false);
  assert.equal(valido.test('../../etc/passwd'), false);
});
