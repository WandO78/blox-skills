# blox-skills

Universal skill library for Claude Code — from idea to production.

## What is blox?

blox is a modular skill library that guides you through the entire software development lifecycle. Whether you're a complete beginner or an experienced developer, blox adapts to your level.

**Beginners:** Just type `/blox:idea` and describe what you want to build. blox handles the rest.

**Professionals:** Use any skill directly — `/blox:build`, `/blox:check`, `/blox:deploy` — and take manual control whenever you want.

## Install

```
/plugin add WandO78/blox-skills
```

## Quick Start

```
/blox:idea "Describe what you want to build"
```

That's it. blox guides you through everything else — planning, branding, design, building, testing, security, and deployment.

## Skills

### Core
| Skill | What it does |
|-------|-------------|
| `/blox:idea` | Brainstorm, plan, and start building — the single entry point |
| `/blox:plan` | Create a detailed implementation plan |
| `/blox:build` | Write code with TDD and auto-checkpoints |
| `/blox:check` | Quality review (code, brand, accessibility, security) |
| `/blox:done` | Complete a phase and capture lessons learned |
| `/blox:scan` | Audit an existing project (read-only) |
| `/blox:setup` | Install and update recommended plugins |
| `/blox:fix` | Debug and fix issues systematically |

### Domain
| Skill | What it does |
|-------|-------------|
| `/blox:brand` | Create brand identity, colors, guidelines |
| `/blox:design` | Design UI/UX with accessibility |
| `/blox:image` | Generate images with AI |
| `/blox:secure` | Security audit (OWASP) |
| `/blox:deploy` | Deploy to production |
| `/blox:test` | Run unit and E2E tests |
| `/blox:docs` | Generate documentation |

## How It Works

1. **You describe your idea** — blox asks clarifying questions
2. **blox suggests a tech stack** — or you choose your own
3. **blox creates a plan** — broken into phases with clear steps
4. **blox installs what's needed** — plugins, tools, dependencies
5. **blox guides you through each phase** — with quality checks at every step
6. **You ship** — blox helps deploy and document

## Curated Plugin Ecosystem

blox recommends tested, compatible plugins when you need them:

- **Code quality:** TypeScript LSP, Pyright, security guidance
- **Design:** Frontend design, image generation, playground
- **Testing:** Playwright for E2E tests
- **Deploy:** Vercel, and more
- **Integration:** GitHub, Supabase, Context7

Plugins are suggested at the right moment — never forced, always optional.

## License

MIT
