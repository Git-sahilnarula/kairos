# KAIROS — AI-Powered Freelance Opportunity Research Agent

KAIROS is a personal, zero-cost, n8n-orchestrated agent system that discovers freelance and remote opportunities, filters and normalizes them, and (in later phases) evaluates them against your real skills to answer one question: **should I pursue this?**

Built as a learning project and open-source reference for multi-agent AI orchestration using n8n — not a commercial product. See `docs/` (coming in later phases) for the full architecture writeup.

## Status: Phase 2 complete ✅

* ✅ **Phase 1 — Foundation:** Docker stack (n8n + PostgreSQL/pgvector + Ollama), profile schema seeded
* ✅ **Phase 2 — Discovery:** 4 sources live

  * ✅ RemoteOK — JSON API, no authentication
  * ✅ We Work Remotely — RSS feed, `remote-programming-jobs` category
  * ✅ GitHub Issues — bounty/paid-labeled issues
  * ✅ Arbeitnow — JSON API, no authentication
* ⬜ **Phase 3 onward** — AI agents, deterministic scoring, RAG-based precedent reasoning, frontend

## Discovery Sources

KAIROS currently uses independent discovery workflows for each source:

| Source           | Method                | Authentication                            | Status    |
| ---------------- | --------------------- | ----------------------------------------- | --------- |
| RemoteOK         | JSON API              | None                                      | ✅ Live    |
| We Work Remotely | RSS                   | None                                      | ✅ Live    |
| GitHub Issues    | GitHub API            | n8n Header Auth credential (GitHub token) | ✅ Live    |
| Arbeitnow        | JSON API              | None                                      | ✅ Live    |

Each source is processed independently and writes normalized opportunities into the shared `opportunities` table.

> **Security note:** API tokens and credentials must never be hardcoded into workflow exports or committed to Git. Use n8n credentials or environment variables for secrets.

## Tech stack

| Layer             | Tool                                                  |
| ----------------- | ----------------------------------------------------- |
| Orchestration     | n8n (Docker)                                          |
| Database          | PostgreSQL + pgvector (Docker)                        |
| Local LLM         | Ollama (`llama3.1:8b`)                                |
| Discovery sources | RemoteOK API, We Work Remotely RSS, GitHub Issues API, Arbeitnow API |
| Runtime           | Docker Compose                                        |

## Project structure

```text
kairos/
├── README.md
├── .gitignore
├── docker/
│   ├── docker-compose.yml
│   └── .env.example        # copy to .env and fill in real values — never commit .env
├── database/
│   ├── schema/
│   │   ├── 001_init.sql                # user_profile, preferences tables (+ pgvector extension)
│   │   ├── 002_opportunities.sql       # shared opportunities table written by all discovery workflows
│   │   └── 003_updated_at_trigger.sql  # keeps opportunities.updated_at current
│   └── seed/
│       └── seed_profile.sql
└── n8n/
    └── workflows/
        ├── WF-01 Discovery - RemoteOK.json
        ├── WF-01b WeWorkRemotely.json
        ├── WF-01d Discovery - GitHub Issues.json
        └── WF-01e Discovery - Arbeitnow.json
```

## Setup

```bash
cd docker
cp .env.example .env
# edit .env — set real POSTGRES_PASSWORD and N8N_PASSWORD

docker compose up -d
```

This starts three containers:

* `kairos-postgres` — pgvector-enabled PostgreSQL database
* `kairos-n8n` — n8n UI at **http://localhost:5679**
* `kairos-ollama` — Ollama API at **http://localhost:11434**

> **Note on port 5679:** if you already run another n8n instance on the default port 5678, this project's `docker-compose.yml` maps its n8n instance to **5679** instead to avoid conflicts. Change it back to `5678:5678` in `docker-compose.yml` if you don't have that conflict.

### Database schema

Files in `database/schema/` run automatically, in filename order, the first time the Postgres container starts with an empty volume: `001` creates the profile tables, `002` the shared `opportunities` table, and `003` a trigger that sets `updated_at` whenever a discovery run updates an existing row. `002` and `003` are safe to re-run.

On an existing database, apply a new migration manually from the `docker/` folder:

```bash
docker exec -i kairos-postgres psql -U kairos -d kairos < ../database/schema/003_updated_at_trigger.sql
```

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
3. Import the workflow files from `n8n/workflows/`
4. Each workflow needs its own Postgres credential created on first import:

   * **Host:** `kairos-postgres`
   * **Database:** `kairos`
   * **User:** `kairos`
   * **Password:** your configured PostgreSQL password
   * **Port:** `5432`
5. Configure any source-specific credentials required by the workflow.
6. Activate each workflow once its credentials are configured.

