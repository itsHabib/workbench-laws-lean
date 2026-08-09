# Source map and conformance boundary

All Go references below were read from Workbench commit
`6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1`, not from an assumed moving head.
The machine-readable form is `source-map.json`.

| Go rule | Lean definition | Theorem | Frozen fixtures |
|---|---|---|---|
| First invalid verdict wins; checks producer → decision → local block (`verify.go:121-131`) | `validateOne`, `validate` | `local_block_is_refused`; `unknown_producer_or_decision_never_authorizes` | local block, unknown producer/decision, both multi-invalid orders |
| Only literal `ci-classify` is enrichment for floor presence (`verify.go:133-140`; `ciclassify.go:21-23`) | `isFloorSource`, `isFloor` | `missing_floor_never_passes`; `judgment_cannot_launder_missing_floor` | empty, judgment-only floor laundering, arbitrary source |
| Code-block dominance is source-blind (`verify.go:148-150,159-166`) | `hasCodeBlock`, `composedDecision` | `code_block_dominates` | judgment override attempt, enrichment-source block |
| Strict-greater tier replacement; unknown/empty rank 3 (`verify.go:142-144`; `tier.go:10-22`) | `tierRank`, `chooseHigherTier`, `composedTier` | `tier_is_monotone`; `permutation_invariant_decision_and_rank`; `raw_tier_first_max_wins`; `unknown_tier_has_top_rank` | unknown, empty, both rank-tie orders |
| Last judgment wins (`verify.go:118,155-180`) | `lastJudgmentDecision` | `permutation_invariant_decision_and_rank` | judgment pass fixtures |
| Ceiling validated, candidate not (`capability.go:140-148`) | `tierWithin` | full matrix and unknown/empty-at-T3 theorems | Lean matrix |

## Conformance projection decision

Phase 0 freezes only refusal class, decision, and tier rank. Raw tier spelling
is deliberately excluded because it is not permutation-invariant at rank ties.
If a later Gate-owned evaluation surface compares raw tier, it must reproduce
first-strict-maximum exactly; canonicalizing the tier would be a policy change.

Fixtures establish provenance and bounded evidence only. They do not establish
equivalence with current or future Go. A later assurance claim requires a
Gate-owned versioned evaluation surface and declared coverage of rank ties,
source equality, multi-invalid order, and judgment counts.

## Permutation theorem domain

The restrictions are stated once as `PermutationDomain` and expanded here:

1. Inputs have passed raw validation, so producers and decisions are known.
2. There is at most one judgment.
3. There is no local block.
4. Tiers are unrestricted; unknown and empty strings are allowed.
5. Sources are unrestricted; the literal equality with `ci-classify` remains
   observable.

Only restriction 2 is needed by the valid-list decision proof; restriction 3
is retained to match the accepted domain of the Go generator. No valid-tier
restriction hides the raw-tier issue.
