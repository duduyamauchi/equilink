// Testes da autenticação: senha, sessão e autorização.
//
// Rodam no Node puro (`node --test`), sem rede e sem banco — exercitam as
// funções puras que o Worker usa. A verificação contra o banco real é feita no
// navegador e por curl no deploy; aqui o objetivo é pegar regressão de lógica
// antes de publicar.

import test from 'node:test';
import assert from 'node:assert/strict';

import {
  base64ParaBytes,
  bytesParaBase64,
  conferirSenha,
  cookieDeSessao,
  derivarHash,
  emitirSessao,
  gerarSalt,
  iguaisEmTempoConstante,
  lerCookie,
  lerSessao,
  paraHex,
} from '../src/auth.js';

const SEGREDO = 'segredo-de-teste-nao-use-em-producao';
const PEPPER = 'pepper-de-teste';

test('hash de senha confere com a mesma senha e falha com outra', async () => {
  const salt = gerarSalt();
  const hash = await derivarHash('senha-correta', salt, 100000, PEPPER);

  assert.equal(await conferirSenha('senha-correta', { hash, salt, iteracoes: 100000 }, PEPPER), true);
  assert.equal(await conferirSenha('senha-errada', { hash, salt, iteracoes: 100000 }, PEPPER), false);
});

test('pepper errado invalida a senha certa', async () => {
  const salt = gerarSalt();
  const hash = await derivarHash('senha-correta', salt, 100000, PEPPER);

  // Sem o pepper do servidor, o dump do banco não autentica.
  assert.equal(await conferirSenha('senha-correta', { hash, salt, iteracoes: 100000 }, 'outro-pepper'), false);
  assert.equal(await conferirSenha('senha-correta', { hash, salt, iteracoes: 100000 }, undefined), false);
});

test('salt diferente gera hash diferente para a mesma senha', async () => {
  const a = await derivarHash('mesma-senha', gerarSalt(), 100000, PEPPER);
  const b = await derivarHash('mesma-senha', gerarSalt(), 100000, PEPPER);
  assert.notEqual(a, b);
});

test('registro ausente ou incompleto nunca autentica', async () => {
  assert.equal(await conferirSenha('x', null, PEPPER), false);
  assert.equal(await conferirSenha('x', {}, PEPPER), false);
  assert.equal(await conferirSenha('x', { hash: 'abc' }, PEPPER), false);
});

test('sessão emitida é aceita e preserva o usuário', async () => {
  const valor = await emitirSessao('eduardo', SEGREDO);
  const sessao = await lerSessao(valor, SEGREDO);

  assert.equal(sessao.usuarioId, 'eduardo');
  assert.ok(sessao.expiraEm > Date.now());
});

test('sessão adulterada é recusada', async () => {
  const valor = await emitirSessao('eduardo', SEGREDO);
  const [corpo, assinatura] = valor.split('.');

  // Troca o usuário mantendo a assinatura antiga.
  const outroCorpo = bytesParaBase64(new TextEncoder().encode('{"u":"invasor","e":9999999999}'));
  const forjada = `${outroCorpo}.${assinatura}`;
  assert.equal(await lerSessao(forjada, SEGREDO), null);

  // Assinatura alterada.
  assert.equal(await lerSessao(`${corpo}.${assinatura.slice(0, -2)}xy`, SEGREDO), null);
});

test('sessão assinada com outro segredo é recusada', async () => {
  const valor = await emitirSessao('eduardo', SEGREDO);
  assert.equal(await lerSessao(valor, 'outro-segredo'), null);
});

test('sessão vencida é recusada', async () => {
  const agora = Date.now();
  const valor = await emitirSessao('eduardo', SEGREDO, agora - 9 * 60 * 60 * 1000);
  assert.equal(await lerSessao(valor, SEGREDO, agora), null);
});

test('sem segredo configurado, nenhuma sessão vale', async () => {
  const valor = await emitirSessao('eduardo', SEGREDO);
  assert.equal(await lerSessao(valor, ''), null);
  assert.equal(await lerSessao(valor, undefined), null);
});

test('cookie de sessão é HttpOnly, Secure e SameSite=Strict', async () => {
  const valor = await emitirSessao('eduardo', SEGREDO);
  const cookie = cookieDeSessao(valor, { seguro: true });

  assert.match(cookie, /HttpOnly/);
  assert.match(cookie, /Secure/);
  assert.match(cookie, /SameSite=Strict/);
  assert.match(cookie, /Path=\//);
});

test('logout gera cookie vencido', async () => {
  const { cookieVazio } = await import('../src/auth.js');
  assert.match(cookieVazio(true), /Max-Age=0/);
});

test('leitura de cookie ignora outros pares', () => {
  assert.equal(lerCookie('a=1; equilink_sessao=valor; b=2'), 'valor');
  assert.equal(lerCookie('outro=1'), null);
  assert.equal(lerCookie(null), null);
});

test('comparação em tempo constante acerta igualdade e diferença', () => {
  assert.equal(iguaisEmTempoConstante('abc', 'abc'), true);
  assert.equal(iguaisEmTempoConstante('abc', 'abd'), false);
  assert.equal(iguaisEmTempoConstante('abc', 'abcd'), false);
  assert.equal(iguaisEmTempoConstante('', ''), true);
});

test('hash de IP não guarda o endereço em claro', () => {
  const hash = paraHex(new TextEncoder().encode('200.1.2.3:segredo'));
  assert.ok(!hash.includes('200.1.2.3'));
  assert.equal(base64ParaBytes(bytesParaBase64(new Uint8Array([1, 2, 3]))).join(','), '1,2,3');
});
