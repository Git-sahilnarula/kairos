-- Edit this file with YOUR real skills/preferences before first run,
-- or run it manually later via: docker exec -i kairos-postgres psql -U kairos -d kairos < seed_profile.sql

INSERT INTO user_profile (name, skills, tools, experience_level, ai_tools_known, automation_tools_known, availability)
VALUES (
    'default_user',
    ARRAY['Python', 'n8n', 'SQL', 'PostgreSQL', 'Supabase', 'Docker', 'Data Analysis'],
    ARRAY['Docker', 'Git', 'GitHub', 'VS Code'],
    'intermediate',
    ARRAY['LLM integration', 'Ollama', 'RAG', 'Prompt engineering'],
    ARRAY['n8n', 'AI automation'],
    'part-time'
)
ON CONFLICT DO NOTHING
RETURNING id;

-- Preferences referencing the profile above (assumes id = 1 for first insert)
INSERT INTO preferences (
    user_profile_id, preferred_categories, preferred_project_types,
    skills_to_avoid, minimum_opportunity_score, preferred_max_effort_hours
)
VALUES (
    1,
    ARRAY['AI automation', 'n8n', 'LLM integration', 'data automation'],
    ARRAY['automation workflow', 'AI agent build'],
    ARRAY['mobile development', 'graphic design', 'WordPress'],
    70,
    10
)
ON CONFLICT DO NOTHING;
