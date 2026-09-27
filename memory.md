# Reforge — Project Memory & Technical Context Log

**Project Name:** Reforge  
**Status:** ✅ Phase A2 Complete — Phase A3 implementation complete; verification pending
**Last Updated:** September 27, 2026
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

### ADR-007: Exclusively Light-Mode Design System Aligned with Figma Specifications
* **Status:** Accepted (2026-09)
* **Context:** The product aesthetic is inspired by physical engineering workshops, technical documentation, and warm notebook paper (`warmSurface` #FBF9F5). The user explicitly mandated the omission of dark mode.
* **Decision:** The application will strictly implement a single, high-fidelity Light Theme and will not maintain dual light/dark stylesheets.
* **Consequences:** Eliminates visual drift, reduces theme maintenance overhead by 50%, guarantees 1:1 fidelity with provided Figma artboards (Home, Ideas Vault, Detail, Post-Mortem, Reforge V2), and speeds up UI delivery.

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

### Milestone A1: Foundation & Core Infrastructure (In Progress)
* **2026-09-26 — TASK-A1.1: Core Dependencies Configuration Completed:**
  * Integrated core production packages into `pubspec.yaml`:
    * `flutter_riverpod` (`^3.4.3`): Declarative reactive state management and dependency injection.
    * `supabase_flutter` (`^2.17.2`): Managed backend client SDK (PostgreSQL, Auth, Storage, Edge Functions).
    * `go_router` (`^18.0.1`): Declarative URL routing and redirect guards.
    * `lucide_icons` (`^0.257.0`): Minimalist outline iconography per design system.
    * `intl` (`^0.20.3`): Internationalization, time, and numeric formatting.
    * `flutter_dotenv` (`^6.0.1`): Secure environment variable bootstrap.
  * Resolved complete dependency tree cleanly without version conflicts via `pub get`.
  * Verified static analysis with 0 errors/warnings.

* **2026-09-26 — TASK-A1.2: Design Tokens & Theme Setup Completed:**
  * Analyzed user-provided Figma artboards (Home Screen, Ideas Vault, Idea Detail, Post-Mortem, Reforge V2).
  * Formalized ADR-007 establishing a strict, single Light Theme (`warmSurface` `#FBF9F5`, pure white card containers, `#172033` deep slate contrast elements).
  * Implemented design tokens:
    * `lib/core/theme/colors.dart`: Surfaces, typography colors, brand forge accent (`#B45309`), semantic status pills (`success`, `warning`, `danger`, `category`), and callout tints.
    * `lib/core/theme/typography.dart`: Strict Inter font sizing and line-height constraints (Greeting, ScreenTitle, SectionTitle, CardTitle, Badges, Metrics, Quotes, Code).
    * `lib/core/theme/theme.dart`: Material 3 `ThemeData` configuration including AppBar, Card, Button, Input, and Divider themes.
  * Added unit and widget tests (`test/core/theme/theme_test.dart`) verifying token consistency and scaffold rendering.
  * Ran static analysis with 0 errors/warnings.

* **2026-09-26 — TASK-A1.3: Error & Failure Architecture Completed:**
  * Implemented typed exception layer (`lib/core/errors/exceptions.dart`): `AppException`, `NetworkException`, `AuthException`, `NotFoundException`, `ServerException`, `ValidationException`.
  * Implemented domain failure layer (`lib/core/errors/failures.dart`): `AppFailure` base class, `NetworkFailure`, `AuthFailure`, `NotFoundFailure`, `ServerFailure`, `ValidationFailure`.
  * Added unified exception-to-failure mapper factory (`AppFailure.fromException`) handling generic Dart exceptions, custom AppExceptions, and Supabase client errors (`AuthException`, `PostgrestException` with specific `PGRST116` mapping to `NotFoundFailure`).
  * Created unit test suite (`test/core/errors/failure_test.dart`) verifying 10 distinct error mapping cases.
  * Ran static analysis with 0 errors/warnings.

* **2026-09-26 — TASK-A1.4: Supabase Client & Environment Bootstrapping Completed:**
  * Created `assets/.env` for local credential storage (gitignored for production) with `SUPABASE_URL` and `SUPABASE_ANON_KEY` keys; also added `.env.example` as template.
  * Registered `assets/.env` as Flutter asset in `pubspec.yaml`.
  * Implemented `SupabaseBootstrap` (`lib/core/network/supabase_client.dart`):
    * Resilient dual-path loader (`assets/.env` → `.env` fallback).
    * Placeholder credential detection — boots into offline/demo mode without crashing if credentials are missing.
    * Uses `publishableKey` parameter (not deprecated `anonKey`) with `AuthFlowType.pkce` for secure PKCE auth flow.
  * Exposed Riverpod providers: `supabaseClientProvider`, `currentUserProvider`, `authStateChangesProvider`.
  * Rewrote `lib/main.dart`: `ProviderScope` root → `WidgetsFlutterBinding.ensureInitialized()` → `SupabaseBootstrap.initialize()` → `ReforgeApp` with `ReforgeTheme.lightTheme`.
  * Added foundation `ReforgeShellScreen` as temporary home scaffold with Forge-styled greeting, workshop-active badge, and connection-status card.
  * Updated smoke test (`test/widget_test.dart`) for new `ReforgeApp` structure.
  * Ran static analysis with 0 errors/warnings.

### ✅ Phase A1: Foundation & Core Infrastructure — COMPLETE
All four tasks (A1.1 → A1.4) are done. The app now has:
- Core production dependencies resolved.
- Strict Light Theme with full Figma-aligned design tokens.
- Type-safe error/failure architecture with Supabase-aware mapping.
- Resilient Supabase bootstrap with offline/demo mode fallback.

---

### Milestone A2: Authentication & Profile (Completed)
* **2026-09-26 — TASK-A2.1: Supabase Profiles Migration & RLS:**
  * Created database migration `supabase/migrations/20260926000001_create_profiles.sql`.
  * Configured `public.profiles` table linked via foreign key to `auth.users(id)` with cascading delete.
  * Implemented automated profile trigger function (`handle_new_user`) populating default username, display name, and avatar on `auth.users` insertion.
  * Enforced Row-Level Security (RLS) policies:
    * `profiles_select_policy`: Publicly readable by authenticated users.
    * `profiles_update_policy`: Strictly updatable only by the owning user (`auth.uid() = id`).
    * `profiles_insert_policy`: Restricted to owning user or trigger function.

* **2026-09-26 — TASK-A2.2: Auth Repository & Data Source:**
  * Defined domain model `UserProfile` (`lib/features/auth/models/user_profile.dart`) with JSON serialization and immutable copy utilities.
  * Defined abstract contract `AuthRepository` (`lib/features/auth/data/auth_repository.dart`):
    * Methods: `signUp`, `signIn`, `signOut`, `getCurrentSession`, `getProfile`, `updateProfile`.
    * Streams & getters: `authStateChanges`, `currentUser`.
  * Implemented concrete `SupabaseAuthRepository` with unified `AppFailure` error translation.
  * Added unit test suite (`test/features/auth/auth_repository_test.dart`) validating sign in, sign up, session management, and profile fetches.

* **2026-09-26 — TASK-A2.3: Auth UI & Protected Routing:**
  * Implemented state management with `AuthNotifier` and `AuthUiState` (`lib/features/auth/presentation/auth_notifier.dart`).
  * Built Figma-aligned `LoginScreen` (`lib/features/auth/presentation/login_screen.dart`) supporting toggling between Login and Signup modes, password visibility toggle, input validation, and loading indicators.
  * Configured declarative routing and redirect guards with `GoRouter` (`lib/app/routes.dart`):
    * Unauthenticated users attempting to access protected routes (`/home`, etc.) are redirected to `/login`.
    * Authenticated users visiting `/login` or `/signup` are redirected to `/home`.
    * Reactive auth state synchronization via `GoRouterRefreshStream`.
  * Added integration tests (`test/features/auth/auth_ui_and_routing_test.dart`) verifying route protection and screen rendering.
  * Ran static analysis and tests with 0 errors/failures.

### ✅ Phase A2: Authentication & Profile — COMPLETE
All three tasks (A2.1 → A2.3) are done. The app now has:
- PostgreSQL profiles schema with automated triggers and RLS policies.
- Repository layer for authentication and user profile management.
- Complete Login/Signup UI with form validation and feedback.
- GoRouter redirect guards protecting application routes.

---

### Milestone A3: Idea Vault (Implementation Complete; Verification Pending)
* **2026-09-27 — TASK-A3.1: Ideas & Tags Schema:** Added `supabase/migrations/20260926000002_create_ideas_and_tags.sql` with `ideas`, `tags`, and `idea_tags`, lifecycle/stage constraints, composite indexes, cascading relationships, and owner-scoped RLS policies. The migration has not been applied against a Supabase database in this session, so cross-user RLS behavior remains unverified.
* **TASK-A3.2: Repository & State:** Added idea/tag domain models, `SupabaseIdeasRepository` CRUD and tag association methods, Riverpod list/detail/tag/stat providers, filter state, and mutation actions. Added notifier tests for create, filtered list, tag association, and archive in `test/features/ideas/ideas_notifier_test.dart`; tests were not executed. Concrete repository queries still need a backend-backed check.
* **TASK-A3.3: Idea Vault UI:** The Ideas tab is wired into the existing shell work. The vault provides search, status/tag filters, stats, loading/error/empty states, and idea cards. Quick capture supports title-first entry, optional description, tag selection, and tag creation. Idea detail includes lifecycle/stage display, archive/delete actions, and an edit sheet for idea fields, tags, status, and stage. The project conversion CTA remains an intentional Phase A4 placeholder.
* **Verification constraint:** No `flutter analyze`, `flutter test`, or database commands were run, at the user's request. Dart editor diagnostics reported no issues in the changed Dart files; run the Flutter checks and apply/verify the migration locally before marking A3 fully done in `task.md`.
