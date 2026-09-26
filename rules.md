# Reforge — Engineering Rules, Coding Guidelines & AI Agent Directives

**Document Version:** 1.0  
**Target:** Engineering Team & AI Coding Agents  
**Scope:** Dart/Flutter Client, Supabase Backend, SQL Migrations, Edge Functions

---

## 1. Core Engineering Principles

1. **Lifecycle Depth Over Feature Breadth:** We do not aim to build another generic task manager or Kanban board. Every line of code must serve the core lifecycle: `Capture → Shape → Build → Abandon → Reflect → Learn → Reforge`.
2. **Fail Safe, Fail Explicitly:** Project abandonment is a natural lifecycle state, not a failure or deletion. System errors must never lose user draft input.
3. **Zero Untrusted Client Code:** The Flutter client is completely untrusted. All security, access limits, and data integrity checks must be enforced at the PostgreSQL RLS and Edge Function level.

---

## 2. AI Coding-Agent Rules (Strict Directives)

When AI agents or automated assistants generate or edit code in this codebase, the following rules are non-negotiable:

> [!IMPORTANT]
> 1. **Read Before Writing:** Always read and inspect existing files and module patterns before proposing or creating edits.
> 2. **Never Hallucinate APIs:** Never guess or invent methods, properties, or packages. Verify all Flutter and Supabase Dart SDK APIs against official documentation.
> 3. **No Repository Bypassing:** Never make direct Supabase calls (`Supabase.instance.client.from(...)`) from widgets or presentation files to "finish faster". Every database or network interaction must pass through a dedicated Repository.
> 4. **No Completion Without Verification:** Never mark a task, phase, or feature as complete without adding or executing corresponding tests and running `flutter analyze`.
> 5. **Isolate Assumptions:** If an API shape or design detail is ambiguous, isolate the assumption behind an abstract interface rather than scattering unverified code throughout the codebase.
> 6. **Zero Secrets in Client Code:** Never place `service_role` keys, OpenAI/Gemini private API keys, or database administrative credentials inside Dart files. Use Supabase Edge Function secrets.
> 7. **Sanitize LLM Output:** Always treat output returned from AI models as untrusted data; validate the schema before rendering or persisting it to PostgreSQL.

---

## 3. Flutter & Dart Coding Standards

### 3.1 Naming Conventions
* **Classes & Enums:** `UpperCamelCase` (e.g., `IdeaVaultRepository`, `ProjectStatus`, `ReforgePlanNotifier`).
* **Files & Directories:** `snake_case` (e.g., `idea_vault_screen.dart`, `project_repository.dart`).
* **Variables, Parameters & Methods:** `lowerCamelCase` (e.g., `fetchActiveProjects()`, `mvpScope`, `userId`).
* **Constants:** `lowerCamelCase` or `kUpperCamelCase` (e.g., `defaultPageLimit = 20`, `kDefaultAnimationDuration`).
* **Feature Folder Naming:** Singular nouns representing the domain feature (e.g., `auth`, `ideas`, `projects`, `graveyard`, `postmortem`, `reforge`).

### 3.2 Widget Architecture & Best Practices
* **Keep Widgets Small & Focused:** Avoid monolith build methods. Extract sub-trees into private helper widgets or reusable stateless components.
* **Separation of Presentation & Business Logic:**
  * Widgets only describe UI and user interactions.
  * State and side effects reside inside Riverpod `Notifier` or `AsyncNotifier` classes.
* **Avoid Hardcoded Magic Values:** Use tokens from `lib/core/theme/` for colors, border radii, text styles, and spacing.
* **Accessibility (a11y) First:**
  * Ensure all `IconButton` and interactive elements provide explicit `tooltip` or `semanticsLabel`.
  * Maintain minimum touch target size of 48x48 logical pixels.

---

## 4. Architectural Rules & Layer Separation

