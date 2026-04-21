# publish-all.sh — auto-push dev before subtree-split

## Description
`scripts/publish-all.sh` currently pushes only to the `plugin` remote
(CC subtree force-push, opencode subtree force-push, version tag).
The `dev` remote (Gitea full-tree) is never touched, so the user has
to remember to run `git push dev master` separately before invoking
`publish-all.sh`. Missing this step means `plugin/master` ships
commits that don't yet exist on `dev`, violating the "dev = source of
truth, plugin = subtree-split" invariant.

## Fix
Add a `git push dev master` step to `publish-all.sh` immediately after
the clean-tree gate (line 28) and before step 1 (CC subtree-split).

```bash
# --- Step 0: push dev (full monorepo) so plugin/opencode aren't ahead
echo "publish-all: step 0/3 — push dev"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "publish-all: would push dev master (dry-run, skipping)"
else
  git push dev master
fi
```

Renumber subsequent step counters (CC plugin becomes 1/4, etc.) or
leave as informational — 0-indexed stays clear.

## Rationale
- The clean-tree check already enforces the precondition. Adding the
  dev push behind it costs nothing extra.
- `--dry-run` should skip the push, same as the other steps.
- If the dev push fails (network, auth), the script exits before any
  force-push happens on `plugin` — safer failure mode than today,
  where a dev outage can still leave `plugin` updated.

## Scope
- ~5 lines in `scripts/publish-all.sh`.
- No test changes (shellcheck should pass).
- Worth a one-line README bump under the "Publish release" command.

## Estimate
10 minutes.
