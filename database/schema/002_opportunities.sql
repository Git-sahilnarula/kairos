-- 002_opportunities.sql
-- Shared table written to by every Discovery workflow (WF-01 series).
-- Idempotent: safe to run against a database where the table already exists.

CREATE TABLE IF NOT EXISTS opportunities (
    id SERIAL PRIMARY KEY,
    source TEXT NOT NULL,
    source_opportunity_id TEXT NOT NULL,
    title TEXT,
    description TEXT,
    url TEXT,
    category TEXT,
    skills TEXT[],
    budget_min NUMERIC,
    budget_max NUMERIC,
    currency TEXT,
    pricing_type TEXT,
    posted_at TIMESTAMPTZ,
    deadline TIMESTAMPTZ,
    location TEXT,
    experience_level TEXT,
    client_name TEXT,
    client_country TEXT,
    client_rating NUMERIC,
    client_hiring_history INTEGER,
    proposal_count INTEGER,
    metadata JSONB,
    raw_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    is_relevant BOOLEAN DEFAULT false,
    UNIQUE (source, source_opportunity_id)
);