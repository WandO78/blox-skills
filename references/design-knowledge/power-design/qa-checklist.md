# Design QA Checklist (21 points)
# Source: ItsssssJack/power-design SKILL.md "Pre-emit checklist" (MIT)
# Run every UI/slide output through this gate before presenting.

- [ ] **#1** Each slide carries one idea. Max one headline (≤10 words) + one supporting block.
- [ ] **#2** Each slide is glanceable in ≤3 seconds.
- [ ] **#3** Max 7 visual chunks per slide; ideal 3–5. Group with proximity.
- [ ] **#4** Whitespace ≥40% of slide area. Hero slides ≥60%.
- [ ] **#5** 5% safe-zone on every side (≥96px on 1920×1080).
- [ ] **#6** All type sizes derived from one modular ratio (1.25 / 1.333 / 1.414 / 1.5 / 1.618). No ad-hoc.
- [ ] **#7** ≤4 distinct type sizes per slide. ≤6 across the deck.
- [ ] **#8** Body ≥24px, title ≥48px, caption ≥18px.
- [ ] **#9** Line-height 1.4–1.6 for body; 1.05–1.2 for display type.
- [ ] **#10** Line length ≤60 characters (slides shouldn't have paragraphs anyway).
- [ ] **#11** WCAG contrast ≥4.5:1 body, ≥3:1 large; **aim for 7:1 (AAA)** for projector resilience.
- [ ] **#12** 60-30-10 color split. 60% dominant (usually background), 30% secondary, 10% accent.
- [ ] **#13** One accent color per slide. Multiple accents = no accent.
- [ ] **#14** Never encode meaning by hue alone. Pair color with shape, weight, label, or icon.
- [ ] **#15** 8pt grid. All spacing values ∈ {8, 16, 24, 32, 48, 64, 96, 128}. Never 13. Never 27.
- [ ] **#16** Single 12-column grid with 24–32px gutters. All elements snap.
- [ ] **#17** Proximity: related items ≤16px apart, unrelated ≥48px apart.
- [ ] **#18** Data-ink ratio ≥80% on charts. No 3D, no gradients, no chartjunk.
- [ ] **#19** Headlines + key visuals in the top-left band. First 200px vertical = primary attention zone.
- [ ] **#20** Pick one mode per deck and stay in it. Presenter (sparse, ≤15 words/slide) OR document (denser, hierarchical). Never mix.
- [ ] **#21 (default ON)** Brand logo present on every slide unless the user has explicitly opted out. Default placement: small wordmark, bottom-left, ~24px tall, inside the 5% safe-zone. Use the logo from `brand-style.md` (path or inline SVG) — never a placeholder.
