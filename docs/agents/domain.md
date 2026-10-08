# Domain Docs

## Layout

This is a single-context repo: one `GLOSSARY.md` at the repo root and architecture decisions under `docs/adr/`.

## Before exploring

- Read root `GLOSSARY.md` if it exists.
- If a root `GLOSSARY-MAP.md` exists, follow it to the glossaries relevant to the topic instead.
- Read ADRs under `docs/adr/` that concern the area being explored. If the repo later adopts multiple contexts, also read relevant context-scoped ADRs identified by the map.

If these files do not exist, proceed silently. Create domain documentation lazily through `/domain-modeling` when terms or meaningful architectural decisions are resolved; do not create empty glossary or ADR files upfront.

## Vocabulary

Use the glossary's canonical terms in ticket titles, designs, code, and tests. If a needed concept is missing, reconsider whether it belongs to the domain or note the gap for `/domain-modeling`.

## ADR conflicts

Surface any conflict with an existing ADR, citing the decision and explaining why it may need reopening rather than silently overriding it.
