-- ============================================================
-- Migration: aceita tipo = 'painel' em mvmr_lancamentos
-- Data: 2026-06-26
-- Autor: Vinicius
--
-- POR QUÊ: a 1ª coleção (Águas) não são "cores" — são novos modelos de
-- PAINÉIS (o Rica cravou isso). O check original só permitia
-- cor/produto/colecao; aqui amplio pra incluir 'painel'.
-- ============================================================

alter table public.mvmr_lancamentos
  drop constraint mvmr_lancamentos_tipo_check;

alter table public.mvmr_lancamentos
  add constraint mvmr_lancamentos_tipo_check
  check (tipo in ('cor','produto','colecao','painel'));
