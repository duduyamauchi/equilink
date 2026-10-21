-- EquiLink — schema inicial
--
-- Objetivo: sair do acervo em memória para um banco relacional com acesso por
-- proprietário. A regra central: o perfil público (fotos, genealogia, histórico)
-- é legível por qualquer visitante; manejo, ocorrências e observações só pelo
-- dono autenticado.
--
-- Este arquivo é idempotente: pode rodar mais de uma vez.

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Proprietários e vínculo de acesso
-- ---------------------------------------------------------------------------

create table if not exists haras (
  id          uuid primary key default gen_random_uuid(),
  nome        text not null,
  cidade      text not null default '',
  telefone    text not null default '',
  criado_em   timestamptz not null default now()
);

-- Um usuário autenticado pode administrar um ou mais haras.
create table if not exists usuario_haras (
  usuario_id  text not null,              -- id do provedor de autenticação
  haras_id    uuid not null references haras(id) on delete cascade,
  papel       text not null default 'proprietario'
              check (papel in ('proprietario', 'operador', 'leitor')),
  primary key (usuario_id, haras_id)
);

-- ---------------------------------------------------------------------------
-- Cavalos
-- ---------------------------------------------------------------------------

create table if not exists cavalos (
  id            text primary key,
  haras_id      uuid not null references haras(id) on delete cascade,
  nome          text not null,
  registro      text not null,
  sexo          text not null check (sexo in ('femea', 'macho')),
  nascimento    date not null,
  pelagem       text not null default '',
  raca          text not null default 'EquiLink',
  altura        text not null default '',
  peso          text not null default '',
  descricao     text not null default '',
  foto_perfil   text not null default '',
  principal     boolean not null default false,
  proprietario  jsonb not null default '{}'::jsonb,
  criador       jsonb not null default '{}'::jsonb,
  pai           jsonb not null default '{}'::jsonb,
  mae           jsonb not null default '{}'::jsonb,
  sgpe_url      text,                      -- link público do SGPe, quando houver
  atualizado_em timestamptz not null default now(),
  unique (haras_id, registro)
);

create index if not exists cavalos_haras_idx on cavalos (haras_id);

-- ---------------------------------------------------------------------------
-- Provas e mídias
-- ---------------------------------------------------------------------------

create table if not exists provas (
  id            text primary key,
  cavalo_id     text not null references cavalos(id) on delete cascade,
  data          date not null,
  nome          text not null,
  local         text not null default '',
  categoria     text not null default '',
  colocacao     integer not null default 0,
  tempo_seg     numeric(8, 3) not null default 0,
  inscritos     integer not null default 0,
  premiacao     text
);

create index if not exists provas_cavalo_idx on provas (cavalo_id, data desc);

create table if not exists midias (
  id            text primary key,
  cavalo_id     text not null references cavalos(id) on delete cascade,
  tipo          text not null check (tipo in ('foto', 'video')),
  arquivo       text not null,             -- URL no R2 ou caminho de asset
  legenda       text not null default '',
  local         text,
  poster        text,
  duracao_seg   integer,
  ordem         integer not null default 0
);

create index if not exists midias_cavalo_idx on midias (cavalo_id, ordem);

-- ---------------------------------------------------------------------------
-- Baias, manejo, ocorrências e observações (dados privados do haras)
-- ---------------------------------------------------------------------------

create table if not exists baias (
  numero         text not null,
  haras_id       uuid not null references haras(id) on delete cascade,
  cavalo_id      text references cavalos(id) on delete set null,
  status         text not null default 'emDia'
                 check (status in ('emDia', 'manutencao', 'atencao')),
  area           text not null default 'Haras principal',
  ultima_limpeza timestamptz,
  atualizado_em  timestamptz not null default now(),
  primary key (haras_id, numero)
);

create table if not exists tarefas_manejo (
  id             text primary key,
  baia_numero    text not null,
  haras_id       uuid not null references haras(id) on delete cascade,
  tipo           text not null
                 check (tipo in ('alimentacao', 'agua', 'exercicio', 'higiene', 'saude')),
  descricao      text not null,
  horario        text not null default '',   -- previsto, HH:mm
  quantidade     text not null default '',
  responsavel    text not null default '',
  concluida      boolean not null default false,
  concluida_em   timestamptz,                -- horário real de execução
  foreign key (haras_id, baia_numero) references baias(haras_id, numero) on delete cascade
);

create index if not exists tarefas_baia_idx on tarefas_manejo (haras_id, baia_numero);

create table if not exists ocorrencias (
  id           text primary key,
  baia_numero  text not null,
  haras_id     uuid not null references haras(id) on delete cascade,
  data         timestamptz not null default now(),
  tipo         text not null check (tipo in ('saude', 'manejo', 'estrutura')),
  descricao    text not null,
  responsavel  text not null default '',
  resolvida    boolean not null default false,
  foreign key (haras_id, baia_numero) references baias(haras_id, numero) on delete cascade
);

create table if not exists observacoes (
  id           text primary key,
  baia_numero  text not null,
  haras_id     uuid not null references haras(id) on delete cascade,
  data         timestamptz not null default now(),
  autor        text not null default '',
  texto        text not null,
  foreign key (haras_id, baia_numero) references baias(haras_id, numero) on delete cascade
);

-- ---------------------------------------------------------------------------
-- Eventos analíticos
-- ---------------------------------------------------------------------------

create table if not exists eventos_analiticos (
  id          bigserial primary key,
  nome        text not null,
  quando      timestamptz not null default now(),
  sessao      text not null,
  usuario     text,
  tela        text,
  entidade    text,
  entidade_id text,
  valor       numeric,
  propriedades jsonb not null default '{}'::jsonb,
  haras_id    uuid references haras(id) on delete set null
);

create index if not exists eventos_quando_idx on eventos_analiticos (quando desc);
create index if not exists eventos_nome_idx on eventos_analiticos (nome);
create index if not exists eventos_haras_idx on eventos_analiticos (haras_id);

-- ---------------------------------------------------------------------------
-- Função auxiliar: o usuário atual tem acesso a este haras?
-- ---------------------------------------------------------------------------

create or replace function tem_acesso_haras(p_haras uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from usuario_haras
    where usuario_id = current_setting('app.usuario_id', true)
      and haras_id = p_haras
  );
$$;

-- Se o provedor de autenticação expuser o usuário em `request.jwt.claims`,
-- esta versão usa esse valor; o app define `app.usuario_id` por requisição.
