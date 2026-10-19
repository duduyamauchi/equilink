# Auditoria de modularidade

Pergunta: o código é modular "em outros aspectos também, como analytics?"

Resposta curta: **em dados e analytics, sim. Em interface, não.** A separação
existe onde importa para trocar infraestrutura; falta onde causa duplicação real.

---

## 1. O que já está modular (e bem)

| Módulo | Onde | Por que está certo |
| --- | --- | --- |
| **Domínio** | `modelos.dart` | puro Dart, sem Flutter, com serialização tolerante |
| **Fonte de dados** | `fonte_dados.dart` + 2 implementações | trocar memória por Postgres não toca em tela |
| **Fachada** | `repositorio.dart` | telas falam uma API só; escrita otimista + erro |
| **Evento** | `analytics/evento.dart` | puro Dart, esquema livre |
| **Coletores** | `analytics/coletor.dart` | memória, HTTP, console, nulo, composto |
| **Análise** | `analytics/analise.dart` | **puro Dart**, funções puras |

O ponto mais forte é a `Analise`: não importa Flutter, não conhece HTTP, não conhece
widgets. Recebe `List<EventoAnalitico>` e devolve agregados. Isso significa que
**o mesmo cálculo roda no app, no painel e num backend Dart** — e é o que permite
trocar `ColetorMemoria` por um serviço sem reescrever funil ou retenção.

Números: **3.390 linhas de núcleo** contra 5.234 (app) e 4.457 (painel).

### O padrão que se repete

```
Contrato (interface)  →  implementações  →  fachada  →  telas
FonteDeDados          →  memória/http      Repositorio
ColetorAnalytics      →  memória/http/...  Analytics
```

É o mesmo desenho duas vezes. Novos eixos deveriam seguir a mesma forma:
`Contrato → implementações → fachada`.

---

## 2. O que **não** está modular

### 2.1 Dois temas visuais duplicados
`core/tema.dart` existe nos dois apps: 190 linhas no app, 118 no painel. São
paletas diferentes por decisão de design — mas as **constantes geométricas e a
tipografia** são repetidas. Mudar o raio de borda exige editar dois arquivos.

### 2.2 Widgets com o mesmo nome em bases diferentes
`Painel`, `Etiqueta`, `Vazio`, `Campo` existem duplicados nos dois `widgets/comuns.dart`
(569 vs 316 linhas). Não são iguais hoje — as cores divergiram — mas a *estrutura* é
a mesma e vai divergir mais a cada mudança.

### 2.3 `formatos.dart` idêntico nos dois apps
127 linhas, **byte a byte iguais**. É código compartilhado que ficou copiado.

### 2.4 Núcleo ainda acoplado ao Flutter
Três arquivos importam `package:flutter/foundation.dart`:

| Arquivo | Usa | Consequência |
| --- | --- | --- |
| `repositorio.dart` | `ChangeNotifier` | não roda em servidor Dart puro |
| `analytics.dart` | `ChangeNotifier`, `debugPrint` | idem |
| `analytics/coletor.dart` | `debugPrint` | idem |

Isso impede usar o núcleo num backend Dart (ex.: uma API `shelf` no Railway) sem
puxar o framework de UI.

### 2.5 Caminhos de asset espalhados
`'assets/img/act1.jpg'` como fallback aparece em 4 telas + no núcleo +
no painel. Um pacote compartilhado de mídia resolveria; hoje, mover uma imagem
quebra em vários pontos.

### 2.6 Cálculo de apresentação nas telas
`reduce((a, b) => a > b ? a : b)` para achar o maior valor de um gráfico aparece
em 3 telas. É cálculo simples, mas é o tipo de coisa que deveria ser uma função
pura testável (`Analise.maiorValor`), não lógica de widget.

---

## 3. Por que isso aconteceu (e por que não é grave)

O painel nasceu depois do app, e a decisão consciente foi **não** criar um pacote
de UI compartilhada: os dois produtos têm linguagens visuais distintas (app do
produtor × ferramenta operacional). Duplicar 316 linhas de widgets foi mais barato
que abstrair cedo demais.

O custo aparece agora, não antes: com dois apps estáveis, extrair é seguro; antes,
seria adivinhação.

---

## 4. Plano de modularização

### Fase 1 — barato e sem risco (vale fazer já)

