// API do Quarto de Milha — roda na Cloudflare Workers e fala com o Neon.
//
// Por que existe: o app é Flutter Web, que não abre conexão TCP. Falar com o
// Postgres direto do navegador é impossível (e exporia credenciais). Esta API
// é a ponte: HTTP do navegador, driver serverless para o banco.
//
// Contrato (o mesmo que `FonteHttp` já consome):
//   GET    /acervo                              -> Acervo
//   PUT    /acervo                              -> substitui tudo
//   PUT    /cavalos/:id                         -> grava um cavalo
//   DELETE /cavalos/:id                         -> remove um cavalo
//   PUT    /baias/:numero                       -> grava uma baia
//   DELETE /baias/:numero                       -> remove uma baia
//   PUT    /cavalos/:id/provas/:provaId         -> grava uma prova
//   PUT    /cavalos/:id/midias/:midiaId         -> grava uma mídia
//   POST   /cavalos/:id/principal               -> define o destaque do app
//   POST   /eventos                             -> recebe lote de analytics

import { neon } from '@neondatabase/serverless';

const json = (corpo, status = 200) =>
  new Response(JSON.stringify(corpo), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'access-control-allow-origin': '*',
      'access-control-allow-methods': 'GET,PUT,POST,DELETE,OPTIONS',
      'access-control-allow-headers': 'content-type,authorization',
    },
  });

const erro = (mensagem, status = 400) => json({ erro: mensagem }, status);

// ---------------------------------------------------------------------------
// Conversão entre o JSON do app e as colunas do banco
// ---------------------------------------------------------------------------

const paraCavalo = (l, provas, midias) => ({
  id: l.id,
  nome: l.nome,
  registro: l.registro,
  sexo: l.sexo,
  nascimento: l.nascimento instanceof Date ? l.nascimento.toISOString() : l.nascimento,
  pelagem: l.pelagem,
  raca: l.raca,
  altura: l.altura,
  peso: l.peso,
  descricao: l.descricao,
  proprietario: l.proprietario ?? {},
  criador: l.criador ?? {},
  pai: l.pai ?? {},
  mae: l.mae ?? {},
  fotoPerfil: l.foto_perfil ?? '',
  principal: l.principal ?? false,
  sgpeUrl: l.sgpe_url ?? null,
  provas,
  midias,
});

const paraProva = (p) => ({
  id: p.id,
  data: p.data instanceof Date ? p.data.toISOString() : p.data,
  nome: p.nome,
  local: p.local,
  categoria: p.categoria,
  colocacao: p.colocacao,
  tempoSegundos: Number(p.tempo_seg),
  inscritos: p.inscritos,
  premiacao: p.premiacao ?? null,
});

const paraMidia = (m) => ({
  id: m.id,
  tipo: m.tipo,
  arquivo: m.arquivo,
  legenda: m.legenda,
  local: m.local ?? null,
  poster: m.poster ?? null,
  duracaoSegundos: m.duracao_seg ?? null,
});

const paraBaia = (b, manejo, ocorrencias, observacoes) => ({
  numero: b.numero,
  cavaloId: b.cavalo_id,
  status: b.status,
  area: b.area,
  ultimaLimpeza: b.ultima_limpeza ?? b.atualizado_em,
  manejo,
  ocorrencias,
  observacoes,
});

const paraTarefa = (t) => ({
  // Remove o prefixo de baia para o app ver o id original do domínio.
  id: String(t.id).includes(':') ? String(t.id).split(':').slice(1).join(':') : t.id,
  tipo: t.tipo,
  descricao: t.descricao,
  horario: t.horario,
  quantidade: t.quantidade,
  responsavel: t.responsavel,
  concluida: t.concluida,
  concluidaEm: t.concluida_em ?? null,
});

const paraOcorrencia = (o) => ({
  id: String(o.id).includes(':') ? String(o.id).split(':').slice(1).join(':') : o.id,
  data: o.data,
  tipo: o.tipo,
  descricao: o.descricao,
  responsavel: o.responsavel,
  resolvida: o.resolvida,
});

