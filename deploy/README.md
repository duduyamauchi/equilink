# Deploy

## Estado atual (20/10/2026)

| Serviço | Recurso | Endereço |
| --- | --- | --- |
| Cloudflare Workers (Pages) | app do usuário | https://quarto-de-milha.quarto-de-milha.workers.dev |
| Cloudflare Workers (Pages) | painel administrativo | https://quarto-admin.quarto-de-milha.workers.dev |
| Neon `aws-sa-east-1` | banco `quarto-de-milha` | projeto `fragrant-field-06733330` |
| Cloudflare R2 | bucket `quarto-midia` | https://pub-8df2b57f664a42c0ad09120d9bf49cef.r2.dev |

Ambos servem o build estático com dados de demonstração (`FonteMemoria`).
O banco está criado e o schema aplicado (10 tabelas, validado com dados reais),
mas **o app ainda não o consome** — falta a `FonteNeon`.

## Publicar novamente

```bash
# app
cd quarto_de_milha
flutter build web --release --base-href=/
npx wrangler deploy

# painel
cd quarto_admin
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

## Pendências para produção

1. `FonteNeon` — adaptador do contrato `FonteDeDados` para Postgres
2. Gravação por entidade (o contrato atual salva o acervo inteiro)
3. Login do proprietário e manejo privado
4. Mídia por URL (hoje `Image.asset`)
5. ~~Ativar R2~~ — feito; bucket `quarto-midia` com domínio público ativo
6. Domínio próprio
