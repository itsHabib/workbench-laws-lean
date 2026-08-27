# workbench-laws-lean

Lean 4 proofs about the rule that decides whether a pull request may merge.

[gate](https://github.com/itsHabib/gate) authorizes a merge by folding a list of
verdicts — CI results, review findings, human judgments — into a single
decision. That fold is small, it is load-bearing, and a single fail-open in it
merges an unready PR. This repository restates it as a Lean model and proves
laws that hold for **every** input, not the inputs a test happened to draw.

```sh
lake build
```

Lean and Lake are pinned by `lean-toolchain`. Mathlib is not used, so the build
needs nothing but the toolchain.

The model is an independent hand-port of workbench's verdict reducer at commit
[`6eee6aa`](https://github.com/itsHabib/workbench/tree/6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1).
Every claim below is about that model. Nothing here runs in production, and
nothing consumes its output to permit a merge.

## What it found

Two edges the existing Go property tests could not reach — which is the reason
the exercise was worth doing at all.

**Raw tier spelling is order-dependent at a rank tie.** Decision and tier
*rank* are permutation-invariant: shuffle the verdicts, get the same answer.
The raw tier *string* is not. `[T3, garbage]` retains `T3`; reversed, it
retains `garbage`. Composition follows first-strict-maximum, so a tie is broken
by arrival order.

The Go generator could never have caught this. It draws only valid tiers, so
the valid × invalid cross-product is outside the domain it samples — not a gap
in coverage but a gap in what coverage was possible.

**Unknown and empty tier strings carry rank 3.** The modeled comparator admits
them only against a valid `T3` ceiling; `WorkbenchLaws/Verdict/Reachability.md`
records what that does and does not imply upstream.

Neither finding authorizes a change to workbench. A policy response belongs
there, as its own reviewed decision.

## What it proves

| law | claim |
|---|---|
| `code_block_dominates` | A code block wins, whatever else is in the list — including when its source is `ci-classify`. |
| `missing_floor_never_passes` | A missing required check never composes into a pass. |
| `judgment_cannot_launder_missing_floor` | ...and a human judgment cannot override that. |
| `local_block_is_refused` | A locally-produced block cannot validate into an authorizing result. |
| `unknown_producer_or_decision_never_authorizes` | Neither can a verdict from a producer or decision the model does not recognize. |
| `tier_is_monotone` | Composed tier rank never decreases as verdicts are added. |
| `unknown_tier_has_top_rank` | An unrecognized tier string ranks at the top rather than falling through. |

## Why the proofs are not vacuous

A proof that holds because the statement is trivially true teaches nothing. Two
checks guard against that.

**Negative controls.** Three mutations of the rules, each of which *compiles*,
each paired with a proved existential counterexample — not an expected compiler
error:

- drop the floor check → the empty list passes
- drop local-block validation → a local block is accepted
- apply judgment after dominance → a judgment pass overwrites a code block

**Axiom audit.** No `sorry`, no `admit`, no project-defined axioms. Every
theorem bottoms out in Lean's three core axioms — `propext`, `Quot.sound`,
`Classical.choice` — and nothing else. The recorded `#print axioms` output is
in [`docs/evidence/axioms.txt`](docs/evidence/axioms.txt).

## What this does not establish

These are universal statements about the **Lean definitions**, not about a
running gate binary. The definitions were translated by hand after reading the
baseline commit; there is no executable Go↔Lean correspondence, and workbench
can drift while every proof here stays green. Closing that gap needs a
gate-owned versioned evaluation surface, which is a separate piece of work.

Deliberately outside the model: confidence, subjects, reason accumulation, JSON
decoding, GitHub freshness, grant authenticity and expiry, clocks, artifact
provenance, and merge-command enforcement. Multiple judgments stay accepted and
last-one-wins, faithful to the source; refusing them would be a policy proposal,
not a fix.

Full write-up in [`docs/report.md`](docs/report.md); provenance and conformance
boundaries in [`docs/source-map.md`](docs/source-map.md).

## Learning modules

`docs/learn/modules/` teaches Lean against these proofs rather than toy
examples — orientation, then the language itself, with exercises that import
`WorkbenchLaws.Verdict`. They are the Lean track of
[formal-methods](https://github.com/itsHabib/formal-methods), which is why that
course needs this repository to build.

## License

MIT
