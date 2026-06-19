# /blox:idea — Worked Examples

End-to-end walkthroughs of the 8-step pipeline. Reference material — the decision logic lives in SKILL.md.

## Example 1: Complete beginner (Autopilot mode)

```
User: /blox:idea "I want to build a restaurant website where people can book tables"

blox: "Great idea! Let me ask a few questions to understand what you need.

       Who is this website for?
       a) A specific restaurant you own/work at
       b) A template for any restaurant
       c) A platform where multiple restaurants can list"

User: "a"

blox: "What should visitors be able to do on the site?
       a) Just see the menu and contact info
       b) Book a table online
       c) Book a table + order food for delivery
       d) All of the above"

User: "b"

blox: "Any similar sites you've seen that you like? (optional — skip if none)"

User: "no"

blox: "Any constraints? Budget, timeline, must-use technology?
       (skip if none)"

User: "no"

blox: "Got it! Here's what I see:

       A website for a specific restaurant where visitors can view the menu,
       see restaurant info, and book tables online.

       This involves:
       - Public-facing site with menu and restaurant info
       - Table booking system with date/time selection
       - Admin view for the restaurant to manage bookings

       Does this capture what you want to build?"

User: "yes"

blox: "For this, I suggest:

       Next.js + Supabase + Vercel

       This gives you a fast website with a database for bookings,
       user-friendly admin panel, and free hosting on Vercel.

       Sound good?"

User: "yes"

blox: [scaffolds project — CLAUDE.md, START_HERE.md, etc.]
      [chains to /blox:plan — generates 5-phase master plan]
      [chains to /blox:setup — checks plugins]

      "Everything is ready!

       5 phases planned
       4 plugins installed
       7 files + 4 directories created

       Phase 1: Brand Identity — colors, fonts, style (/blox:brand)
       Phase 2: UI Design — pages and components (/blox:design)
       Phase 3: Core Build — booking system, menu page (/blox:build)
       Phase 4: Testing & Security (/blox:test + /blox:secure)
       Phase 5: Deploy to Vercel (/blox:deploy)

       Start with Phase 1? (y/n)"

User: "y"

blox: [loads Phase 1, chains to /blox:brand]
```

## Example 2: Experienced developer (Guided/Manual mode)

```
User: /blox:idea "REST API in Go with PostgreSQL for inventory management"

blox: "Who will use this API?
       a) Just you / personal project
       b) Small team (2-10 people)
       c) Public API (anyone can access)
       d) Enterprise / internal company tool"

User: "Internal warehouse team, about 20 users"

blox: "What specific functionality do you need?
       (The core idea is clear — what are the key endpoints?)"

User: "JWT auth, CRUD for products, stock levels, barcode scanning endpoint"

blox: "Here's what I see:

       Go REST API with PostgreSQL for warehouse inventory management.
       JWT authentication, product CRUD operations, stock level tracking,
       and a barcode scanning endpoint. Internal use for ~20 warehouse users.

       This involves:
       - Auth middleware (JWT)
       - Product management (CRUD + stock levels)
       - Barcode scanning integration
       - Admin/reporting endpoints

       Correct?"

User: "yes, and I'll use Chi router and sqlx"

blox: "Perfect. Using your stack: Go + Chi + sqlx + PostgreSQL.

       [scaffolds project with Go-specific structure]
       [chains to /blox:plan — generates plan, skips brand/design phases]
       [chains to /blox:setup — checks Go-relevant plugins]

       Everything is ready!

       5 phases planned
       2 plugins installed
       7 files + 4 directories created

       Phase 1: Foundation — DB schema, auth middleware (/blox:build)
       Phase 2: Core API — product CRUD, stock endpoints (/blox:build)
       Phase 3: Barcode — scanning endpoint integration (/blox:build)
       Phase 4: Testing & Security (/blox:test + /blox:secure)
       Phase 5: Deploy (/blox:deploy)

       Start? (y/n)"
```

## Example 3: User provides everything upfront

```
User: /blox:idea "Personal finance tracker. React Native + Expo + Supabase.
       I want to track expenses, set budgets, and see charts. Just for me."

blox: [detects: vision clear, tech stack specified, audience known]
      [skips Q1 (already answered), Q2 (personal use), Q3 (clear), Q5 (no constraints mentioned)]

      "Any similar apps you've seen that you like? (optional)"

User: "YNAB is great but too expensive"

blox: [notes: YNAB as inspiration — envelope budgeting style]

      "Here's what I see:

       Personal finance tracker for mobile (React Native + Expo + Supabase).
       Track expenses, set budgets (YNAB-inspired envelope style),
       and visualize spending with charts. Personal use only.

       This involves:
       - Expense tracking (add, categorize, search)
       - Budget management (envelope-style, monthly reset)
       - Charts and reports (spending by category, trends)
       - Data sync via Supabase (accessible from any device)

       Does this capture what you want?"

User: "yes"

blox: "Using your chosen stack: React Native + Expo + Supabase.

       [scaffolds, plans, setup]

       6 phases planned...
       Start with Phase 1? (y/n)"
```

## Example 4: Scope too ambitious — MVP suggestion

```
User: /blox:idea "I want to build the next Airbnb but for office spaces,
       with AI matching, blockchain payments, and VR tours"

blox: [Q1 answered, proceeds with Q2-Q5]
      ...

blox: "This is a big vision! It has several independent systems:
       - Office listing marketplace
       - AI matching engine
       - Blockchain payment system
       - VR tour integration

       I suggest starting with an MVP:
       Office listing marketplace with search and booking.
       We can add AI matching, blockchain, and VR as separate phases later.

       This MVP involves:
       - Office listings with photos and details
       - Search and filter by location, size, price
       - Booking and payment (standard, not blockchain yet)
       - User accounts for hosts and renters

       Start with this scope?"

User: "yes, that makes sense"

blox: [proceeds with MVP scope]
```
