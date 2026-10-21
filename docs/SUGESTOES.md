# Sugestões do cliente

O cliente anota, em cada página do painel, o que gostaria que ela fizesse. O
desenvolvedor (ou um agente) lê a fila e implementa.

## Por que assim

A sugestão nasce **ancorada na página**: o botão "Sugestões" fica em todas as
telas e grava a rota atual. Quem implementa não precisa adivinhar onde mexer —
a rota está no registro e, opcionalmente, um caminho de arquivo.

## Modelo

Tabelas em `deploy/migracao_sugestoes.sql`.

| Campo | Para que serve a quem implementa |
| --- | --- |
| `rota` | página exata (`/cavalos`, `/provas`, `/cavalos/novo`) |
| `referencia` | dica opcional: `arquivo.dart#Símbolo` |
| `titulo` | resumo de uma linha |
| `texto` | o pedido completo, nas palavras do cliente |
| `status` | `aberta` → `em_andamento` → `implementada` / `recusada` |
| `prioridade` | `baixa`, `normal`, `alta` |
| `versao` | cresce a cada edição |

Apagar é **exclusão lógica** (`apagada_em`): some da lista do cliente, o
histórico permanece.

`sugestoes_historico` é append-only: um instantâneo por mudança, com autor e
ação (`criada`, `editada`, `status`, `apagada`). É o "histórico do git" que o
cliente vê no botão de histórico.

## API

| Método | Rota | Efeito |
| --- | --- | --- |
| GET | `/sugestoes?rota=/cavalos&apagadas=1` | lista do usuário |
| POST | `/sugestoes` | cria (`rota`, `titulo`, `texto`, `referencia?`, `prioridade?`) |
| PUT | `/sugestoes/:id` | edita conteúdo, incrementa `versao` |
| PATCH | `/sugestoes/:id` | muda só o `status` |
| DELETE | `/sugestoes/:id` | apaga (lógico) |
| GET | `/sugestoes/:id/historico` | versões, da mais nova para a mais antiga |

Todas exigem sessão. Cada usuário vê apenas as próprias sugestões.

## Implementando uma sugestão

1. Ler a fila aberta:

```sql
select id, rota, referencia, titulo, texto, prioridade, criado_em
from sugestoes
where status = 'aberta' and apagada_em is null
order by case prioridade when 'alta' then 0 when 'normal' then 1 else 2 end,
         criado_em;
```

2. Abrir o arquivo indicado em `referencia` (ou seguir `rota` → `lib/rotas.dart`)
   e implementar.
3. Marcar o andamento pela interface do painel, ou:

```bash
curl -X PATCH "$API/sugestoes/<id>" -H 'content-type: application/json' \
  -d '{"status":"implementada"}'
```

## Limites

- 500 sugestões por leitura, 8 000 caracteres por texto.
- `rota` e `titulo` são obrigatórios; a API recusa texto vazio.
- O histórico cresce com o uso; nenhuma rotina de poda existe hoje.