const paraObservacao = (o) => ({
  id: String(o.id).includes(':') ? String(o.id).split(':').slice(1).join(':') : o.id,
  data: o.data,
  autor: o.autor,
  texto: o.texto,
});

// ---------------------------------------------------------------------------
// Leitura
// ---------------------------------------------------------------------------

async function lerAcervo(sql, harasId) {
  const cavalos = await sql`
    select c.*,
      coalesce((
        select json_agg(json_build_object(
          'id', p.id, 'data', p.data, 'nome', p.nome, 'local', p.local,
          'categoria', p.categoria, 'colocacao', p.colocacao,
          'tempo_seg', p.tempo_seg, 'inscritos', p.inscritos, 'premiacao', p.premiacao
        ) order by p.data desc) from provas p where p.cavalo_id = c.id
      ), '[]'::json) as provas,
      coalesce((
        select json_agg(json_build_object(
          'id', m.id, 'tipo', m.tipo, 'arquivo', m.arquivo, 'legenda', m.legenda,
          'local', m.local, 'poster', m.poster, 'duracao_seg', m.duracao_seg
        ) order by m.ordem) from midias m where m.cavalo_id = c.id
      ), '[]'::json) as midias
    from cavalos c
    where c.haras_id = ${harasId}
    order by c.principal desc, c.nome
  `;

  const baias = await sql`
    select b.*,
      coalesce((
        select json_agg(json_build_object(
          'id', t.id, 'tipo', t.tipo, 'descricao', t.descricao, 'horario', t.horario,
          'quantidade', t.quantidade, 'responsavel', t.responsavel,
          'concluida', t.concluida, 'concluida_em', t.concluida_em
        ) order by t.horario) from tarefas_manejo t
        where t.haras_id = b.haras_id and t.baia_numero = b.numero
      ), '[]'::json) as manejo,
      coalesce((
        select json_agg(json_build_object(
          'id', o.id, 'data', o.data, 'tipo', o.tipo, 'descricao', o.descricao,
          'responsavel', o.responsavel, 'resolvida', o.resolvida
        ) order by o.data desc) from ocorrencias o
        where o.haras_id = b.haras_id and o.baia_numero = b.numero
      ), '[]'::json) as ocorrencias,
      coalesce((
        select json_agg(json_build_object(
          'id', v.id, 'data', v.data, 'autor', v.autor, 'texto', v.texto
        ) order by v.data desc) from observacoes v
        where v.haras_id = b.haras_id and v.baia_numero = b.numero
      ), '[]'::json) as observacoes
    from baias b
    where b.haras_id = ${harasId}
    order by b.numero
  `;

  return {
    versao: 1,
    cavalos: cavalos.map((c) => paraCavalo(c, c.provas.map(paraProva), c.midias.map(paraMidia))),
    baias: baias.map((b) =>
      paraBaia(b, b.manejo.map(paraTarefa), b.ocorrencias.map(paraOcorrencia), b.observacoes.map(paraObservacao)),
    ),
  };
}

// ---------------------------------------------------------------------------
// Escrita
// ---------------------------------------------------------------------------

