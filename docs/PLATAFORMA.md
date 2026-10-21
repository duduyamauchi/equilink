# Plataforma de hospedagem — recomendação

Pergunta: onde colocar o Quarto de Milha para servir clientes reais.

Resposta curta: **Cloudflare Pages (apps) + Neon em São Paulo (banco e login) +
Cloudflare R2 (arquivos) — US$ 0 para começar.** Ao ter clientes pagantes, migre o
banco para **Supabase Pro (US$ 25/mês)**, que traz storage nativo, backup e suporte.

---

## 1. O que o sistema precisa hospedar

Não é "um site". São cinco coisas com perfis diferentes:

| Necessidade | Hoje | Em produção |
| --- | --- | --- |
| App do usuário (Flutter Web) | build estático servido local | CDN global + domínio |
| Painel administrativo (Flutter Web) | build estático servido local | CDN global + domínio |
| API de dados | `FonteMemoria` | banco + API |
| Login do proprietário | **não existe** | autenticação de verdade |
| Fotos e vídeos | assets no bundle | storage com CDN |

O ponto decisivo: o feedback do cliente exige **"somente o proprietário vê e edita
o manejo"**. Isso não pode ser resolvido no aplicativo — precisa ser garantido no
servidor, senão qualquer visitante contorna.

---

## 2. Recomendação

### Cloudflare Pages — para os dois apps Flutter Web

- **Grátis**: builds ilimitados até 500/mês, **bandwidth ilimitado**, 100 domínios
  customizados por projeto, 20.000 arquivos por deploy (o app tem 44).
- CDN global; no Brasil a Cloudflare tem PoP em São Paulo e Rio.
- Deploy via Git: push na branch → build automático.
- Limite que importa: **arquivo único até 25 MiB**. O bundle atual é tranquilo
  (maior arquivo: 6,9 MB do CanvasKit, que nem precisa ser publicado — vem do CDN
  da Google).

### Supabase — para dados, login e arquivos

- **Postgres gerenciado em São Paulo (`sa-east-1`)**, com Auth, Storage e API REST
  embutidos.
- **Row Level Security (RLS)**: a regra "o dono só vê o que é dele" é escrita em
  SQL e aplicada pelo banco em toda query. É a única forma de cumprir o pedido do
  cliente sem confiar no app.
- Auth pronta: e-mail/senha, magic link, recuperação de senha, MFA.
- Storage com CDN para fotos e vídeos (o plano Pro inclui 100 GB).
- **Pro: US$ 25/mês**, com 8 GB de banco, 250 GB de egress, backup diário de 7 dias,
  e US$ 10 de crédito de compute (cobre uma instância Micro).
- Free tier serve para desenvolvimento: 2 projetos, 500 MB, mas **pausa após 1
  semana sem uso** — não use em produção.

### Por que não um PaaS só (Railway, Render, Fly)

Também funcionam e são mais baratos no começo (Railway Hobby: US$ 5/mês com US$ 5
de uso). A diferença é que neles **você implementa login, upload, permissões e
backup**. Para uma equipe pequena, isso é semanas de trabalho e superfície de erro
de segurança; no Supabase vem pronto e testado em batalha.

Use Railway se, mais adiante, precisar de um serviço com processo longo (sincronizar
SGPe, gerar relatórios pesados). Ele convive bem com o Supabase.

---

## 3. Custo real de começar

| Item | Custo |
| --- | --- |
| Cloudflare Pages | US$ 0 |
| Supabase Pro | US$ 25/mês |
| Domínio `.com.br` | ~R$ 40/ano (Registro.br) |
| Play Store (Android) | US$ 25 taxa única |
| App Store (iOS) | US$ 99/ano |
| **Total mensal com web + Android** | **≈ US$ 25–27** (~R$ 140) |

Para 100 clientes, isso é ~R$ 1,40 por cliente/mês em infraestrutura. O gargalo de
custo será suporte, não hospedagem.

---

## 4. Como isso encaixa no código que já existe

A arquitetura foi feita para esta troca. Nenhuma tela muda.

```
FonteDeDados (contrato)
├── FonteMemoria   ← hoje
├── FonteHttp      ← pronta, esperando uma API
└── FonteSupabase  ← nova, falando direto com o Postgres via RLS
```

O trabalho é:

1. **Banco**: tabelas `cavalos`, `baias`, `provas`, `midias`, `tarefas`, `ocorrencias`,
   `observacoes`, `eventos_analiticos`, mais `haras` e `usuarios_haras` (vínculo).
