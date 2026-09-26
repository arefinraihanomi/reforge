# Reforge — UI & Design System Specification

**Document Version:** 1.0  
**Design Theme:** Industrial Precision & Calm Engineering Craft  
**Aesthetic Metaphor:** Modern Technical Documentation + Subtle Blacksmith "Forge"  
**Typography:** Inter  
**Iconography:** Lucide Icons (Outline, 2px stroke)

---

## 1. Visual Identity & Design Principles

Reforge avoids neon gamification and overwhelming enterprise dashboard clutter. Instead, it adopts a calm, high-trust engineering aesthetic inspired by technical documentation, modern IDEs, and minimalist craft.

### Core Design Principles:
1. **Clarity Over Decoration:** Clean typography and precise spacing communicate hierarchy better than flashy gradients.
2. **Context Before Action:** Crucial project memory, failure context, and MVP scope are always prominently visible before prompts for action.
3. **Progressive Disclosure:** Simple capture flows on top; detailed tags, architectural rationales, and post-mortem deep dives reveal themselves as needed.
4. **Visible Lifecycle:** Statuses (`Draft`, `Active`, `Paused`, `Abandoned`, `Reforged`) are explicit and visually distinct.
5. **Low Cognitive Load:** Every screen prioritizes one primary call-to-action (CTA).

### 1.1 Official App Icon & Brand Assets
- **Icon Asset Path:** `assets/icons/app_icon.png` (1024x1024 px, high-resolution master)
- **Brand Logomark Path:** `assets/brand/logo_mark.png`
- **Full Horizontal Logo Path:** `assets/brand/app_logo.png` (1024x341 px, transparent background)
- **Visual Design & Typography:**
  - **Mark:** An architectural, folded geometric "R" rendered with a rich amber/bronze forge gradient (`#B45309` to darker tones) encased within a dark graphite squircle background.
  - **Logotype:** Bold "Reforge" in dark graphite `#111827` accompanied by an amber forge spark.
  - **Brand Tagline:** `"BUILD. LEARN. REBUILD."` in uppercase tracking, rendered in forge accent bronze (`#B45309`).
  - **Recommended Screen Usage:**
    - `app_logo.png`: Welcome / Onboarding screen, Auth login/signup header, Web navigation bar, and Splash screen.
    - `app_icon.png`: Launcher app icon, notification tray, and compact profile avatar.

---

## 2. Color System & Design Tokens

Reforge strictly adheres to a single, high-trust **Light Mode** palette anchored by a warm paper-like surface (`warmSurface` `#FBF9F5`) and an amber-bronze "Forge" accent (`#B45309`). Dark mode is intentionally omitted:

| Token Name | Hex Code | Semantic Role | Light Mode Usage |
| :--- | :--- | :--- | :--- |
| **`colorGraphite`** | `#111827` | Primary Dark Surface / Text | Primary text color & high contrast elements |
| **`colorWarmSurface`**| `#FBF9F5` | Soft Neutral Background | Main app background (warm paper texture) |
| **`colorCardSurface`**| `#FFFFFF` | Card & Container Surface | Primary card background |
| **`colorDeepSlate`** | `#172033` | Deep Slate Surface / Contrast | Bottom navigation bar, avatar, dark feature cards |
| **`colorForgeAccent`**| `#B45309` | Brand Primary / Action CTA | Primary buttons, active state, left border stripes |
| **`colorMuted`** | `#64748B` | Secondary Text & Dividers | Metadata, subtitles, timestamps |
| **`colorSuccess`** | `#15803D` | Success & Active States | Completed tasks, active badges (`#ECFDF5` bg) |
| **`colorWarning`** | `#B45309` | In-Progress & Exploring | Exploring badges, sprint progress (`#FEF3C7` bg) |
| **`colorDanger`** | `#B91C1C` | Alert, Abandon & Blockers | Abandon actions, failure points (`#FEF2F2` bg) |
| **`colorCategory`** | `#4338CA` | Category & Technical Tags | Dev Tools, Security, Architecture (`#EEF2FF` bg) |

---

## 3. Typography System (Inter)

Typography is standardized on `Inter` with strict sizing and line-height constraints:

| Style Role | Font Size | Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Greeting** | 20 px | SemiBold (600) | 28 px | Dashboard hero greetings |
| **Section Title** | 18 px | SemiBold (600) | 24 px | List headers, card group titles |
| **Card Title** | 17 px | SemiBold (600) | 22 px | Project & Idea card headlines |
| **Subtitle** | 14 px | Regular (400) | 20 px | Helper text, secondary descriptions|
| **Body** | 14 px | Regular (400) | 20 px | Paragraph copy, notes, tasks |
| **Button** | 14 px | Medium (500) | 18 px | Action buttons and pills |
| **Stats Number** | 24 px | Bold (700) | 32 px | Counter cards, graveyard metrics |
| **Card Label** | 12 px | Medium (500) | 16 px | Status chips, timestamps |
| **Stats Label** | 12 px | Regular (400) | 16 px | Sub-labels under metric numbers |

---

## 4. Spacing, Grid & Layout System

