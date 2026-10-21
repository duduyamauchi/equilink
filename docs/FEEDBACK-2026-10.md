# Feedback do cliente — análise e plano de correção

Origem: `Considerações.pdf` (manuscrito, 2 páginas, recebido em 19/10/2026).
Este documento transcreve cada ponto, compara com o que existe hoje no código e
propõe como aplicar — com as decisões de produto que dependem do cliente.

---

## 1. Perfil

### 1.1 Abas: Fotos / Vídeos / Genealogia / Histórico
**Situação:** já implementado exatamente assim (`lib/telas/perfil.dart`, `AbasPilula`).

**Observação do cliente:** "Sem fotos (galeria)" e "Rolo de fotos (máx 5 fotos)".

**Como aplicar:**
- O carrossel do topo passa a exibir **no máximo 5 fotos** (hoje exibe todas as 12).
- A galeria completa continua na aba Fotos / tela Fotos e Vídeos.
- Quando não houver foto, mostrar um *placeholder* com as iniciais do animal em vez
  de imagem quebrada.

### 1.2 Bloco de pessoas: Proprietário | Criador | Treinador
**Situação:** existem Proprietário e Criador. **Treinador não existe** no modelo.

**Como aplicar:**
- Novo tipo no núcleo: `Treinador { nome, centroTreinamento }`, com `fromJson`/`toJson`
  e campo opcional em `Cavalo` (retrocompatível: ausente = nulo).
- Perfil passa a mostrar três colunas; Treinador exibe nome e o CT.
- Painel administrativo ganha o campo no diálogo "Proprietário e criador".

### 1.3 Registro e "Sobre o animal"
**Situação:** já existem (registro no cabeçalho e bloco de descrição).

**Como aplicar:** nenhuma mudança de estrutura. Ajustar apenas a ordem visual para
que Registro apareça após o bloco de pessoas, como no rascunho.

### 1.4 Ficha técnica: remover Altura e Peso
**Situação:** existem hoje (`perfil.dart:244-245`) e no modelo.

**Como aplicar:**
- Remover da **exibição** do perfil.
- Manter no modelo e no painel administrativo (dado útil para o haras; remover do
  banco seria perda de informação sem pedido explícito).
- Se o cliente quiser sumir de vez, é uma linha no painel também — decidir.

### 1.5 Edição restrita ao dono da placa (login/senha)
**Situação:** hoje qualquer visitante edita a descrição no perfil público. Não há
autenticação em lugar nenhum.

**Como aplicar — mudança estrutural, a maior do feedback:**
1. Introduzir `Sessao` no núcleo: usuário logado, papel (`visitante`, `proprietario`,
   `admin`) e o conjunto de animais que pode editar.
2. A tela de perfil passa a ler a sessão: ícone de editar só aparece para quem tem
   permissão; a rota protegida redireciona visitantes.
3. Autenticação: começar com senha local por placa (hash no backend) e evoluir para
   provedor externo. Enquanto não houver backend, o **painel administrativo** é a
   única via de edição — o que já é verdade na prática.
4. Pergunta em aberto do cliente ("talvez criar um login? Usuário/Senha?"): sim, é
   necessário. Sem backend, login não protege nada, porque o dado vive no cliente.

> **Bloqueio:** autenticação de verdade exige o backend. Sem ele, "só o dono edita"
> é encenação — qualquer pessoa altera o JSON local. Este item deve entrar junto com
> a API, não antes.

### 1.6 Compartilhar perfil
**Situação:** o texto compartilhado inclui "Histórico: 12 provas, 5 vitórias"
(`servicos/compartilhar.dart:18`). E o site não tem metatags Open Graph — por isso
o WhatsApp mostra o link sem imagem.

**Como aplicar:**
1. **Remover o histórico** do texto compartilhado (pedido explícito).
2. **Imagem no preview do WhatsApp:** o WhatsApp lê `og:image` do HTML da URL
   compartilhada. Como o app é uma SPA que carrega em canvas, é preciso uma rota de
   pré-visualização por cavalo — uma página HTML estática por animal com
   `og:title`, `og:description` e `og:image`, que redireciona para o app. Isso exige
   o backend (ou geração estática por cavalo).
   - Alternativa imediata e barata: ao compartilhar, **anexar a imagem da foto de
     perfil junto do link** (`share_plus` com arquivo). O WhatsApp mostra a foto no
     cartão da mensagem, sem depender de metatag.

---

## 2. Placa de identificação

**Situação:** existe a tela com QR, ficha, três formatos e PDF.

