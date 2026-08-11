# Explicit mode — rewriting a prompt on request

Loaded only when the user asks for the prompt itself ("optimize this prompt",
"rewrite this for Claude", "why isn't this working"). For silent spec-filling
before ordinary work, `rubric.md` is enough — do not load this.

## Output contract

Output the rewritten prompt and nothing else. No preamble, no before/after
table, no bullet list of what you changed. If the user wants the reasoning they
will ask for it.

Two hard limits:

- **Keep their voice.** Same register, same vocabulary. A casual prompt stays
  casual. Do not add "Please" or "You are an expert…" — role preamble does
  nothing for a model that already has a system prompt.
- **Keep their length, roughly.** A rewrite twice as long has failed. You are
  removing ambiguity, not adding ceremony. Most good rewrites are *shorter*
  because vague hedging gets replaced by one concrete noun.

## The seven failures

Scan for these in order. Most prompts have one or two, not seven — fix those
and stop.

1. **Unresolved referent.** "it", "that", "the thing", "this bug" with no
   antecedent. The single highest-value fix: replace with a path, symbol, or
   error string.
2. **Buried deliverable.** "Thoughts on the auth flow?" when they want a patch.
   Ask what artifact ends the task, and name it.
3. **Open scope.** "Clean this up", "make it better" — an invitation to
   refactor the world. Bound it: which files, which behavior stays fixed.
4. **Missing rework constraint.** The thing that gets the answer thrown away:
   language version, framework, a file that must not change, an API that must
   stay compatible. One line each.
5. **No acceptance signal.** Nothing observable distinguishes done from
   plausible. Name the test, the command, the rendered output.
6. **Compound request.** Three asks in one sentence; models reliably serve the
   first and drop the rest. Split into a numbered list — that alone fixes it.
7. **Fake precision.** The prompt dictates a *solution* the user guessed at,
   hiding the *problem*. "Add a Redis cache to the feed endpoint" may mean "the
   feed endpoint takes 4s". Rewrite to lead with the symptom and keep their
   proposed fix as a suggestion, not a mandate. This is the only failure where
   you must not silently obey the original.

## Worked examples

**Referent + acceptance**

> before: the login thing is broken, fix it
> after: Login fails after the session refactor — `POST /api/auth/login`
> returns 500. Find the cause and fix it. Check: `npm test auth` passes and a
> manual login sets the session cookie.

**Fake precision**

> before: rewrite the dashboard queries to use raw SQL instead of the ORM
> after: The dashboard takes ~6s to load; I think the ORM queries are the
> cause but haven't profiled it. Find where the time actually goes and fix the
> biggest contributor. Dropping to raw SQL is fine if that's what it takes.

**Compound + scope**

> before: can you clean up the api folder, also the tests are flaky and we
> should probably document the endpoints
> after: Three separate things, in priority order:
> 1. Fix the flaky tests in `api/` — identify which ones and why.
> 2. Document the public endpoints in `api/routes/` as a README table.
> 3. Leave any broader cleanup for now; tell me what you'd change.

**Already good — leave it**

> before: bump zod to v4 and fix the resulting type errors in src/schemas/
> after: (unchanged — deliverable, scope, anchor, and check are all present)

That last case matters most. A prompt optimizer that cannot return a prompt
untouched will damage every good prompt it sees.
