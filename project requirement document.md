# Reforge — Project Requirement Document (PRD)

**Document Version:** 1.0  
**Date:** September 2026  
**Status:** Approved for Implementation (MVP)  
**Target Platform:** Mobile-First (Flutter Android/iOS) + Flutter Web Demo  
**Backend:** Supabase (PostgreSQL, Supabase Auth, Storage, Edge Functions)

---

## 1. Executive Summary & Vision

Reforge is a builder-focused project memory and resurrection system. Its purpose is not to compete with general-purpose project management suites like Jira, Linear, or Trello. Instead, Reforge treats an idea, its execution journey, the deliberate reasons it was paused or abandoned, the post-mortem lessons extracted, and its eventual resurrection into a smarter version (V2) as a continuous, unified engineering lifecycle.

### The Problem It Solves
Builders frequently generate promising software ideas but face severe friction turning them into sustainable MVPs. Due to time constraints, unchecked scope creep, technical obstacles, or sudden loss of direction, side projects are frequently abandoned. When this occurs in traditional tools, the project simply goes stale or gets archived; all architectural decisions, contextual notes, and failure lessons are scattered and forgotten. Builders subsequently repeat the exact same mistakes on future projects and permanently lose high-potential concepts.

### Value Proposition
> *"Reforge turns project history into reusable engineering knowledge. It provides one connected lifecycle from idea to project, from project to learning, and from learning back to a better project."*

---

## 2. Problem Analysis & Target Users

### 2.1 The Nine Builder Dilemmas (Hypotheses)
1. **Idea Overload:** Too many ideas captured without structured qualification or MVP boundary definition.
2. **Execution Friction:** High barrier to convert a fleeting concept into a structured, trackable execution workspace.
3. **Scope Creep:** Lack of a hard, visible MVP boundary leading to burnout before initial launch.
4. **Time & Energy Loss:** Context switching and irregular side-project schedules cause loss of momentum.
5. **Context Evaporation:** Architectural decisions, trade-offs, and technical rationale are lost when work pauses.
6. **No Explicit Abandonment Lifecycle:** Stopping a project feels like a shameful failure rather than a natural engineering checkpoint.
7. **Repeated Mistakes:** Failure causes (e.g., poor tech stack choice, wrong API, oversized MVP) are never synthesized into permanent lessons.
8. **Lost Rediscovery:** Old ideas sit buried in note apps without searchable tags or retrospective data.
9. **Dead-End Failures:** A good product concept dies permanently just because its initial implementation approach failed.

### 2.2 Target Personas
* **Primary Target:** Solo software engineers, indie makers, computer science students, hobby hackers, and hackathon participants building multiple small-to-medium web/mobile applications.
* **Secondary Target:** Small agile teams wanting lightweight retrospective capture and organizational memory continuity.
* *Note on MVP Scope:* The MVP strictly targets individual builders. Team collaboration introduces multi-tenant RBAC, real-time presence, and complex notification semantics which are deferred.

### 2.3 User Needs
- Capture an idea in under 60–120 seconds on a mobile device.
- Establish explicit, visible MVP boundaries before writing code.
- Quick-log technical decisions, blockers, and "why" notes during active development without leaving flow state.
- Gracefully pause or abandon a project through an intentional, guided workflow.
- Complete a lightweight post-mortem in under 3 minutes.
- Catalog reusable lessons across multiple historical projects.
- "Reforge" an abandoned project into a clean V2 with preserved lineage and imported insights.

---

## 3. Product Scope & Feature Boundaries

### 3.1 Prioritization Matrix (MoSCoW)

