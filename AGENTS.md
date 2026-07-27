# AGENTS.md

General-purpose workspace. Minimal tokens. Telegraph style.

## Structure

- Custom tools map 1:1 to skill directories.
- Put skill behavior in `skills/<name>/AGENTS.md`.

Pattern:

```text
/name -> skills/name/AGENTS.md
```

Custom tools:

- TBA

## Operating Rules

- If task invokes `/name`, read `skills/name/AGENTS.md` first.
- Keep edits small. Preserve structure unless change is required.
- Prefer explicit repo-root paths in docs.
- Use reversible deletion. Use `trash` instead of permanent delete when practical.

## Conventions

- **Pick last screenshot**. pick the newest PNG in `~/Desktop` or `~/Downloads`; verify it is the right UI, do not trust filename alone.

## Style

- Telegraph style.
- Direct. Concrete. Minimal filler.
- Ask short, specific option questions when uncertain.

## Verification

- Verify every substantial change.
- Check paths, links, structure, internal consistency, and affected outputs.
- If no executable test exists, perform document and layout verification.
- If verification is blocked, state exactly what is missing.

## Critical Thinking

- Fix root cause, not cosmetic symptoms.
- Read more before acting if the situation is unclear.
- Call out conflicts and choose the safer path.
- If unexpected changes appear, assume concurrent work. Do not trample them.