### GitHub Issues authentication

The GitHub Issues workflow authenticates with a GitHub Personal Access Token stored as an n8n credential, never typed into the workflow itself.

1. On GitHub, generate a classic Personal Access Token (Settings → Developer settings → Personal access tokens → Tokens (classic)). Leave every scope unchecked, since only public data is read, and set an expiry.
2. In n8n, open the HTTP Request node of the GitHub Issues workflow. Set **Authentication** to Generic Credential Type and **Generic Auth Type** to Header Auth.
3. Create a new Header Auth credential: **Name** `Authorization`, **Value** `Bearer ` followed by the token (one space, nothing after the token).
4. Do not add an Authorization row under **Send Headers**. The credential supplies it. Only `Accept: application/vnd.github+json` is set manually.
5. Never commit the token. The exported workflow JSON contains only the credential's id and label.

To confirm the token is attached, temporarily turn on **Options → Include Response Headers and Status** on the node, run it, and read `x-ratelimit-limit`: GitHub's search endpoint allows 30 requests per minute with a valid token and 10 without. Remove the option afterwards, because it changes the output shape the next node expects.

GitHub Push Protection should remain enabled on the repository so accidentally committed credentials are detected before they reach the remote repository.

## Verify it's working

After running the discovery workflows:

```bash
docker exec -it kairos-postgres psql -U kairos -d kairos -c "SELECT source, COUNT(*) FROM opportunities GROUP BY source;"
```

Expected output will vary as the feeds and APIs update:

```text
     source     | count
----------------+-------
 remoteok       |   100
 weworkremotely |    25
 github_issues  |    30
 arbeitnow      |    50
```

The exact number of opportunities is expected to change between runs.

## Failure cases to check

| Symptom                                             | Likely cause                                                                                                                                        |
| --------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| n8n container restarts in a loop                    | Postgres wasn't healthy yet — check `docker compose logs postgres`                                                                                  |
| `vector` extension error on Postgres startup        | Wrong image — must be `pgvector/pgvector:pg16`                                                                                                      |
| Postgres node errors on `Columns to match on`       | Set it explicitly to `source, source_opportunity_id`, not `id`                                                                                      |
| A source's Filter node passes 100% of items through | Check for overly broad keyword substrings (e.g. `"ai"` matching inside unrelated words) — use word-boundary regex matching in the Code node instead |
| GitHub workflow returns authentication errors       | Check the n8n GitHub credential/token configuration                                                                                                 |
| GitHub workflow runs but is rate-limited like an anonymous client (`x-ratelimit-limit: 10`) | Token isn't attached. Check the Header Auth credential: Name must be exactly `Authorization` and Value must start with `Bearer ` |
| GitHub workflow finds no opportunities              | Check the issue-label/filter configuration and GitHub API response                                                                                  |
| Arbeitnow workflow returns empty data array          | Check API endpoint status and response structure                                                                                                    |

## Design notes

* Each source is its own independent n8n workflow rather than one merged workflow. This means a failure in one source does not block the others, and each source can be scheduled or toggled independently.
* All sources write into a single shared `opportunities` table using an **UPSERT** on `(source, source_opportunity_id)`, keeping the pipeline source-agnostic from Phase 3 onward.
* `opportunities.updated_at` is maintained by a database trigger, so it records the last time a discovery run saw a listing, not when the source changed it.
* Keyword filtering at discovery time is intentionally a cheap, blunt noise-reduction pass. Real relevance judgment is deferred to the **Skill Match Agent (Phase 3)** rather than being decided entirely during discovery.
* Source-specific authentication is isolated from exported workflow definitions wherever possible.
* Discovery workflows are designed to produce normalized opportunity records that downstream agents can process consistently.
* Reddit was initially planned but replaced with Arbeitnow due to OAuth app registration issues with Reddit's developer portal.

## Roadmap

### Phase 1 — Foundation ✅

* Docker-based development environment
* n8n orchestration
* PostgreSQL + pgvector
* Ollama local LLM
* User profile and preferences schema

### Phase 2 — Discovery ✅

* [x] RemoteOK
* [x] We Work Remotely
* [x] GitHub Issues
* [x] Arbeitnow
* [x] Discovery validation and refinement

### Phase 3 — Intelligence ⬜

Planned components include:

* Skill Match Agent
* Opportunity classification
* Deterministic scoring
* Relevance analysis
* Duplicate detection
* RAG-based precedent reasoning

### Phase 4 — Interface ⬜

Planned components include:

* Opportunity dashboard
* Search and filtering
* Skill/profile management
* AI-assisted opportunity analysis
* Application tracking

## License

Not yet finalized — will be added before public release.