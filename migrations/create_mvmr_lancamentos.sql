-- ============================================================
-- Migration: cria a tabela mvmr_lancamentos
-- Data: 2026-06-26
-- Autor: Vinicius (workspace Movelmar)
--
-- POR QUE ESSA TABELA EXISTE
-- --------------------------
-- A página `lancamentos.html` (GitHub Pages) lê esta tabela ao vivo,
-- do mesmo jeito que `cores.html` lê `mvmr_cores`: o site é estático,
-- mas os dados vêm do Supabase em tempo real. Assim, quando sai um
-- lançamento novo (uma cor, um produto ou uma coleção inteira), eu só
-- INSIRO uma linha aqui e a página atualiza sozinha — sem precisar de
-- `git push`. Na circular pro lojista eu mando UM link só: ele abre a
-- página e vê o lançamento da vez + o histórico.
--
-- COMO OS DADOS ENTRAM E SAEM
-- ---------------------------
-- - EU (Vinicius) ESCREVO usando a service_role key (bypassa RLS).
-- - A PÁGINA LÊ com a anon key (read-only). A RLS abaixo garante que
--   o anon só enxerga linhas com `ativo = true` — então posso deixar
--   um lançamento em rascunho (ativo=false) sem ele vazar pro site.
--
-- ESPELHO DE `mvmr_cores`
-- -----------------------
-- Mesmo banco (`ze`), mesmo padrão. Igual a `mvmr_cores`, esta tabela
-- NÃO tem `workspace_id` (este banco não usa a defesa de workspace pras
-- tabelas `mvmr_*`). RLS ligada + policy de SELECT é a proteção real.
-- ============================================================

create table public.mvmr_lancamentos (
  id              uuid primary key default gen_random_uuid(),

  -- Identidade do card -------------------------------------------------
  titulo          text not null,            -- nome do lançamento. Ex: cor "Negro"
  subtitulo       text,                     -- coleção/linha. Ex: "Coleção Águas"
  descricao       text,                     -- texto da arte (poético/animado), aparece no card

  -- Classificação ------------------------------------------------------
  tipo            text not null default 'colecao'
                    check (tipo in ('cor','produto','colecao')),
                                            -- o que é: uma cor avulsa, um produto, ou uma coleção

  data_lancamento date not null default current_date,  -- quando lançou (ordena o histórico)

  -- Mídia / material ---------------------------------------------------
  capa_url        text,                     -- imagem de capa do card (a arte). URL do github.io,
                                            -- ex: .../assets/lancamentos/aguas-negro.jpg
  material_url    text,                     -- o que o botão "Ver material" abre: PDF, link, etc.

  -- Apresentação na página --------------------------------------------
  destaque        boolean not null default false,  -- true = card grande no topo ("lançamento da vez")
  ordem           integer not null default 0,      -- ordenação manual (menor aparece primeiro)
  ativo           boolean not null default true,   -- false = rascunho, invisível pro site

  -- Auditoria ----------------------------------------------------------
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
                                            -- eu seto `= now()` à mão quando dou UPDATE
);

-- Comentários no catálogo do banco (quem abrir o schema entende sozinho)
comment on table  public.mvmr_lancamentos               is 'Lançamentos Movelmar exibidos em lancamentos.html (cores/produtos/coleções). Leitura anon read-only; escrita via service_role.';
comment on column public.mvmr_lancamentos.tipo          is 'cor | produto | colecao';
comment on column public.mvmr_lancamentos.destaque      is 'true = card de destaque no topo da página (lançamento da vez)';
comment on column public.mvmr_lancamentos.ordem         is 'Ordenação manual crescente; empate desempata por data_lancamento desc';
comment on column public.mvmr_lancamentos.ativo         is 'false = rascunho; a RLS esconde do site enquanto não publico';

-- Índice pra ordenação da página (ordem asc, depois mais recente primeiro)
create index idx_mvmr_lancamentos_vitrine
  on public.mvmr_lancamentos (ordem, data_lancamento desc)
  where ativo = true;

-- ============================================================
-- Segurança (RLS) — igual ao espírito da mvmr_cores, porém mais enxuto:
-- a página é read-only, então o anon recebe SÓ o privilégio de SELECT
-- (a mvmr_cores tem grants largos demais por herança; aqui faço certo).
-- ============================================================

-- 1) Privilégio de tabela: anon só pode LER
grant select on public.mvmr_lancamentos to anon;

-- 2) Liga a Row Level Security (sem policy, ninguém lê — nem o anon)
alter table public.mvmr_lancamentos enable row level security;

-- 3) Policy de leitura pública: anon/authenticated leem apenas o que está
--    publicado (ativo = true). Defesa em profundidade — mesmo sem o filtro
--    `?ativo=eq.true` na URL, rascunho não aparece.
create policy public_read_lancamentos
  on public.mvmr_lancamentos
  for select
  to anon, authenticated
  using (ativo = true);