2. **RLS**: políticas por `auth.uid()`; leitura pública apenas do perfil, genealogia
   e histórico; manejo e ocorrências só para o dono.
3. **`FonteSupabase`**: implementa `carregar()` e `salvar()` do contrato atual.
4. **Auth no app**: tela de login, sessão no `Analytics` (já existe campo `usuario`),
   e o botão "Editar" só aparece para quem tem permissão.
5. **`FonteHttp`**: mantida para clientes que quiserem API própria, e para o painel
   administrativo operar por um endpoint com service role.

### Um ajuste de contrato importante

Hoje `salvar()` grava o **acervo inteiro**. Isso funcionou porque havia um usuário e
um navegador. Com vários clientes simultâneos, duas pessoas editando salvariam por
cima uma da outra (lost update).

Antes de ir para produção, o contrato precisa evoluir para gravação por entidade
(`salvarCavalo`, `salvarBaia`, …) — o `Repositorio` já tem esses métodos; é a fonte
que precisa expor operações granulares. É a mudança mais relevante e deve entrar
junto com o backend, não depois.

---

## 5. Ordem de implantação

| Fase | Entrega | Bloqueia o quê |
| --- | --- | --- |
| 1 | Cloudflare Pages com os dois apps (domínio + HTTPS) | nada |
| 2 | Supabase: schema + RLS + `FonteSupabase` | nada |
| 3 | Login, manejo privado, edição por dono | feedback do cliente |
| 4 | Storage para fotos/vídeos (sair do bundle) | app pequeno |
| 5 | Eventos analíticos no Postgres (trocar `ColetorHttp`) | analytics real |
| 6 | Lojas: Play (US$ 25) e iOS (US$ 99/ano, exige Mac + conta Apple) | distribuição mobile |

O iOS é o item mais lento e caro: exige conta de desenvolvedor Apple e um Mac para
build e assinatura. Para os primeiros clientes, o app web instalável (PWA) resolve
sem passar pelas lojas.

---

## 6. Riscos e cuidados

- **LGPD**: o banco guarda nome, telefone e cidade de proprietários. Escolher região
  no Brasil (`sa-east-1`) já resolve residência de dados; falta política de
  privacidade e prazo de retenção. A senha nunca deve ser armazenada pelo app — o
  Auth do Supabase cuida do hash.
- **Chave anon é pública**: com Supabase direto do cliente, a `anon key` fica no
  bundle. Isso é normal, **desde que a RLS esteja correta**. Testar as políticas com
  um usuário de cada tipo antes de abrir para clientes.
- **Backup**: o Pro dá 7 dias. Para dados de clientes, considere PITR (US$ 100/mês)
  ou um `pg_dump` agendado para storage próprio.
- **Egress de vídeo**: 250 GB/mês parece muito, mas vídeo de treino consome rápido.
  No começo, mantenha vídeos curtos ou limite-os ao dono autenticado.
- **Domínio**: registrar no Registro.br e apontar para a Cloudflare. Evite depender
  do domínio do GitHub Pages, que é do projeto e não do negócio.

---

## 7. Alternativas, quando fariam sentido

| Plataforma | Quando escolher |
| --- | --- |
| **Firebase** (Google) | se a equipe já usa GCP e quer Firestore/NoSQL; em compensação, consultas relacionais (genealogia, relatórios) ficam piores |
| **Railway** | quando houver serviço de longa duração (sync SGPe) ou preferir API própria em Node/Dart |
| **Render** | similar ao Railway, com Postgres gerenciado; free tier hiberna |
| **Vercel** | só se o foco for web e não houver banco; ótimo DX, mas auth/DB são de terceiros |
| **AWS/GCP direto** | a partir de dezenas de milhares de usuários ou exigência de contrato/compliance; hoje seria custo de operação sem retorno |

---

## 8. Veredito

Para servir clientes reais, com login, dados de cliente e a exigência de privacidade
do feedback:

1. **Cloudflare Pages** para os apps — grátis, rápido, domínio próprio.
2. **Supabase em São Paulo** para dados, login e mídia — US$ 25/mês, RLS resolvendo
   o "só o dono vê" no banco.
3. **Railway** apenas se e quando surgir um processo de longa duração.

Total ~US$ 25/mês, com espaço de sobra para os primeiros clientes, e sem retrabalho:
o contrato `FonteDeDados` já prevê a troca.

