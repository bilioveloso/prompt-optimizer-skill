---
name: prompt-optimizer
description: Turn a vague or underspecified request into a concrete spec (deliverable, scope, anchors, constraints, check, ambiguities) before acting on it, or rewrite a prompt on request. Use when a prompt is ambiguous, when "it"/"that"/"the thing" has no clear referent, when several asks are bundled into one sentence, or when the user says "optimize this prompt", "make this prompt better", "rewrite this for Claude", "why isn't this prompt working". Runs automatically on every turn if the UserPromptSubmit hook is installed.
---

# Prompt optimizer

## Implicit mode (default)

Apply [rubric.md](rubric.md): fill the six slots silently, then do the work.
The user sees results, not the spec. State assumptions inline, one line each,
only where they change what gets built.

This is the mode the `UserPromptSubmit` hook covers. If the hook is installed,
the rubric is already in context and this file adds nothing — do the work.

## Explicit mode

The user asked about the prompt itself rather than the task. Read
[explicit.md](explicit.md) and follow its output contract: rewritten prompt
only, their voice, roughly their length.

## The one rule both modes share

A prompt that is already clear gets returned untouched and acted on directly.
Optimizing an unambiguous prompt makes it worse. Most short prompts are fine.
