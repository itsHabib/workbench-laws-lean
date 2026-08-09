# Lean From Zero — a curriculum anchored in my own verified code

**Status:** outline, ready for agents to fill module by module
**Date:** 2026-08-08
**Learner profile:** strong working engineer (Go/Rust/Elixir/TS), zero type
theory, zero Lean. Has a real verified project in this repo
(`WorkbenchLaws/`) built by worker agents — has read the results but cannot
yet read the proofs. End state: can read every file in `WorkbenchLaws/`,
modify a proof, and formalize a new small kernel (the gate grant lifecycle)
without help.

## How agents fill this out

One module = one worker session. For module N, produce:

- `docs/learn/modules/NN-<slug>/lesson.md` — the prose lesson.
- `docs/learn/modules/NN-<slug>/Exercises.lean` — runnable exercises with
  `sorry` holes for the learner, plus `Solutions.lean`.
- Wire `Solutions.lean` into the lake build (a `Learn` lib target is fine);
  **`lake build` must stay green** — that is the done-check for every module.

Rules for the filling agent:

1. **Anchor in this repo and in workbench.** Every concept must be shown
   first in the learner's own code (cite `file:line`), THEN generalized.
   Never lead with `Nat` or fizzbuzz when `composedDecision` exists.
2. **Compile every claim.** Any Lean snippet in lesson.md must exist in
   `Exercises.lean`/`Solutions.lean` and build. No pseudo-Lean.
3. **Programmer's vocabulary first.** Introduce each type-theory term as the
   programming concept it corresponds to (∀ = generics; evidence = an
   argument you pass; tactic = code that writes code), then name it formally
   once. A glossary line per new term at the bottom of the lesson.
4. **No Mathlib.** Core/std only, matching the project's own constraint.
5. **Exercises are graded**: 2-3 trivial (fill one tactic), 1-2 real (prove a
   small new lemma), 1 stretch (marked optional). Solutions must not use
   tactics the module hasn't introduced.
6. **Honesty threads through**: every module that proves something must also
   state what the proof does NOT establish (the model/implementation gap is
   module 8, but the caveat appears wherever relevant).
7. Keep each lesson readable in ~20-30 minutes; exercises another 30-60.

Fill order: modules build strictly; do them in order. Mark each row in the
tracker table below when done.

## Tracker

| # | Module | Status |
|---|--------|--------|
| 0 | Orientation: what got built and why | todo |
| 1 | Lean is a programming language | todo |
| 2 | Types as propositions, proofs as programs | todo |
| 3 | Equality, computation, and `rfl` | todo |
| 4 | First proofs: `simp`, `cases`, evidence | todo |
| 5 | Induction: the move tests cannot make | todo |
| 6 | Tactics, the kernel, and why to believe any of this | todo |
| 7 | Case study: the failed proof was the bug report | todo |
| 8 | The model/implementation gap and conformance | todo |
| 9 | The tool ladder: tests, model checkers, SMT, proofs | todo |
| 10 | Capstone: formalize the grant lifecycle | todo |

---

## Module 0 — Orientation: what got built and why

**Goal:** the learner can give the 5-minute tour of this repo to someone
else, without understanding any proof yet.

Cover: what gate's `verify.Reduce` does in Go and why it matters (merge
authorization; ladder law); what the Lean project is (a hand-ported pure
model + machine-checked laws about it); the two real findings (raw-tier
rank-tie order dependence; `TierWithin` unknown-candidate) and where they
came from; the file map (`Raw → Domain → Validate → Reduce → Laws →
Examples → NegativeControls → TierWithin`); how to run `lake build` and read
its output (including the `#print axioms` lines). Anchors:
`workbench/cmd/gate/internal/verify/verify.go:102-188`, `docs/report.md`,
`docs/source-map.md`.

**Exercise:** none in Lean. The learner writes a 10-line summary of what is
and is not proved, checked against `docs/report.md`'s stop decision.

## Module 1 — Lean is a programming language

**Goal:** demystify: before any logic, Lean is a typed functional language
the learner can already mostly read.

Cover: `def`, `inductive` (sum types — map to Gleam custom types / Rust
enums, which the learner knows), structures, pattern matching, `List`
operations, `Option`/`Except` (map to Go's `(T, error)` and Rust's
`Result`), `#eval` to run code. Walk `Domain.lean` and `Reduce.lean`
top to bottom as *programs*, ignoring every `theorem`: `composedDecision`
is just the Go `Reduce` rewritten pure — show the side-by-side with
`verify.go:109-188` and point at where Go's mutation became a fold
(`composedTier`, Reduce.lean:27-28).

