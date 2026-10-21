-- Sugestões do cliente, por página do painel
--
-- Objetivo: o cliente anota o que quer em cada tela, o desenvolvedor (ou um
-- agente) lê e implementa. Por isso cada sugestão carrega metadados que
-- apontam para o código: a rota da página e uma referência opcional ao arquivo
-- ou símbolo.
--
-- `sugestoes` guarda o estado atual; `sugestoes_historico` é um log append-only
-- com um instantâneo por mudança (como um histórico de git). Apagar é lógico:
-- a linha sai da visão do cliente, mas o histórico continua para auditoria.

create table if not exists sugestoes (
  id            uuid primary key default gen_random_uuid(),

  -- Dono e escopo
  haras_id      uuid not null references haras(id) on delete cascade,
  usuario_id    text not null,          -- quem sugeriu

  -- Onde
  rota          text not null,          -- '/cavalos', '/provas', '/cavalos/novo'
  referencia    text,                   -- dica para o agente: arquivo#símbolo

  -- O que
  titulo        text not null,
  texto         text not null,
  status        text not null default 'aberta'
                check (status in ('aberta', 'em_andamento', 'implementada', 'recusada')),
  prioridade    text not null default 'normal'
                check (prioridade in ('baixa', 'normal', 'alta')),

  -- Versão atual; cada edição incrementa e grava uma linha no histórico
  versao        integer not null default 1,

  criado_em     timestamptz not null default now(),
  atualizado_em timestamptz not null default now(),
  apagada_em    timestamptz             -- exclusão lógica
);

-- Consulta principal: "minhas sugestões nesta página", mais recentes primeiro.
create index if not exists sugestoes_pagina_idx
  on sugestoes (haras_id, usuario_id, rota, atualizado_em desc);

-- Fila de trabalho: o que ainda não foi implementado.
create index if not exists sugestoes_abertas_idx
  on sugestoes (haras_id, status, prioridade, criado_em desc)
  where apagada_em is null;

create table if not exists sugestoes_historico (
  id          bigserial primary key,
  sugestao_id uuid not null references sugestoes(id) on delete cascade,
  versao      integer not null,
  acao        text not null check (acao in ('criada', 'editada', 'status', 'apagada')),
  titulo      text not null,
  texto       text not null,
  status      text not null,
  prioridade  text not null,
  referencia  text,
  rota        text not null,
  autor       text not null,            -- quem fez esta alteração
  quando      timestamptz not null default now()
);

create index if not exists sugestoes_historico_idx
  on sugestoes_historico (sugestao_id, versao desc);

comment on table sugestoes is
  'Sugestões do cliente por página do painel. `rota` é a página, `referencia` aponta para o código.';
comment on column sugestoes.referencia is
  'Dica para quem implementa: caminho do arquivo e símbolo, ex. equilink_admin/lib/telas/cavalos.dart#TelaCavalos';
comment on column sugestoes.apagada_em is
  'Exclusão lógica: some da visão do cliente, permanece para auditoria.';