**Observação do cliente:** "não tem necessidade disso; somente nós da empresa geramos
essa ficha. Talvez libere para compartilhar somente o QR Code."

**Como aplicar:**
- Manter a geração de PDF, mas **fora do app público**: mover para o painel
  administrativo (a empresa gera, o cliente não).
- No app do usuário, a tela vira "Compartilhar QR Code": botão que compartilha só a
  imagem do QR (ou o link), sem ficha e sem PDF.
- Pergunta em aberto ("tem alguma consideração?"): sim — manter no painel é o que
  evita que qualquer pessoa imprima uma placa com dados divergentes do cadastro.

---

## 3. Genealogia

### 3.1 Árvore mais visual
**Situação:** a árvore atual desenha conectores e caixas por geração, com recuo.

**Como aplicar:** redesenhar o layout seguindo o rascunho:
- Animal no topo como **círculo** com iniciais/foto.
- Pais como dois círculos ligados por uma linha horizontal em "T".
- Avós e bisavós descendo em pares, com linhas ortogonais.
- Cada nó clicável abre um cartão com nome, registro e pelagem.
- Implementação: `CustomPainter` para as linhas + posicionamento calculado por
  geração, dentro de `InteractiveViewer` para permitir zoom em telas estreitas.

### 3.2 Remover seletor de profundidade
**Situação:** existe o seletor "Pais / Avós / Bisavós" (`genealogia.dart:103`).

**Como aplicar:** remover. A árvore passa a mostrar **sempre até os bisavós**
(4 gerações), que já é o padrão hoje.

### 3.3 "Manter somente a árvore, retirar a lista e ancestrais"
**Situação:** existem três abas: Árvore, Lista e Ancestrais.

**Ambiguidade:** no manuscrito, a frase está **riscada**, indicando dúvida.

**Como aplicar (recomendação):**
- Manter **Árvore** como aba principal.
- Remover a aba **Ancestrais** (redundante: repete as gerações da árvore).
- Manter **Lista** como visão alternativa — é útil para copiar nomes e para
  acessibilidade (leitor de tela não navega bem em árvore desenhada).
- Se o cliente confirmar "somente árvore", remover também a Lista: são 2 arquivos.

---

## 4. Histórico esportivo

### 4.1 Integração com o SGPe
**Situação:** o app tem histórico próprio, digitado no painel. Não há integração.

**O que verifiquei sobre o SGPe** (`sgpsistema.com`):
- O perfil do cavalo é público: `https://www.sgpsistema.com/?id=<id>&page=horse_profile`.
- O HTML é **renderizado no servidor** e contém os dados (Criador, premiação,
  resultados por ano) — tecnicamente raspável.
- **Não existe API pública** documentada, nem endpoint JSON.
- O `robots.txt` bloqueia apenas páginas de ranking, não o perfil do cavalo.

**Como aplicar — duas rotas, com riscos muito diferentes:**

| Rota | O que entrega | Risco |
| --- | --- | --- |
| **A. Link para o SGPe** (recomendada) | Campo `sgpeUrl` por cavalo; o perfil mostra "Ver no SGPe" e "Última atualização". Resolve o pedido do cliente: o histórico completo fica acessível. | nenhum |
| **B. Sincronização automática** | Rotina que lê o perfil e importa provas. | HTML pode mudar sem aviso; uso não autorizado dos dados; manutenção contínua |

**Recomendação:** fazer A agora e, se o cliente quiser B, **pedir autorização ao SGP**
(telefone no rodapé do site) e implementar como um coletor — `FonteSgpe` atrás do
mesmo padrão `FonteDeDados`, rodando no backend, nunca no app.

> Observação para o cliente: "esse app não conseguiria organizar essas informações
> do SGP e expor elas aqui? Isso pode?" — **Sim, é possível tecnicamente. Depende de
> autorização do SGP, não de capacidade técnica.**

### 4.2 "Mostrar última atualização"
**Como aplicar:** o perfil já mostra a data da última limpeza nas baias; falta no
histórico. Adicionar campo `atualizadoEm` no histórico (ou derivar da prova mais
recente importada) e exibir no topo da aba.

---

## 5. Baias → Manejo

### 5.1 Renomear a aba "Baias" para "Manejo"
**Situação:** hoje as abas são `Baias | Manejo | Relatórios`.

**Justificativa do cliente:** cada QR Code aponta para **1 animal**, então listar
baias não faz sentido no contexto da placa.

**Como aplicar:** renomear a primeira aba para `Manejo` e reorganizar em duas abas:
`Manejo | Relatórios`. A tela "Gestão das Baias" continua existindo no **painel
administrativo**, onde faz sentido (visão do haras inteiro).

