# EquiLink

Aplicativo Flutter de identidade digital e gestão de haras para cavalos Quarto de Milha,
em português do Brasil. Roda em **web**, **Android** e **iOS** a partir de um único
código-fonte.

## Versão publicada

**https://equilink.quarto-de-milha.workers.dev**

Servido por um Cloudflare Worker que hospeda o build e encaminha `/api/*` para a
API. O sufixo `quarto-de-milha` é o subdomínio da conta Cloudflare, que a API
recusa alterar.

Para republicar após uma alteração:

```bash
flutter build web --release --base-href=/ --no-web-resources-cdn \
  --dart-define=EQUILINK_FONTE=http \
  --dart-define=EQUILINK_API=/api
npx -y wrangler@latest deploy
```

Sem `--base-href`, os arquivos são procurados na raiz do domínio
(`duduyamauchi.github.io/`) e a página abre em branco.

## Módulos

| Tela | Abas | Conteúdo |
| --- | --- | --- |
| Detalhes do Cavalo | Fotos, Vídeos, Genealogia, Histórico | Identificação, carrossel de mídias, ficha técnica, proprietário, criador e descrição editável |
| Genealogia | Árvore, Lista, Ancestrais | Árvore de ascendentes até os bisavós, relação numerada e resumo por geração |
| Histórico Esportivo | Provas, Resultados, Estatísticas | Provas com colocação e tempo, tabela de resultados, indicadores, evolução mensal e distribuição |
| Fotos e Vídeos | Fotos, Vídeos | Galeria com mídia em destaque, grade de fotos e reprodução de vídeos |
| Gestão das Baias (Haras) | Baias, Manejo, Relatórios | Baias com situação, rotina consolidada do dia e relatórios de consumo e ocupação |
| Baia (detalhe) | Manejo, Ocorrências, Observações | Rotina editável, registro de ocorrências e observações da equipe |
| Placa de identificação | — | QR Code de identidade, ficha impressa, formatos de impressão e exportação em PDF |

A navegação usa barra inferior em telas estreitas e barra lateral em telas largas
(≥ 900 px), mantendo o conteúdo centralizado em até 760 px no desktop.

## Como executar

```bash
flutter pub get
flutter run -d chrome     # web
flutter run -d android    # Android
flutter run -d ios        # iOS
```

## Verificação

```bash
flutter analyze
flutter test
flutter build web --release
```

## Arquitetura

```
lib/
├── main.dart                  ponto de entrada
├── app.dart                   MaterialApp.router, tema e idioma pt-BR
├── escopo.dart                RepositorioEscopo (InheritedNotifier)
├── rotas.dart                 go_router com StatefulShellRoute e moldura de navegação
├── core/
│   ├── tema.dart              paleta, raios, espaçamentos e ThemeData
│   └── formatos.dart          datas, tempos, medidas e idade no padrão brasileiro
├── dados/
│   ├── modelos.dart           Cavalo, Ancestral, Prova, Midia, Baia, ...
│   ├── dados_semente.dart     plantel, genealogia, provas e baias de demonstração
│   └── repositorio.dart       fonte única de dados (ChangeNotifier) e regras de negócio
├── servicos/
│   ├── compartilhar.dart      compartilhamento do perfil e QR Code
│   └── placa_pdf.dart         geração da placa de identificação em PDF
├── widgets/
│   ├── comuns.dart            abas em pílula, etiquetas, painéis, barras, botões
│   └── visualizador_midia.dart visualizador de fotos e vídeos
└── telas/                     uma tela por módulo do guia visual
```

Os dados de demonstração vivem em memória. Para conectar uma API real, basta
substituir a implementação de `Repositorio`: as telas observam as mudanças por
`RepositorioEscopo.de(context)` e não conhecem a origem dos dados.

## Identidade visual

| Token | Valor | Uso |
| --- | --- | --- |
| `Cores.escuro` | `#0A1A19` | barras, abas ativas, botões secundários |
| `Cores.dourado` | `#A6834B` | ações principais e destaques |
| `Cores.fundo` | `#F0EFEB` | plano de fundo |
| `Cores.verde` | `#6FA047` | situação "Em dia" e vitórias |
| `Cores.ambar` | `#EAA40E` | situação "Manutenção" e 2º/3º lugares |

Tipografia **Poppins**. Créditos das fotos e vídeos de demonstração em
[`assets/CREDITOS.md`](assets/CREDITOS.md).
