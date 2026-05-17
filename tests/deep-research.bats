#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

repo_root() {
  cd "$BATS_TEST_DIRNAME/../.." && pwd
}

@test "deep-research preserves PDFs as binary artifacts" {
  local root
  root=$(repo_root)

  for skill in \
    "$root/plugin/skills/deep-research/SKILL.md" \
    "$root/codex/.codex/skills/deep-research/SKILL.md"
  do
    [ -f "$skill" ]
    run grep -F 'PDFs must be saved as binary `.pdf` files' "$skill"
    [ "$status" -eq 0 ]
    run grep -F 'curl -sL -m 60 -o "$TOPIC/fetched/NN-slug.pdf" "URL"' "$skill"
    [ "$status" -eq 0 ]
    run grep -F 'Do **not** pipe through `head`, paste PDF bytes into markdown' "$skill"
    [ "$status" -eq 0 ]
  done
}
