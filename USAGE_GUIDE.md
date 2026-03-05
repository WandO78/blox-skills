# wando-skills — Usage Guide

> Mit csinalj ha...

---

## 1. Uj projektet kezdek nullarol

```
/wando:init
```

**Mi tortenik:**
1. **Brainstorm** — Az agent megkerdezi mi a cel, milyen tech stack, mik a fobb feature-ok
2. **Decisions** — Egyutt dontitek el: zona (Z0-Z7), projekt tipus (T1-T7), architektura
3. **Scaffolding** — Letrehozza a teljes projekt infrastrukturat:
   - `CLAUDE.md` — projekt identitas + skill registry
   - `START_HERE.md` — phase tracker + Resumption Protocol
   - `CONTEXT_CHAIN.md` — session kovetkezo lanc
   - `ARCHITECTURE.md`, `GOLDEN_PRINCIPLES.md`, `QUALITY_SCORE.md`, `TECH_DEBT.md`
   - `plans/` + `completed/` + `failed/` konyvtarak
4. **Phase Generation** — Legeneralja az elso phase fajlt (vagy tobbet)

**Utana:** `/wando:plan` a kovetkezo phase-hez.

---

## 2. Meglevo projektet szeretnek rendbe rakni (retrofit)

```
/wando:audit
```
majd
```
/wando:init
```

**Mi tortenik:**
1. Az **audit** vegigelemzi a projektet ANELKUL hogy barmi modositana:
   - Tech stack felismeres (T1-T7)
   - Zona azonositas (Z0-Z7) — hol tart a projekt
   - 17 elemu gap analysis — mi hianzik
   - Quality baseline — tesztek, lint, build allapota
   - Git tortenelem es doksi elemzes
2. Az **init** RETROFIT modban indul — nem ir felul semmit ami mar letezik,
   csak kipotolja a hianyzo infrastrukturat

**Fontos:** Az audit READ-ONLY — soha nem modosit semmit.

---

## 3. Uj phase-t kell terveznem

```
/wando:plan
```

**Mi tortenik:**
1. Repo Knowledge Check — beolvassa a szukseges forrasokat
2. 9-szekcios tervezesi checklist
3. AUTO-DISCOVERY — megkeresi mely skill-ek relevasak ehhez a phase-hez
4. Legeneralja a phase fajlt:
   - Checklist (max 50 item)
   - Checkpoint markerek (`--- CHECKPOINT ---`)
   - Exit Criteria + Verification Commands
   - Golden Answers (input → output parok)
   - Architekturalis Invariansok
5. Te jovahagyod (vagy modositod) → kesz

**Mikor NE:** Ha < 5 item a feladat — csak csinaldd meg, nem kell phase fajl.

---

## 4. Dolgozom egy phase-en es nem akarom elvesziteni a munkam

A **checkpoint** automatikusan mukodik, nem kell hivnod:

| Szint | Mikor | Mit csinal |
|-------|-------|-----------|
| **Level 1: AUTO** | Minden 5. befejezett checklist item | Checklist frissites, `>>> CURRENT <<<` mozgatas |
| **Level 2: SMART** | `--- CHECKPOINT ---` marker-nel vagy context 50%-nal | Level 1 + Progress Log + CONTEXT_CHAIN frissites |
| **Level 3: EMERGENCY** | Context window 80%-nal | MINDEN mentes + debug context + uncommitted fajlok lista |

**Ha uj session-t kezdesz:** Kovetkezd a Resumption Protocol-t a `START_HERE.md`-ben.
Az agent automatikusan folytatja ahol abbahagyta.

---

## 5. Befejeztem egy phase-t

```
/wando:close
```

**Mi tortenik:**
1. **Pre-Submission Checklist** (8 pont) — nincs TODO, tesztek PASS, stb.
2. **Exit Criteria** ellenorzes — a phase fajlban definialt kriteriumok
3. **Severity assessment:**
   - **S1 MINOR** — auto-fix, folytatodik
   - **S2 MODERATE** — TE dontesz: elfogadod vagy javitod
   - **S3 MAJOR** — FAILED, Phase Memory KOTELEZO, javitas kell
   - **S4 CATASTROPHIC** — rollback, ujrakezdés
4. **Phase Memory** — MINDIG irododik, FOLEG ha FAIL (a kudarc tanulsagai a legertekesebbek)
5. Meta fajlok frissitese: QUALITY_SCORE, TECH_DEBT, GOLDEN_PRINCIPLES, START_HERE, CONTEXT_CHAIN
6. Phase fajl athelyezese: `plans/` → `completed/` (vagy `failed/`)

---

## 6. Ellenorizni akarom a munka minoseget

```
/wando:review
```

**Ket mod:**

| Mod | Mikor | Mit csinal |
|-----|-------|-----------|
| **NORMAL** | Checkpoint-oknal, gyors ellenorzes | Valtozasok attekintese, invariansok, tesztek |
| **THOROUGH** | Phase vegeken (close hivja) | Teljes 9-lepes review: checklist, invariansok, tesztek, lint, Golden Answers, Quality Score, severity |