---

## Adendo: dá para começar com US$ 0?

Sim. A recomendação de US$ 25 foi por produção, não porque não exista opção gratuita.
Abaixo, o que cada free tier realmente entrega para **este** sistema.

### Por que o free tier do Supabase não serve para clientes reais

| Limite | Consequência |
| --- | --- |
| **Pausa após 1 semana sem uso** | o app de um cliente fica fora do ar até alguém entrar no painel e retomar à mão |
| 500 MB de banco | suficiente para começar, apertado com fotos e eventos |
| 1 GB de arquivos, 50 MB por arquivo | não cabe vídeo de treino |
| 2 projetos ativos | um para produção, nenhum para homologação |
| Sem backup | dados de cliente sem cópia |

A pausa é o item decisivo: um haras pode passar dez dias sem abrir o app.

### Alternativas gratuitas que funcionam de verdade

| Plataforma | Free tier | Região no Brasil | Pausa |
| --- | --- | --- | --- |
| **Neon** (Postgres) | 1 GB/projeto, 100 CU-horas/mês, 100 projetos, 10 branches, restore de 6 h | **Sim** (`aws-sa-east-1`) — Postgres e Auth | **não pausa**: escala a zero em 5 min e acorda sozinho em ~1 s |
| **Cloudflare R2** (arquivos) | 10 GB, 1 M escritas, 10 M leituras/mês, **egress grátis** | rede global | — |
| **Cloudflare Pages** (apps) | builds 500/mês, **bandwidth ilimitado** | PoP em São Paulo | — |
| Supabase Free | 500 MB, 1 GB de arquivos, 2 projetos | Sim | pausa após 7 dias |
| Firebase Spark | Firestore 1 GiB, Auth grátis | Sim | não pausa |
| Railway Free | apenas US$ 1/mês de uso | não escolhe região fácil | dorme |

### A pilha de custo zero que eu usaria

```
Cloudflare Pages   →  os dois apps Flutter (bandwidth ilimitado)   US$ 0
Neon (São Paulo)   →  Postgres + login                            US$ 0
Cloudflare R2      →  fotos e vídeos (10 GB, egress grátis)       US$ 0
──────────────────────────────────────────────────────────────────────
                                                                  US$ 0
```

No Neon em São Paulo há **Postgres e Auth**, mas **não** há Object Storage nem
Functions — por isso o R2 entra separado. É uma combinação melhor do que parece:
o R2 não cobra egress, que é justamente o custo que dói com vídeo.

### O que muda em relação ao Supabase

| Aspecto | Supabase Pro (US$ 25) | Neon Free (US$ 0) |
| --- | --- | --- |
| Banco e Auth no mesmo lugar | sim | sim |
| Storage nativo | sim (100 GB) | não (usar R2) |
| Login pronto e maduro | Supabase Auth | Managed Better Auth (mais novo) |
| Backup | diário, 7 dias | restore de 6 h + 1 snapshot |
| Suporte | e-mail | comunidade |
| Pausa por inatividade | não | não (escala a zero e volta sozinho) |
| SLA | não (só Team) | não |

### Riscos honestos do caminho gratuito

- **Sem SLA e sem suporte** — se cair, você resolve sozinho.
- **100 CU-horas/mês por projeto**: com escala a zero, uso esporádico fica muito
  abaixo disso; um app com tráfego constante pode estourar.
- **Cold start** de algumas centenas de milissegundos na primeira consulta após
  ociosidade — imperceptível no app, mas existe.
- **Free tiers mudam** sem aviso. Não construa o negócio sobre um deles sem plano B.
- **Managed Better Auth é recente**: validar login, recuperação de senha e sessão
  antes de abrir para clientes.

### Quando migrar para pago

| Gatilho | Ação |
| --- | --- |
| Primeiro cliente pagante | Neon Launch (uso, ~US$ 15) ou Supabase Pro |
| Banco passando de 1 GB | idem |
| Precisa de backup diário e suporte | Supabase Pro |
| Vídeo passando de 10 GB no R2 | R2 é barato: US$ 0,015/GB |

### Recomendação revisada

**Comece em US$ 0** com Pages + Neon (São Paulo) + R2. O contrato `FonteDeDados`
foi feito exatamente para isso: trocar de Neon para Supabase, ou de R2 para
Storage nativo, é implementar uma classe — nenhuma tela muda.

Passe para pago no primeiro cliente pagante, não antes.