async function gravarCavalo(sql, harasId, c) {
  await sql`
    insert into cavalos (id, haras_id, nome, registro, sexo, nascimento, pelagem, raca,
                         altura, peso, descricao, foto_perfil, principal, proprietario,
                         criador, pai, mae, sgpe_url, atualizado_em)
    values (${c.id}, ${harasId}, ${c.nome}, ${c.registro}, ${c.sexo}, ${c.nascimento},
            ${c.pelagem ?? ''}, ${c.raca ?? 'Quarto de Milha'}, ${c.altura ?? ''},
            ${c.peso ?? ''}, ${c.descricao ?? ''}, ${c.fotoPerfil ?? ''},
            ${c.principal ?? false}, ${JSON.stringify(c.proprietario ?? {})}::jsonb,
            ${JSON.stringify(c.criador ?? {})}::jsonb, ${JSON.stringify(c.pai ?? {})}::jsonb,
            ${JSON.stringify(c.mae ?? {})}::jsonb, ${c.sgpeUrl ?? null}, now())
    on conflict (id) do update set
      nome = excluded.nome, registro = excluded.registro, sexo = excluded.sexo,
      nascimento = excluded.nascimento, pelagem = excluded.pelagem, raca = excluded.raca,
      altura = excluded.altura, peso = excluded.peso, descricao = excluded.descricao,
      foto_perfil = excluded.foto_perfil, principal = excluded.principal,
      proprietario = excluded.proprietario, criador = excluded.criador,
      pai = excluded.pai, mae = excluded.mae, sgpe_url = excluded.sgpe_url,
      atualizado_em = now()
  `;

  // Provas e mídias vêm aninhadas no cavalo pelo contrato do app; gravar o
  // cavalo precisa persistir também esses filhos.
  for (const p of c.provas ?? []) {
    await gravarProva(sql, c.id, p);
  }
  for (const m of c.midias ?? []) {
    await gravarMidia(sql, c.id, m);
  }
}

async function gravarProva(sql, cavaloId, p) {
  await sql`
    insert into provas (id, cavalo_id, data, nome, local, categoria, colocacao,
                        tempo_seg, inscritos, premiacao)
    values (${p.id}, ${cavaloId}, ${p.data}, ${p.nome}, ${p.local ?? ''},
            ${p.categoria ?? ''}, ${p.colocacao ?? 0}, ${p.tempoSegundos ?? 0},
            ${p.inscritos ?? 0}, ${p.premiacao ?? null})
    on conflict (id) do update set
      data = excluded.data, nome = excluded.nome, local = excluded.local,
      categoria = excluded.categoria, colocacao = excluded.colocacao,
      tempo_seg = excluded.tempo_seg, inscritos = excluded.inscritos,
      premiacao = excluded.premiacao
  `;
}

async function gravarMidia(sql, cavaloId, m) {
  await sql`
    insert into midias (id, cavalo_id, tipo, arquivo, legenda, local, poster, duracao_seg)
    values (${m.id}, ${cavaloId}, ${m.tipo}, ${m.arquivo}, ${m.legenda ?? ''},
            ${m.local ?? null}, ${m.poster ?? null}, ${m.duracaoSegundos ?? null})
    on conflict (id) do update set
      tipo = excluded.tipo, arquivo = excluded.arquivo, legenda = excluded.legenda,
      local = excluded.local, poster = excluded.poster, duracao_seg = excluded.duracao_seg
  `;
}

