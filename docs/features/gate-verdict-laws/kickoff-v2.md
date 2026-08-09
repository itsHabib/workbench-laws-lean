# Gate Verdict Laws — Lean POC Kickoff v2 (worker-ready)

**Status:** ready to implement
**Date:** 2026-08-08
**Baseline:** Workbench HEAD `6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1`
**Supersedes:** `kickoff.md` (v1) — read it for full background. This v2 folds
in the required changes from `adversarial-review.md` plus the two independent
channel reviews (`lean-poc-review`: lean-reviewer, claude-lean-reviewer). Both
reviewers' verdict: revise, then proceed. This is the revision.

## Goal

Determine whether Lean 4 can state and mechanically prove laws about Gate's
verdict ladder meaningfully stronger than its example + Rapid property tests —
without the model becoming production authority or a second policy
implementation. Specification archaeology; Go stays behavioral truth; the
project stays outside `/Users/mh/dev/workbench`; nothing consumes Lean output
to permit a merge.

## Model (revised where reviews required)

Two layers, unchanged in spirit: `RawVerdict` (producer/decision/tier/source
as Strings) → `validate` → `ValidVerdict` → `reduce` → `ComposedVerdict`,
with raw strings retained so unknown-input safety is proved, not assumed.

Revisions:

1. **Validation is ordered traversal, not a set predicate.** Go returns the
   FIRST invalid verdict in list order, checking unknown-producer →
   unknown-decision → local-block within each verdict (`verify.go:121-131`).
   Model exactly that; add a multi-invalid fixture proving which refusal wins.
2. **`SourceKind` mapping is one literal, consulted in one place.**
   `enrichment ⇔ source == "ci-classify"` (`verify.go:139`, `ciclassify.go:23`);
   every other source string — typos included — is floor for a code-class
   verdict. Do NOT enumerate known-good floor sources (that proves a stricter
   policy than Go implements). And the mapping is consulted **only** in the
   has-floor predicate: code-block dominance is source-blind
   (`verify.go:148-150` has no source check — an enrichment-source code block
   would dominate). Two fixtures required: arbitrary-source code/pass composes
   as floor; enrichment-source block dominates.
3. **Raw tier is order-dependent at rank ties — model it, don't deny it.**
   `verify.go:142-144` replaces tier only on strictly-greater rank, so the
   first max-rank string wins; every unknown string ranks 3 (`tier.go:12-22`).
   Witness: `[pass/T3, pass/garbage]` vs reversed → same decision, raw tier
   `"T3"` vs `"garbage"`, zero judgments.
4. **Tier includes the empty string.** `Rank("") = 3`; a drifted artifact's
   zero value is an unknown tier. One fixture.
5. Confidence stays excluded from this slice, and stays excluded from the
   conformance projection.

## Headline theorems (revised)

1-6 and 8 as in v1 (verified faithful to Go this session): code-block
dominance, missing-floor-never-passes, local-block refused, unknown
producer/decision refused, tier monotone (over rank, from the T0 seed),
judgment-cannot-launder-missing-floor, unknown-tier-top-rank.

Theorem 7 is replaced by a pair:

- 7a `permutation_invariant_decision_and_rank`: decision and tier **rank** are
  permutation-invariant under the FULL Go-generator domain restrictions,
  enumerated once and by name: **(i) at most one judgment, (ii) no local
  block, (iii) valid tiers only is NOT required for 7a — rank invariance holds
  with unknown tiers — but (iv) no restriction hides it either.** State
  exactly which restrictions each theorem needs; do not import "the property
  test's restriction" by reference (v1 named one of four).
- 7b `raw_tier_first_max_wins`: a proved counterexample theorem exhibiting the
  rank-tie order dependence of the raw tier string. This is genuine leverage:
  the Go permutation generator draws valid tiers only
  (`property_test.go:41,50`), so permutation × unknown-tier has zero existing
  coverage — correct v1's "generates unknown/local-block cases" sentence
  accordingly (unknown producer/decision and local-block ARE generated,
  `property_test.go:175-211`; unknown tier is example-tested only,
  `verify_test.go:785-798`).

Conformance projection: refusal class (under ordered semantics), decision, and
tier **rank**. If raw tier is ever compared instead, the model must reproduce
first-max-wins exactly — decide once, in writing.

## `TierWithin` slice (revised)

Model the comparator: ceiling validated, candidate not
(`capability.go:143-148`); report the full known/unknown × T0-T3 cross-product.
The unknown-under-T3 result is true at the comparator — AND the report must
carry a **reachability row**: current producer paths refuse unknown tiers
before they enter a live run (floor parser `floor.go:25-27`, judgment
validation `judge.go:206-208`, readiness/ci-classify pin T0), so the path
requires a foreign or drifted artifact. Comparator semantics + reachability
analysis, presented together; neither "safe" nor "exploitable" language.

## Phase-0 steps

1. Pin Lean 4 + Lake (nothing on PATH; installation is part of the
   experiment). No Mathlib unless a concrete proof demands it.
2. Types, ordered `validate`, small inspectable `reduce`.
3. Frozen fixtures translated from named Go tests, each with a source-map row
   (Go file:line ↔ fixture ↔ theorem). Include the review-required fixtures:
   multi-invalid, arbitrary-source floor, enrichment-source block, rank-tie
   pair, empty-string tier.
4. Prove the headline theorems; no `sorry`/`admit`/project axioms; record
   `#print axioms` per theorem.
5. `TierWithin` cross-product + reachability table.
6. Negative controls: mutated reducers that still compile (floor check
   removed, local-block acceptance, dominance broken), each with a proved
   existential counterexample witness. Primary build stays green.
7. Machine-readable mapping table: Go rule ↔ Lean def ↔ theorem ↔ fixtures ↔
   excluded assumptions ↔ (new) reachability notes.
8. Stop and review: did Lean expose a real ambiguity (7b and the TierWithin
   row are candidates) or restate Go's tests? "No leverage beyond Rapid" is a
   successful stop result.

## Assurance language (hold this line)

Phase 0 proves laws of the **Lean model**. Frozen fixtures give provenance,
not conformance; nothing here guarantees current or future Gate behavior.
Any later assurance claim requires a Gate-owned versioned evaluation surface
(a Workbench decision, not this POC's) and a declared coverage strategy for
the finite equivalence classes (rank ties, source equality, multi-invalid,
judgment counts) — that requirement attaches to the later slice, not to
Phase 0. Every report splits findings into "universal about the model" vs
"bounded evidence about Go".

## Worker notes

- Layout as v1's "Expected POC shape"; add `Verdict/Reachability.md` (or fold
  into `docs/source-map.md`) for the producer-path survey.
- Faithful model only in this phase: no source allow-lists, no
  multiple-judgment refusal, no unknown-tier refusal, no canonicalized tier
  max. Each of those is a Gate policy proposal — separate, labeled, later.
- Verify all cited Go lines against the baseline HEAD above before relying on
  them; if Workbench has moved, re-verify and update the source map first.