**Quality Score formula:** `score = 100 - (20 × FAIL) - (10 × CONCERN)`

---

## 7. Tobb agent-tel akarok parhuzamosan dolgozni

```
/wando:dispatch
```

**Elofeltetel:** A phase fajlnak tartalmaznia kell egy `Parallel Work Plan` szekciót
(ezt a `/wando:plan` generalja ha a phase alkalmas ra).

**Mi tortenik:**
1. Ellenorzi a precondition-oket (>20 item, fuggetlen szekciok, git clean)
2. Worktree-ket hoz letre worker-enkent (`git worktree add`)
3. Kiosztja a feladatokat (scope, fajlok, exit criteria, FORBIDDEN lista)
4. Worker-ek parhuzamosan dolgoznak izolaltan
5. Merge sorrend vegrehajtasa (a tervben megadott sorrendben)
6. Post-merge TELJES teszt suite (KOTELEZO)
7. Worktree cleanup

**Szabalyok:**
- Phase fajl = CSAK a Leader irja
- Kozos fajlok (barrel exports, config) = CSAK a Leader nyul hozzajuk
- Worker-ek NEM latjak egymas fajljait

**Mikor NE:** Phase < 20 item, erosen osszefuggo szekciok, ismeretlen domain.

---

## 8. A dokumentaciom elavult, rendet akarok rakni

```
/wando:gc
```

**Mi tortenik (6-lepes GC Report):**
1. **Doc freshness** — mely docsik elavultak a kodjukhoz kepest
2. **Cross-link** — torott hivatkozasok keresese
3. **TECH_DEBT review** — lejart vagy egyszeru debt item-ek
4. **QUALITY_SCORE** — ujraszamitas a jelenlegi allapot alapjan
5. **Cleanup javaslatok** — arva fajlok, ures fajlok, nem mozgatott phase-ek
6. **Skill registry** — telepitett vs. regisztralt skill-ek konzisztenciaja

**Fontos:** A GC SOHA NEM TOROL AUTOMATIKUSAN — csak javasol. Te dontesz.

---

## 9. Uj session-t kezdek es nem tudom hol tartok

Kovetkezd a **Resumption Protocol**-t:

```
1. Olvasd: START_HERE.md          → phase tracker, melyik phase aktiv
2. Olvasd: CONTEXT_CHAIN.md       → utolso bejegyzes, mi tortent legutobb
3. Olvasd: aktiv phase fajl       → keresd a >>> CURRENT <<< markert
4. git status + git log            → van-e befejezetlen munka
5. Futtasd a teszteket            → minden PASS?
6. Folytasd a kovetkezo [ ] item-mel
```

**Idoigenye:** ~2 perc, es az agent pontosan tudja hol tartunk.

---

## 10. Forras anyagot (spec, API doc) szeretnek feldolgozni

```
/wando:extract
```
majd
```
/wando:analyze
```

**Megjegyzes:** Ezek JOVOBENI skill-ek — a pipeline vazat tartalmazzak,
de a reszletes logika meg nem keszult el. A jelenlegi vazak:

- **extract:** 3-retegu pipeline (determinisztikus → AI → deep) → EXTRACT.md
- **analyze:** 4-lepes szintezis (funkcionalis csoportositas, 3-way comparison, korrekciok, mintak) → SYNTHESIS.md

---

## Gyors referenciak

### Skill flow diagram

```
UJ PROJEKT:     /wando:init → /wando:plan → [munka] → /wando:close
RETROFIT:       /wando:audit → /wando:init → /wando:plan → [munka] → /wando:close
PHASE KOZBENI:  [munka] → /wando:checkpoint (auto) → /wando:review → /wando:close
KARBANTARTAS:   /wando:gc (periodikusan)
PARHUZAMOS:     /wando:plan (Parallel Work Plan) → /wando:dispatch
```

### Severity tabla

| Szint | Mi tortenik | Ki dont |
|-------|------------|---------|
| S1 MINOR | Auto-fix, megy tovabb | Agent |
| S2 MODERATE | Dontes szukseges | **Te** |
| S3 MAJOR | FAILED, Phase Memory irododik | Agent (javitas kell) |
| S4 CATASTROPHIC | Rollback | Agent (ujrakezdes) |

### Fontos fajlok

| Fajl | Mire valo | Ki irja |
|------|-----------|---------|
| `START_HERE.md` | Phase tracker + Resumption Protocol | `/wando:init`, `/wando:close` |
| `CONTEXT_CHAIN.md` | Session folytonossag | `/wando:chain` (auto) |
| `QUALITY_SCORE.md` | Minosegi metriak | `/wando:close`, `/wando:gc` |
| `TECH_DEBT.md` | Nyitott technikai adossag | `/wando:close` |
| `GOLDEN_PRINCIPLES.md` | Ami BIZONYITOTTAN mukodik | `/wando:close` |
| `plans/*.md` | Aktiv phase fajlok | `/wando:plan` |
| `completed/*.md` | Befejezett phase-ek (Phase Memory!) | `/wando:close` |