async function gravarBaia(sql, harasId, b) {
  await sql`
    insert into baias (numero, haras_id, cavalo_id, status, area, ultima_limpeza, atualizado_em)
    values (${b.numero}, ${harasId}, ${b.cavaloId}, ${b.status ?? 'emDia'},
            ${b.area ?? 'Haras principal'}, ${b.ultimaLimpeza ?? null}, now())
    on conflict (haras_id, numero) do update set
      cavalo_id = excluded.cavalo_id, status = excluded.status, area = excluded.area,
      ultima_limpeza = excluded.ultima_limpeza, atualizado_em = now()
  `;

  // Rotina e registros filhos: substitui o conjunto da baia.
  await sql`delete from tarefas_manejo where haras_id = ${harasId} and baia_numero = ${b.numero}`;
  for (const t of b.manejo ?? []) {
    // O mesmo id de tarefa se repete entre baias no modelo do app; a chave
    // primária aqui é global, então prefixamos com o número da baia.
    const idTarefa = t.id.includes(b.numero) ? t.id : `${b.numero}:${t.id}`;
    await sql`
      insert into tarefas_manejo (id, baia_numero, haras_id, tipo, descricao, horario,
                                  quantidade, responsavel, concluida, concluida_em)
      values (${idTarefa}, ${b.numero}, ${harasId}, ${t.tipo}, ${t.descricao},
              ${t.horario ?? ''}, ${t.quantidade ?? ''}, ${t.responsavel ?? ''},
              ${t.concluida ?? false}, ${t.concluidaEm ?? null})
      on conflict (id) do nothing
    `;
  }

  await sql`delete from ocorrencias where haras_id = ${harasId} and baia_numero = ${b.numero}`;
  for (const o of b.ocorrencias ?? []) {
    await sql`
      insert into ocorrencias (id, baia_numero, haras_id, data, tipo, descricao, responsavel, resolvida)
      values (${o.id.includes(b.numero) ? o.id : `${b.numero}:${o.id}`}, ${b.numero}, ${harasId},
              ${o.data ?? new Date().toISOString()}, ${o.tipo}, ${o.descricao},
              ${o.responsavel ?? ''}, ${o.resolvida ?? false})
      on conflict (id) do nothing
    `;
  }

  await sql`delete from observacoes where haras_id = ${harasId} and baia_numero = ${b.numero}`;
  for (const v of b.observacoes ?? []) {
    await sql`
      insert into observacoes (id, baia_numero, haras_id, data, autor, texto)
      values (${v.id.includes(b.numero) ? v.id : `${b.numero}:${v.id}`}, ${b.numero}, ${harasId},
              ${v.data ?? new Date().toISOString()}, ${v.autor ?? ''}, ${v.texto})
      on conflict (id) do nothing
    `;
  }
}

// ---------------------------------------------------------------------------
// Carga em lote
//
// O Worker tem limite de subrequests por invocação. Inserir registro a registro
// estoura esse limite com o acervo inteiro, então a carga usa uma instrução por
// tabela, com `unnest` para percorrer o JSON.
// ---------------------------------------------------------------------------

