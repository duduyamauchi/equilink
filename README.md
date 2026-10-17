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

Os dados vêm de uma fonte em memória (`FonteMemoria`), semeada com um acervo de
demonstração: cinco animais, baias 01 a 05, doze provas e uma galeria de fotos e
vídeos. O painel administrativo edita esse acervo ao vivo.

**Limite importante:** por ser em memória, o acervo é por sessão do navegador —
recarregar a página restaura o estado inicial, e duas abas não compartilham dados
entre si. Para painel e aplicativo compartilharem o mesmo acervo de verdade, é
preciso um backend; ver [`docs/ARQUITETURA.md`](docs/ARQUITETURA.md), que explica
como trocar a fonte sem mexer em nenhuma tela.

Para apontar para um backend real, basta compilar com
`--dart-define=QUARTO_FONTE=http --dart-define=QUARTO_API=<endereço>`. A API precisa
responder `GET /acervo` e aceitar `PUT /acervo` no mesmo JSON que o painel exporta.

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
