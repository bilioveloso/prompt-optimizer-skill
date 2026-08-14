---
name: prompt-optimizer
description: Turn a vague or underspecified request into a concrete spec (deliverable, scope, anchors, constraints, check, ambiguities) before acting on it, or rewrite a prompt on request. Use when a prompt is ambiguous, when "it"/"that"/"the thing" has no clear referent, when several asks are bundled into one sentence, when it names a fix instead of the problem underneath it, or when the user says "optimize this prompt", "make this prompt better", "rewrite this for Claude", "why isn't this prompt working". Do NOT use for prompts that are already clear, or for follow-ups like "still broken" or "revert that" — those inherit the previous turn's context and need no spec.
---

# Prompt optimizer

## Implicit mode (default)

Apply [rubric.md](rubric.md): fill the six slots silently, then do the work.
The user sees results, not the spec. State assumptions inline, one line each,
only where they change what gets built.

The hook does not carry the rubric — it carries a 116-token pointer that sends
you here. So `rubric.md` must actually be read when a prompt is unclear; it will
not already be in context.

**Follow-ups are exempt.** "still broken", "revert that", "no, the other one",
"why?" inherit the previous turn's spec and never get a new one. Most prompts in
a working session are follow-ups — building a fresh spec for them discards
context and restarts work already in progress.

## Explicit mode

The user asked about the prompt itself rather than the task. Read
[explicit.md](explicit.md) and follow its output contract: rewritten prompt
only, their voice, roughly their length.

## The one rule both modes share

A prompt that is already clear gets returned untouched and acted on directly.
Optimizing an unambiguous prompt makes it worse. Most short prompts are fine.

## What implicit mode looks like

User: *"the retry logic is wrong, can you sort it out"*

<bad_response>
Before I start, let me clarify a few things: which retry logic are you
referring to, what's the expected backoff behavior, and should I also add
tests? Once I know these I can proceed.
</bad_response>

Three questions, zero work, and the first one is answerable with a grep.

<good_response>
[greps for retry, finds `src/queue/retry.ts`, reads it, finds the backoff
multiplier resets on every attempt]

Fixed in `src/queue/retry.ts:34` — `delay` was reassigned from the base value
each loop, so every retry waited 1s instead of backing off. Now compounds.

Assumed you want exponential backoff since the constant is named
`BACKOFF_FACTOR`; it caps at 30s, say if you want a different ceiling.
</good_response>

The spec was filled — deliverable, anchor, check, one assumption stated in a
line — and none of it was shown. That is the target behavior.