### 4.1 Spacing Scale (4px Base Unit)
* **`spacing-xxs`**: 4 px (Tight icon-text gap)
* **`spacing-xs`**: 8 px (Input internal padding, chip padding)
* **`spacing-sm`**: 12 px (Card elements spacing)
* **`spacing-md`**: 16 px (Standard screen padding, card margin)
* **`spacing-lg`**: 24 px (Section breaks, modal spacing)
* **`spacing-xl`**: 32 px (Page header margins)
* **`spacing-xxl`**: 40 px (Major landing spacers)

### 4.2 Grid & Viewport Rules
* **Mobile (Default):** 16 px horizontal viewport margin, single column card flow.
* **Tablet / Desktop Web:** Max content container width of 1200–1280 px. Multi-column masonry or 2–3 column responsive grid for card libraries.

---

## 5. Shape, Elevation & Borders

* **Border Radii:**
  * `radiusSmall` (8 px): Interactive inputs, buttons, filter chips.
  * `radiusMedium` (12 px): Content cards, post-mortem cards, task items.
  * `radiusLarge` (16 px): Bottom sheets, modals, major dialogue surfaces.
* **Elevation & Shadows:**
  * Reforge minimizes heavy drop shadows to prevent visual noise.
  * Flat design with 1 px subtle borders (`#E2E8F0` in light mode, `#334155` in dark mode) is preferred.
  * Floating action buttons and active modals use subtle elevation (`elevation: 2`).

---

## 6. Iconography Specification

* **Icon Library:** [Lucide Icons](https://lucide.dev)
* **Style:** Monoline Outline
* **Stroke Width:** 2.0 px
* **Standard Sizes:**
  * Small (Meta / Chips): 16–20 px
  * Standard (Navigation & Action buttons): 24 px
  * Hero / Feature Icons: 32–48 px

---

## 7. Component Specifications

### 7.1 Action Buttons
* **Primary Button:** Solid `Forge Accent` (`#B45309`) background with white bold text. Used for main action (e.g., "Create Idea", "Reforge to V2").
* **Secondary Button:** Outlined border (1.5 px) with `Deep Slate` text.
* **Destructive Action:** Ghost or red-tinted button (`#B91C1C`). Triggers explicit confirmation modal before executing abandonment or deletion.

### 7.2 Project & Idea Cards
* Cards must display:
  1. Title (17px SemiBold)
  2. Status Chip (e.g., Active in Green, Abandoned in Dark Red, Reforged in Amber)
  3. Last active timestamp (e.g., "Updated 2 days ago")
  4. Primary Category / Tech Tag
  5. Context Snippet (MVP Scope snippet or Failure reason)

### 7.3 Memory Timeline Entry
* Chronological vertical track with colored indicator:
  * 🟢 **Decision:** Indicates architectural direction chosen.
  * 🔴 **Blocker:** Indicates technical or scope hurdle.
  * ⚪ **Note:** General engineering discovery.

---

## 8. Screen Layout & UX Wireframes

### 8.1 Screen: Home & Dashboard
* **Header:** Greeting + Quick Add FAB (`+ Idea`).
* **Active Focus:** Top 1–2 active projects currently in flight.
* **Graveyard Quick Stats:** Total abandoned projects, lessons extracted, reforged count.
* **Bottom Navigation Bar:** `Home`, `Ideas`, `Projects`, `Graveyard`, `Profile`.

### 8.2 Screen: Idea Vault
* **Search & Tag Filter Bar:** Instant real-time filtering.
* **Idea List Cards:** Quick tap to view, swipe to archive.
* **Idea Detail View:** Problem statement, target users, and prominent CTA: **"Convert to Project"**.

### 8.3 Screen: Project Workspace
* **Sticky MVP Scope Banner:** High-contrast bar showing *"MVP Scope Boundary"*.
* **Task Checklist:** Add task input + checkable list.
* **Project Memory Tab:** Reverse-chronological timeline of decisions and blockers.
* **Lifecycle Menu:** Options to `Complete`, `Pause`, or `Abandon & Learn`.

### 8.4 Screen: Project Graveyard
* **Memorial List:** Shows all abandoned/paused projects with duration and failure badges.
* **Quick Stats Header:** E.g., *"14 Projects Rested • 28 Lessons Captured • 4 Reforged"*.
* **Item Action:** Tap card to view details or start **Post-Mortem / Reforge**.

### 8.5 Screen: Post-Mortem Reflection Form
* Guided multi-step or single scrollable form:
  * Select primary abandonment reason (dropdown).
  * What went wrong? (text field with AI draft assistant button).
  * What went well?
  * Reusable lessons learned (bullet point creator with categories).

### 8.6 Screen: Reforge Resurrection Wizard
* **Step 1:** Review past failure reasons and extracted lessons.
* **Step 2:** Choose which lessons apply to the new iteration.
* **Step 3:** Define a restricted, tighter MVP scope for V2.
* **Step 4:** Confirm and spawn `[Project Name] V2`.

---

## 9. Empty, Loading & Feedback States

* **Empty States:** Never display blank "No items found". Every empty screen educates the builder:
  * *Idea Vault Empty:* "No ideas logged yet. Capture that late-night flash of inspiration before it fades."
  * *Graveyard Empty:* "No projects in the Graveyard. Paused or abandoned projects will rest here as reusable lessons."
* **Loading States:** Use shimmer skeleton placeholders mirroring the actual card layouts rather than generic spinner wheels.
* **Toasts & Snackbars:** Non-intrusive floating feedback confirming actions (e.g., *"Idea converted to Project"*, *"Draft preserved locally"*).