**Exercises:** `#eval reduceValid` on hand-built verdict lists and predict
outputs; write a small pure function (e.g. `countEscalations`) and `#eval`
it; port one tiny Go helper (`knownDecision`, verify.go:77-79) and test it.

## Module 2 — Types as propositions, proofs as programs

**Goal:** the core idea lands: a theorem is a type; proving = constructing a
value; type checking = proof checking (Curry-Howard).

Cover: read `code_block_dominates` (Laws.lean:5-8) as a *function
signature* — takes any `vs`, takes evidence `h : hasCodeBlock vs = true`
(evidence is an ordinary argument with a strange type), returns a value of
type `(reduceValid vs).decision = .block`. ∀ as the ultimate generic; the
difference from a Rapid property (`property_test.go:118-135` samples points;
the theorem quantifies the whole domain — infinite lists, one finite
proof). `→` as both "function" and "implies" — same thing. What a
proposition-as-type means for `∃` (a pair: witness + evidence), shown with
`local_block_is_refused`'s conclusion (Laws.lean:43).

**Exercises:** state (not prove — leave `sorry`) three theorem signatures
about `reduceValid` in correct syntax, including one with `∃`; identify
which of a list of statements are propositions vs definitions.

## Module 3 — Equality, computation, and `rfl`

**Goal:** understand the strangest part — computation happens *inside*
types, and "just run it" is a legal proof.

Cover: definitional equality; `rfl` proves `2 + 2 = 4` and, identically,
`reduceValid [floorPass] = { decision := .pass, tier := "T0" }` — the
checker *evaluates the learner's own reducer* to check the type. Why
`Examples.lean` fixtures are theorems-by-computation and what that gives
over a unit test (nothing at a single point — the leverage comes later;
honesty rule). `decide` for decidable props. When `rfl` fails (open
variables — motivates tactics).

**Exercises:** prove 4-5 fixture equalities about `reduceValid` with `rfl`,
including one translated from a named Go test case in
`verify_test.go:785-798`; break one deliberately and read the error.

## Module 4 — First proofs: `simp`, `cases`, evidence

**Goal:** read and write basic tactic proofs; understand a proof state
(goals + hypotheses) as the thing the infoview shows.

Cover: tactic mode as an interactive game — the infoview (VS Code lean4
extension) shows goal + context at the cursor; `simp [defs, h]` as
"unfold and rewrite until closed" — walk `code_block_dominates`'s one-line
proof and SHOW the intermediate goal states; `cases`/`rcases` on Bool and
on inductive types — walk `missing_floor_never_passes` (Laws.lean:10-14):
case split on `hasCodeBlock`, both branches simp closed; using a hypothesis
as a rewrite. `unfold`, `exact`, `apply`.

**Exercises:** re-prove `judgment_cannot_launder_missing_floor` from scratch
(it is one `exact`); prove `escalation_without_floor_escalates` (new small
lemma, `cases` + `simp`); prove a negated statement (`≠`) to meet
`intro`/`contradiction`.

## Module 5 — Induction: the move tests cannot make

**Goal:** the learner can read `validate_error_of_member`
(Laws.lean:21-36) line by line and explain to a colleague why a finite
argument covers infinitely many inputs.

Cover: structural induction over `List` = the recursion the learner already
writes, reflected into proof; base case (`nil` — membership impossible),
`cons` case, the induction hypothesis as "the theorem, for the tail";
walking the real proof's rcases/branches; contrast with Rapid — sampling
vs constructors-handled-once. Then `foldl` lemmas: how
`tierRank_fold_ge_start` (Laws.lean:75+) generalizes over the accumulator —
the classic strengthen-the-hypothesis move, stated in programmer terms
("prove it for every starting value, not just T0").

**Exercises:** prove `length_nonneg`-style warmups on the learner's own
types; prove `hasFloor (vs ++ ws) = hasFloor vs || hasFloor ws` by
induction; stretch: prove `composedTier` never returns a strictly lower
rank than any member (a weaker restatement of `tier_is_monotone` —
then compare with the real proof, Laws.lean:98-101).

## Module 6 — Tactics, the kernel, and why to believe any of this

**Goal:** the trust story: tactics can be buggy, proofs cannot sneak through.

Cover: elaborator vs kernel — tactics *generate* a proof term; the small
kernel re-checks it; trusting a few thousand lines instead of `simp`.
`#print axioms` on this repo's theorems: most report no axioms; explain
propext/Classical.choice/Quot.sound on the one that uses them
(`docs/evidence/axioms.txt`). What `sorry` is, why the kickoff banned it,
and how to grep for holes. What the negative controls are
(NegativeControls.lean): mutated reducers that still compile + proved
existential counterexamples — mutation testing where the "test" is a
theorem. Why an expected-compile-failure would have been weaker.