| Priority | Feature / Capability | Complexity | Value | Notes |
| :--- | :--- | :--- | :--- | :--- |
| **Must Have** | Supabase Auth & User Profiles | Low | High | Secure authentication, user data boundary |
| **Must Have** | Idea Vault (CRUD, tags, status) | Low | High | Fast idea capture & categorization |
| **Must Have** | Idea → Project Conversion | Low | High | Transitions ideas directly into projects |
| **Must Have** | Project Workspace & MVP Scope | Medium | High | Visible boundaries, simple tasks |
| **Must Have** | Project Memory (Decisions & Blockers) | Medium | Very High | Core differentiator during active build |
| **Must Have** | Pause / Deliberate Abandon Flow | Low | High | Removes failure stigma, captures reason |
| **Must Have** | Project Graveyard | Low | High | First-class archive for stopped projects |
| **Must Have** | Structured Post-Mortem & Lessons | Medium | Very High | Captures what went wrong and core lessons |
| **Must Have** | Reforge Engine (V2 Creation & Linkage) | Medium | Very High | Primary resurrection mechanism |
| **Must Have** | PostgreSQL Row-Level Security (RLS) | Medium | Critical | Mandatory data privacy enforcement |
| **Should Have** | Advisory AI Idea Scope & Risk Analysis | Medium | Medium | Evaluates MVP scope via Edge Function |
| **Should Have** | Advisory AI Post-Mortem Synthesis | Medium | Medium | Summarizes lessons from project log |
| **Should Have** | Advisory AI Reforge V2 Proposal | Medium | High | Generates V2 roadmap based on past failures |
| **Should Have** | Local Draft Persistence | Low | Medium | Prevents form data loss on mobile |
| **Could Have** | GitHub Repo Linking & Issue Import | High | Medium | Context enrichment from Git repos |
| **Could Have** | Cross-Project Pattern Detection | High | High | Surfaces recurring technical bottlenecks |
| **Won't Have (MVP)** | Full Issue/Sprint Tracker | High | Low | Reforge is not Jira or Linear |
| **Won't Have (MVP)** | Real-Time Multi-User Collaboration | High | Low | Solo builders are the MVP focus |
| **Won't Have (MVP)** | Complex Automation Rules & Webhooks | High | Low | Avoid premature platform bloat |

### 3.2 Non-Goals
* **Not an Issue Tracker:** Will not support complex issue hierarchies, Kanban swimlanes, story points, or velocity burn-down charts.
* **Not a Code Host or IDE:** Will not clone git repositories, run test runners, or serve as a source-code viewer.
* **Not a Social Network:** No public feeds, social likes, comments, or public follower graphs in MVP.
* **Not an Autonomous Coding Agent:** Reforge does not generate implementation code; AI assistance is strictly analytical and advisory.

---

## 4. Core Features & Detailed Functional Requirements

### 4.1 Module: Authentication & Profile (`features/auth`)
* **FR-01.1:** The user must be able to sign up and sign in using Supabase Auth (Email/Password or magic link).
* **FR-01.2:** On account creation, a public profile row (`profiles`) must be automatically initialized linked to `auth.users.id`.
* **FR-01.3:** Session tokens must be securely persisted on mobile storage; upon token expiration, the user must be cleanly routed to login.

### 4.2 Module: Idea Vault (`features/ideas`)
* **FR-02.1:** Users can create an idea with: Title (required), Description/Problem, Target Users, and arbitrary Tags.
* **FR-02.2:** Ideas can be filtered by tags and searched by title/description.
* **FR-02.3:** Ideas can have lifecycle states: `draft`, `active`, `converted`, `archived`.
* **FR-02.4:** Fast-capture interaction: An idea must be savable with only a title in under 10 seconds.

### 4.3 Module: Idea-to-Project Conversion (`features/projects`)
* **FR-03.1:** A user can convert any eligible Idea into an active Project with a single action.
* **FR-03.2:** The conversion must execute atomically:
  1. Creates a new row in `projects` referencing the `idea_id`.
  2. Sets the original idea status to `converted`.
  3. Pre-populates the project title and initial MVP scope from the idea problem statement.

### 4.4 Module: Project Workspace & Execution
* **FR-04.1:** Each project must contain an explicit **MVP Scope Definition** field, permanently visible at the top of the workspace.
* **FR-04.2:** Lightweight task tracking: Users can add, reorder, check off, and delete project tasks with simple statuses (`pending`, `completed`).
* **FR-04.3:** Project status model: `active`, `paused`, `abandoned`, `completed`, `reforged`.

