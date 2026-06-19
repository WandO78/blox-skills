# /blox:ui — Worked Examples

Worked, end-to-end examples of the 5-step design pipeline (read brand → wireframe →
UX copy → component spec → handoff). These illustrate the SKILL LOGIC in SKILL.md.

---

## Example 1: Restaurant booking page (full pipeline — chained from /blox:idea)

```
/blox:idea autopilot chains to /blox:design for Phase 2 (UI Design)

STEP 1 — Read Brand Context:
  Brand loaded: Bella Vita — Warm, Authentic, Family-friendly
  Colors: Terracotta primary (#C75B39), Olive Green secondary (#6B7C3F)
  Typography: Playfair Display headings, Lato body
  Spacing: 4px base grid from design-tokens.css
  Tech stack: Next.js + Tailwind CSS

  "Brand context loaded — designing within your Bella Vita brand system."

STEP 2 — Wireframe/Layout:
  "Which layout for your booking page?

   a) Centered form — clean, focused
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├──────────────────────────────────┤
      │       ┌──────────────┐           │
      │       │  Hero image  │           │
      │       ├──────────────┤           │
      │       │ Booking Form │           │
      │       │  date, time  │           │
      │       │  guests, CTA │           │
      │       └──────────────┘           │
      ├──────────────────────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   b) Split screen — image left, form right
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├────────────────┬─────────────────┤
      │                │                 │
      │  Hero image    │  Booking Form   │
      │  (restaurant   │  date, time     │
      │   interior)    │  guests, name   │
      │                │  [Book Now]     │
      │                │                 │
      ├────────────────┴─────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   c) Full-width hero + form below
      ┌──────────────────────────────────┐
      │  HEADER (logo + nav)             │
      ├──────────────────────────────────┤
      │  HERO (full-width image + text)  │
      ├──────────────────────────────────┤
      │  ┌────────────────────────────┐  │
      │  │  Booking Form (wide)       │  │
      │  │  date | time | guests |CTA │  │
      │  └────────────────────────────┘  │
      ├──────────────────────────────────┤
      │  TESTIMONIALS / INFO SECTION     │
      ├──────────────────────────────────┤
      │  FOOTER                          │
      └──────────────────────────────────┘

   Pick one, or describe what you'd prefer."

User: "b) the split screen"

  "Split screen layout — image showcasing the restaurant on the left,
   booking form on the right.

   Responsive behavior:
   - Mobile (< 768px): stacks vertically — image on top, form below
   - Tablet (768-1024px): 40/60 split (narrower image, wider form)
   - Desktop (> 1024px): 50/50 split as designed"

STEP 3 — UX Copy:
  "Here's all the text for your booking page:

   | Location | Element | Text | Notes |
   |----------|---------|------|-------|
   | Header | nav | Home, Menu, Book a Table, About, Contact | 5 nav items |
   | Hero | h1 | 'Your Table Awaits' | Main headline over image |
   | Form | h2 | 'Reserve Your Evening' | Form section heading |
   | Form | label | 'Date' | Date picker label |
   | Form | label | 'Time' | Time picker label |
   | Form | label | 'Guests' | Guest count dropdown label |
   | Form | placeholder | 'Select a date' | Date picker hint |
   | Form | placeholder | 'Choose a time' | Time picker hint |
   | Form | placeholder | 'Number of guests' | Dropdown hint |
   | Form | label | 'Your Name' | Name input label |
   | Form | placeholder | 'Full name' | Name input hint |
   | Form | label | 'Email' | Email input label |
   | Form | placeholder | 'your@email.com' | Email input hint |
   | Form | CTA | 'Book My Table' | Primary submit button |
   | Form | helper | 'We will send confirmation to this email' | Under email |
   | Form | error | 'Please choose a date for your visit' | Missing date |
   | Form | error | 'Please select a time slot' | Missing time |
   | Form | error | 'Please tell us how many guests' | Missing guests |
   | Form | error | 'Please enter your name' | Missing name |
   | Form | error | 'Please enter a valid email address' | Invalid email |
   | Loading | text | 'Checking available tables...' | During API call |
   | Success | h2 | 'Table Booked!' | Confirmation heading |
   | Success | body | 'We have sent a confirmation to [email]. See you [date]!' | Confirmation |
   | Error | text | 'We could not complete your booking. Please try again.' | API failure |
   | Error | action | 'Try Again' | Retry button |
   | Image | alt | 'Candlelit dining room at Bella Vita with rustic wooden tables' | Hero img |
   | Icon | aria-label | 'Close confirmation' | X on success modal |
   | Skip nav | text | 'Skip to booking form' | Screen reader |"

STEP 4 — Component Specification:
  "Component hierarchy:

   BookingPage
   ├── Header
   │   ├── Logo
   │   └── Navigation (5 items)
   ├── SplitLayout
   │   ├── HeroImage
   │   └── BookingForm
   │       ├── DatePicker
   │       ├── TimePicker
   │       ├── GuestSelector
   │       ├── NameInput
   │       ├── EmailInput
   │       └── SubmitButton
   ├── BookingConfirmation (modal)
   └── Footer

   [Full props/states/a11y spec for each component...]"

STEP 5 — Design Handoff:
  "Design handoff saved:
   - docs/design/booking-page.md (full implementation spec)

   Files to create: 8 components, 1 API route, 1 style module
   API endpoints: GET /api/availability, POST /api/bookings
   Design tokens: Terracotta primary, Playfair headings, 4px grid

   Design complete. Ready for next phase."

→ /blox:idea autopilot asks: "Continue to Phase 3 (Build)?"
```