async function gravarAcervoEmLote(sql, harasId, acervo) {
  const cavalos = acervo.cavalos ?? [];

  await sql`
    insert into cavalos (id, haras_id, nome, registro, sexo, nascimento, pelagem, raca,
                         altura, peso, descricao, foto_perfil, principal, proprietario,
                         criador, pai, mae, sgpe_url, atualizado_em)
    select d.id, ${harasId}, d.nome, d.registro, d.sexo, d.nascimento::date, d.pelagem,
           d.raca, d.altura, d.peso, d.descricao, d.foto_perfil, d.principal,
           d.proprietario::jsonb, d.criador::jsonb, d.pai::jsonb, d.mae::jsonb,
           d.sgpe_url, now()
    from unnest(
      ${cavalos.map((c) => c.id)}::text[],
      ${cavalos.map((c) => c.nome)}::text[],
      ${cavalos.map((c) => c.registro)}::text[],
      ${cavalos.map((c) => c.sexo ?? 'femea')}::text[],
      ${cavalos.map((c) => c.nascimento)}::text[],
      ${cavalos.map((c) => c.pelagem ?? '')}::text[],
      ${cavalos.map((c) => c.raca ?? 'Quarto de Milha')}::text[],
      ${cavalos.map((c) => c.altura ?? '')}::text[],
      ${cavalos.map((c) => c.peso ?? '')}::text[],
      ${cavalos.map((c) => c.descricao ?? '')}::text[],
      ${cavalos.map((c) => c.fotoPerfil ?? '')}::text[],
      ${cavalos.map((c) => c.principal ?? false)}::boolean[],
      ${cavalos.map((c) => JSON.stringify(c.proprietario ?? {}))}::text[],
      ${cavalos.map((c) => JSON.stringify(c.criador ?? {}))}::text[],
      ${cavalos.map((c) => JSON.stringify(c.pai ?? {}))}::text[],
      ${cavalos.map((c) => JSON.stringify(c.mae ?? {}))}::text[],
      ${cavalos.map((c) => c.sgpeUrl ?? null)}::text[]
    ) as d(id, nome, registro, sexo, nascimento, pelagem, raca, altura, peso,
           descricao, foto_perfil, principal, proprietario, criador, pai, mae, sgpe_url)
    on conflict (id) do update set
      nome = excluded.nome, registro = excluded.registro, sexo = excluded.sexo,
      nascimento = excluded.nascimento, pelagem = excluded.pelagem, raca = excluded.raca,
      altura = excluded.altura, peso = excluded.peso, descricao = excluded.descricao,
      foto_perfil = excluded.foto_perfil, principal = excluded.principal,
      proprietario = excluded.proprietario, criador = excluded.criador,
      pai = excluded.pai, mae = excluded.mae, sgpe_url = excluded.sgpe_url,
      atualizado_em = now()
  `;

  // Provas e mídias de todos os cavalos.
  const provas = [];
  const midias = [];
  for (const c of cavalos) {
    for (const p of c.provas ?? []) provas.push({ ...p, cavaloId: c.id });
    for (const m of c.midias ?? []) midias.push({ ...m, cavaloId: c.id });
  }

  if (provas.length) {
    await sql`
      insert into provas (id, cavalo_id, data, nome, local, categoria, colocacao,
                          tempo_seg, inscritos, premiacao)
      select d.id, d.cavalo_id, d.data::date, d.nome, d.local, d.categoria,
             d.colocacao::int, d.tempo_seg::numeric, d.inscritos::int, d.premiacao
      from unnest(
        ${provas.map((p) => p.id)}::text[],
        ${provas.map((p) => p.cavaloId)}::text[],
        ${provas.map((p) => p.data)}::text[],
        ${provas.map((p) => p.nome)}::text[],
        ${provas.map((p) => p.local ?? '')}::text[],
        ${provas.map((p) => p.categoria ?? '')}::text[],
        ${provas.map((p) => p.colocacao ?? 0)}::int[],
        ${provas.map((p) => p.tempoSegundos ?? 0)}::numeric[],
        ${provas.map((p) => p.inscritos ?? 0)}::int[],
        ${provas.map((p) => p.premiacao ?? null)}::text[]
      ) as d(id, cavalo_id, data, nome, local, categoria, colocacao, tempo_seg, inscritos, premiacao)
      on conflict (id) do update set
        colocacao = excluded.colocacao, tempo_seg = excluded.tempo_seg,
        inscritos = excluded.inscritos, premiacao = excluded.premiacao
    `;
  }

  if (midias.length) {
    await sql`
      insert into midias (id, cavalo_id, tipo, arquivo, legenda, local, poster, duracao_seg)
      select d.id, d.cavalo_id, d.tipo, d.arquivo, d.legenda, d.local, d.poster, d.duracao_seg::int
      from unnest(
        ${midias.map((m) => m.id)}::text[],
        ${midias.map((m) => m.cavaloId)}::text[],
        ${midias.map((m) => m.tipo)}::text[],
        ${midias.map((m) => m.arquivo)}::text[],
        ${midias.map((m) => m.legenda ?? '')}::text[],
        ${midias.map((m) => m.local ?? null)}::text[],
        ${midias.map((m) => m.poster ?? null)}::text[],
        ${midias.map((m) => m.duracaoSegundos ?? null)}::text[]
      ) as d(id, cavalo_id, tipo, arquivo, legenda, local, poster, duracao_seg)
      on conflict (id) do update set
        arquivo = excluded.arquivo, legenda = excluded.legenda, poster = excluded.poster
    `;
  }

  await gravarBaiasEmLote(sql, harasId, acervo.baias ?? []);
}