**Exercises:** run `#print axioms` on three theorems and explain output;
write one new mutation (e.g. drop the escalation branch) + prove its
counterexample witness following the existing pattern.

## Module 7 — Case study: the failed proof was the bug report

**Goal:** the payoff module. The learner re-derives the project's headline
finding and understands *why formalization found it when Rapid didn't*.

Cover: attempt (guided) to prove raw-tier permutation invariance; get stuck
exactly at `chooseHigherTier`'s strictly-greater comparison
(Reduce.lean:23-24 mirroring verify.go:142-144); realize two spellings at
rank 3 make output order-dependent — the witness `[T3, garbage]` vs
reversed; see why Rapid's generator (valid tiers only,
`property_test.go:41,50`) can never sample it. Then the honest resolution:
`PermutationDomain` (Reduce.lean:53-54) as an explicit named restriction,
invariance proved over *rank* (`permutation_invariant_decision_and_rank`),
and the tie behavior promoted to its own theorem
(`raw_tier_first_max_wins`). Close with the exports: the Go regression and
the `TierWithin` policy question (`TierWithin.lean`, `Reachability.md`) —
proof feeding production.

**Exercises:** state the exact false theorem and exhibit the counterexample
pair by `#eval` and by a small proof; modify `chooseHigherTier` to `≥` and
predict-then-check which theorems break.

## Module 8 — The model/implementation gap and conformance

**Goal:** the learner can articulate the technique's honest limits — the
module that prevents them becoming an evangelist.

Cover: proofs are about the Lean model; Go can drift while every proof
stays green; frozen fixtures = provenance, not conformance
(`docs/source-map.md`, report.md's stop decision); what real conformance
needs (a Gate-owned versioned evaluator + shared vector corpus; declared
finite-class coverage: rank ties, source equality, multi-invalid, judgment
counts); the extraction/generation alternative and its costs. Industry
anchor: AWS Cedar (authorization language, Lean model + differential
testing against production Rust — structurally identical to this repo);
brief seL4/CompCert context for scale.

**Exercise (design, not Lean):** write the one-page design for the
Gate-owned evaluator: JSON vector schema, the projection compared
(refusal class under ordered semantics / decision / tier RANK), where it
runs, what a red diff means. This becomes a real workbench proposal.

## Module 9 — The tool ladder: tests, model checkers, SMT, proofs

**Goal:** judgment — matching the tool to the shape of the question.

Cover the ladder with one worked micro-example each, drawn from the
portfolio: property tests (Rapid — cheap, continuous, sampling; the
first line always); model checking (Quint/TLA+ — exhaustive over finite
state, automatic, best for interleavings; anchor: the rooms gc/snapshot
race from rooms `docs/follow-ups.md`, which is a model-checking problem,
not a Lean problem); SMT-backed verification (Dafny/Verus — annotate code,
solver discharges; middle cost); proof assistants (unbounded universal
claims, manual effort; this repo). Rules of thumb: pure algebraic law →
Lean; concurrency/ordering across processes → model checker; everything →
property tests underneath. When formal anything is NOT worth it.

**Exercise:** classify 8 given portfolio questions (provided in the lesson)
to the right rung with one sentence each; the answer key argues, not just
labels.

## Module 10 — Capstone: formalize the grant lifecycle

**Goal:** unaided transfer. The learner (with an agent pairing, not
leading) formalizes gate's second kernel end to end.

Scope: `capability.go` — `Verify`'s binding/expiry/scope checks
(capability.go:120-138), `TierWithin` (:143-148), `CyclesWithin`
(:153-155). Model raw grant → validated grant; laws to state and prove:
expired-never-authorizes, scope-mismatch-never-authorizes,
invalid-ceiling-authorizes-nothing (already touched in TierWithin.lean —
extend it), cycle-ceiling monotonicity, and at least one law the learner
*discovers* by attempting something false (there is one waiting in the
zero-value/back-compat semantics of `CyclesWithin`). Deliverables mirror
the main project: model, laws, fixtures with source map, negative control,
`#print axioms`, a short report with an honest stop decision.

**Done when:** `lake build` green, no `sorry`, source map complete, and the
learner can answer: "what did this prove, what didn't it, and what would
conformance require?"

---

## After the curriculum

Natural continuations, each its own effort: the blog post / work talk
(drafts keyed to modules 2, 5, 7, 8); the Gate-owned conformance evaluator
(module 8's exercise, promoted); formalizing the Gleam `decide`/`evolve`
(replay determinism, duplicate-reply rejection) as verified kernel #3 —
the trigger, per house doctrine, for extracting shared law-harness infra.
