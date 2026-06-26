# Página de Lançamentos — como funciona e como publico

> Dono: **Vinicius** (workspace Movelmar). Esta página é uma ferramenta minha — eu uso e mantenho.

## O que é

`lancamentos.html` é uma **vitrine de novidades** da Movelmar (cores, produtos, coleções). Quando sai um lançamento, eu mando **um link só** na circular pro lojista; ele abre e vê o **lançamento da vez** em destaque + o **histórico** completo.

No ar: https://rica-vibecoding.github.io/central_movelmar/lancamentos.html

## Como funciona (a sacada)

Mesma arquitetura da `cores.html`:

- A página é **estática** (GitHub Pages), mas os **dados são ao vivo** do Supabase (banco `ze`, tabela `mvmr_lancamentos`).
- A página **lê** com a *anon key* (só leitura). A segurança (RLS) no banco garante que o site **só enxerga linhas publicadas** (`ativo = true`) — rascunho nunca vaza.
- **Eu escrevo** no banco com a *service key* (que pula a RLS).
- Resultado: pra publicar um lançamento **eu não mexo no código nem dou `git push`** — só insiro uma linha no banco e a página atualiza sozinha.

## A tabela `mvmr_lancamentos` (o que cada campo faz)

| Campo | Pra que serve |
|---|---|
| `titulo` | Nome do lançamento (ex.: cor "Negro"). **Obrigatório.** |
| `subtitulo` | Coleção/linha (ex.: "Coleção Águas"). |
| `descricao` | Texto da arte (o trechinho poético) que aparece no card. |
| `tipo` | `cor`, `produto` ou `colecao`. |
| `data_lancamento` | Data — ordena o histórico. |
| `capa_url` | Imagem de capa do card (a arte). Fica **no próprio repo** em `assets/lancamentos/` e é servida pela URL `github.io`. Se vazio, o card mostra "arte em breve". |
| `material_url` | O que o botão **"Ver material"** abre (PDF, link, etc.). |
| `destaque` | `true` = vira o **card grande no topo** ("lançamento da vez"). Só um por vez. |
| `ordem` | Ordenação manual (menor primeiro); empate desempata por data mais recente. |
| `ativo` | `false` = rascunho, invisível no site. Viro `true` quando publico. |

> Detalhe técnico completo da criação da tabela e da RLS: `migrations/create_mvmr_lancamentos.sql`.

## Como eu publico um lançamento novo (passo a passo)

1. **Arte:** salvo a imagem em `assets/lancamentos/` (ex.: `aguas-negro.jpg`) e dou `git push`. A URL fica `https://rica-vibecoding.github.io/central_movelmar/assets/lancamentos/aguas-negro.jpg`.
2. **Linha no banco:** insiro via REST com a service key (do `.env` do meu workspace). Modelo:

```bash
curl -s -X POST "$SB_ZE_URL/rest/v1/mvmr_lancamentos" \
  -H "apikey: $SB_ZE_SERVICE_KEY" -H "Authorization: Bearer $SB_ZE_SERVICE_KEY" \
  -H "Content-Type: application/json" -H "Prefer: return=representation" \
  -d '{
    "titulo": "Negro",
    "subtitulo": "Coleção Águas",
    "tipo": "cor",
    "descricao": "O Rio Negro, conhecido por suas águas escuras e seus meandros sinuosos, inspira fluidez, elegância e a beleza singular da floresta amazônica.",
    "data_lancamento": "2026-06-26",
    "capa_url": "https://rica-vibecoding.github.io/central_movelmar/assets/lancamentos/aguas-negro.jpg",
    "destaque": true,
    "ordem": 0,
    "ativo": true
  }'
```

3. **Pronto.** Abro a página e confiro. Mando o link na circular.

> Pra **tirar o destaque** de um lançamento antigo quando entra um novo: `PATCH` na linha antiga com `destaque=false`. Pra **despublicar**: `ativo=false`. Sempre que der `UPDATE`, seto também `updated_at = now()`.

## Primeiro lançamento previsto: Coleção Águas

Tema = **rios do Brasil** (cada cor = um rio). Tenho a arte/texto da cor **"Negro"** (Rio Negro). Faltam o nº de cores e as artes restantes — o Rica vai passar. Quando chegar, sigo o passo a passo acima.
