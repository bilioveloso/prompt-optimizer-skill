# Eval

Twenty cases. No harness, no dependencies — paste a prompt into a session and
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

Append `--spec` to any case to make the model print the spec it built before
answering. Without it you are scoring an invisible mechanism: a good answer to a
vague prompt is indistinguishable from the model simply being good, and that
ambiguity is what makes the table below weaker than it looks. With it you can
see whether the rubric fired, what it inferred, and which lines it tagged
[guess]. Score the answer, not the spec — the spec is there to explain a score.

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
| C7 | `great, that makes sense` | treats an acknowledgement as a request |

C6 is the follow-up case. It has no deliverable, scope, or anchor of its own
and must inherit them from the prior turn.

## Stakes — clear, but big enough to deserve a spec

Clarity and blast radius are independent. These prompts are not ambiguous; they
are expensive to get wrong, which is where scope and an acceptance signal earn
their keep.

| # | Prompt | Pass looks like | Failure signature |
|---|---|---|---|
| B1 | `rewrite the auth layer to use sessions instead of JWTs` | bounds what is in and out, names a check | starts editing files with no stated scope |
| B2 | `let's add multi-tenancy` | surfaces the decisions it implies before building | picks one interpretation silently |

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

## False premise — clear, and wrong

The prompt has no ambiguity to resolve; it is simply about something that is not
there. Distinct from the vague cases, and not covered by any of the six slots,
which is why it needed naming.

| # | Prompt | Pass looks like | Failure signature |
|---|---|---|---|
| F1 | `fix the retry logic in src/queue.ts` — there is no retry logic in that file | says the premise does not hold, then proposes where it probably lives | writes retry logic and reports it "fixed" |

F1 is the most expensive failure in the set: every other failure produces
visibly incomplete work, while this one produces work that looks finished.

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

Twenty cases, three configurations. Record pass/fail per cell; the number that
matters is not the total but the split between the two halves. High vague-side
scores with control failures means the thing is over-firing and should be
reverted, however good the vague-side numbers look.

## Run 1 — dogfood, 2026-08-11

Not the synthetic cases above. Scored against the nine real prompts of the
session that built this repo, which is worse evidence in one way (self-scored,
n=1 session, `pointer` config only, hook active from prompt 5 onward) and
better in another: the prompts are real, unrehearsed, and were not written to
be scored.

| # | Prompt (abridged) | Category | Result |
|---|---|---|---|
| 1 | `See my repo? the idea is to make a prompt optimizer using…` | vague | pass — fetched the named sources, built, no clarifying question |
| 2 | `Update my repo with the skill make it great … and make the repo public` | compound ×3 | pass — all three addressed; "public" checked and found already true |
| 3 | `Analize the repos I gave and see how we can take more from them` | vague | pass — resolved "the repos" to specific files, read them |
| 4 | `Install it here and let's test` | control | pass — no spec restated, no question asked |
| 5 | `I'll fix the token later. About the skill is it done?` | follow-up | pass — answered directly, no fresh spec |
| 6 | `But can we optimize prompts and save tokens at the same time?` | question | **fail — scope** |
| 7 | `Just try to make it great and push and commit` | compound ×3 | pass |
| 8 | `Fix gaps commit and push` | vague | pass — audited to find the gaps instead of asking which |
| 9 | `Keep working until you finish it` | follow-up | pass — inherited, did not rebuild |

**8/9, with one instructive failure.** Prompt 6 asked whether something was
possible. The answer was yes; the response also rewrote the architecture,
edited settings.json, and pushed. The analysis was right and the change was
kept, but "can we X?" is a question about feasibility, and answering it by
shipping X is exactly the scope-widening the rubric's calibration block
forbids. The rubric names the failure and did not prevent it.

That is the single most useful line in this table: a rule stated in the
document is not a rule enforced, and the eval that catches it has to include
prompts nobody wrote to be caught by.

Untested: the `off` and `payload` columns. Both need fresh sessions with
different settings.json state, so they cannot be run from inside a session
that already has the hook loaded.

## Known limitation

These cases were written by the same author as the rubric, which is the weakest
form of eval there is — it tests whether the rubric does what it says, not
whether what it says is right. Cases drawn from real sessions where a prompt
actually misfired are worth more than all sixteen of these. Add them as they
come up.
