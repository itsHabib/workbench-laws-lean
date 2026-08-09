# Gate verdict laws — Phase-0 result

## Result

The POC succeeded as specification archaeology. Lean proves the requested laws
of the independent model with no `sorry`, `admit`, or project-defined axioms,
and three compiling mutations each have a concrete existential counterexample.
Lean core/Std is sufficient; Mathlib was not added.

The experiment also found real leverage beyond the current Rapid permutation
generator: decision and tier rank are permutation-invariant on the declared
accepted domain, but the raw tier string is not. `[T3, garbage]` retains `T3`;
the reverse retains `garbage`. The Go generator draws only valid tiers, so it
does not cover that cross-product. The `TierWithin` model independently shows
that unknown and empty candidates compare within a valid T3 ceiling, subject to
the separate reachability limits in `Verdict/Reachability.md`.

## Universal about the Lean model

- A code block dominates, including when its source is `ci-classify`.
- Missing floor never passes, and judgment cannot launder it.
- Local blocks and unknown producers/decisions cannot validate into an
  authorizing result.
- Composed tier rank is monotone over every accepted input.
- Under `PermutationDomain`, decision and tier rank are invariant under list
  permutation; unknown tier strings remain included.
- Raw tier spelling follows first-strict-maximum and is order-dependent at rank
  ties.
- Unknown and empty tier strings have rank 3; the modeled comparator accepts
  them only at a valid T3 ceiling.

These are universal statements about the Lean definitions, not about a running
Gate binary.

## Bounded evidence about Go

The definitions and fixtures were translated after reading the exact baseline
commit. They cover named Go examples plus the required multi-invalid,
arbitrary-source, enrichment-block, rank-tie, and empty-tier cases. This is
bounded provenance evidence. There is no executable Go↔Lean correspondence,
and Workbench can drift while every Lean proof stays green.

Confidence, subjects, reason accumulation, JSON decoding, GitHub freshness,
grant authenticity/expiry/scope, clocks, artifact provenance, and merge command
enforcement are excluded. Multiple judgments remain accepted and last-one-wins
in the faithful model; refusing them would be a separate policy proposal.

## Negative controls

All mutations compile in the primary build:

- Removing the floor check permits the empty list to pass.
- Removing local-block validation accepts a local block.
- Applying judgment after dominance lets a judgment pass overwrite a code
  block.

Each counterexample is a proved existential witness, not an expected compiler
failure.

## Stop decision

Stop Phase 0 here. The proof exposed two concrete semantic edges rather than
merely restating examples: raw-tier rank-tie order dependence, and the
unknown/empty candidate result at the `TierWithin` comparator. Neither result
authorizes a Workbench change from this project. Any policy response belongs in
Workbench as a separately reviewed decision; any production assurance claim
first needs a Gate-owned versioned evaluation surface and declared finite-class
coverage.
