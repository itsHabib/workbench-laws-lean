# Adversarial Review — Gate Verdict Laws Kickoff

**Reviewed:** 2026-08-08  
**Target:** `kickoff.md`  
**Disposition:** revise factual model before implementation

## Review posture

Assume the Lean proof will create false confidence. Look for behaviors defined
away by types, policy accidentally invented during formalization, and proofs
that cannot be connected to the current Go implementation.

## Findings

### 1. Unknown-tier refusal was factually wrong

**Severity:** critical

The initial kickoff said Gate rejects an unknown tier and proposed
`unknownTier` as a refusal. The actual reducer preserves an unknown tier string.
`tier.Rank` maps every unknown value to rank 3
([`cmd/gate/internal/tier/tier.go:5-22`](https://github.com/itsHabib/workbench/blob/6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1/cmd/gate/internal/tier/tier.go#L5-L22)), and the existing
test explicitly expects `"garbage"` to survive reduction at rank 3
([`cmd/gate/internal/verify/verify_test.go:785-798`](https://github.com/itsHabib/workbench/blob/6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1/cmd/gate/internal/verify/verify_test.go#L785-L798)).

This is described as fail-closed, but `Grant.TierWithin` validates the grant's
ceiling and then compares ranks; it does not validate the candidate tier
([`cmd/gate/internal/capability/capability.go:140-148`](https://github.com/itsHabib/workbench/blob/6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1/cmd/gate/internal/capability/capability.go#L140-L148)).
Therefore an unknown candidate tier appears capable of comparing within a T3
grant. That implication must be reproduced and checked before the POC claims
unknown tiers cannot authorize.

**Required change:** model current unknown-tier-as-top semantics exactly. Add a
narrow boundary probe for `TierWithin`, label the T3 result as a discovered
policy question, and do not silently “fix” Gate in the Lean model.

### 2. `ambiguousJudgment` invented policy

**Severity:** high

The proposed refusal type included `ambiguousJudgment`, but Go accepts multiple
judgments and effectively makes the last encountered one decisive. The property
test avoids the ambiguity by generating at most one judgment. Refusing multiple
judgments may be a better policy, but it is not current behavior.

**Required change:** remove the refusal from the faithful model. Preserve list
semantics and state the single-judgment precondition on permutation theorems. A
separate alternate model may explore refusal, clearly labeled as a proposal.

### 3. A proof of copied logic can remain green while Gate drifts

**Severity:** high

Frozen examples provide provenance, not conformance. They cannot show that a
later Go change still matches Lean.

**Required change:** Phase 0 may stay fixture-based, but its conclusion must be
limited to “the model has these laws.” Production assurance requires a Gate-owned
machine evaluation surface or another independent equivalence mechanism. Do not
count source links as executable correspondence.

### 4. The first seven laws may add no assurance over Rapid

**Severity:** medium

Most headline laws already have example/property coverage. Lean earns its cost
only if it clarifies the exact domain, exposes an ambiguity (as it already did
for unknown tier), or proves a compositional statement difficult to sample.

**Required change:** keep “no added leverage” as an acceptable result. Report
proof effort and the assumption surface, not just theorem count.

### 5. Intentionally broken files are a poor negative control

**Severity:** medium

Expected theorem failures can make the normal build awkward or encourage an
unreviewed script that treats compiler failure as success.

**Required change:** define mutated reducers that still compile, then prove
small existential counterexample witnesses against them. Keep the primary build
green and the failure legible.

### 6. “Lean is the reference contract” is not yet earned

**Severity:** note

During the POC, Go remains behavioral truth and Lean is an independent model.
Promoting Lean to normative policy would change ownership, review, CI, and drift
boundaries.

**Required change:** retain the experiment outside Workbench and require a
separate design decision before any production consumer trusts Lean output.

## Bottom line

The false unknown-tier assumption is exactly the sort of ambiguity that can
justify the experiment. Proceed with the corrected faithful model. Do not patch
the production behavior from this POC; first prove what it currently implies,
then bring any policy change back to Workbench as a separately reviewed decision.
