# wando-skills (private)

Private extension of [blox-skills](https://github.com/WandO78/blox-skills) with personal and corporate patterns.

## Structure

This repo mirrors blox-skills with an additional `extensions/` directory:
- `skills/` — identical to blox-skills
- `registry/` — identical to blox-skills
- `references/` — identical to blox-skills
- `extensions/` — **PRIVATE** (Veolia patterns, T1-T7, corporate plugins)

## Sync

On push to main, GitHub Action strips `extensions/` and syncs to the public blox-skills repo.

## Install (personal use)

```
/plugin add WandO78/wando-skills
```

## Skills

Same as [blox-skills](https://github.com/WandO78/blox-skills#skills) plus private extensions.

## License

MIT
