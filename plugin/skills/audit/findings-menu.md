# Shared: Findings Menu

Used by `/rpm:audit documents` to present scored findings to the user
and wait for a reply. Referenced from `SKILL.md` Phase 2.

## Format

```
## Audit findings — {date} ({N} findings)

1. **{quick phrase}** — {description} ({score})

2. **{quick phrase}** — {description} ({score})

3. **{quick phrase}** — {description} ({score})

Reply: `fix 1 2 4` · `all` · `none` · `<#>?` for details
```

Each option leads with a bolded 2–4 word phrase (no line break after),
then the full finding inline. **Blank line between options.**

## Reply grammar (interpret liberally)

- `fix 1 2 4` / `1 2 4` / `1,2,4` → fix those rows
- `all` / `fix all` → fix every finding
- `none` / `skip all` / `cancel` → skip every finding; log as cancelled
- `<#>?` / `<#>` alone / `tell me about 2` → show full details
  (location, evidence, proposed fix) for that finding, then re-print
  the list and wait for another reply
- natural phrasings like `fix the first two` → map to the obvious action

When in doubt, ask.

## Execute

Once the user confirms a fix set (anything but `none`/`cancel`):

1. For each fix: apply, verify, record result.
2. For each skipped row: record as skipped.
3. Print a compact summary:

   ```
   | # | Result   | Finding |
   |---|----------|---------|
   | 1 | ✅ fixed | ...     |
   | 2 | ⏭ skipped | ...    |
   | 3 | ❌ failed — {reason} | ... |
   ```

Then continue to Phase 4 (log results) in `SKILL.md`.
