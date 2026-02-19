-- Migration: Adicionar campo textura à tabela mvmr_cores
-- Data: 2026-02-19
-- Motivo: Diferenciar variantes de acabamento da mesma cor (matt, micro, etc.)

-- Adicionar campo textura
ALTER TABLE mvmr_cores 
ADD COLUMN textura TEXT;

-- Comentário do campo
COMMENT ON COLUMN mvmr_cores.textura IS 'Textura/acabamento superficial: matt (fosco), micro (microporo), etc. NULL quando não aplicável.';

-- Índice para filtros por textura
CREATE INDEX idx_mvmr_cores_textura ON mvmr_cores(textura) WHERE textura IS NOT NULL;
