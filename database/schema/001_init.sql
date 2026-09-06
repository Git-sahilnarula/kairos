-- KAIROS Phase 1 schema
-- Runs automatically on first Postgres container startup.

CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- user_profile: who you are, what you can do
-- Single row expected for a personal-use system.
-- ============================================================
CREATE TABLE IF NOT EXISTS user_profile (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL DEFAULT 'default_user',
    skills TEXT[] NOT NULL DEFAULT '{}',
    tools TEXT[] NOT NULL DEFAULT '{}',
    experience_level TEXT NOT NULL DEFAULT 'intermediate',
    ai_tools_known TEXT[] NOT NULL DEFAULT '{}',
    automation_tools_known TEXT[] NOT NULL DEFAULT '{}',
    availability TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- preferences: configurable rules, separate from identity data
-- so they can change without touching the profile.
-- ============================================================
CREATE TABLE IF NOT EXISTS preferences (
    id SERIAL PRIMARY KEY,
    user_profile_id INTEGER NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
    preferred_categories TEXT[] NOT NULL DEFAULT '{}',
    preferred_project_types TEXT[] NOT NULL DEFAULT '{}',
    skills_to_avoid TEXT[] NOT NULL DEFAULT '{}',
    minimum_budget NUMERIC,
    preferred_budget_min NUMERIC,
    preferred_budget_max NUMERIC,
    preferred_project_duration TEXT,
    minimum_opportunity_score INTEGER NOT NULL DEFAULT 70,
    preferred_max_effort_hours INTEGER NOT NULL DEFAULT 10,
    location_preferences TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_preferences_user ON preferences(user_profile_id);
