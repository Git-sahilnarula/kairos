# KAIROS Architecture & Roadmap

## Product Vision

KAIROS is an **Opportunity Intelligence + Opportunity Network + Path Engine** that discovers real opportunities, understands their requirements and outcomes, and eventually connects them into evidence-based progression paths for people trying to reach their next opportunity.

**Core Question:** "Given where I am now, what real opportunity should I pursue next, what evidence will it create, and what opportunities will that unlock afterward?"

**Potential Tagline:** From Where You Are to What's Next

### Differentiation

Most platforms help people **FIND** opportunities. KAIROS should eventually help people **UNDERSTAND THE PATH BETWEEN** opportunities.

**The Core Chain:**
```
Current Capability → Opportunity → Evidence → New Capability → Next Opportunity → Evidence → Better Opportunity → Target Opportunity
```

**Example Path:**
```
GitHub Issue → Open-source contribution → Proof of Skill → Portfolio evidence → Hackathon → Community/Team → Internship → Real Project → Junior Role
```

## Competitive Context

### Studied Products

**Tadrisya** (https://www.tadrisya.com/)
- Skills-first career intelligence platform
- Career Atlas, Capability Profile, Career GPS, Opportunity Intelligence
- Model: Skills → Career → Opportunities
- Lesson: Evidence-based capabilities and explainable recommendations

**Bugbaar Opportunity Graph** (https://github.com/Bugbaar/Opportunity-Graph)
- Network connecting people, skills, organizations, projects, communities, events
- Lesson: Opportunities can be represented as nodes in a larger ecosystem

### KAIROS Positioning

**Not claiming uniqueness** in the broad "opportunity graph" concept.

**Exploring differentiated approach:**
- Opportunities modeled as progression nodes
- Connected through skills, evidence, and downstream opportunities
- Evidence-first capability assessment
- Real opportunity-based paths (not just course recommendations)

**Working Definition:**
KAIROS = Opportunity Network + Capability Intelligence + Evidence + Progression

## Opportunity DNA

Every opportunity should eventually have a structured representation:

### Core Schema

```json
{
  "identity": {
    "source": "...",
    "source_opportunity_id": "...",
    "url": "..."
  },
  "basic": {
    "title": "...",
    "organization": "...",
    "type": "internship|job|freelance|open-source|hackathon|competition|mentorship|project|community|event|scholarship|grant"
  },
  "requirements": {
    "skills": [],
    "technologies": [],
    "experience": null,
    "education": null,
    "qualifications": []
  },
  "constraints": {
    "location": null,
    "remote": true,
    "compensation": null,
    "deadline": null,
    "duration": null,
    "availability": null
  },
  "accessibility": {
    "student_eligible": true,
    "fresher_eligible": true,
    "experience_required": 0,
    "portfolio_accepted": true,
    "beginner_friendly": false,
    "mentor_available": false,
    "entry_barrier": "low|medium|high"
  },
  "evidence": {
    "produces": [],
    "skills_demonstrated": [],
    "portfolio_evidence": []
  },
  "trajectory": {
    "unlocks": [],
    "related_opportunities": [],
    "skills_gained": [],
    "evidence_generated": []
  },
  "provenance": {
    "source": "...",
    "source_url": "...",
    "source_id": "...",
    "retrieved_at": "...",
    "updated_at": "...",
    "freshness": "...",
    "extraction_method": "source_fact|ai_extraction|ai_inference"
  }
}
```

### Provenance & Trust

Distinguish between:
- **SOURCE FACT**: "RemoteOK listing says Python is required"
- **AI EXTRACTION**: "AI extracted Python as a required skill"
- **AI INFERENCE**: "This opportunity may be useful for building backend experience"

Never silently mix these. Every important piece of intelligence should have provenance.

## Technical Architecture

### Current Stack

| Layer             | Tool                         |
| ----------------- | ---------------------------- |
| Orchestration     | n8n (Docker)                 |
| Database          | PostgreSQL + pgvector (Docker)|
| Local LLM         | Ollama (llama3.1:8b)         |
| Discovery sources | Multiple APIs/RSS feeds      |
| Runtime           | Docker Compose                |

### Conceptual Architecture

```
SOURCES
  ↓
n8n DISCOVERY WORKFLOWS
  ↓
NORMALIZATION
  ↓
FILTER
  ↓
POSTGRESQL
  ↓
FUTURE AI AGENTS
  ↓
SKILL MATCH
  ↓
RAG / PRECEDENT REASONING
  ↓
PATH ENGINE
```

### Future Graph Relationships

Start with PostgreSQL relationships before considering dedicated graph databases:

```
Opportunity → requires → Skill
Skill → demonstrated_by → Project
Project → creates → Evidence
Evidence → improves_access_to → Opportunity
Opportunity → leads_to → Opportunity
Person → has → Capability
Person → produced → Evidence
Organization → offers → Opportunity
Community → connects → People
```

## Phase Roadmap

### Phase 1 — Foundation ✅

**Status:** Complete

**Components:**
- Docker-based development environment
- n8n orchestration setup
- PostgreSQL + pgvector database
- Ollama local LLM integration
- User profile and preferences schema
- Profile seeding capability

**Key Decisions:**
- Port 5679 for KAIROS n8n (avoids conflict with existing user n8n on 5678)
- pgvector for future semantic search capabilities
- Local-first architecture (no cloud dependencies)

### Phase 2 — Discovery ✅

**Status:** Complete

**Components:**
- RemoteOK discovery workflow (JSON API)
- We Work Remotely discovery workflow (RSS feed)
- GitHub Issues discovery workflow (GitHub API with token)
- Arbeitnow discovery workflow (JSON API)
- Shared opportunities table with UPSERT logic
- Database trigger for updated_at maintenance
- Source-specific workflow isolation

**Key Decisions:**
- One workflow per source (not merged mega-workflow)
- Shared opportunities table for source-agnostic downstream processing
- Cheap keyword filtering at discovery time
- Deep relevance deferred to Phase 3
- Reddit planned but replaced with Arbeitnow due to OAuth registration issues

**Discovery Sources:**
| Source           | Method         | Authentication | Status |
| ---------------- | -------------- | --------------- | ------ |
| RemoteOK         | JSON API       | None            | ✅ Live |
| We Work Remotely | RSS            | None            | ✅ Live |
| GitHub Issues    | GitHub API     | Header Auth     | ✅ Live |
| Arbeitnow        | JSON API       | None            | ✅ Live |

**Database Schema:**
- `opportunities` table with normalized structure
- Logical uniqueness on (source, source_opportunity_id)
- UPSERT semantics to prevent duplicates
- Provenance tracking (source, source_opportunity_id, timestamps)

### Phase 3 — Opportunity Intelligence

**Status:** Planned

**Components:**
- Skill extraction from opportunity descriptions
- Technology extraction
- Opportunity classification
- Experience requirement extraction
- Eligibility analysis (student, fresher, experience level)
- Beginner-friendliness analysis
- Compensation extraction
- Deadline extraction

**Output:** Raw Opportunity → Structured Opportunity DNA

**AI Agents:**
- Skill Match Agent
- Opportunity Classification Agent
- Experience Extraction Agent
- Eligibility Analysis Agent

### Phase 4 — User Capability Model

**Status:** Planned

**Components:**
- Structured user profile representation
- Skills with evidence levels
- Projects and contributions
- Experience tracking
- GitHub evidence integration
- Certifications
- Interests and goals

**Purpose:** Understand "What can this person realistically do next?"

**Not:** Generic resume builder

### Phase 5 — Opportunity Relationships

**Status:** Planned

**Components:**
- PostgreSQL-based relationship modeling
- Opportunity → Skill connections
- Skill → Evidence connections
- Evidence → Opportunity connections
- Opportunity → Opportunity trajectories

**Approach:** Start with PostgreSQL, consider graph database only if genuinely insufficient.

### Phase 6 — Path Engine

**Status:** Planned

**Components:**
- Target opportunity analysis
- Current capability assessment
- Gap identification (capability and evidence)
- Accessible opportunity discovery
- Evidence generation prediction
- Path recommendation

**Example:**
```
Target: Data Science Internship
Current: Python + SQL + 2 projects
Gap: Real-world ML experience

KAIROS Path:
1. GitHub ML issue → contribution → Python/data skill evidence
2. Hackathon → ML project → team collaboration evidence
3. Internship/project → real-world ML experience
4. Target internship
```

**Key:** Paths made of REAL opportunities + evidence, not just courses.

### Phase 7 — Outcome Intelligence

**Status:** Planned

**Components:**
- User action tracking (saved, applied, interviewed, accepted, completed)
- Evidence creation tracking
- Capability updates
- Profile evolution
- Path effectiveness analysis

**Purpose:** Create feedback loop to learn which paths actually work.

### Phase 8 — Interface

**Status:** Planned

**Components:**
- Opportunity dashboard
- Search and filtering
- Skill/profile management
- AI-assisted opportunity analysis
- Path visualization
- Application tracking

### Phase 9 — Intelligence Platform

**Status:** Long-term Vision

**Potential Users:**
- Students
- Freshers
- Freelancers
- Developers
- Professionals
- Employers
- Institutions

### Phase 10 — College Presentation

**Status:** Final Phase

**Components:**
- Demo script
- Architecture diagrams
- DFD (Data Flow Diagram)
- ER (Entity Relationship) diagram
- Testing documentation
- Viva preparation

## Database Architecture

### Current Tables

**user_profile**
- User identity and capabilities
- Skills, tools, experience level
- AI tools known, automation tools known
- Availability status

**preferences**
- User's opportunity preferences
- Preferred categories, project types
- Skills to avoid
- Budget ranges
- Location preferences
- Minimum opportunity score

**opportunities**
- Shared table for all discovery sources
- Normalized opportunity data
- Provenance tracking
- UPSERT on (source, source_opportunity_id)

### Future Tables

**capability_profile**
- Rich capability representation
- Skills with evidence levels
- Projects and contributions
- Experience tracking
- Evidence sources

**evidence**
- Proof of skills and capabilities
- GitHub repositories
- Open-source contributions
- Hackathon projects
- Freelance projects
- Certifications

**opportunity_relationships**
- Connections between opportunities
- Skill requirements
- Evidence outcomes
- Trajectory mappings

**user_outcomes**
- User action tracking
- Path effectiveness
- Feedback loop data

**source_registry**
- Source metadata
- Reliability tracking
- Rate limit information
- Health monitoring
- Attribution requirements

## AI Agent Architecture

### Agent Design Principles

- Structured JSON input/output contracts
- Explainable decisions
- Provenance tracking
- Human-in-the-loop by default
- No autonomous external actions without approval

### Planned Agents

**Skill Match Agent**
- Input: User profile + opportunity
- Output: Skill compatibility analysis
- Structured scoring with explanation

**Opportunity Classification Agent**
- Input: Opportunity description
- Output: Category, type, difficulty level
- Multi-label classification

**Experience Extraction Agent**
- Input: Opportunity requirements
- Output: Required experience level, eligibility analysis
- Student/fresher friendly assessment

**Automation Potential Agent**
- Input: Opportunity description
- Output: Automation feasibility, tool recommendations
- n8n workflow potential

**Delivery Feasibility Agent**
- Input: Opportunity scope + user capability
- Output: Delivery timeline, risk assessment
- Resource requirements

**Risk Analysis Agent**
- Input: Opportunity + user profile
- Output: Risk factors, mitigation strategies
- Success probability

**Decision Agent**
- Input: All agent outputs + deterministic scoring
- Output: Final recommendation with explanation
- Should I pursue this? Yes/No with reasons

### RAG Integration

**Scope:** Precedent-based reasoning only

**Purpose:**
- Retrieve similar past opportunities
- Access their outcomes and feedback
- Provide grounded context to agents

**Not:**
- General "chat with your opportunities"
- Index arbitrary web content
- Broad knowledge base

**Usage:**
- Research Agent context
- Risk Agent historical patterns
- Decision Agent precedent reasoning

## Deterministic Scoring

**Principle:** LLM agents produce structured JSON evaluations; n8n CODE NODE computes final weighted score.

**Weighting Plan:**
- Skill Match: 25%
- Delivery Feasibility: 25%
- Automation Potential: 20%
- Opportunity Quality: 15%
- Effective Rate: 10%
- Scope Clarity: 5%
- Risk adjustment applied after

**Purpose:** Preserve explainability and debuggability for college viva.

## Security Principles

**Never hardcode secrets:**
- API tokens
- Database passwords
- OAuth credentials
- GitHub PATs

**Always use:**
- n8n Credentials system
- Environment variables
- Proper credential management

**Git safety:**
- Never commit secrets
- Use git status/diff before committing
- GitHub Push Protection enabled
- Immediate token revocation if exposed

## Business Model Considerations

**Do not monetize prematurely.** First prove intelligence value.

### Potential Future Layers

**KAIROS Free (Student Layer)**
- Opportunity discovery
- Basic profile
- Basic Opportunity DNA
- Saved opportunities
- Alerts
- Basic path information

**KAIROS Pro**
- Unlimited paths
- Advanced capability analysis
- Evidence analysis
- Portfolio analysis
- Deadline intelligence
- Historical opportunity intelligence
- Advanced semantic search
- Deeper Path Engine

**Hypothetical Price Range:** ₹199–₹499/month (not final)

**Employer / Recruiter Intelligence**
- Evidence-based candidate discovery
- Talent discovery
- Contribution history
- Skill/evidence matching
- Targeted outreach

**Institutions**
- Opportunity intelligence
- Student skill gaps
- Participation analytics
- Career readiness
- Employer demand trends

**API / Intelligence**
- Opportunity trends
- Skill demand
- Opportunity relationships
- Accessibility data
- Progression intelligence

## Development Philosophy

**Build incrementally:**
- Simple → Correct → Observable → Explainable → Extensible

**Current priority:**
1. Reliable opportunity data (Phase 2 ✅)
2. Opportunity intelligence (Phase 3)
3. Capability/evidence (Phase 4)
4. Graph (Phase 5)
5. Path Engine (Phase 6)
6. Outcome feedback (Phase 7)

**Avoid:**
- Premature graph database adoption
- Massive microservices
- Dozens of AI agents immediately
- Expensive APIs
- Unnecessary infrastructure

## Target Users

**Primary:**
- Students
- Freshers
- People entering tech
- People starting freelancing
- People with limited professional experience
- People who have skills but don't know where/how to get their first real experience

**Common Questions:**
- "I know Python, but what should I actually do with it?"
- "I want a data science internship, but I don't have experience."
- "How do I go from beginner to my first real opportunity?"

## Key Product Principles

Every feature should answer one of these questions:

**DISCOVERY?** - What opportunities exist?

**UNDERSTANDING?** - What does this opportunity actually require?

**ACCESSIBILITY?** - Can someone like me realistically enter it?

**PROGRESSION?** - What should I do before it?

**EVIDENCE?** - What proof will I gain from doing it?

**TRAJECTORY?** - What will this unlock next?

**OUTCOME?** - Did this path actually work?

## Current Project State

**Completed:**
- ✅ Phase 1: Foundation
- ✅ Phase 2: Discovery (4 sources, 211 opportunities)

**In Progress:**
- Phase 3: Opportunity Intelligence

**Repository:**
- GitHub: https://github.com/Git-sahilnarula/kairos
- Local: C:\Users\sahil\OneDrive\Desktop\Kairos

**Active Workflows:**
- WF-01 Discovery - RemoteOK
- WF-01b WeWorkRemotely
- WF-01d Discovery - GitHub Issues
- WF-01e Discovery - Arbeitnow

## Long-term Moat

**Not:** "We have lots of job listings"

**Potential moat:**
- Opportunity History
- Skill Relationships
- Evidence Relationships
- Path Relationships
- User Outcomes
- Provenance

**Unique dataset:**
"How opportunities, skills, evidence and progression have historically related to each other"

## North Star

**Most important conceptual sentence:**

Most platforms help people FIND opportunities. KAIROS should eventually help people UNDERSTAND THE PATH BETWEEN opportunities.

**The long-term flywheel:**

Discovery → Normalization → Provenance → Opportunity DNA → Skills → Evidence → Relationships → Paths → Outcomes → Better intelligence → Better recommendations → More outcomes

**One-sentence definition:**

KAIROS is an opportunity intelligence and path engine that discovers real opportunities, understands their requirements and outcomes, and eventually connects them into evidence-based progression paths for people trying to reach their next opportunity.

---

*This architecture document serves as the living technical vision for KAIROS, guiding development from Phase 2 (Discovery) through Phase 10 (College Presentation).*