# Eval

Sixteen cases. No harness, no dependencies — paste a prompt into a session and
score the response binary: did the listed failure occur, yes or no.

Half the cases exist to catch **over-firing**. An optimizer that improves vague
prompts but mangles clear ones is a net loss, and over-firing is the failure
mode you will not notice without deliberately testing for it.

## Method

Run each case in a **fresh session** — context bleed between cases is the main
way to get a wrong reading. Score three configurations:

1. **off** — no hook, no skill installed
2. **pointer** — `trigger.md` on the hook (current default)
3. **payload** — `rubric.md` on the hook (always-on, pre-`731be7f` behavior)

`off` vs `pointer` is the question "does this help at all". `pointer` vs
`payload` is "does delegating the vague/clear judgment to the model lose
recall, and is that worth ~90% of the tokens". Both matter; the second is the
one that decides whether the current architecture stays.

## Controls — must NOT fire

Passing means the model just does the work. Any spec-restating, any clarifying
question, any "before I start" preamble is a failure.

| # | Prompt | Failure signature |
|---|---|---|
| C1 | `bump zod to v4 and fix the resulting type errors in src/schemas/` | asks which errors, or restates the request |
| C2 | `fix the typo in README` | treats a two-word task as underspecified |
| C3 | `what does this function do?` (file open) | demands a path it can already see |
| C4 | `run the tests` | asks which tests before looking for a test script |
| C5 | `add a --verbose flag to the CLI, default off` | invents constraints the user never stated |
| C6 | `revert that` | builds a fresh spec instead of inheriting |

C6 is the follow-up case. It has no deliverable, scope, or anchor of its own
and must inherit them from the prior turn.

## Vague — should fire

Passing means the model resolves the gap itself (grep, read, infer) and does
the work, stating at most one assumption. Asking the user to fill the gap is a
failure, not a pass.

| # | Prompt | Pass looks like | Failure signature |
|---|---|---|---|
| V1 | `the login thing is broken, fix it` | locates the auth path, fixes, names a check | asks "which login?" |
| V2 | `make the dashboard faster` | measures before changing | picks an optimization blind |
| V3 | `clean up the api folder` | bounds scope, states what it left alone | refactors broadly |
| V4 | `this is wrong` | resolves "this" from the last turn | asks what "this" refers to |
| V5 | `add tests` | finds the framework in use, covers the recent change | invents a new test setup |

## Compound — every ask served

Failure is serving the first and silently dropping the rest. This is the most
reliably reproducible failure in the set.

| # | Prompt | Failure signature |
|---|---|---|
| K1 | `fix the flaky tests, document the endpoints, and bump the deps` | fewer than 3 addressed, no mention of the rest |
| K2 | `rename the class and update the callers and the docs` | callers updated, docs forgotten |

## Stated solution — problem over fix

Failure is complying with the named fix without checking whether it addresses
the real problem.

| # | Prompt | Pass looks like | Failure signature |
|---|---|---|---|
| S1 | `add a Redis cache to the feed endpoint` | asks what's slow / measures first, then decides | installs Redis |
| S2 | `switch to websockets, polling is laggy` | confirms polling is the bottleneck | rewrites the transport |
| S3 | `add an index on users.email` | checks the query plan | adds the index |

S1–S3 are the only cases where a *correct* response may decline to do the
literal thing asked. If the model measures and the named fix turns out right,
doing it is still a pass — the failure is doing it without checking.

## Scoring

Sixteen cases, three configurations. Record pass/fail per cell; the number that
matters is not the total but the split between the two halves. High vague-side
scores with control failures means the thing is over-firing and should be
reverted, however good the vague-side numbers look.

## Known limitation

These cases were written by the same author as the rubric, which is the weakest
form of eval there is — it tests whether the rubric does what it says, not
whether what it says is right. Cases drawn from real sessions where a prompt
actually misfired are worth more than all sixteen of these. Add them as they
come up.
