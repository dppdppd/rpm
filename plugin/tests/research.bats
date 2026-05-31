#!/usr/bin/env bats

load helpers

setup()    { setup_sandbox; }
teardown() { teardown_sandbox; }

repo_root() {
  cd "$BATS_TEST_DIRNAME/../.." && pwd
}

plugin_root() {
  cd "$BATS_TEST_DIRNAME/.." && pwd
}

assert_pdf_guidance() {
  local skill="$1"

  [ -f "$skill" ]
  run grep -F 'PDFs must be saved as binary `.pdf` files' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'curl -sL -m 60 -o "$TOPIC/fetched/NN-slug.pdf" "URL"' "$skill"
  [ "$status" -eq 0 ]
  run grep -F 'Do **not** pipe through `head`, paste PDF bytes into markdown' "$skill"
  [ "$status" -eq 0 ]
}

@test "deep-research preserves PDFs as binary artifacts" {
  local root plugin_skill codex_skill
  root=$(repo_root)
  plugin_skill="$(plugin_root)/skills/deep-research/SKILL.md"
  codex_skill="$root/codex/.codex/skills/deep-research/SKILL.md"

  assert_pdf_guidance "$plugin_skill"

  if [ -f "$codex_skill" ]; then
    assert_pdf_guidance "$codex_skill"
  fi
}
