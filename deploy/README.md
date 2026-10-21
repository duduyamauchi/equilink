# Deploy

## Estado atual (20/10/2026)

| Serviço | Recurso | Endereço |
| --- | --- | --- |
| Cloudflare Workers (Pages) | app do usuário | https://equilink.quarto-de-milha.workers.dev |
| Cloudflare Workers (Pages) | painel administrativo | https://equilink-admin.quarto-de-milha.workers.dev |
| Neon `aws-sa-east-1` | banco `equilink` | projeto `fragrant-field-06733330` |
| Cloudflare R2 | bucket `equilink-midia` | https://pub-8df2b57f664a42c0ad09120d9bf49cef.r2.dev |
| Cloudflare Worker | API (ponte app ↔ Neon) | https://equilink-api.quarto-de-milha.workers.dev |

O app do usuário está compilado com `EQUILINK_FONTE=http` e lê o acervo do Neon
através do Worker `equilink-api`. O painel ainda usa a fonte em memória.

## Publicar novamente

```bash
# app
cd equilink
flutter build web --release --base-href=/
npx wrangler deploy

# painel
cd equilink_admin
flutter build web --release --base-href=/
npx wrangler deploy
```

Credenciais lidas de `~/.segredos/cloudflare.token` (nunca versionadas):
`CLOUDFLARE_API_TOKEN` e `CLOUDFLARE_ACCOUNT_ID`.

## Banco

```bash
psql "<connection string do Neon>" -f deploy/schema.sql
```

A connection string está em `~/.segredos/neon_projeto.json`.

## Por que existe um Worker de API

Flutter Web não abre conexão TCP: falar com o Postgres direto do navegador é
impossível e exporia a credencial. O Worker `equilink-api` é a ponte — HTTP do
navegador, driver serverless (`@neondatabase/serverless`) para o banco.

## Pendências para produção

1. ~~Fonte de dados~~ — `FonteHttp` apontando para o Worker (feito)
2. ~~Gravação por entidade~~ — contrato evoluído, sem lost update (feito)
3. Login do proprietário e manejo privado
4. Mídia por URL (hoje `Image.asset`, fotos estão no bundle)
5. ~~Ativar R2~~ — feito; bucket `equilink-midia` com domínio público
6. Domínio próprio
7. Painel administrativo apontando para a API
