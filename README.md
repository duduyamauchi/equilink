# Quarto de Milha

Sistema de gestão e identidade digital para haras de cavalos Quarto de Milha, em
português do Brasil. Três projetos, um núcleo compartilhado.

| Projeto | O que é | Plataformas |
| --- | --- | --- |
| [`quarto_de_milha`](quarto_de_milha/) | Aplicativo do usuário: perfil, genealogia, histórico esportivo, galeria e baias | Web, Android, iOS |
| [`quarto_admin`](quarto_admin/) | Painel administrativo: CRUD do acervo, indicadores, **analytics** e inspeção da fonte | Web |
| [`pacotes/quarto_core`](pacotes/quarto_core/) | Modelos, contrato de fonte de dados e fachada usada pelos dois apps | — |

## Por onde começar

- **Entender a arquitetura, plugar um banco e usar o analytics:** [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md)
- **Rodar tudo localmente:** `python ferramentas/servir.py`
- **Testar:** `flutter test` dentro de cada projeto

## Estado atual

**Publicado e lendo do Postgres.** Os três componentes conversam de verdade:

| Recurso | URL |
| --- | --- |
| App do usuário | https://quarto-de-milha.quarto-de-milha.workers.dev |
| Painel administrativo | https://quarto-admin.quarto-de-milha.workers.dev |
| API (ponte app ↔ Neon) | https://quarto-api.quarto-de-milha.workers.dev |

O acervo vive num Postgres no Neon e os dois apps o consomem pela API. Sem
argumentos de build, ambos usam a fonte em memória com o acervo de demonstração
— útil para desenvolvimento offline e para os testes.

### Por que existe uma API

Flutter Web não abre conexão TCP: falar com o Postgres direto do navegador é
impossível e exporia a credencial do banco. O Worker `quarto-api` é a ponte —
HTTP do navegador, driver serverless para o banco. O app usa a `FonteHttp` que já
existia; nenhuma tela precisou mudar.

### Gravação por entidade

O contrato `FonteDeDados` evoluiu de "salvar o acervo inteiro" para operações por
entidade (`salvarCavalo`, `salvarBaia`, `salvarProva`, `salvarMidia`, …). Isso
elimina o *lost update*: dois operadores editando registros diferentes não se
sobrescrevem mais. `salvar(acervo)` continua existindo como fallback para fontes
que não suportam escrita granular.

Para apontar para um backend, compile com
`--dart-define=QUARTO_FONTE=http --dart-define=QUARTO_API=<endereço>`.

## Analytics

O aplicativo instrumenta a jornada do usuário (telas, mídias, manejo) e o painel
lê esses eventos. O modelo é genérico — nome livre + propriedades + valor — para
cobrir, sem mudanças no núcleo, casos como pagamentos, funil de conversão e
retenção:

```dart
analytics.pagamento('mensalidade', 14990, status: 'aprovado');
analytics.funil('assinatura', 'plano_escolhido');
```

O painel tem abas de **visão geral, eventos, funil e retenção**, com importação do
JSON exportado pelo aplicativo. Telemetria nunca lança: uma falha no destino é
registrada, jamais interrompe a ação do usuário. Detalhes em
[`docs/ARQUITETURA.md`](docs/ARQUITETURA.md).