async function gravarBaiasEmLote(sql, harasId, baias) {
  if (!baias.length) return;

  await sql`
    insert into baias (numero, haras_id, cavalo_id, status, area, ultima_limpeza, atualizado_em)
    select d.numero, ${harasId}, d.cavalo_id, d.status, d.area, d.ultima_limpeza::timestamptz, now()
    from unnest(
      ${baias.map((b) => b.numero)}::text[],
      ${baias.map((b) => b.cavaloId)}::text[],
      ${baias.map((b) => b.status ?? 'emDia')}::text[],
      ${baias.map((b) => b.area ?? 'Haras principal')}::text[],
      ${baias.map((b) => b.ultimaLimpeza ?? null)}::text[]
    ) as d(numero, cavalo_id, status, area, ultima_limpeza)
    on conflict (haras_id, numero) do update set
      cavalo_id = excluded.cavalo_id, status = excluded.status,
      area = excluded.area, ultima_limpeza = excluded.ultima_limpeza,
      atualizado_em = now()
  `;

  const tarefas = [];
  const ocorrencias = [];
  const observacoes = [];
  for (const b of baias) {
    for (const t of b.manejo ?? []) {
      tarefas.push({ ...t, baiaNumero: b.numero, idUnico: `${b.numero}:${t.id}` });
    }
    for (const o of b.ocorrencias ?? []) {
      ocorrencias.push({ ...o, baiaNumero: b.numero, idUnico: `${b.numero}:${o.id}` });
    }
    for (const v of b.observacoes ?? []) {
      observacoes.push({ ...v, baiaNumero: b.numero, idUnico: `${b.numero}:${v.id}` });
    }
  }

  await sql`delete from tarefas_manejo where haras_id = ${harasId}`;
  if (tarefas.length) {
    await sql`
      insert into tarefas_manejo (id, baia_numero, haras_id, tipo, descricao, horario,
                                  quantidade, responsavel, concluida, concluida_em)
      select d.id, d.baia_numero, ${harasId}, d.tipo, d.descricao, d.horario,
             d.quantidade, d.responsavel, d.concluida, d.concluida_em::timestamptz
      from unnest(
        ${tarefas.map((t) => t.idUnico)}::text[],
        ${tarefas.map((t) => t.baiaNumero)}::text[],
        ${tarefas.map((t) => t.tipo)}::text[],
        ${tarefas.map((t) => t.descricao)}::text[],
        ${tarefas.map((t) => t.horario ?? '')}::text[],
        ${tarefas.map((t) => t.quantidade ?? '')}::text[],
        ${tarefas.map((t) => t.responsavel ?? '')}::text[],
        ${tarefas.map((t) => t.concluida ?? false)}::boolean[],
        ${tarefas.map((t) => t.concluidaEm ?? null)}::text[]
      ) as d(id, baia_numero, tipo, descricao, horario, quantidade, responsavel, concluida, concluida_em)
    `;
  }

  await sql`delete from ocorrencias where haras_id = ${harasId}`;
  if (ocorrencias.length) {
    await sql`
      insert into ocorrencias (id, baia_numero, haras_id, data, tipo, descricao, responsavel, resolvida)
      select d.id, d.baia_numero, ${harasId}, d.data::timestamptz, d.tipo, d.descricao,
             d.responsavel, d.resolvida
      from unnest(
        ${ocorrencias.map((o) => o.idUnico)}::text[],
        ${ocorrencias.map((o) => o.baiaNumero)}::text[],
        ${ocorrencias.map((o) => o.data ?? new Date().toISOString())}::text[],
        ${ocorrencias.map((o) => o.tipo)}::text[],
        ${ocorrencias.map((o) => o.descricao)}::text[],
        ${ocorrencias.map((o) => o.responsavel ?? '')}::text[],
        ${ocorrencias.map((o) => o.resolvida ?? false)}::boolean[]
      ) as d(id, baia_numero, data, tipo, descricao, responsavel, resolvida)
    `;
  }

  await sql`delete from observacoes where haras_id = ${harasId}`;
  if (observacoes.length) {
    await sql`
      insert into observacoes (id, baia_numero, haras_id, data, autor, texto)
      select d.id, d.baia_numero, ${harasId}, d.data::timestamptz, d.autor, d.texto
      from unnest(
        ${observacoes.map((v) => v.idUnico)}::text[],
        ${observacoes.map((v) => v.baiaNumero)}::text[],
        ${observacoes.map((v) => v.data ?? new Date().toISOString())}::text[],
        ${observacoes.map((v) => v.autor ?? '')}::text[],
        ${observacoes.map((v) => v.texto)}::text[]
      ) as d(id, baia_numero, data, autor, texto)
    `;
  }
}

