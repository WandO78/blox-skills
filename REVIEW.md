# blox-skills — független review

> **Dátum:** 2026-07-25
> **Verzió:** blox 2.1.0 (`2f2ed0f`)
> **Terjedelem:** 21 SKILL.md (9 443 sor / 374 KB), 95 fájl design-knowledge, 224 fájl összesen
> **Módszer:** minden SKILL.md végigolvasva + mechanikus ellenőrzések (hivatkozás-validálás,
> névütközés, duplikáció-mérés, token-becslés) + hidegindítás-szimuláció

---

## 0. Rövid ítélet

| Dimenzió | Értékelés | Egy mondatban |
|---|---|---|
| Domain-tudás mélysége (design/brand/media/slides) | **Erős** | Valódi, forrásolt tudásbázisra épül, nem kitalált szabályokra. |
| Egy-egy skill belső logikája | **Jó** | A pipeline-ok végiggondoltak, van hibakezelés és verifikáció. |
| Csomagszintű architektúra | **Gyenge** | Két, egymással versengő stílus, nincs gépi index, nincs réteghatár. |
| Token-hatékonyság | **Gyenge** | ~94k token nyers utasítás; egy autopilot fáziskör ~35–40k. |
| Hidegindítás (üres kontextusú agent) | **Közepes / kockázatos** | A skillek megtalálhatók, de a *feltételezéseik* nem teljesülnek egy idegen repóban. |
| Hordozhatóság (agentic OS) | **Gyenge** | 110 feloldhatatlan relatív útvonal, Claude Code-specifikus hívások, nincs manifest. |
| Konzisztencia (belső ellentmondások) | **Gyenge** | 6 konkrét, egymásnak ellentmondó szabály (lásd 2. fejezet). |

**A lényeg:** ez nem egy „félkész, be kell fejezni" csomag. Ez egy **túlnőtt** csomag.
A probléma nem a hiányzó funkció, hanem hogy a jó részeket elnyomja a ceremónia, és
hogy a csomag valójában **két külön terméket** próbál egyben kezelni: egy opinionated
életciklus-láncot és egy önálló domain-skill-könyvtárat. A javaslatom az egyszerűsítés
és a szétválasztás, nem a kiegészítés.

---

## 1. Ami már most jó — ezt ne bántsd

1. **A vendorolt design-tudás.** `references/design-knowledge/` — 3 forrás (awesome-design-md,
   power-design, ui-ux-pro-max), mindegyik korrekt `ATTRIBUTION.md`-vel, MIT-licenc feltüntetve.
   Ez ritka igényesség, és ez a csomag valódi versenyelőnye. A `search.py` stdlib-only BM25,
   nincs függősége — pont jó.
2. **A `media` és `slides` skillek stílusa.** 83 és 81 sor, minden részlet `references/`-be
   kiszervezve, a SKILL.md csak döntési logika. **Ez a helyes minta** — és véletlenül épp
   ez a két legfrissebb skill. A csomag többi részének ide kell konvergálnia.
3. **A `superpowers`-re való delegálás + slim fallback minta.** `build:145-157`, `fix:88-105`,
   `check:735-755`. „A metodológia a superpowersé, a blox az overlay" — tiszta felelősség-
   megosztás, működő degradációval. Ezt tartsd meg mintaként.
4. **A media költség-invariáns.** „Soha ne futtass fizetős generálást árajánlat és
   explicit igen nélkül" (`media:73`). Ez egy valódi, betartatható safety rule.
5. **Hivatkozás-higiénia.** Végigellenőriztem az összes SKILL.md-ben szereplő fájlhivatkozást:
   **nincs halott link.** Ez sok karbantartott repóról nem mondható el.
6. **A `_internal` koncepció.** A checkpoint/chain/cleanup elrejtése a felhasználó elől helyes
   döntés (`user-invocable: false`).

---

## 2. Konkrét hibák — ezek ma is rontanak a működésen

### H1 — Ügyfélspecifikus tartalom szivárgott egy publikus repóba `[magas]`

`skills/plan/SKILL.md:106-128` egy konkrét ügyfélprojekt döntését tartalmazza példaként:

```
question: "Az ATHOS kapcsolat technikailag hogyan működjön?",
header: "ATHOS",
options: [ ... "Go service közvetlenül az ATHOS SQL Server-en" ... ]
```

Ugyanez a fájl `:423`-ban: `Do NOT ask "jónak tartod?" in text`. A git history szerint volt is
már egy privacy-tisztítási kör emiatt (`06c73b5`). Ez a kettő kimaradt.

**Teendő:** cseréld semleges példára (`references/examples.md`-be), és tegyél a CI-ba egy
grep-alapú ellenőrzést a `docs/`-on túl a `skills/`-re is.

### H2 — A `plannotator` kötelezőként van előírva, miközben opcionális `[magas]`

