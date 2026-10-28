# Passagem do projeto — Eduardo → Edson (EdYuTo)

Última atualização: 2026-10-28.

Destinatário: **Edson Y. Toma** — `edson.yudi.toma@gmail.com`, GitHub `EdYuTo`
(id 18668585).

Este documento é o checklist da transferência. A seção 1 lista o que o Eduardo
já fez, a 2 o que ainda depende dele, a 3 o que depende do Edson e a 4 o
inventário do que está sendo entregue.

---

## 1. Já executado (2026-10-28)

| Item | Estado |
| --- | --- |
| Transferência de `duduyamauchi/equilink` para `EdYuTo` | **pedida**, aguardando aceite (expira em 24 h) |
| Transferência de `duduyamauchi/equilink-infra` para `EdYuTo` | **pedida**, aguardando aceite (expira em 24 h) |
| Convite de colaborador (escrita) nos dois repositórios | enviado |
| Convite para a organização Neon `Equilink` como **admin** | enviado |

A transferência pelo GitHub só se completa quando o Edson clicar no link do
e-mail "You've been invited to collaborate on…"/"transfer". Se expirar, basta
repetir o pedido:

```bash
TOKEN=$(printf 'protocol=https\nhost=github.com\n\n' | git credential fill | sed -n 's/^password=//p')
curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.github+json' \
  -d '{"new_owner":"EdYuTo"}' https://api.github.com/repos/duduyamauchi/equilink/transfer
curl -X POST -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.github+json' \
  -d '{"new_owner":"EdYuTo"}' https://api.github.com/repos/duduyamauchi/equilink-infra/transfer
```

Depois do aceite, o GitHub re-adiciona o dono anterior como colaborador do
repositório transferido; o Edson pode remover o Eduardo em Settings →
Collaborators quando quiser encerrar o acesso.

---

## 2. Pendente do lado do Eduardo

### 2.1 Convite na Cloudflare (só pelo painel)

O token em `~/.segredos/cloudflare.token` tem permissão de **Workers/R2** e
**leitura** de conta, mas **não** de gerenciar membros: `POST
/accounts/{id}/members` devolve `403`. O convite tem de ser feito à mão:

1. <https://dash.cloudflare.com/5a6dba3ad4226ffea81ff99285c032c8/members>
2. **Invite** → `edson.yudi.toma@gmail.com` → papel **Administrator**
   (*Administrator* inclui Workers, R2, DNS, membros e faturamento; para ele
   ficar independente, essa é a escolha certa).
3. Se a intenção for mantê-lo longe do faturamento, use um papel customizado
   com **Workers Scripts: Edit**, **Workers R2 Storage: Edit**,
   **Account Settings: Read** e **Account Members: Read** — mas ele não
   conseguirá adicionar nem remover outros membros.

Sem esse passo o Edson **não** consegue publicar (`wrangler deploy` falha com
autenticação), porque o token de deploy pertence à conta do Eduardo.

### 2.2 Rotação das credenciais, depois do aceite

Combinado: o Edson recebe as chaves atuais (para não parar produção) e a
rotação acontece depois que ele confirmar que consegue publicar. Procedimento
completo em `infra/config/rotacao.md`. Ordem recomendada:

| # | Segredo | Efeito |
| --- | --- | --- |
| 1 | `cloudflare.token` | nenhum; republicar os três Workers confirma |
| 2 | `neon.token` | nenhum |
| 3 | `neon_uri.txt` (senha do Postgres) | API fora do ar entre o reset e o deploy |
| 4 | `SESSION_SECRET` | todos precisam entrar de novo |
| 5 | `SERVICE_TOKEN` | scripts com o token antigo param |
| 6 | `PEPPER_SENHA` | **invalida a senha de todos**; só junto com redefinição |

Enquanto as chaves antigas existirem, o Eduardo mantém acesso técnico ao banco
de produção e à Cloudflare — é o principal motivo para rotacionar.

### 2.3 Decidir sobre a conta Neon

