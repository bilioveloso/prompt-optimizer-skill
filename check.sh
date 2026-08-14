#!/bin/sh
# Asserts the two things that break silently: the path trigger.md points at,
# and the token numbers in the README table. Both have drifted before.
cd "$(dirname "$0")" || exit 1
fail=0

# 1. trigger.md's pointer must resolve wherever the skill is installed.
target=$(grep -o '~/[^ ]*rubric\.md' trigger.md | head -1)
installed=$(printf '%s' "$target" | sed "s|^~|$HOME|")
if [ -f "$installed" ]; then
  echo "ok    pointer -> $target"
else
  echo "FAIL  pointer -> $target (not installed; copy the folder there)"
  fail=1
fi

# 2. README token claims must match reality within 15%.
for f in trigger.md rubric.md SKILL.md explicit.md; do
  actual=$(( $(wc -c < "$f") / 4 ))
  claimed=$(grep "\`$f\`" README.md | grep -o '~[0-9]*' | tr -d '~')
  [ -z "$claimed" ] && { echo "FAIL  $f: no token claim in README"; fail=1; continue; }
  lo=$(( claimed * 85 / 100 )); hi=$(( claimed * 115 / 100 ))
  if [ "$actual" -ge "$lo" ] && [ "$actual" -le "$hi" ]; then
    echo "ok    $f ~${actual} tok (README: ~${claimed})"
  else
    echo "FAIL  $f ~${actual} tok but README claims ~${claimed}"
    fail=1
  fi
done

# 3. The hook must point at a file that actually exists.
#    This is the one failure nobody notices: `cat` on a missing path prints
#    nothing, the hook contributes nothing, and the skill looks installed while
#    doing absolutely nothing. Check 1 above validates the pointer INSIDE
#    trigger.md; this validates the command that loads trigger.md in the first
#    place. Warn rather than fail — a hookless or non-Claude install is valid.
settings="$HOME/.claude/settings.json"
if [ ! -f "$settings" ]; then
  echo "warn  no ~/.claude/settings.json — skipping hook check"
elif ! grep -q 'UserPromptSubmit' "$settings"; then
  echo "warn  no UserPromptSubmit hook — the skill loads only when the model elects to"
else
  hooked=$(grep -o "[A-Za-z]:[\/][^\"']*trigger\.md\|~/[^\"']*trigger\.md\|/[^\"']*trigger\.md" "$settings" | head -1)
  if [ -z "$hooked" ]; then
    echo "warn  UserPromptSubmit hook found, but no trigger.md path in it"
  else
    resolved=$(printf '%s' "$hooked" | sed "s|^~|$HOME|")
    if [ -f "$resolved" ]; then
      echo "ok    hook -> $hooked"
    else
      echo "FAIL  hook -> $hooked (file missing; the hook is silently doing nothing)"
      fail=1
    fi
  fi
fi

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAILED"
exit $fail
