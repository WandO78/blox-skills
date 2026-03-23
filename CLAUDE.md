# wando-skills — Fejlesztoi utasitasok

> Privat skill library repo. A publikus valtozat: [blox-skills](https://github.com/WandO78/blox-skills)

## Repo architektura

```
wando-skills/              ← EZ A REPO (privat, fejlesztes itt tortenik)
├── skills/                ← 16 felhasznaloi + 4 _internal SKILL.md
├── references/            ← Sablonok es mintak (phase-template, project-scaffold, knowledge-patterns)
├── registry/              ← curated-plugins.yaml (plugin okoszisztema)
├── extensions/            ← PRIVAT — corporate patterns, project-types (NEM kerul a publikus repo-ba)
├── hooks/                 ← PRIVAT — context-reminder.sh, load-extensions.sh (NEM kerul a publikus repo-ba)
├── scripts/               ← bump-version.sh (auto-version CI hasznalja)
├── .sync/                 ← Publikus repo override fajlok (README-blox.md, plugin.json, marketplace.json)
├── .github/workflows/     ← CI/CD: sync-to-blox.yml + auto-version.yml
└── .claude-plugin/        ← Plugin manifest (plugin.json, marketplace.json)
```

## Sync workflow

Push to `main` → 2 GitHub Action:
1. **auto-version.yml** — commit msg prefix alapjan bump-ol (feat: → minor, fix: → patch, BREAKING: → major)
2. **sync-to-blox.yml** — strip-eli a privat tartalmat (extensions/, hooks/, .github/, .sync/, CHANGELOG.md), csereli a publikus fajlokat (.sync/ tartalmabol), privacy check, majd force push a `WandO78/blox-skills` repo-ba

**Kovetkezmeny:** MINDEN fejlesztes ebben a repo-ban tortenik. A publikus blox-skills SOHA nem szerkesztheto kozvetlenul.

## Konvenciok

### Commit uzenetek
- `feat:` — uj funkcio (minor version bump)
- `fix:` — javitas (patch version bump)
- `BREAKING:` — nem kompatibilis valtozas (major version bump)
- `chore:` — karbantartas (nincs version bump)
- NE hasznalj `Co-Authored-By`, `Claude`, `Opus`, `Anthropic` hivatkozast commit uzenetben

### SKILL.md fajlok
- Minden skill a `skills/<nev>/SKILL.md` helyen el
- Belso skill-ek: `skills/_internal/<nev>/SKILL.md`
- Kotelozo elemek: YAML frontmatter (`name`, `description`), AUTO-DISCOVERY blokk
- A skill leirasa `"Use when..."` formatumu legyen a discovery szamara
- Ne hasznalj `!`command`` auto-detect-et — runtime discovery-t hasznalj

### Privat tartalom vedelem
- `extensions/` — SOHA nem kerulhet a publikus repo-ba
- `.sync/private-patterns.txt` — privat mintakat tartalmaz, a sync ellenorzi
- Uj privat referenciat hozzaadni → frissitsd a `private-patterns.txt`-t is

### Nyelv
- Dokumentacio, kommentek: magyar (ekezet nelkul)
- SKILL.md tartalom: angol (felhasznalok szamara)
- Commit uzenetek: angol

## Fejlesztes

### Uj skill hozzaadasa
1. `mkdir skills/<nev>/`
2. `SKILL.md` letrehozasa frontmatter + AUTO-DISCOVERY blokk + skill logika
3. Teszteles: telepitsd a plugin-t es probald ki valos projekten
4. Commit: `feat: add /blox:<nev> skill — <rovid leiras>`

### Skill modositasa
1. Modositsd a `skills/<nev>/SKILL.md`-t
2. Teszteles valos projekten
3. Commit: `feat:` vagy `fix:` prefix-szel

### Registry bovitese
- `registry/curated-plugins.yaml` — curated (tesztelt) es known (letezik) plugin-ok
- Uj plugin hozzaadasa: tier, category, triggers, priority kotelozo

## Hasznos parancsok

```bash
# Lokalis teszteles
# A plugin a ~/.claude/plugins/cache/wando-marketplace/blox/<verzio>/ ala telepul
# Frissiteshez: /plugin update wando-marketplace

# Osszes SKILL.md frontmatter ellenorzes
grep -l "^---" skills/*/SKILL.md skills/_internal/*/SKILL.md

# Privat tartalom kereso (manualis ellenorzes sync elott)
grep -rlf .sync/private-patterns.txt --include="*.md" --include="*.yaml" skills/ references/ registry/
```