```text
[ Presentation Layer: Views & Widgets ]
                  │
                  ▼
[ Application Layer: Riverpod Notifiers ]
                  │
                  ▼
[ Domain Layer: Entities & Failure Models ]
                  │
                  ▼
[ Data Layer: Repositories & Data Sources ]
                  │
                  ▼
[ Remote / Local: Supabase Client / Local Cache ]
```

### Invariants:
1. **Unidirectional Dependency:** Dependencies only point downward. Repositories must never depend on ViewModels or UI widgets.
2. **Cross-Feature Communication:** Features must never import private implementation files from other features. Communication occurs via shared domain models, exported service interfaces, or Riverpod providers declared in public feature barrels.
3. **Immutable State:** Application state exposed by providers must be immutable. Use `copyWith` methods to emit updated state objects.

---

## 5. Security & Privacy Rules

1. **Row-Level Security (RLS) is Mandatory:** No table containing user data may exist in production without RLS enabled. Every table must have explicit `SELECT`, `INSERT`, `UPDATE`, and `DELETE` policies tied to `auth.uid()`.
2. **Client Key Restriction:** The Flutter application bundle must only ever contain the Supabase `anon_key` (public anonymous key).
3. **No Sensitive PII in Server Logs:** Edge Functions and client error trackers must redact passwords, auth tokens, and raw user project notes from logs.
4. **IDOR Prevention:** Always verify that the entity being updated or deleted belongs to `auth.uid()`, even if an RPC function accepts an ID parameter.

---

## 6. Error Handling & Failure Modeling

1. **No Silent Failures:** Never catch an exception and swallow it silently (`catch (e) {}` is strictly forbidden).
2. **Typed Domain Failures:** All exceptions from network, database, or device storage must be caught in the repository layer and converted to typed `AppFailure` subclasses:
   * `NetworkFailure`
   * `AuthFailure`
   * `NotFoundFailure`
   * `ValidationFailure`
   * `ServerFailure`
3. **Actionable User Feedback:** Error messages shown to users must be human-readable and suggest a recovery action (e.g., *"Unable to save your idea. Check your connection and try again."* instead of *"SocketException: OS Error 111"*).
4. **Draft Protection:** When an error occurs during form submission (e.g., post-mortem or idea capture), the form content must remain intact in memory or local storage.

---

## 7. Testing Rules & Quality Gates

| Test Layer | Requirement | Target Coverage |
| :--- | :--- | :--- |
| **Unit Tests** | Status transitions, data parsing, DTO mapping, Reforge calculations | > 85% of domain logic |
| **Widget Tests** | Critical screen rendering, loading states, empty states, error displays | Key user-facing surfaces |
| **RLS Policy Tests** | Automated SQL tests ensuring User B cannot read User A's data | 100% of tables |
| **Integration Tests** | Complete end-to-end loop: `Idea → Project → Abandon → Post-Mortem → Reforge` | All critical paths |

---

## 8. Version Control & Git Conventions

### 8.1 Branch Strategy
* `main`: Protected production branch. Direct pushes forbidden.
* `feature/<feature-name>`: Dedicated feature development branches.
* `fix/<bug-name>`: Urgent patches and bug fixes.

### 8.2 Commit Messages (Conventional Commits)
Commits must follow the Conventional Commits format:
```text
<type>(<scope>): <short description>

[optional body]
```
* **Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`.
* **Examples:**
  * `feat(ideas): implement tag filtering in Idea Vault`
  * `fix(postmortem): preserve form fields on network timeout`
  * `chore(supabase): add migration for project lineage check constraint`

### 8.3 Pull Request Checklist
Before opening or merging a PR:
- [ ] Code passes `flutter analyze` with 0 warnings.
- [ ] All unit and widget tests pass (`flutter test`).
- [ ] New database tables or columns have matching versioned SQL migrations in `supabase/migrations/`.
- [ ] RLS policies are attached and verified for any new tables.
- [ ] No secret tokens or keys are committed.
