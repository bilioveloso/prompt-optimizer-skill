# prompt-optimizer-skill

A generic prompt-optimizer skill for Claude Code, Junie CLI, and agentic platforms.

It does not rewrite your prompt with a second model call. It injects a six-slot
rubric — deliverable, scope, anchors, constraints, check, ambiguities — that the
agent fills in silently before acting. Zero added latency, zero extra API calls.

## Install

Clone anywhere, then pick one:

**Always-on (recommended).** Add to `~/.claude/settings.json` — fires on every
prompt, output is injected as context:

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat ~/path/to/prompt-optimizer-skill/rubric.md"
          }
        ]
      }
    ]
  }
}
```

Windows without Git Bash: use `type C:\path\to\prompt-optimizer-skill\rubric.md`.

**On demand.** Symlink or copy the folder into `~/.claude/skills/prompt-optimizer/`
and invoke it with `/prompt-optimizer`, or let the model trigger it on vague prompts.

Both can coexist. The hook covers the implicit path; the skill covers "optimize
this prompt for me" as an explicit request.

## Files

| File | Loaded when | Cost |
|---|---|---|
| `rubric.md` | every prompt, via the hook | ~450 tokens |
| `SKILL.md` | model decides it's relevant | ~200 tokens |
| `explicit.md` | only on "rewrite my prompt" | ~700 tokens |

The split is deliberate. `rubric.md` is on the hot path so it stays terse;
the failure taxonomy and worked examples live in `explicit.md` and cost
nothing until someone actually asks for a rewrite.

## Other platforms

`rubric.md` is plain text with no Claude-specific syntax. Paste it into any
system prompt, Junie's `.junie/guidelines.md`, a Cursor rule, or an OpenAI
`developer` message.

## Design notes

Modeled on the instruction patterns in Anthropic's own system prompts:
conditional triggers over blanket rules, absolute language reserved for hard
constraints, and explicit negative cases so the model knows when *not* to apply
the behavior — which is why the rubric tells the agent to skip itself on short,
already-clear prompts.

The design constraint that shaped everything else: **a prompt optimizer that
can't leave a prompt alone is a downgrade.** Most prompts people actually type
are fine. The value is concentrated in a few failure modes — unresolved
referents, bundled asks, and solutions stated in place of problems — so the
skill targets those and returns everything else untouched.

MIT.
