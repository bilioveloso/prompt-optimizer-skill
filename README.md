# prompt-optimizer-skill

A generic prompt-optimizer skill for Claude Code, Junie CLI, and agentic platforms.

It does not rewrite your prompt with a second model call. A hook puts an
84-token check on every turn; when a prompt is actually unclear, that pulls in a
six-slot rubric — deliverable, scope, anchors, constraints, check, ambiguities —
which the agent fills in silently before acting. Zero added latency, zero extra
API calls, and near-zero cost on the prompts that don't need it.

## Install

Both steps are required. The hook carries a *pointer*, so it does nothing
without the skill files it points at.

**1. Install the files.** Copy or symlink the folder to
`~/.claude/skills/prompt-optimizer/`. This path is not arbitrary —
`trigger.md` refers to it directly. Installing elsewhere means editing the
path inside `trigger.md` to match.

**2. Add the hook** to `~/.claude/settings.json`, so the check fires on every
prompt rather than only when the model happens to think the skill is relevant:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/path/to/prompt-optimizer-skill/trigger.md"
          }
        ]
      }
    ]
  }
}
```

Windows without Git Bash: use `type C:\path\to\prompt-optimizer-skill\trigger.md`.
Shell-agnostic (works under both cmd and bash):
`node -p "require('fs').readFileSync('C:/path/to/trigger.md','utf8')"`

Skipping step 2 still works, just non-deterministically: the skill's
description keeps it available to `/prompt-optimizer` and to the model's own
judgment, but nothing guarantees it gets consulted. The hook is what makes the
check happen every turn.

## Files

| File | Loaded when | Cost |
|---|---|---|
| `trigger.md` | every prompt, via the hook | ~84 tokens |
| `rubric.md` | only when the prompt is actually unclear | ~810 tokens |
| `SKILL.md` | model decides it's relevant | ~580 tokens |
| `explicit.md` | only on "rewrite my prompt" | ~900 tokens |
| `eval.md` | never, by the model — it's for you | — |

## Uninstall

Delete the `UserPromptSubmit` block from `~/.claude/settings.json` and remove
`~/.claude/skills/prompt-optimizer/`. Nothing else is touched. To disable the
always-on path but keep `/prompt-optimizer` on demand, remove the hook only.

## Why the hook is a pointer, not the payload

Hook output is appended per turn and **stays in the transcript**. It is not a
one-time cost — inject 810 tokens on every prompt and a 40-turn session carries
~32k tokens of byte-identical repetition, none of it cached.

So the hot path holds an 84-token pointer, and the rubric loads only when a
prompt actually needs it. Same session: ~3.4k instead of ~32k, a 90% cut, with
the deterministic trigger preserved — the hook still fires every turn, it just
carries a pointer instead of a payload.

The general rule, which applies to any hook you write: `UserPromptSubmit` is for
content that *changes* per turn — git status, changed files, current time.
Static text belongs in the cached prefix (`CLAUDE.md`, system prompt) or behind
an on-demand load. Putting a constant on the per-turn path pays for it once per
turn forever.

## Other platforms

`rubric.md` is plain text with no Claude-specific syntax. Paste it into any
system prompt, Junie's `.junie/guidelines.md`, a Cursor rule, or an OpenAI
`developer` message.

`trigger.md` is the only Claude Code-specific piece — it exists to keep a
per-turn hook cheap. On a platform where the text lives in a cached system
prompt, that problem doesn't exist: skip the trigger and paste `rubric.md`
directly. The token argument for splitting them applies only to per-turn
injection.

## Design notes

Five techniques are borrowed from the way Anthropic writes its own system
prompts and injected reminders. They are the reason this works better than a
"you are an expert prompt engineer" wrapper:

**Evidence tags.** Anthropic's memory system tags stored facts by source so
inferences never harden into stated facts. The same tags — `[said]` / `[found]`
/ `[guess]` — applied to a prompt spec kill the dominant failure mode of prompt
optimizers: quietly promoting your own invention into the user's requirement.
The paired gate is a question the model must answer per line — *did the user say
this, or did I decide it?*

**Written as an injected reminder, not a command.** Anthropic's turn-injected
reminders open by conceding they are probably irrelevant and inviting the model
to ignore them, and they forbid the model from ever referencing the injection.
`trigger.md` runs on literally every prompt, so it does both in 84 tokens, and
`rubric.md` repeats them. Without the never-mention rule you get "Based on your
prompt, I understand you want…" on every turn — which is why that phrase is now
on an explicit forbidden list.

**Specificity matching.** One mention earns consideration, not a mandate — the
same rule that stops a single stated preference becoming a persistent label.

**Recency as tie-breaker.** Current message beats stored context, stated beats
inferred. Ported directly: the user's latest message overrides any spec built
earlier in the conversation.

**Ask-vs-assume calibration.** Answer the ambiguous version first, cap
clarifying questions at one, and never ask what a file could answer.

Beyond those five, the general patterns:
conditional triggers over blanket rules, absolute language reserved for hard
constraints, and explicit negative cases so the model knows when *not* to apply
the behavior — which is why the rubric tells the agent to skip itself on short,
already-clear prompts.

The design constraint that shaped everything else: **a prompt optimizer that
can't leave a prompt alone is a downgrade.** Most prompts people actually type
are fine. The value is concentrated in a few failure modes — unresolved
referents, bundled asks, and solutions stated in place of problems — so the
skill targets those and returns everything else untouched.

That is why `eval.md` spends six of sixteen cases on prompts that must produce
*no* optimizer behavior at all, and why a run that scores well on vague prompts
while failing controls should be treated as a regression.

## Two taxonomies, on purpose

`rubric.md` has six slots; `explicit.md` has seven failures. They are not
duplicates and should not be merged. The slots are **constructive** — what a
complete spec contains, used when building one silently. The failures are
**diagnostic** — what is wrong with a given prompt, used when rewriting one on
request. Five of them correspond; compound and stated-solution appear in the
rubric's calibration block because they are diagnoses without a matching slot.

Change one and check the other.

## Status

Run once, against the nine real prompts of the session that built it: 8/9, with
one scope failure that produced a new calibration rule. See `eval.md`.

That is one self-scored session in one configuration — enough to have caught a
real defect, not enough to support the design notes above, which remain
reasoning from source technique rather than demonstrated results. The `off` and
`payload` columns are unrun.

MIT.
