-- 004_opportunity_extractions.sql
-- AI extraction results, kept separate from source data in `opportunities`.
-- One row per opportunity per (model, prompt_version). Idempotent: safe to re-run.

CREATE TABLE IF NOT EXISTS opportunity_extractions (
    id SERIAL PRIMARY KEY,
    opportunity_id INTEGER NOT NULL REFERENCES opportunities(id) ON DELETE CASCADE,
    model TEXT NOT NULL,
    prompt_version TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'ok',   -- 'ok' or 'invalid_output'
    extracted JSONB,                      -- parsed and validated fields, each with a provenance label
    raw_response TEXT,                    -- the model's reply exactly as returned
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (opportunity_id, model, prompt_version)
);

CREATE INDEX IF NOT EXISTS idx_opportunity_extractions_opportunity
    ON opportunity_extractions (opportunity_id);