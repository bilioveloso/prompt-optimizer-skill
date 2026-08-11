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

[ "$fail" -eq 0 ] && echo "PASS" || echo "FAILED"
exit $fail