### 4.5 Module: Project Memory (`features/projects/memory`)
* **FR-05.1:** Quick-capture memory entries during development:
  * **Architectural Decisions:** Title, Decision made, Rationale/Why.
  * **Blockers:** Description, Severity, Technical hurdle encountered.
  * **General Log:** Lightweight notes and findings.
* **FR-05.2:** Timeline View: All memory records must be displayed in a reverse-chronological timeline with timestamps.

### 4.6 Module: Abandonment Flow & Project Graveyard (`features/graveyard`)
* **FR-06.1:** When abandoning or pausing a project, the user is prompted with an explicit **Abandonment Dialog**:
  * Structured reason selection: `Scope Creep`, `Loss of Interest`, `Technical Blocker`, `Time Constraint`, `Wrong Assumptions`, `Market Change`, `Other`.
  * Brief exit note.
* **FR-06.2:** Abandoning a project updates `projects.status = 'abandoned'` and records `abandoned_at = now()`. It is **never** a hard database deletion.
* **FR-06.3:** The **Project Graveyard** screen lists all abandoned and paused projects with graveyard stats (days alive, last updated, primary abandonment reason).

### 4.7 Module: Post-Mortem & Lesson Extraction (`features/postmortem`)
* **FR-07.1:** Directly accessible from any abandoned project in the Graveyard.
* **FR-07.2:** Structured reflection capture:
  * *Primary Failure Reason* (categorized enum)
  * *What went wrong?* (free text)
  * *What went well?* (free text)
  * *Reusable Lessons Learned* (structured items with category: `Architecture`, `Scoping`, `Tooling`, `Market`).
* **FR-07.3:** Lessons are persisted to `project_lessons` and tagged for cross-project searchability.

### 4.8 Module: Reforge Engine & V2 Creation (`features/reforge`)
* **FR-08.1:** Any abandoned project with a completed post-mortem can trigger the **Reforge** action.
* **FR-08.2:** The Reforge workflow presents the user with:
  * Review of previous failure reasons and extracted lessons.
  * Checklist to select which lessons must apply to V2.
  * V2 Scope Redefinition (forcing a smaller, more realistic MVP).
* **FR-08.3:** When confirmed, the engine creates a new active Project (`V2`) and registers a lineage record in `project_versions`:
  * `source_project_id` = original abandoned project
  * `new_project_id` = newly forged V2 project
  * `version_label` = "V2" (or V3, etc.)
  * `changes_summary` = synthesized improvement strategy.

### 4.9 Module: Advisory AI Assistance (Serverless via Edge Functions)
* **FR-09.1:** **AI Idea Scope Review:** Evaluates idea description and warns against scope creep, suggesting a minimal 1-week MVP cut.
* **FR-09.2:** **AI Post-Mortem Assistant:** Analyzes project decisions, blockers, and exit notes to draft an initial post-mortem summary and suggested lessons.
* **FR-09.3:** **AI Reforge Strategist:** Synthesizes past failures and proposes 3 concrete architectural simplifications for V2.
* **FR-09.4:** *Rule of Architecture:* AI features are advisory only. Users can accept, edit, or reject all AI suggestions. AI failure or quota exhaustion must never block non-AI core workflows.

### 4.10 Module: Search & Filtering (`features/search`)
* **FR-10.1:** Global search bar indexing: Idea titles/notes, active projects, graveyard projects, and reusable lessons.
* **FR-10.2:** Filter by status (`active`, `paused`, `abandoned`, `reforged`) and tags.

---

## 5. Non-Functional Requirements (NFRs)

### 5.1 Security & Data Isolation
* **NFR-01:** **100% RLS Coverage:** Every table with user data must enforce Row-Level Security policies verifying `auth.uid() = user_id`.
* **NFR-02:** **Zero Client Secrets:** The Flutter mobile client must only possess the public anonymous API key (`anon_key`). Service-role keys and AI provider API tokens must reside exclusively within Supabase Edge Function environment secrets.
* **NFR-03:** **LLM Input Sanitization:** User project text passed to AI prompts must be treated as untrusted data to mitigate prompt injection.

