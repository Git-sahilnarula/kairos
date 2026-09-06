# KAIROS — Phase 1: Foundation

## Setup

```bash
cd kairos/docker
cp .env.example .env
# edit .env — set real POSTGRES_PASSWORD and N8N_PASSWORD

docker compose up -d
```

This starts three containers:
- `kairos-postgres` (pgvector-enabled, auto-runs `database/schema/001_init.sql` on first boot)
- `kairos-n8n` (UI at http://localhost:5678, login with N8N_USER/N8N_PASSWORD from .env)
- `kairos-ollama` (API at http://localhost:11434)

## Seed your profile

Edit `database/seed/seed_profile.sql` with your real skills first, then:

```bash
docker exec -i kairos-postgres psql -U kairos -d kairos < ../database/seed/seed_profile.sql
```

## Pull a local model

```bash
docker exec -it kairos-ollama ollama pull llama3.1:8b
# or a smaller model if RAM-constrained: ollama pull llama3.2:3b
```

## Verify Phase 1 is done

```bash
docker exec -it kairos-postgres psql -U kairos -d kairos -c "SELECT * FROM user_profile;"
docker exec -it kairos-postgres psql -U kairos -d kairos -c "SELECT * FROM preferences;"
```

You should see one row in each. Open http://localhost:5678 and confirm you can log into n8n.

## Failure cases to check

| Symptom | Likely cause |
|---|---|
| n8n container restarts in a loop | Postgres wasn't healthy yet — check `depends_on` healthcheck, run `docker compose logs postgres` |
| `vector` extension error on Postgres startup | Wrong image — must be `pgvector/pgvector:pg16`, not plain `postgres` |
| seed_profile.sql inserts nothing | `ON CONFLICT DO NOTHING` triggered because a row already exists — check with the SELECT above before re-seeding |
| Ollama pull is very slow | Normal on first run — model weights are several GB, one-time download |

## Phase 1 exit criteria

- [ ] `docker compose up -d` brings up all 3 containers without errors
- [ ] `user_profile` and `preferences` tables exist and contain your real data
- [ ] n8n UI is reachable and logged in
- [ ] Ollama responds to `curl http://localhost:11434/api/tags`

Once all four are checked, Phase 1 is complete — move to Phase 2 (Discovery).