| Ação | Ganho |
| --- | --- |
| Mover `formatos.dart` para `quarto_core` (já é código puro) | remove 127 linhas duplicadas |
| `Analise.maiorValor` / `menorValor` no núcleo | remove lógica de 3 telas |
| Constante `Midia.fallbackImagem` no núcleo | remove 6 strings mágicas |
| Extrair `quarto_ui` com **primitivas neutras**: espaçamento, raios, `Painel`, `Vazio`, `Campo`, `Etiqueta` recebendo cores por parâmetro | elimina ~250 linhas duplicadas sem unificar a identidade visual |

> O truque para não engessar o design: o widget base aceita a paleta; cada app
> injeta a sua. Estrutura compartilhada, aparência independente.

### Fase 2 — desacoplar o núcleo do Flutter

Trocar `ChangeNotifier` por um `Observable` mínimo próprio (ou usar `signals`
/ `riverpod` puro Dart), e `debugPrint` por uma função injetável.

Ganho concreto: o núcleo passa a compilar para **Dart puro**, então:
- a API do backend pode importá-lo (mesmas validações, mesma serialização);
- a `Analise` roda em job agendado no servidor;
- testes ficam mais rápidos, sem `flutter_test`.

Custo: médio. Só faça quando o backend existir — hoje o ganho é teórico.

### Fase 3 — empacotar por domínio

Se o produto crescer (reprodução, financeiro, sanidade), o núcleo vira vários
pacotes:

```
pacotes/
├── quarto_dominio/      modelos + regras
├── quarto_dados/        fontes + repositório
├── quarto_analytics/    eventos + coletores + análise
└── quarto_ui/           primitivas visuais
```

**Não fazer isso agora.** Um pacote por camada, com um produto só, adiciona
cerimônia sem retorno. O gatilho é o segundo consumidor real (backend ou app
novo).

---

## 5. Veredito

| Aspecto | Modular? |
| --- | --- |
| Trocar banco de dados | ✅ sim (`FonteDeDados`) |
| Trocar destino de telemetria | ✅ sim (`ColetorAnalytics`) |
| Rodar análise fora do app | ✅ sim (`Analise` é puro Dart) |
| Evitar duplicação entre os apps | ❌ não (`formatos`, widgets, tema) |
| Rodar o núcleo sem Flutter | ❌ não (`ChangeNotifier`) |
| Trocar a identidade visual | ⚠️ parcial (cores espalhadas nas telas) |

O código é modular onde a modularidade **paga a conta**: infraestrutura trocável.
Não é modular onde a abstração **ainda não se pagou**: UI de dois produtos distintos.

A Fase 1 é barata e eu recomendo fazer antes do backend — ela reduz a superfície que
o backend terá de tocar.


---

## Execução da Fase 1 (concluída)

| Ação | Resultado |
| --- | --- |
| `formatos.dart` movido para `quarto_core` | 127 linhas duplicadas removidas; 2 cópias → 1 |
| `Analise.maiorValor` / `menorValor` / `normalizar` | 7 `reduce` espalhados em telas substituídos |
| `MidiaPadrao.imagem` / `capaVideo` no núcleo | 6 strings mágicas de asset removidas |
| Pacote `quarto_ui` com primitivas neutras | `Painel`, `Etiqueta`, `Vazio`, `Campo`, `Secao` compartilhados |
| `PaletaUi` + `EscopoUi` | cada app injeta a sua paleta; identidade visual preservada |

### Números

| Arquivo | Antes | Depois |
| --- | --- | --- |
| `quarto_de_milha/lib/widgets/comuns.dart` | 569 | 538 |
| `quarto_admin/lib/widgets/comuns.dart` | 316 | 227 |
| `pacotes/quarto_ui/lib` | — | 338 (novo, compartilhado) |

A contagem bruta não cai muito porque o código mudou de lugar — mas a **duplicação
caiu**: `Painel`, `Etiqueta`, `Vazio` e `Campo` agora existem uma vez, e cada app
mantém só um adaptador fino que injeta a sua paleta.

### Verificação

- `flutter analyze` limpo nos quatro pacotes
- 85 testes passando (42 núcleo + 25 app + 18 painel)
- App e painel abertos no navegador: perfil, baias com etiquetas de status e a
  visão geral do painel renderizam **idênticos** ao estado anterior

### O que ficou para depois

- `SecaoUi` foi criada, mas `TituloSecao` (app) e `CabecalhoSecao` (painel) ainda
  não a usam — têm diferenças de tipografia que merecem decisão de design.
- `Indicador` e `FaixaErro` continuam só no painel (não há equivalente no app).
- `BarraProporcao` e `BotaoDourado` continuam só no app.
- Fase 2 (desacoplar do Flutter) segue parada, como planejado.
