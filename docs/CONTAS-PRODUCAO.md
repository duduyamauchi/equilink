# Contas e serviços para ir à produção

Lista do que criar, em ordem. O que está marcado como **já temos** não precisa ser
criado de novo.

---

## 1. Já temos

| Serviço | Estado |
| --- | --- |
| **GitHub** (`duduyamauchi`) | conta ativa; repositório `quarto-de-milha` com a branch de código e o `gh-pages` |
| Token de API do GitHub | existe, mas **deve ser revogado e recriado** (ver §5) |

---

## 2. Contas a criar — caminho gratuito

| # | Conta | Para quê | Plano | Custo |
| --- | --- | --- | --- | --- |
| 1 | **Cloudflare** | hospedar os dois apps Flutter (Pages) e guardar fotos/vídeos (R2) | Free | US$ 0 |
| 2 | **Neon** | Postgres gerenciado em São Paulo + login (Better Auth) | Free | US$ 0 |
| 3 | **Registro.br** | domínio `.com.br` | — | ~R$ 40/ano |

> A Cloudflare cobre dois serviços com uma conta: Pages (apps) e R2 (arquivos).
> Ao criar o projeto no Neon, escolher a região **AWS São Paulo (`sa-east-1`)**.

### Observação sobre o Neon

No Free, cada projeto tem **1 GB** de banco e 100 CU-horas/mês. Para o volume inicial
de um haras isso é folgado. O Neon não pausa: escala a zero e acorda na primeira
consulta.

---

## 3. Contas a criar — quando houver cliente pagante

| # | Conta | Para quê | Gatilho |
| --- | --- | --- | --- |
| 4 | **Supabase** | banco + storage + backup num lugar só | banco passando de 1 GB, ou necessidade de backup diário e suporte |
| 5 | **UptimeRobot** (ou similar) | monitorar se o app está no ar | antes do primeiro cliente |
| 6 | **Sentry** (opcional) | capturar erros em produção | quando houver usuários reais |

Esses dois últimos têm plano gratuito suficiente para começar.

---

## 4. Distribuição nas lojas (só se quiser app instalável)

| # | Conta | Para quê | Custo | Pré-requisito |
| --- | --- | --- | --- | --- |
| 7 | **Google Play Console** | publicar o APK/AAB no Android | **US$ 25, taxa única** | conta Google |
| 8 | **Apple Developer Program** | publicar no iOS | **US$ 99/ano** | **Mac** para build e assinatura |

O iOS é o item mais caro e lento. Para os primeiros clientes, o **PWA instalável**
resolve sem passar por loja nenhuma — o app já é Flutter Web.

### Não precisa de conta para

- **Firebase** — não usamos.
- **Serviço de e-mail transacional** — o Auth do Neon/Supabase já envia os e-mails de
  confirmação e recuperação de senha. Só vale trocar por um provedor próprio
  (Resend, Postmark) quando o volume justificar e a marca nos e-mails importar.
- **CDN separada** — a Cloudflare já é a CDN.
- **Servidor / VPS** — não há backend próprio para hospedar neste desenho.

---

## 5. Antes de qualquer coisa: revogar o token exposto

O token `gho_…` do GitHub foi impresso em texto claro durante a publicação e ficou
gravado no `.git/config` (já removido do arquivo, mas o valor continua válido).

**Ações, nesta ordem:**

1. GitHub → Settings → Developer settings → Tokens → **revogar** o token atual.
2. Criar outro, com escopo mínimo (`repo` apenas) e validade curta.
3. Guardar no Git Credential Manager, **nunca** na URL do remote.

Motivo: um token com `repo` dá acesso de escrita a todos os repositórios da conta.
Enquanto ele existir, qualquer histórico ou log que o contenha é uma porta aberta.

---

## 6. Ordem prática de criação

```
1. Revogar o token antigo            (5 min)
2. Cloudflare                       (10 min)  → Pages + R2
3. Neon, região São Paulo           (10 min)  → banco + Auth
4. Registro.br, comprar o domínio   (15 min)  → apontar DNS para a Cloudflare
5. UptimeRobot                      (10 min)  → monitorar o domínio
```

Com 2 e 3 prontos, o trabalho passa a ser código: schema, políticas de acesso,
login e a `FonteNeon`.

---

## 7. Custos consolidados

| Cenário | Mensal | Anual |
| --- | --- | --- |
| **Gratuito** (Cloudflare + Neon Free) | US$ 0 | domínio ~R$ 40 |
| **Com cliente pagante** (Supabase Pro) | ~US$ 25 | ~US$ 300 |
| **Com apps nas lojas** | + US$ 99/mês (iOS) | + US$ 25 único (Android) |

---

## 8. Uma conta que vale considerar: o próprio SGP

Se o cliente quiser sincronizar o histórico esportivo, será necessário **pedir
autorização ao SGP** (contato no rodapé de `sgpsistema.com`). Não é uma conta a
criar, é um acordo a firmar — e sem ele a integração não deve ser feita.
