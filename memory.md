# Reforge — Project Memory & Technical Context Log

**Project Name:** Reforge  
**Status:** Architecture & Documentation Phase Completed  
**Last Updated:** September 2026  
**System Version:** 1.0 (MVP)

---

## 1. Project Context & Vision Summary

Reforge is a builder-focused project memory and resurrection platform. It connects idea capture, execution context, deliberate abandonment, post-mortem reflection, and project resurrection (V2) into an unbroken lifecycle:

$$\text{Capture} \longrightarrow \text{Shape} \longrightarrow \text{Build} \longrightarrow \text{Abandon / Pause} \longrightarrow \text{Reflect} \longrightarrow \text{Learn} \longrightarrow \text{Reforge} \longrightarrow \text{Build V2}$$

The central thesis of Reforge is that side-project failure is not a terminal dead-end; it is a primary source of reusable engineering knowledge.

---

## 2. Architectural Decision Records (ADRs)

### ADR-001: Mobile-First Flutter Client with Riverpod
* **Status:** Accepted (2026-09)
* **Context:** Need cross-platform support with high-performance UI rendering on mobile devices and responsive web demo capabilities.
* **Decision:** Use Flutter with Dart 3.x and Riverpod for state management.
* **Consequences:** Provides declarative reactive state, compile-time safety, effortless test mocking, and unified multi-platform compilation without maintaining multiple client repos.

### ADR-002: Managed Supabase Platform with PostgreSQL & Row-Level Security
* **Status:** Accepted (2026-09)
* **Context:** MVP requires rapid setup, relational data integrity, authentication, and secure access boundaries without operating dedicated server clusters.
* **Decision:** Choose Supabase over a custom Spring Boot / Node.js backend or Firebase.
* **Consequences:** Eliminates backend boilerplate; kernel-level PostgreSQL Row-Level Security (RLS) guarantees data privacy; built-in auth and edge functions simplify operational overhead.

### ADR-003: Relational Project Lineage Model for Resurrection (V2)
* **Status:** Accepted (2026-09)
* **Context:** Projects resurrected into V2 must maintain traceable links to their ancestor project and original failure lessons without duplicating raw task history.
* **Decision:** Model lineage explicitly via the `project_versions` relational table (`source_project_id`, `new_project_id`, `version_label`, `changes_summary`).
* **Consequences:** Enables graph-like project ancestry tracking and cross-version retrospective analysis while maintaining clean task separation for new iterations.

### ADR-004: Edge Functions as Isolated AI Gateway
* **Status:** Accepted (2026-09)
* **Context:** AI features (Idea Review, Post-Mortem Synthesis, Reforge Scaffolding) require third-party LLM API keys that must never be exposed on client devices.
* **Decision:** Encapsulate all AI logic inside Supabase Deno Edge Functions with strict JSON schemas, server-side secret injection, and per-user rate limiting.
* **Consequences:** AI failures never compromise client stability; API secrets remain 100% confidential; LLM providers can be swapped without updating mobile client binaries.

### ADR-005: Feature-Driven Modular Architecture
* **Status:** Accepted (2026-09)
* **Context:** Codebases organized purely by technical layer (e.g., all controllers in one folder, all models in another) suffer from high coupling and poor discoverability.
* **Decision:** Organize `lib/features/` into vertical feature slices (`auth`, `ideas`, `projects`, `graveyard`, `postmortem`, `reforge`, `search`, `profile`).
* **Consequences:** High cohesion, well-defined boundaries, easier parallel development, and clear ownership of feature code.

### ADR-006: Deliberate Abandonment as a First-Class Lifecycle State
* **Status:** Accepted (2026-09)
* **Context:** Most tools treat stopping a project as deletion or passive decay.
* **Decision:** Make abandonment an intentional, guilt-free status transition (`status = 'abandoned'`) accompanied by an exit interview and Graveyard entry.
* **Consequences:** Prevents data loss, normalizes learning from stopped work, and directly feeds the Reforge resurrection engine.

---

## 3. Product Hypotheses & Validation Status

| Hypothesis ID | Problem Statement | Validation Method | Current Status |
| :--- | :--- | :--- | :--- |
| **HYP-01** | Builders suffer from idea overload and lack structured MVP scope bounds. | User interviews & Idea-to-Project conversion rates | Proposed (Requires telemetry) |
| **HYP-02** | Builders will spend 2–3 minutes completing a post-mortem if lessons are saved. | Graveyard post-mortem completion rate | Proposed (Target: > 40% completion) |
| **HYP-03** | Resurrection into V2 is significantly more motivating than starting from scratch. | V2 project activity & task completion rates | Proposed (Target: > 25% resurrection rate) |
| **HYP-04** | AI suggestions are valuable only when grounded in past project context. | User acceptance rate of AI-generated MVP cuts | Proposed (Must track accept/reject ratio) |

---

## 4. Risk Log & Active Mitigations

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ RISK 1: Users skip the post-mortem due to fatigue                           │
│ Severity: High | Probability: Medium                                        │
│ Mitigation: Make post-mortem 2-3 fields by default; provide optional        │
│             1-tap AI draft from existing decisions/blockers.                │
├─────────────────────────────────────────────────────────────────────────────┤
│ RISK 2: Reforge feels like Notion/Jira with different branding              │
│ Severity: Critical | Probability: High                                      │
│ Mitigation: Make Graveyard, Post-Mortem, and V2 Reforge central to the      │
│             primary navigation and onboarding demo. Avoid deep tasks.       │
├─────────────────────────────────────────────────────────────────────────────┤
│ RISK 3: RLS misconfiguration exposes private builder notes                  │
│ Severity: Critical | Probability: Low/Medium                                │
│ Mitigation: Automated policy-by-policy SQL test suite verifying that no     │
│             unauthorized user can query foreign data.                       │
├─────────────────────────────────────────────────────────────────────────────┤
│ RISK 4: Edge Function AI costs exceed budget                                │
│ Severity: Medium | Probability: Medium                                      │
│ Mitigation: Implement daily per-user rate limits; make AI strictly optional;│
│             core app operates deterministically without AI.                 │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 5. Engineering Journal & Changelog

### Version 1.0 (September 2026) — Documentation & System Blueprinting
* **Milestone:** Completed full product, technical, and engineering specification based on Research v1.0.
* **Created:**
  * `README.md`: Upgraded with project overview, lifecycle diagrams, tech stack, and quick start guide.
  * `project requirement document.md`: Full PRD with functional and non-functional requirements, user personas, problem analysis, and MVP scope boundaries.
  * `architechture.md`: Complete system architecture, component topologies, PostgreSQL schema, RLS policies, RPC endpoints, and Riverpod structure.
  * `rules.md`: Comprehensive engineering rules, AI coding-agent directives, security invariants, and Dart/Flutter conventions.
  * `design.md`: Visual identity, design tokens, color palette, typography hierarchy, component specifications, and wireframe layouts.
  * `task.md`: Phased execution roadmap (A1–A8) with granular checklists and Definitions of Done.
  * `memory.md`: Living project memory and ADR repository.