### 5.2 Performance & Responsiveness
* **NFR-04:** Screen transitions and local list views must render at 60 FPS on standard modern mobile hardware.
* **NFR-05:** Cold load of Idea Vault and Project Workspace should take less than 1.5 seconds over standard 4G/LTE mobile connections.
* **NFR-06:** Edge Function AI calls must timeout gracefully after 15 seconds with clear user feedback and retry options.

### 5.3 Maintainability & Code Quality
* **NFR-07:** Strict modular architecture: Presentation layer (Widgets) must never communicate directly with Supabase clients; all access flows through Riverpod Notifiers and Repository interfaces.
* **NFR-08:** Zero static analysis warnings (`flutter analyze` with `flutter_lints` must pass cleanly).

### 5.4 Accessibility (a11y)
* **NFR-09:** All interactive tap targets must measure at least 48x48 dp.
* **NFR-10:** Text elements must honor system accessibility font scaling up to 150%.
* **NFR-11:** Contrast ratio between background and foreground text must meet WCAG 2.1 AA standards (minimum 4.5:1).

### 5.5 Operational Cost
* **NFR-12:** The entire architecture must run within Supabase Free / Low-tier limits without requiring dedicated always-on EC2 or Kubernetes clusters.

---

## 6. Business Rules & Domain Invariants

1. **Owner Exclusivity:** In MVP, only the authenticated owner of an idea or project can read, update, or archive that record.
2. **Resurrection Eligibility:** A project cannot be reforged unless it has an explicit status of `abandoned` or `paused`.
3. **Lineage Preservation:** A V2 project must always maintain a permanent foreign-key link to its source ancestor project.
4. **Soft Deletion Semantics:** Moving a project to the "Graveyard" is an active lifecycle state transition (`status = 'abandoned'`), not a deletion. Hard deletion requires an explicit secondary confirmation.
5. **No AI Vendor Lock-in:** AI Edge Functions must accept and return standardized JSON schemas, keeping the client code completely agnostic to whether OpenAI, Anthropic, or Google Gemini is used.

---

## 7. Edge Cases & Error Handling

| Scenario | System Behavior |
| :--- | :--- |
| **Idea converted multiple times** | Prevent duplicate active project creation from the same idea unless explicitly branching. |
| **Project abandoned with zero tasks** | Allow abandonment, prompt for brief reason without forcing full post-mortem. |
| **Network failure during Abandon Flow** | Persist form state locally in memory/draft cache; retry automatically on reconnection. |
| **AI Rate Limit or Service Outage** | Show a non-blocking toast: *"AI advisory currently unavailable"*; provide full manual text entry for all post-mortem fields. |
| **Deleting an ancestor project** | Protect lineage: Ancestor projects with active V2 descendants cannot be hard-deleted without warning that lineage history will be orphaned. |
| **Long periods of inactivity** | The system marks projects inactive visually but never automatically modifies project status without user confirmation. |

---

## 8. MVP Acceptance Criteria (Definition of Done)

The Reforge MVP is accepted when an end-to-end user session can achieve the following without error:
1. User signs up, validates session, and sees an informative empty state.
2. User captures an idea with title, problem description, and tags in < 60 seconds.
3. User converts the idea into an active Project; the idea status becomes `converted`.
4. User defines an MVP scope statement, adds 3 tasks, and logs 2 architectural decisions in Project Memory.
5. User marks the project as `abandoned`, specifying "Scope Creep" as the primary reason.
6. The project appears immediately in the Project Graveyard.
7. User opens the abandoned project, completes a 4-field post-mortem, and extracts 2 reusable lessons.
8. User clicks **Reforge**, reviews lessons, defines a streamlined V2 scope, and spawns the V2 project.
9. The V2 project displays a prominent badge linking to its V1 ancestor.
10. Database RLS verifies that no other user can query or modify these records.
