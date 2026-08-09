# Gate Verdict Laws — Lean POC Kickoff

**Status:** exploration / POC  
**Date:** 2026-08-08
**Review:** `adversarial-review.md` — findings incorporated

## Goal in one line

Determine whether Lean can state and mechanically prove useful laws about
Gate's existing verdict ladder that are meaningfully stronger than its current
example and property tests, without turning the proof model into production
authority or a second policy implementation.

## Framing

This is specification archaeology, not a Gate redesign. The Go reducer remains
the behavioral source of truth. The POC extracts a deliberately small formal
model, proves named laws, and records every assumption needed to connect those
proofs back to the running implementation.

The project stays outside `/Users/mh/dev/workbench`. That honors Workbench's
boundary law: tools share versioned artifacts and vocabulary, never another
tool's decision call stack
(`/Users/mh/dev/workbench/docs/DESIGN.md:43-72`). Initial conformance uses frozen
fixtures; no Workbench code or CI is changed by this POC.

## What exists today

Gate already has an unusually good first proof target:

- `verify.Reduce` states the ladder law: deterministic code blocks cannot be
  lowered, local models may pass or escalate but never block, judgment may
  resolve escalation but cannot override a code block, and tier/confidence
  compose monotonically
  (`/Users/mh/dev/workbench/cmd/gate/internal/verify/verify.go:1-12`).
- The reducer rejects unknown producers/decisions and local-model blocks, needs
  a real code floor before passing, and resolves decisions in an explicit order
  (`/Users/mh/dev/workbench/cmd/gate/internal/verify/verify.go:73-188`).
- Unknown tiers are different: the reducer preserves the unknown string and
  `tier.Rank` maps it to top rank T3 rather than refusing it
  (`/Users/mh/dev/workbench/cmd/gate/internal/tier/tier.go:5-22`,
  `/Users/mh/dev/workbench/cmd/gate/internal/verify/verify_test.go:785-798`).
- Existing Rapid tests compare the reducer with an independently shaped oracle,
  permute inputs, and generate unknown/local-block cases
  (`/Users/mh/dev/workbench/cmd/gate/internal/verify/property_test.go:12-17`,
  `:57-92`, `:114-211`).
- The property suite honestly restricts order-independence to at most one
  judgment because multiple judgments currently make last-one-win order
  observable (`/Users/mh/dev/workbench/cmd/gate/internal/verify/property_test.go:21-27`).

The POC must add assurance beyond restating these tests in prettier notation.

## Formal boundary

Start with the verdict reducer plus the narrow `TierWithin` comparator needed to
understand unknown-tier behavior. Do not initially model GitHub, grant
signatures/expiry, time, JSON parsing, merge execution, or the entire Gate run.

Model two layers so closed algebraic types do not erase the failures that matter:

```text
RawVerdict
  producer : String
  decision : String
  tier     : String
  source   : String
        |
        v validate
Except Refusal ValidVerdict
        |
        v reduce
Except Refusal ComposedVerdict
```

Suggested internal types:

- `ProducerClass := code | local | judgment`
- `Decision := pass | escalate | block`
- `TierValue := known Tier | unknown String`, with `Tier := t0 | t1 | t2 | t3`
- `SourceKind := floor | enrichment`
- `Refusal := unknownProducer | unknownDecision | localBlock`
- `ValidVerdict` with subject omitted from Phase 0 because the reducer does not
  compare it internally.

Raw strings remain in the model specifically to prove the actual boundary.
Making unknown inputs unrepresentable before modeling validation would "prove"
the most important cases by assuming them away. The faithful model retains an
unknown tier and assigns it top risk because that is current Go behavior; it
must not silently replace that behavior with refusal.

## Headline theorems

Use theorem names that describe authorization consequences, not implementation
steps:

1. `code_block_dominates`: any accepted set containing a code block reduces to
   block, regardless of a judgment pass.
2. `missing_floor_never_passes`: an empty set or a set without a non-enrichment
   code verdict cannot reduce to pass.
3. `local_block_is_refused`: validation/reduction never accepts a local-model
   block as an authorizing input.
4. `unknown_producer_or_decision_never_authorizes`: unknown producers and
   decisions yield refusal rather than pass.
5. `tier_is_monotone`: a composed verdict's tier is at least every accepted
   input tier.
6. `judgment_cannot_launder_missing_floor`: judgment pass does not substitute
   for deterministic evidence.
7. `permutation_invariant_under_single_judgment`: decision and tier are
   independent of input order under the same explicit domain restriction as the
   Go property test.
8. `unknown_tier_has_top_rank`: the formal model reproduces current Go ranking
   without claiming that ranking alone always refuses authorization.

Confidence is excluded from the first slice. The Go implementation uses
floating-point confidence; formalizing its minimum adds little safety value
until the decision and tier model proves useful.

## Phase-0 spike

1. Install/pin Lean 4 and Lake. Neither Lean/Lake nor Gleam was present on this
   machine when this kickoff was written.
