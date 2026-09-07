# KAIROS — AI-Powered Freelance Opportunity Research Agent

KAIROS is a personal, zero-cost, n8n-orchestrated agent system that discovers freelance/remote opportunities, filters and normalizes them, and (in later phases) evaluates them against your real skills to answer one question: **should I pursue this?**

Built as a learning project and open-source reference for multi-agent AI orchestration using n8n — not a commercial product. See `docs/` (coming in later phases) for the full architecture writeup.

## Status: Phase 2 in progress

- ✅ **Phase 1 — Foundation:** Docker stack (n8n + PostgreSQL/pgvector + Ollama), profile schema seeded
- 🔄 **Phase 2 — Discovery:** 2 of planned sources live
  - ✅ RemoteOK (JSON API, no auth)
  - ✅ We Work Remotely (RSS feed, "remote-programming-jobs" category)
  - ⬜ Reddit (r/forhire, r/freelance_forhire, r/jobbit — official public JSON endpoints)
  - ⬜ GitHub Issues (bounty/paid-labeled issues)
- ⬜ Phase 3 onward — AI agents, deterministic scoring, RAG-based precedent reasoning, frontend

## Tech stack (all zero-cost, self-hosted)

| Layer | Tool |
|---|---|
| Orchestration | n8n (Docker) |
| Database | PostgreSQL + pgvector (Docker) |
| Local LLM | Ollama (`llama3.1:8b`) |
| Sources (so far) | RemoteOK API, We Work Remotely RSS |

## Project structure

```
kairos/
├── README.md
├── .gitignore
├── docker/
│   ├── docker-compose.yml
│   └── .env.example        # copy to .env and fill in real values — never commit .env
├── database/
│   ├── schema/
│   │   └── 001_init.sql    # user_profile, preferences tables (+ pgvector extension)
│   └── seed/
│       └── seed_profile.sql
└── n8n/
    └── workflows/
        ├── WF-01 Discovery - RemoteOK.json
        └── WF-01b WeWorkRemotely.json
```

## Setup

```bash
cd docker
cp .env.example .env
# edit .env — set real POSTGRES_PASSWORD and N8N_PASSWORD

docker compose up -d
```

This starts three containers:
- `kairos-postgres` (pgvector-enabled, auto-runs `database/schema/001_init.sql` on first boot)
- `kairos-n8n` — UI at **http://localhost:5679** (kept on a non-default port; see note below)
- `kairos-ollama` — API at http://localhost:11434

> **Note on port 5679:** if you already run another n8n instance on the default port 5678, this project's `docker-compose.yml` maps its n8n to **5679** instead to avoid conflicts. Change it back to `5678:5678` in `docker-compose.yml` if you don't have that conflict.

### Seed your profile

Edit `database/seed/seed_profile.sql` with your real skills first, then:

```bash
docker exec -i kairos-postgres psql -U kairos -d kairos < ../database/seed/seed_profile.sql
```

### Pull a local model

```bash
docker exec -it kairos-ollama ollama pull llama3.1:8b
```
Use a smaller model (e.g. `llama3.2:3b`) if you have 8GB RAM or less.

### Import the discovery workflows

1. Open n8n at `http://localhost:5679`
2. Go to **Workflows → Import from File**
3. Import each file from `n8n/workflows/`
4. Each workflow needs its own Postgres credential created on first import (host: `kairos-postgres`, db: `kairos`, user: `kairos`, your password, port `5432`)
5. Activate each workflow once its credential is set

## Verify it's working

```bash
docker exec -it kairos-postgres psql -U kairos -d kairos -c "SELECT source, COUNT(*) FROM opportunities GROUP BY source;"
```

Expected output (row counts will vary as feeds update):
```
     source     | count
-----------------+-------
 remoteok        |   100
 weworkremotely  |    25
```

## Failure cases to check

| Symptom | Likely cause |
|---|---|
| n8n container restarts in a loop | Postgres wasn't healthy yet — check `docker compose logs postgres` |
| `vector` extension error on Postgres startup | Wrong image — must be `pgvector/pgvector:pg16` |
| Postgres node errors on `Columns to match on` | Set it explicitly to `source, source_opportunity_id`, not `id` |
| A source's Filter node passes 100% of items through | Check for overly broad keyword substrings (e.g. `"ai"` matching inside unrelated words) — use word-boundary regex matching in the Code node instead |

## Design notes

- Each source is its own independent n8n workflow (not one merged workflow) so a failure in one source never blocks the others, and each can be scheduled/toggled independently.
- All sources write into a single shared `opportunities` table using an `UPSERT` on `(source, source_opportunity_id)`, so the pipeline is source-agnostic from Phase 3 onward.
- Keyword filtering at discovery time is intentionally a cheap, blunt noise-reduction pass — real relevance judgment is deferred to the Skill Match Agent (Phase 3), not decided here.

## License

Not yet finalized — will be added before public release.