### 5.2 Manejo editável pelo dono (login/senha) e visível só para ele
**Situação:** hoje o manejo é público no app e editável por qualquer um.

**Como aplicar:** depende do item 1.5 (autenticação + backend). Modelo de
visibilidade:
- **Público:** perfil, fotos, genealogia, histórico.
- **Privado (dono):** rotina de manejo, ocorrências, observações, relatórios.

### 5.3 "Deve mostrar última atualização"
**Situação:** existe `ultimaLimpeza`, mostrada nas baias. Não existe "última
atualização" do manejo.

**Como aplicar:** adicionar `atualizadoEm` na baia, atualizado a cada alteração de
rotina/tarefa, e exibir no cabeçalho da aba.

### 5.4 Rotina de manejo editável (adicionar/excluir)
**Situação:** **já é possível no painel administrativo**; no app do usuário, não.

**Como aplicar:** expor no app apenas para o dono autenticado (item 5.2). O painel
já cobre o caso de a empresa gerenciar pelo cliente.

### 5.5 Registrar o horário em que a tarefa foi realizada
**Situação:** hoje a tarefa guarda apenas `concluida: true/false` e um horário
planejado (`horario`). Não há registro do horário real.

**Como aplicar — mudança de modelo pequena e importante:**
- Novo campo `concluidaEm: DateTime?` em `TarefaManejo` (opcional; ausente = antigo).
- Ao marcar, gravar o instante; ao desmarcar, limpar.
- A tabela de manejo passa a mostrar "Previsto 06:00 · Realizado 06:12" e sinaliza
  atraso acima de um limite configurável (ex.: 30 min).
- Isso também enriquece o analytics: já emitimos `manejo_alternado`; passa a levar
  `atrasoMinutos` e permite medir aderência à rotina.

---

## 6. Item cancelado

"Quando abrir o QR Code → criar uma área do usuário" está **riscado** no manuscrito.
Interpretado como descartado. Se a intenção era manter, muda o escopo do item 1.5:
a área do usuário seria o próprio login do dono.

---

## 7. Priorização proposta

### P0 — rápido, sem dependências, alto valor
| Item | Onde |
| --- | --- |
| Carrossel com no máximo 5 fotos + placeholder sem foto | `perfil.dart` |
| Remover Altura/Peso da ficha técnica | `perfil.dart` |
| Remover histórico do texto compartilhado | `compartilhar.dart` |
| Bloco do Treinador (modelo + perfil + painel) | núcleo + 2 apps |
| Renomear aba Baias → Manejo (2 abas) | `baias.dart` |
| Remover seletor de profundidade da genealogia | `genealogia.dart` |
| Campo `sgpeUrl` + "Ver no SGPe" + "Última atualização" | núcleo + perfil + painel |
| `concluidaEm` nas tarefas + exibição de previsto/realizado | núcleo + painel + app |
| Mover geração de placa para o painel; no app, só compartilhar QR | 2 apps |

### P1 — depende de decisão de produto
| Item | Depende de |
| --- | --- |
| Compartilhar QR apenas (sem ficha) | confirmar escopo da placa |
| Árvore genealógica redesenhada (layout visual) | aprovar o desenho |
| Remover também a aba Lista | confirmar a dúvida riscada |
| Preview com foto no WhatsApp | escolher: anexar imagem (imediato) ou `og:image` (backend) |

### P2 — depende de backend
| Item | Bloqueio |
| --- | --- |
| Login do proprietário | precisa de API + sessão |
| Manejo privado, editável só pelo dono | idem |
| Sincronização SGPe | autorização do SGP + serviço de coleta |

---

## 8. Decisões que preciso do cliente

1. **Placa:** remover do app do usuário por completo, ou manter em modo "compartilhar
   QR apenas"?
2. **Genealogia:** manter a aba Lista (recomendo) ou só a árvore?
3. **Altura/Peso:** remover só da exibição ou também do cadastro?
4. **SGPe:** link manual agora (recomendo) ou buscamos autorização para sincronizar?
5. **Login:** aprovam que só faz sentido junto com o backend?

---

## 9. Nota de escopo

Nove dos dezoito pontos são ajustes pequenos e podem sair sem backend. Os outros
nove giram em torno de **autenticação**, que hoje não existe: sem uma API, "só o
dono vê/edita" não é garantível, porque o dado vive no navegador do visitante.
Recomendo fechar o P0, validar com o cliente e então iniciar o backend com o login.