- `registry/requirements.yaml:11`: „plan/code annotation UI … **(optional)**"
- `skills/plan/SKILL.md:422`: „**MANDATORY:** After saving the phase file, open it in Plannotator"
- `skills/check/SKILL.md:689`: „User review via Plannotator (THOROUGH mode, **MANDATORY**)"
- `skills/ui/SKILL.md:579`: „User review via Plannotator (**MANDATORY**)"

A `plan` ad fallbacket (`:440`). A `check` és az `ui` **nem ad**. Ha a plannotator nincs
telepítve — és a saját registryd szerint ez a normál eset —, akkor a `check` THOROUGH és az
`ui` handoff lépése egy nem létező skillt hív kötelező lépésként. Ez pont az a fajta hard
dependency, amit a csomag minden más helyen gondosan elkerül („inform, don't block").

**Teendő:** vagy mindhárom helyre ugyanaz az `AskUserQuestion` fallback, vagy — jobb —
a jóváhagyás legyen egy egysoros absztrakció (`approve(file)`), aminek egy implementációja
a plannotator.

### H3 — A `scan` egy subagent-promptot tartalmaz, de senki nem forkolja `[magas]`

`skills/scan/SKILL.md:19`:
> „**You are an Explore agent** tasked with auditing the project at: $ARGUMENTS"

és `:611`:
> „Note: **As a forked Explore agent, you cannot invoke other skills.**"

Semmi nem forkolja ezt a skillt subagentbe. Amikor a főagent betölti, azt mondod neki, hogy
ő egy másik ágens, aki nem tudja azt, amit valójában tud. Szerepzavar — és a `$ARGUMENTS`
placeholder sem oldódik fel skill-kontextusban.

**Teendő:** vagy tényleg dispatcheld subagentbe (`Agent(subagent_type: "Explore")`) és akkor
a prompt a hívó oldalon éljen, vagy írd át normál skill-hangnemre.

### H4 — A „read-only" skill ír és commitol `[közepes]`

`skills/scan/SKILL.md:82` **CRITICAL INVARIANT:** „The audit is read-only… writes NOTHING".
`skills/scan/SKILL.md:212-267` Step 2b: fájlokat módosít és `git commit`-ol.
A `:638` failure indicator pedig: „Files were created or modified (VIOLATES read-only invariant!)".

Az invariáns tehát a saját lépését jelöli hibának. A „csak user jóváhagyással" kikötés
(`:252`) enyhíti, de egy invariáns, aminek van kivétele, az nem invariáns — és az agent
pont ezen fog elbizonytalanodni.

**Teendő:** a legacy-migráció kerüljön ki külön skillbe (vagy törlésre, lásd H8), a `scan`
maradjon szigorúan read-only.

### H5 — Az autopilot-átmenet szabálya önmagának mond ellent `[közepes]`

- `skills/idea/SKILL.md:519` INVARIANT 7: „**Autopilot always asks** before phase transitions — user controls the pace"
- `skills/idea/SKILL.md:469`: „Autopilot: `/blox:done` chains directly… **the flow does not stall**"
- `skills/done/SKILL.md:452`: „**Do NOT stop and wait** — the loop continues"

A `done:454` megpróbálja összebékíteni („honor the ask… but proceed automatically"), de egy
üres kontextusú agentnek ez két egymást kizáró utasítás. A gyakorlatban vagy megáll minden
fázisnál (és a felhasználó azt hiszi, elakadt), vagy nem áll meg (és megsérti az invariánst,
amit ugyanez a fájl felsorol failure indicatorként).

**Teendő:** töröld az INVARIANT 7-et, és mondd ki egy helyen: autopilot módban a `done`
láncol, és a felhasználó megszakíthatja. Egy szabály, egy helyen.

### H6 — A Pre-Submission Checklist két különböző hosszúságban létezik `[közepes]`

- `skills/check/SKILL.md:161-171`: **9 pont** (0–8), a 8. a „Test completeness".
- `skills/done/SKILL.md:107-116`: **8 pont** (PSC-0…PSC-7), a test-completeness **hiányzik**.

Miközben a `check:794` failure indicatora explicit: „New source files without corresponding
test files (**PSC #8** FAIL)". A `done` tehát egy olyan PSC-számozásra hivatkozik implicit
módon, ami nála nem létezik.

**Teendő:** a PSC egy helyen éljen (`references/`-ben, mindkét skill hivatkozza).

### H7 — A design-router szerződése sérül `[közepes]`

`skills/design/SKILL.md:44`: „**Do NOT invoke sub-skills directly** — always go through /blox:design".
De: `ui` → `user-invocable: false` ✅, `media` → `user-invocable: **true**`, `slides` → `true`.

Vagyis a három „sub-skill" közül kettő közvetlenül hívható, és a saját description-jük is
így hirdeti magát („Use when the project needs media created…"). Egy üres kontextusú agent
a `media` description alapján közvetlenül fogja hívni — teljes joggal —, kikerülve a
brand-kontextus betöltését, ami a router egyetlen valódi hozzáadott értéke.

**Teendő:** dönts. Vagy a `media`/`slides` is `false` (és a router az egyetlen kapu), vagy —
amit javaslok — **a router megszűnik**, mindhárom skill maga tölti be a brand-kontextust
(2 sor mindegyikben), és a `design` név átkerül az `ui`-ra. A router ma 384 sor és 7 példa
azért, hogy kulcsszavak alapján eldöntsön egy háromfelé ágazást, amit a description-ök
maguktól is megoldanak.

### H8 — Elavult README `[alacsony, de első benyomás]`

- `README.md:44` hirdet egy `/blox:image` skillt, ami **nem létezik** (a `media` váltotta ki, `006e8df`).
- Hiányzik a README-ből: `/blox:ui`, `/blox:media`, `/blox:slides`, `/blox:wiki`.
- A „Curated Plugin Ecosystem" szekció (`README.md:63-73`) a `6b72872` commitban eltávolított
  plugin-ajánló gépezetet írja le.

Ez az első, amit egy külső ember lát. Ma azt üzeni: „nincs karbantartva".

### H9 — Halott legacy-migráció `[alacsony]`

`skills/scan/SKILL.md:212-274` ~60 sor arról, hogyan migrálja a `wando-skills v1/v2`
hivatkozásokat. Ez egy privát elődcsomag, amiből rajtad kívül senkinek nincs projektje.
Publikus repóban ez tiszta zaj, és a `scan` read-only invariánsát is ez töri meg (H4).

---

## 3. Szerkezeti problémák — ez a review lényege

### Sz1 — Token-súly: a csomag saját magát nyomja agyon

| Skill | Sor | ~Token | | Skill | Sor | ~Token |
|---|---:|---:|---|---|---:|---:|
| check | 818 | 8 000 | | scan | 657 | 6 400 |
| ui | 705 | 7 400 | | brand | 658 | 6 200 |
| idea | 579 | 5 700 | | secure | 594 | 6 000 |
| deploy | 578 | 5 400 | | done | 556 | 5 400 |
| plan | 508 | 5 400 | | checkpoint | 481 | 4 500 |
| build | 428 | 4 800 | | docs | 411 | 4 200 |
| test | 397 | 4 300 | | wiki | 399 | 4 100 |
| design | 384 | 3 200 | | cleanup | 337 | 2 600 |
| setup | 294 | 3 000 | | fix | 230 | 2 700 |
| chain | 265 | 2 100 | | **media** | **83** | **1 157** |
| | | | | **slides** | **81** | **1 008** |

**Összesen ~94 000 token nyers utasítás.** Egy tipikus autopilot fáziskör
(`idea → plan → setup → brand → design → ui → build → checkpoint → check → done → chain → cleanup`)
**~50 000 token utasítást tölt be**, mielőtt egyetlen sor kód megszületne. Ez nem elméleti
probléma: ez az az ok, amiért a saját `checkpoint` skilled 50%-os és 80%-os
kontextus-küszöböket kezel — a csomag azt a problémát menedzseli, amit maga okoz.

A `media` (1 157 token) és a `check` (8 000 token) között **7-szeres** a különbség, miközben
a `media` legalább annyi valódi képességet fed le.

### Sz2 — Ceremónia-adó: ~1 500–2 000 sor tiszta ismétlés

Minden skillben, 21-szer:

| Blokk | Előfordulás | Becsült összsor |
|---|---:|---:|
| `## Language Protocol` (szinte szó szerint azonos) | 21 | ~210 |
| `## AUTO-DISCOVERY` (22–33 sor/skill) | 21 | ~520 |
| `## Context Discovery` (azonos 1 mondat) | 20 | ~60 |
| `## WHEN TO USE` + `## WHEN NOT TO USE` táblák | 19 | ~350 |
| `## VERIFICATION` (success + failure indicators) | 19 | ~400 |
| „No AI attribution / Co-Authored-By" ismétlés | 23 hely | ~50 |

A `WHEN NOT TO USE` táblák ráadásul ugyanazt az információt kódolják, amit a `description`
mező is — csak drágábban, mert a body minden betöltéskor teljes egészében beolvasódik,
míg a description eleve az indexben van.

**Ez az egyetlen legnagyobb, kockázatmentes nyereség: ~35–40% token-megtakarítás nulla
képességvesztéssel.**

### Sz3 — Az `AUTO-DISCOVERY` blokk rossz helyen van

21 skill body-jában ott ül egy strukturált metaadat-blokk (`name`, `category`, `complements`,
`trigger_keywords`, `trigger_files`, `when_to_use`, `auto_invoke`, `priority`). Két gond:

1. **Egyetlen fogyasztója van**: `plan` Step 4. Mégis minden skill minden betöltésekor
   fizetsz érte.
2. **Duplikálja a frontmattert**: a `name` és a `when_to_use` ugyanaz, amit a `description`
   és a `user-invocable` már elmond — csak most már két helyen kell karbantartani, és
   máris el is csúsztak egymástól.

Ráadásul a `plan` Step 4 utasítása (`plan:245-250`) így szól:

```
1. SCAN: Read ALL installed skills' SKILL.md files
   - Plugin skills: ~/.claude/plugins/*/skills/*/SKILL.md
   - blox-skills: [blox-skills install dir]/skills/*/SKILL.md
```

Vagyis **minden tervezéskor be akarja olvastatni az összes telepített skillt** — csak a blox
maga 374 KB. Ez korlátlan, kiszámíthatatlan költség, és a `[blox-skills install dir]`
placeholder gépileg feloldhatatlan.

**Teendő:** az `AUTO-DISCOVERY` blokkok helyett **egy generált `registry/skills.json`**
(build-time script a frontmatterből + egy rövid `triggers` mezőből). A `plan` ezt az egy
fájlt olvassa (~3 KB), nem 21-et. A blokkok kikerülnek a body-ból.

### Sz4 — `check` ↔ `done`: dupla motor

Szó szerinti duplikáció:

| Tartalom | `check` | `done` |
|---|---|---|
| Quality Score képlet | `:489-497` | `:162-169` |
| Score ranges tábla | `:511-517` | `:171-177` |
| Severity mapping tábla | `:519-526` | `:179-186` |
| S1–S4 szemantika | `:554-584` | `:188-247` |

~150 sor kétszer. És funkcionálisan is dupla munka: a `done` lefuttatja a PSC-t (Step 1),
az Exit Criteriát (Step 2), majd **meghívja a `check`-et THOROUGH módban (Step 4)**, ami
újra lefuttatja a PSC-t (Step 2), az Exit Criteriát (Step 4) és a severity assessmentet
(Step 8) — hogy aztán a `done` a Step 3-ban megint severity-t számoljon.

**Teendő:** a Quality Score + severity **egy** helyen (`references/quality-model.md`).
A `done` ne futtasson PSC-t és EC-t: hívja a `check`-et, és fogadja az eredményét. A `done`
felelőssége a *lifecycle* (Phase Memory, fájlmozgatás, tracker, következő fázis) — ennyi.

### Sz5 — Két stílus egy csomagban

| „Régi" stílus | „Új" stílus |
|---|---|
| check 818, ui 705, brand 658, scan 657, idea 579 | media 83, slides 81 |
| Minden a SKILL.md-ben, példák később kiszervezve | Csak döntési logika; minden a `references/`-ben |
| 5-9 lépéses számozott pipeline, teljes output-sablonokkal inline | Számozott lépések, sablonok kívül |
| WHEN TO USE / NOT TO USE / VERIFICATION / ERROR HANDLING táblák | Csak `INVARIANTS` + `REFERENCES` |

A commit-history mutatja, hogy tudatosan indult el a progressive disclosure
(`aff4e9d`, `d0a4e12`, `629026a`) — de félúton megállt: a *példák* kikerültek, a *ceremónia*
bent maradt. A `build` például 428 soros úgy, hogy a tényleges metodológiát a superpowersre
delegálja; a maradék nagyrészt tábla és checklist.

**Cél:** minden SKILL.md **100–200 sor**. A `check` és az `ui` ma 4–7×-e ennek.

### Sz6 — Három forrás ugyanarra az igazságra

A projekt-scaffold definíciója három helyen:

1. `skills/idea/SKILL.md:22-32` — inline lista a fájlokról
2. `skills/idea/references/scaffold-templates.md` — per-file content spec
3. `references/templates/project-scaffold.md` — „source of truth"

És a `skills/idea/SKILL.md` maga is ellentmond magának:
- `:315` → „Generate the project structure using `references/templates/project-scaffold.md` as the **source of truth**"
- `:318` → „Follow the per-file content spec … in `references/scaffold-templates.md`"

Hasonlóan: az a11y-tudás négy helyen (ui Step 4 checklist, check Step 5b, brand WCAG-szabályok,
`power-design/qa-checklist.md`).

### Sz7 — Névtér-inkonzisztencia

Mind a 21 skillnél: könyvtárnév `idea`, frontmatter `name: blox-idea`, dokumentált hívás
`/blox:idea`. A harness a **könyvtárnevet** használja (ellenőrizve: a `session-start-hook`
skill neve `startup-hook-skill`, mégis `session-start-hook`-ként hívható), tehát **működik** —
de a `name:` mező így félrevezető metaadat. Fontosabb: a `plan` AUTO-DISCOVERY-scanje épp
ezt a `name:` mezőt parse-olja, tehát a generált Skills & Tools táblába `blox-idea` kerül,
miközben az agentnek `/blox:idea`-t kell írnia.

### Sz8 — Ellenőrizendő: a `skills/_internal/` beágyazott könyvtár

A `checkpoint`, `chain`, `cleanup` a `skills/_internal/<név>/SKILL.md` útvonalon él, tehát
**két szinttel** a `skills/` alatt. Minden referencia-implementáció, amit láttam, lapos
(`skills/<név>/SKILL.md`). Ha a plugin-loader nem rekurzív, ez a három skill soha nem
regisztrálódik — és a rendszer mégis „működni látszik", mert a `build:205` és a `done:401`
fájlútvonalon hivatkozik rájuk (az agent egyszerűen beolvassa őket).

**Ezt mérd meg**, ne feltételezd: telepítsd a plugint és nézd meg, megjelenik-e
`blox:checkpoint` (vagy `blox:blox-internal-checkpoint`) a skill-listában. Ha nem:
laposítsd őket `skills/_checkpoint/` stílusra, vagy tedd hivatalossá a „fájlként olvasandó
protokoll" megközelítést (ami hordozhatóbb is — lásd 5. fejezet).

---

## 4. Hidegindítás-teszt — „mit tud kezdeni ezzel egy üres kontextusú agent?"

Ez volt a fő kérdésed. Szimuláltam.

### 4.1 Amit az agent ténylegesen lát induláskor

Semmit a 94 000 tokenből. **Csak a 21 `description` mezőt** (~4 200 karakter összesen).
Minden más csak akkor töltődik be, ha az agent már döntött. A csomag minősége hidegindításkor
tehát **kizárólag a description-ökön múlik**.

### 4.2 A description-ök minősítése

| Skill | Karakter | Minősítés | Indoklás |
|---|---:|---|---|
| media | 307 | **Jó** | Konkrét képességek + „Use when…" trigger + a korlát (költség) is benne van. |
| wiki | 272 | **Jó** | Felsorolja a trigger-szavakat, amikre valóban reagálni kell. |
| design | 265 | **Jó** | Kimondja, hogy router, és hogy hova irányít. |
| check | 258 | **Jó** | Konkrét kimenet (S1–S4, Quality Score) + mikor futtasd. |
| ui | 228 | **Speciális** | Helyesen mondja, hogy ne hívd közvetlenül — de akkor helyet foglal az indexben. |
| slides | 227 | Jó | |
| scan | 211 | Jó | |
| plan | 207 | Jó | |
| done | 194 | Közepes | „Complete a phase" — feltételezi, hogy az agent tudja, mi az a blox-fázis. |
| brand | 182 | Közepes | A „premium with Brand Voice plugin" felesleges az indexben. |
| secure | 181 | Közepes | Ugyanaz a premium-zaj. |
| setup | 181 | Közepes | „Slim doctor" — belső zsargon. |
| build | 160 | Közepes | |
| fix | 158 | Közepes | |
| test | 156 | Közepes | |
| **idea** | **152** | **Gyenge** | „Start here. Describe what you want to build and blox guides you through everything" — **ez marketingszöveg, nem trigger-feltétel.** Nincs benne, hogy *mikor* válaszd, és mikor NE. Ez a csomag belépőpontja. |
| docs | 146 | Közepes | |
| **deploy** | **120** | **Gyenge** | A legrövidebb. „Deploy to production — multi-platform support." Nincs benne, mikor NE (pl. amikor csak build kell). |

**Diagnózis:** a description-ök nagyjából fele „mit csinál" típusú, nem „mikor válaszd"
típusú. A csomag legfontosabb skilljének (`idea`) van a legrosszabb triggerje. Ez fordított
prioritás.

### 4.3 A valódi hidegindítási probléma: a feltételezések

Ez súlyosabb, mint a description-ök. A skillek egy **konkrét projekt-alakzatot** tételeznek fel:

`START_HERE.md`, `CONTEXT_CHAIN.md`, `GOLDEN_PRINCIPLES.md`, `QUALITY_SCORE.md`,
`TECH_DEBT.md`, `plans/`, `completed/`, `failed/`, `>>> CURRENT <<<` markerek, fázisfájlok.

Ezeket **kizárólag a `/blox:idea` hozza létre.** Ha egy agent egy tetszőleges meglévő repóban
indul (ami az agentic OS normál esete):

- `build` Step 1a → „No START_HERE.md → **STOP**: Run /blox:idea first." (`build:101`)
  Vagyis a fő kódolóskill **megtagadja a munkát** minden nem-blox repóban.
- `check` Input Requirements → 4-ből 3 fájl hiányzik → mind CONCERN → a Quality Score
  már induláskor romlik olyasmiért, aminek semmi köze a kódhoz.
- `done` → nincs fázisfájl, nincs Exit Criteria → az egész pipeline üresbe fut.
- `plan` Step 1 (Repo Knowledge Check) → mind az 5 fájl hiányzik → „note it and continue",
  de az utána következő 8 lépés ezekre épül.

Így a csomag valójában **egy zárt rendszer**: teljes értékűen csak olyan projekten működik,
amit ő maga hozott létre. A `scan` retrofit-módja próbál hidat verni, de a `scan` maga
read-only, tehát a hiányzó meta-fájlokat nem pótolja.

**Ez a legfontosabb stratégiai kérdés a csomagban**, és a 6. fejezetben erre adok javaslatot.

### 4.4 Nincs belépő dokumentum az agentnek

Nincs `AGENTS.md`, nincs `SKILLS_INDEX.md`, nincs `registry/skills.json`. A README emberi
olvasónak szól, és elavult (H8). Egy agentnek, aki azt kérdezi „mit tud ez a csomag?",
nincs egy fájl, amit beolvashat. Ma 21 fájlt kellene beolvasnia, 374 KB-ot.

---

## 5. Hordozhatóság a saját agentic OS-edbe

Ezt jelölted meg célnak, ezért külön nézem.

### P1 — 110 feloldhatatlan útvonal `[blokkoló]`

A skillek `` `references/patterns/knowledge-patterns.md` `` stílusban hivatkoznak, **relatívan**,
110 helyen. A `${CLAUDE_PLUGIN_ROOT}` prefixet **mindössze 4 skill használja** (brand, media,
slides, ui — összesen 14 előfordulás).

Egy agent, akinek a CWD-je a felhasználó projektje (a normál eset), a `references/patterns/…`
útvonalat **a felhasználó repójában** fogja keresni, és nem találja. A négy „új" skill ezt
helyesen csinálja, a többi 17 nem.

**Teendő:** vagy mindenhol `${BLOX_ROOT}` (a `CLAUDE_PLUGIN_ROOT`-ról aliasolva), vagy —
hordozhatóbban — a hivatkozások a csomag gyökeréhez képest legyenek megadva, és a belépő
dokumentum mondja meg egyszer, mi a gyökér.

### P2 — Claude Code-specifikus feltételezések

| Hely | Feltételezés |
|---|---|
| `setup/scripts/doctor.sh:10` | `$HOME/.claude/plugins/cache/*/<név>` |
| `scan:361-363` | ugyanaz |
| `scan:272` | `~/.claude/skills/wando-*` |
| `plan:248` | `~/.claude/plugins/*/skills/*/SKILL.md` |
| `design:273` és 6 további | `Skill("blox:ui")` — Claude Code tool-szintaxis |
| `plan:429`, `check:693`, `ui:582` | `Skill("plannotator:plannotator-annotate", args: …)` |
| mindenhol | `AskUserQuestion` tool néven hivatkozva |

Ezek egy másik harness alatt mind némán elbuknak (nincs ilyen tool → az agent improvizál).

**Teendő:** vezess be egy vékony **capability-absztrakciót** a csomag szintjén — pl.
`references/capabilities.md`, ami leírja: „user-döntés kérése", „skill hívása",
„fájl vizuális jóváhagyása", „companion jelenlétének ellenőrzése" — és a skillek ezekre
hivatkozzanak, ne konkrét tool-nevekre. A Claude Code-mapping egy fájlban éljen.

### P3 — Nincs gépi manifest

`plugin.json` csak a plugin-metaadatot tartalmazza (név, verzió, keywords). Nincs benne
a skill-lista, a köztük lévő élek (`complements`, chain), a companion-függőségek strukturáltan.
A `registry/requirements.yaml` jó kezdet, de csak a prerekvizitumokat fedi.

**Teendő:** `registry/skills.json` (generált) + `registry/graph.json` (ki hívhat kit).
Ez egyben megoldja Sz3-at és 4.4-et is.

---

## 6. Stratégiai irány — mit javaslok

### 6.1 A központi döntés: szét kell szedni

Ma a csomag két, egymással összeférhetetlen dolog egyben:

**A) Az életciklus-lánc** (`idea → plan → build → check → done` + checkpoint/chain/cleanup).
Erősen opinionated, saját fájlformátumot ír elő, csak saját scaffoldon működik jól.

**B) Önálló domain-skillek** (`brand`, `ui`, `media`, `slides`, `wiki`, `secure`, `test`,
`docs`, `deploy`, `scan`). Ezeknek **bármelyik repóban** működniük kellene, blox-fájlok nélkül.

A gond: (B) ma szennyezett (A)-val. A `brand:538` és az `ui:569` `CONTEXT_CHAIN.md`-t
frissít; az `ui:592` a „`/blox:idea` autopilot flow"-ra hivatkozik; a `test`, `secure`,
`deploy` mind fázisfájlokat feltételez. Ettől a domain-skillek nem használhatók önállóan —
pedig épp ezek a csomag legértékesebb részei, és épp ezeket akarnád az agentic OS-be.

**Javaslat — három réteg:**

```
blox-core/          idea, plan, build, check, done, checkpoint, chain, cleanup
                    → az opinionated lánc. Saját formátum, saját meta-fájlok.
                    → aki ezt akarja, ezt telepíti.

blox-domain/        brand, ui, media, slides, wiki, secure, test, docs, deploy, scan, fix
                    → NULLA blox-meta-fájl feltételezés.
                    → ha van CONTEXT_CHAIN.md, ír bele; ha nincs, nem érdekli.
                    → bármelyik repóban, bármelyik agenttel működik.

blox-knowledge/     references/design-knowledge/ (+ patterns, templates)
                    → tiszta adatcsomag, nincs benne utasítás.
                    → a domain-skillek adatforrása.
```

A szétválasztás nem feltétlenül külön repót jelent (lehet egy repó, három plugin-manifest),
de a **függőségi irány** legyen szigorú: `core → domain → knowledge`, soha visszafelé.

### 6.2 Egyszerűsítés vs. kiegészítés — az én ítéletem

**Egyszerűsíts. Ne egészítsd ki.** A csomagban nincs érdemi funkcionális hiány; a probléma
a jel/zaj arány. Konkrétan:

| Amit vágj | Miért | Becsült nyereség |
|---|---|---|
| `AUTO-DISCOVERY` blokkok → generált `skills.json` | egyetlen fogyasztó, 21× fizeted | ~520 sor |
| `WHEN TO USE` / `WHEN NOT TO USE` táblák | a `description` már ezt kódolja, olcsóbban | ~350 sor |
| `VERIFICATION` success/failure listák → 3-5 soros `INVARIANTS` | a hosszú listák nem javítják a megfelelést, csak hígítanak | ~300 sor |
| `Language Protocol` 21× → 1× a belépő dokumentumban | | ~190 sor |
| `check`/`done` Quality Score duplikáció → `references/quality-model.md` | | ~150 sor |
| `design` router megszüntetése (H7) | 384 sor egy háromfelé ágazásért | ~380 sor |
| `scan` legacy wando-migráció (H9) | halott kód publikus repóban | ~60 sor |
| **Összesen** | | **~1 950 sor ≈ 20 000 token ≈ a csomag 21%-a** |

Ehhez jön a `check` (818) és az `ui` (705) érdemi újraírása a `media`-stílusban — ez további
~800 sort visz. **Reális célszám: 9 443 → ~5 000 sor, azonos képességgel.**

| Amit viszont tegyél hozzá | Miért |
|---|---|
| `registry/skills.json` (generált) | ez oldja meg a hidegindítást, a `plan` scanjét és a manifest hiányát egyszerre |
| `AGENTS.md` / belépő dokumentum | egy fájl, amit egy idegen agent beolvashat és megérti a csomagot |
| `references/quality-model.md` | egy igazság a Quality Score-ról |
| `references/capabilities.md` | harness-absztrakció a hordozhatósághoz |
| CI-ellenőrzés (link-validálás, privacy-grep, description-hossz, SKILL.md sorlimit) | ez tartja meg a rendet |
| Standalone-mód a domain-skilleknek | ez teszi az agentic OS-ben használhatóvá |

### 6.3 A „zárt rendszer" probléma feloldása

A 4.3-ban leírt gond (a csomag csak saját scaffoldon működik) két úton oldható:

**(a) Fogadd el és mondd ki.** A `core` lánc *nyíltan* blox-projektekre való; a `build`
STOP-ja korrekt viselkedés. Ehhez viszont a domain-skilleket teljesen le kell választani (6.1).

**(b) Fokozatos degradáció mindenhol.** Minden skill működjön meta-fájlok nélkül is,
csak kevesebbet nyújtson. Ez ma részben megvan („note it and continue"), de nem
következetes — a `build` STOP-ja épp az ellenkezője.

**Javaslatom: (a) a core-ra, (b) a domainre.** Így a lánc megőrzi a szigorát (ami a valódi
értéke), a domain-skillek pedig univerzálisan használhatók lesznek.

---

## 7. Javasolt sorrend

### Kör 1 — higiénia (fél nap, nulla kockázat)
1. H1: ATHOS/ügyfél-példa kivágása `plan/SKILL.md`-ből → semleges példa a `references`-be.
2. H8: README szinkronizálása (image törlése, ui/media/slides/wiki felvétele, plugin-szekció).
3. H9: legacy wando-blokk törlése a `scan`-ből.
4. H6: PSC egységesítése (9 pont, egy forrásból).
5. H5: az `idea` INVARIANT 7 törlése, az autopilot-szabály egy helyen.
6. Sz8 ellenőrzése: tényleg betöltődik-e a `_internal/`?

### Kör 2 — a gépi réteg (1-2 nap, ez oldja meg a hidegindítást)
7. Script: `registry/build-index.js` → `registry/skills.json` a frontmatterből.
8. `AUTO-DISCOVERY` blokkok törlése minden SKILL.md-ből; a trigger-adat átköltöztetése az indexbe.
9. `plan` Step 4 átírása: az indexet olvassa, ne 21 fájlt.
10. `AGENTS.md` megírása: mi ez a csomag, mi a gyökér, mi a lánc, mi az önálló.
11. A 10 leggyengébb `description` átírása trigger-központúra (kezdve az `idea` és `deploy` párossal).

### Kör 3 — karcsúsítás (2-3 nap)
12. Boilerplate-vágás mind a 21 skillben (Sz2 táblázat szerint).
13. `check` és `done` szétválasztása + `references/quality-model.md`.
14. `check` (818) és `ui` (705) újraírása `media`-stílusban, cél <250 sor.
15. `design` router megszüntetése vagy 80 sorra vágása (H7 döntés).

### Kör 4 — hordozhatóság (az agentic OS-hez)
16. `${BLOX_ROOT}` bevezetése mind a 110 hivatkozásra.
17. `references/capabilities.md` + a Claude Code-mapping különválasztása.
18. A domain-skillek standalone-módja (nulla blox-meta-fájl feltételezés).
19. Réteg-szétválasztás: `core` / `domain` / `knowledge` manifestek.

### Kör 5 — ami megtartja a rendet
20. CI: link-validálás, privacy-grep (`skills/` is), SKILL.md sorlimit (250), description-hossz
    (120–300), frontmatter-séma, `skills.json` frissessége.

---

## 8. Amit érdemes megkérdezned magadtól

1. **Kinek szól a `core` lánc?** Ha csak neked — akkor legyen privát, és publikusan csak a
   domain + knowledge menjen ki. A publikus csomag ma ~60%-ban a te személyes
   munkafolyamatod (fázisfájlok, Phase Memory, CONTEXT_CHAIN, Quality Score), amit egy
   idegen nem fog átvenni. A domain-skillek viszont bárkinek azonnal értékesek.

2. **A `superpowers`-függés stratégia vagy kényszer?** 47 hivatkozás. Ha a saját agentic
   OS-edben nem lesz superpowers, akkor ma minden érintett skill a „slim fallback" ágon fut —
   ami rendben van, de akkor a fallback a *fő* ág, és úgy is kellene megírni.

3. **A `wiki` skill miért van itt?** Saját maga mondja (`wiki:54-56`): „NOT part of the
   idea→plan→build→done chain — no blox phase or driver invokes it automatically."
   Ez egy önálló Obsidian-eszköz egy szoftverfejlesztési csomagban. Külön skillként jobb helye
   lenne — vagy legalábbis ez a legjobb bizonyíték arra, hogy a csomagnak nincs egyértelmű
   határa.

4. **Mi a siker mértéke?** Ma nincs. Javaslom: „egy üres kontextusú agent, egy idegen repóban,
   egy mondatos kéréssel eljut a helyes skillhez és használható eredményt ad" — és ezt
   mérd is le 10-15 eseten (a `skill-creator` eval-eszközével). Ez a metrika minden fenti
   javaslatnál többet fog mondani.

---

## Függelék — mit ellenőriztem

- Mind a 21 `SKILL.md` teljes elolvasása.
- Minden fájlhivatkozás létezésének gépi validálása (**0 halott link**).
- Frontmatter: `name` vs. könyvtárnév (21/21 eltérés — nem hiba, de inkonzisztens),
  `user-invocable` értékek, `description` hosszak.
- Skill-kereszthivatkozások: 19 különböző `/blox:*` név, 1 nem létező (`/blox:image`, README).
- Duplikációmérés a boilerplate-blokkokra.
- Token-becslés per skill és per tipikus folyamat.
- Privacy-grep (`ATHOS`, `Veolia`, magyar szöveg a skill-logikában).
- Vendorolt tartalom licencelése (3/3 `ATTRIBUTION.md` rendben, MIT).
- Hardcode-olt útvonalak (`~/`, `/Users/`, `~/.claude/`).
- Hidegindítás-szimuláció: mit lát az agent index-szinten, és milyen feltételezések buknak
  el egy nem-blox repóban.

**Amit nem tudtam ellenőrizni** (érdemes megtenned): a plugin tényleges telepítése és a
skill-lista ellenőrzése — ez dönti el az Sz7 (névtér) és Sz8 (`_internal/` beágyazás)
kérdéseket, továbbá hogy a `/blox:idea` vagy a `/blox:blox-idea` a valódi hívási forma.