---

## Example 2: Dashboard design (standalone invocation)

```
User: /blox:design "admin dashboard with user management and analytics"

STEP 1 — Read Brand Context:
  No brand guidelines found.
  Tech stack: Next.js + Tailwind
  "No brand found. Using clean defaults — Inter font, blue primary."

STEP 2 — Wireframe/Layout:
  "Which dashboard layout?

   a) Sidebar navigation — classic dashboard
      ┌────────┬─────────────────────────────┐
      │        │  TOP BAR (search + profile)  │
      │ SIDE   ├─────────────────────────────┤
      │ NAV    │  ┌───────┐ ┌───────┐        │
      │        │  │ Stat  │ │ Stat  │ ...    │
      │ Users  │  └───────┘ └───────┘        │
      │ Stats  │  ┌──────────────────────┐   │
      │ Config │  │  Data Table / Chart  │   │
      │        │  └──────────────────────┘   │
      └────────┴─────────────────────────────┘

   b) Top navigation — more content space
      ┌──────────────────────────────────────┐
      │  TOP NAV (logo + items + profile)    │
      ├──────────────────────────────────────┤
      │  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐│
      │  │ Stat │ │ Stat │ │ Stat │ │ Stat ││
      │  └──────┘ └──────┘ └──────┘ └──────┘│
      │  ┌───────────────┐ ┌────────────────┐│
      │  │  Users Table  │ │  Chart Area    ││
      │  └───────────────┘ └────────────────┘│
      └──────────────────────────────────────┘

   c) Collapsible sidebar — best of both
      ┌──┬───────────────────────────────────┐
      │  │  TOP BAR (breadcrumb + actions)   │
      │◀▶├───────────────────────────────────┤
      │  │  KPI cards row                    │
      │  │  ┌─────────────┐ ┌──────────────┐│
      │  │  │ Users table │ │ Activity log ││
      │  │  └─────────────┘ └──────────────┘│
      └──┴───────────────────────────────────┘

   For an admin dashboard with data tables and analytics, I recommend (a)."

User: "a) sidebar"

  [Responsive behavior described]

STEP 3 — UX Copy:
  [Full UX copy table for dashboard: nav labels, stat card labels, table
   headers, empty states for each section, filter labels, action buttons,
   bulk action labels, confirmation dialogs, search placeholder, etc.]

STEP 4 — Component Specification:
  [Full component tree: DashboardLayout, Sidebar, TopBar, StatCard,
   UsersTable, UserRow, UserActions, AnalyticsChart, Pagination,
   SearchInput, FilterDropdown, BulkActionBar, ConfirmDialog...
   Each with props, states, variants, a11y requirements]

STEP 5 — Design Handoff:
  "Design handoff saved: docs/design/admin-dashboard.md

   14 components, 3 API endpoints, full a11y spec.
   Run /blox:build to implement this design."
```

---

## Example 3: Single component design

```
User: /blox:design "pricing card component"

STEP 1 — Read Brand Context:
  Brand loaded: SaaS product, Electric Blue primary
  "Brand context loaded."

STEP 2 — Wireframe (component-level):
  "Pricing card structure:

   ┌─────────────────────┐
   │  Plan Name          │
   │  $XX /month         │
   │  ─────────────────  │
   │  ✓ Feature 1        │
   │  ✓ Feature 2        │
   │  ✓ Feature 3        │
   │  ✗ Feature 4 (gray) │
   │                     │
   │  [ Choose Plan ]    │
   │                     │
   │  'Most Popular' tag │
   │  (optional)         │
   └─────────────────────┘

   3 variants: Basic, Pro (highlighted), Enterprise
   Responsive: full-width on mobile, side-by-side on desktop"

STEP 3-5 — [UX copy, component spec with props/states/a11y, handoff]

  "Design saved: docs/design/pricing-card.md
   1 component with 3 variants, 5 states, full a11y.
   Run /blox:build to implement."
```

---

## Example 4: Multi-step flow design

```
User: /blox:design "onboarding flow for new users"

STEP 1 — Read Brand Context:
  [loads brand]

STEP 2 — Flow wireframe:
  "Onboarding flow — 4 steps:

   ┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
   │ Step 1   │ ──→ │ Step 2   │ ──→ │ Step 3   │ ──→ │ Step 4   │
   │ Welcome  │     │ Profile  │     │ Prefs    │     │ Done!    │
   │ + name   │     │ + avatar │     │ + theme  │     │ → app    │
   └──────────┘     └──────────┘     └──────────┘     └──────────┘
        ↑                                                   │
        └──── 'Start Over' ────────────────────────────────┘

   Progress bar at top shows completion (25%, 50%, 75%, 100%)
   Back button on Steps 2-4
   Skip button on Steps 2-3 (optional fields)

   Responsive: same flow on all devices, form fields stack vertically on mobile"

STEP 3-5 — [UX copy for each step, component specs, handoff with flow logic]
```