// ---------------------------------------------------------------------------
// Roteamento
// ---------------------------------------------------------------------------

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: {
          'access-control-allow-origin': '*',
          'access-control-allow-methods': 'GET,PUT,POST,DELETE,OPTIONS',
          'access-control-allow-headers': 'content-type,authorization',
        },
      });
    }

    const url = new URL(request.url);
    const partes = url.pathname.split('/').filter(Boolean);
    const sql = neon(env.DATABASE_URL);

    // Enquanto não há login, todo o acervo é de um haras só.
    // Quando o login entrar, este id virá do token do usuário.
    const harasId = env.HARAS_ID ?? '00000000-0000-0000-0000-000000000001';

    try {
      // GET /acervo
      if (partes[0] === 'acervo' && request.method === 'GET') {
        return json(await lerAcervo(sql, harasId));
      }

      // PUT /acervo — substituição total (migração entre fontes)
      if (partes[0] === 'acervo' && request.method === 'PUT') {
        const corpo = await request.json();
        for (const c of corpo.cavalos ?? []) {
          await gravarCavalo(sql, harasId, c);
        }
        await gravarBaiasEmLote(sql, harasId, corpo.baias ?? []);
        return json(await lerAcervo(sql, harasId));
      }

      // POST /eventos — lote de analytics
      if (partes[0] === 'eventos' && request.method === 'POST') {
        const corpo = await request.json();
        const lista = corpo.eventos ?? [];
        for (const e of lista) {
          await sql`
            insert into eventos_analiticos (nome, quando, sessao, usuario, tela,
                                            entidade, entidade_id, valor, propriedades, haras_id)
            values (${e.nome}, ${e.quando ?? new Date().toISOString()}, ${e.sessao},
                    ${e.usuario ?? null}, ${e.tela ?? null}, ${e.entidade ?? null},
                    ${e.entidadeId ?? null}, ${e.valor ?? null},
                    ${JSON.stringify(e.propriedades ?? {})}::jsonb, ${harasId})
          `;
        }
        return json({ recebidos: lista.length }, 201);
      }

      // /cavalos/:id
      if (partes[0] === 'cavalos' && partes[1]) {
        const id = decodeURIComponent(partes[1]);

        if (request.method === 'PUT' && !partes[2]) {
          await gravarCavalo(sql, harasId, await request.json());
          return json({ ok: true });
        }
        if (request.method === 'DELETE' && !partes[2]) {
          await sql`delete from cavalos where id = ${id} and haras_id = ${harasId}`;
          return json({ ok: true });
        }
        if (request.method === 'PUT' && partes[2] === 'provas' && partes[3]) {
          await gravarProva(sql, id, await request.json());
          return json({ ok: true });
        }
        if (request.method === 'PUT' && partes[2] === 'midias' && partes[3]) {
          await gravarMidia(sql, id, await request.json());
          return json({ ok: true });
        }
        if (request.method === 'POST' && partes[2] === 'principal') {
          await sql`update cavalos set principal = (id = ${id}) where haras_id = ${harasId}`;
          return json({ ok: true });
        }
      }

      // /baias/:numero
      if (partes[0] === 'baias' && partes[1]) {
        const numero = decodeURIComponent(partes[1]);
        if (request.method === 'PUT') {
          await gravarBaia(sql, harasId, await request.json());
          return json({ ok: true });
        }
        if (request.method === 'DELETE') {
          await sql`delete from baias where numero = ${numero} and haras_id = ${harasId}`;
          return json({ ok: true });
        }
      }

      return erro('Rota não encontrada: ' + url.pathname, 404);
    } catch (e) {
      return erro(e?.message ?? 'Falha inesperada', 500);
    }
  },
};