2. Create the raw and valid types, validation function, and a pure reducer that
   is intentionally small enough to inspect in one sitting.
3. Translate a frozen set of named Go examples into data fixtures, retaining a
   source map from every fixture to its Go test/file line.
4. Prove the eight headline theorems with no `sorry`, `admit`, or project-defined
   `axiom`. Record `#print axioms` output for each headline theorem.
5. Add a narrow model of `Grant.TierWithin` and reproduce the cross-product of
   known/unknown candidate tier against T0–T3 ceilings. Treat the apparent
   unknown-tier/T3 result as a policy question, not permission to change Gate.
6. Add negative-control reducers with one law removed at a time—missing-floor
   check, local-block rejection, code-block dominance—and prove concrete
   existential counterexample witnesses while keeping the normal build green.
7. Produce a machine-readable table mapping: Go rule, Lean definition, theorem,
   fixture coverage, and assumptions not represented.
8. Stop and review whether the proof exposed a real ambiguity or merely mirrored
   existing Go tests. Do not add exact-head/capability laws until that review.

## Conformance strategy

Phase 0 uses checked-in fixtures, not an import or FFI bridge into Gate. Gate's
reducer is under Go `internal/`, and duplicating it in a helper executable solely
to make the proof project green would create the drift the experiment is meant
to measure.

If Phase 0 proves useful, a later slice may propose an intentional machine
surface owned by Gate that evaluates versioned verdict vectors. The Lean model
and Go implementation can then consume the same corpus and compare the
projection that is actually contractual: refusal class, decision, and tier—not
reason prose, timestamps, or finding order.

## Success metric

The POC succeeds only if:

- `lake build` checks every headline theorem with no proof holes or
  project-defined axioms.
- Each theorem links to the exact Go behavior it claims to model and explicitly
  lists excluded runtime assumptions.
- At least one mutation/negative-control has a proved, small, intelligible
  counterexample witness.
- Unknown producers/decisions, unknown tier strings, and local blocks are
  modeled at the boundary rather than excluded by construction.
- The report states exactly whether an unknown candidate tier compares within a
  T3 grant under current semantics; it neither labels that safe nor changes it.
- The formal restriction around multiple judgments is explicit; the proof does
  not overclaim unconditional order independence.
- A reviewer can identify whether Lean added a new guarantee, exposed an
  ambiguity, or supplied no leverage beyond current property testing.

"All proofs compile" is not sufficient if the model is disconnected from the
Go source or has defined away the dangerous inputs.

## Concrete weak spots and bail-points

- **Specification duplication.** A perfect proof of a stale Lean reducer says
  nothing about current Gate. Fixture/source mapping is mandatory, and a live
  conformance surface is a later earned change—not something this POC may sneak
  into Workbench.
- **Closed-type laundering.** Defining only valid producers and decisions makes
  unknown-input safety vacuous. Keep the raw validation layer.
- **Multiple judgments are genuinely order-sensitive today.** Do not silently
  strengthen the theorem or invent an ambiguity refusal in the faithful model.
  Retain the one-judgment precondition; an alternate refusal model must be
  labeled proposed policy.
- **Unknown tier is not currently refusal.** Preserve its top-rank semantics and
  test the T3 grant boundary explicitly. A policy change belongs in Workbench,
  not in this proof project.
- **Proof is conditional on the model.** GitHub freshness, grant authenticity,
  clock correctness, artifact provenance, and `--match-head-commit` enforcement
  are outside Phase 0.
- **Theorem names can smuggle policy.** Every claimed law must trace to existing
  Go behavior or be labeled a proposed policy, never presented as already true.
- **Automation can hide the argument.** Prefer readable structural proofs for
  the small kernel; use tactics to remove repetition, not to make the result
  inscrutable.
- **No production authority.** Nothing consumes Lean output to permit a merge.
  That requires a separate threat model, conformance story, and Workbench
  decision.

## Honest unknowns

- Whether proving the reducer laws reveals anything the existing Rapid oracle
  and properties do not already make sufficiently trustworthy.
- Whether raw JSON/codec behavior belongs in Lean or is better left to Go fuzzing.
- Whether a shared external model would reduce drift or merely introduce a third
  source beside the Go reducer and JSON schema.
- How much proof maintenance policy changes would impose on a one-person
  portfolio.

## Expected POC shape

```text
lakefile.toml
lean-toolchain
WorkbenchLaws/
  Verdict/Raw.lean
  Verdict/Domain.lean
  Verdict/Validate.lean
  Verdict/Reduce.lean
  Verdict/Laws.lean
  Verdict/Examples.lean
  Verdict/NegativeControls.lean
testdata/
  verdict-cases.json
docs/
  evidence/
  source-map.md
```

Do not add Mathlib unless a concrete proof needs it; the small verdict algebra
should first try Lean's core/std library and keep the trusted/dependency surface
obvious.