O Neon não transfere titularidade de projeto entre contas: o projeto
`fragrant-field-06733330` pertence à organização `Equilink`, que tem o Eduardo
como único admin. O convite dá ao Edson o papel de admin na organização, o que
já permite criar projetos, gerenciar roles e ler o banco. Para sair de vez,
o Eduardo deve remover a própria membership em Neon → Organization → People,
depois que o Edson aceitar.

---

## 3. Pendente do lado do Edson

1. **Aceitar** as duas transferências de repositório (e-mail do GitHub, janela
   de 24 h) e o convite da organização Neon.
2. Clonar e configurar a máquina:

   ```bash
   git clone https://github.com/EdYuTo/equilink.git
   git clone https://github.com/EdYuTo/equilink-infra.git
   mkdir -p ~/.segredos && cp equilink-infra/segredos/* ~/.segredos/
   chmod 700 ~/.segredos && chmod 600 ~/.segredos/*
   ```

3. Ler, nesta ordem: `infra/config/infra.md` (mapa), `infra/config/deploy.md`
   (publicar), `infra/segredos/LEIA-ME.md` (o que cada chave destrava).
4. Confirmar que publica: `cd workers/api && npx wrangler deploy` (com
   `CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID` exportados).
5. Ativar 2FA nas três contas e revogar o token `gho_…` antigo do GitHub
   (`docs/CONTAS-PRODUCAO.md` §5).

### Ajustar os remotes locais

O GitHub redireciona as URLs antigas, mas o correto é apontar para o novo dono:

```bash
git remote set-url origin https://github.com/EdYuTo/equilink.git
# dentro de infra/
git remote set-url origin https://github.com/EdYuTo/equilink-infra.git
```

---

## 4. Inventário entregue

| Ativo | Onde | Observação |
| --- | --- | --- |
| Código (app, painel, núcleo, API) | `EdYuTo/equilink` | público; histórico auditado, sem segredos |
| Segredos e operação | `EdYuTo/equilink-infra` | **privado**; ver `infra/segredos/LEIA-ME.md` |
| App do usuário | <https://equilink.quarto-de-milha.workers.dev> | verificado 2026-10-28: HTTP 200 |
| Painel administrativo | <https://equilink-admin.quarto-de-milha.workers.dev> | HTTP 200 |
| API | <https://equilink-api.quarto-de-milha.workers.dev> | HTTP 200 em `/acervo` |
| Banco | Neon `org-bold-morning-64028684` / projeto `fragrant-field-06733330` | Postgres 17, `aws-sa-east-1`, plano Free |
| Hospedagem/arquivos | Cloudflare conta `5a6dba3ad4226ffea81ff99285c032c8` | 3 Workers + bucket R2 `quarto-midia` |
| Nome de subdomínio | `quarto-de-milha.workers.dev` | vem do nome da conta Cloudflare; renomear a conta muda as URLs dos três Workers |

### O que não é transferível por API

| Item | Motivo | Alternativa |
| --- | --- | --- |
| Titularidade da conta Cloudflare | Cloudflare não transfere contas; só membros | convite de membro (seção 2.1) |
| Titularidade da organização Neon | Neon só suporta convites de membro | convite admin (feito) + saída do Eduardo |
| Domínio registrado | não há domínio comprado ainda (`docs/CONTAS-PRODUCAO.md`) | comprar já no nome do Edson |
| Token `gho_…` do GitHub | pertence à conta `duduyamauchi` | Edson cria o seu próprio |

---

## 5. Contexto técnico para começar

Leitura mínima, na ordem:

1. `README.md` — o que é o produto e como rodar localmente.
2. `docs/ARQUITETURA.md` — fluxo app → proxy `/api` → Worker → Neon, e por que
   existe uma API.
3. `docs/PLATAFORMA.md` e `docs/MODULARIDADE.md` — decisões de produto e de
   estrutura.
4. `docs/FEEDBACK-2026-10.md` — feedback do cliente já registrado.
5. `docs/SUGESTOES.md` — funcionalidade mais recente (tabela `sugestoes`).

Pendências já mapeadas em `deploy/README.md` § "Pendências para produção":
login do proprietário no painel, mídia por URL (hoje `Image.asset`), domínio
próprio e o painel apontando para a API.
