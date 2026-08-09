# Module 0 — Orientation: what got built and why

**Status:** filled
**Reading time:** ~20–30 min
**Prerequisites:** none. You need zero Lean and zero type theory for this
module. You do need to be willing to read Go.

**What you get out of it:** by the end you can give the five-minute tour of this
repo to a colleague — what the real Go code (`gate`) does, what the Lean project
next to it actually *is* (and, more importantly, what it is *not*), the two real
findings the proofs surfaced, the file map, and how to run the build and read
its output. No proof-reading yet. That starts in Module 1.

There is exactly one idea in this module you must not leave without, and it is
not a Lean idea:

> **The proofs are about a hand-written model of the Go code. They are not
> about the running Go binary.** Nothing here verifies Workbench. The Go can
> change tomorrow and every proof still passes.

Everything below is built so that sentence lands and stays landed. We will cite
the repo for every factual claim so you can check us.

---

## 1. The thing being modeled: `gate`'s `verify.Reduce`

Before there was any Lean, there was a Go function. It lives in the `workbench`
repo at `cmd/gate/internal/verify/verify.go:102-188`. Its name is `Reduce`.

`gate` is one Go binary whose whole job is to decide whether a pull request may
merge (`workbench/cmd/gate/CLAUDE.md`). It gathers evidence, runs a "ladder" of
verifiers, and each verifier emits a **verdict**. A verdict is a small record:
who produced it (a *producer class* — `code`, `local`, or `judgment`), what it
decided (`pass`, `escalate`, or `block`), a risk *tier* string (`T0`…`T3`), and
a source label.

`Reduce` is the function that folds a whole list of verdicts down into one
composed verdict — the single answer of "may this merge". That composition is
not "take a vote" or "worst wins". It follows specific rules the code calls the
**ladder law** (`workbench/cmd/gate/CLAUDE.md`, "The ladder law lives in code").
Read `Reduce` once, slowly (`verify.go:109-188`); the rules that matter are:

- **A code block dominates.** If any `code`-class verdict says `block`, the
  result is `block`, full stop (`verify.go:148-150, 164-166`).
- **Missing floor never passes.** There must be a real `code`-class verdict
  present ("the floor") for the result to pass. Absence of it *escalates* — it
  never silently reads as green (`verify.go:172-176`; the `noFloorWhy` comment
  at `verify.go:97-100` spells out the reasoning: absence of signal must not
  fall through to a pass).
- **Judgment cannot launder a missing floor.** A human/operator `judgment`
  verdict that says `pass` is applied *after* the floor check, so it cannot turn
  a floorless set green (`verify.go:168-181`).
- **Unknown values fail closed.** An unrecognized producer class or an
  unrecognized decision string — including the empty zero value a "drifted or
  foreign artifact" leaves — is refused with an error, never passed
  (`verify.go:121-129`; `knownDecision` at `verify.go:73-79`).
- **A local model can never block.** If a `local`-class verifier tries to
  `block`, that is a structural ladder violation and `Reduce` returns an error
  (`verify.go:130-131`; `ErrLocalBlock` at `verify.go:81-83`).
- **Tiers compose monotone-max, strictly.** The result's tier is raised to the
  highest tier seen, using a *strictly-greater* comparison
  (`verify.go:142-144`). Hold onto the word "strictly" — one of the two findings
  lives right there.

### Why this matters at all

`gate` sits on the merge boundary. Its exit code is a load-bearing contract that
other tools branch on: **0 pass / 1 blocked / 2 parked / 3 refused / 4 error**
(`workbench/cmd/gate/CLAUDE.md`). If `Reduce` had a bug that let a floorless or
unknown-producer set compose to `pass`, that is not a cosmetic defect — it is an
un-reviewed merge authorized by a machine. This is exactly the class of function
where "it passes its tests" is a weaker statement than you want, because the
tests only cover the verdict lists someone thought to write down. That gap is
the reason the Lean project exists.

---

## 2. What the Lean project actually is

Here is the honest, precise description. The Lean project (this repo,
`workbench-laws-lean/`) is:

**A hand-ported pure model of that narrow slice of `Reduce`, plus a set of
machine-checked laws (theorems) about the model.**

Unpack each phrase, because each one is a limit:

- **Hand-ported.** A human read the Go at a *specific frozen commit* and
  retyped its logic in Lean. The exact commit is recorded:
  `6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1` (`docs/source-map.md:3-4`,
  `docs/evidence/verification.md:6-9`). There is no automatic connection between
  the two. Nobody extracted Go from Lean; nobody generated Lean from Go.
- **Pure model.** The Lean version, `reduceValid` / `reduce`
  (`WorkbenchLaws/Verdict/Reduce.lean:39-43`), is the Go `Reduce` rewritten with
  no mutation, no I/O, no error side-channels — just a function from a list of
  verdicts to a composed verdict. Go's running accumulator (`out.Tier` being
  reassigned in a loop, `verify.go:142-144`) becomes a `foldl`
  (`composedTier`, `Reduce.lean:23-28`). Same rules, functional shape.
- **Narrow slice.** It models the reducer's decision/tier logic and the raw
  validation in front of it. It deliberately excludes almost everything else
  `gate` does: confidence, subjects, reason accumulation, JSON decoding, GitHub
  freshness, grant authenticity/expiry/scope, clocks, artifact provenance, and
  the actual merge-command enforcement (`docs/report.md:43-46`).
- **Machine-checked laws.** The theorems in `Laws.lean` are checked by Lean's
  kernel. When the build is green, every stated law holds *for the model*, with
  no gaps — no `sorry` (Lean's "trust me" placeholder), no `admit`, and no
  axioms the project invented (`docs/report.md:4-8`; `docs/evidence/axioms.txt`).

### What it is NOT (say this part out loud)

It is **not** a verified Go binary. Read the project's own README, first
paragraph: it "proves laws of the model; it is not production authority and
nothing consumes its output to permit a merge" (`README.md:5-7`). And the report
is blunt: "These are universal statements about the Lean definitions, not about
a running Gate binary" (`docs/report.md:32-33`), and "Workbench can drift while
every Lean proof stays green" (`docs/report.md:40-41`).

The reason a proof can be simultaneously airtight and not-about-the-real-code is
the single most important concept in the whole curriculum, and it gets its own
module (Module 8, "the model/implementation gap"). For now just hold both halves
at once: the laws are *genuinely proved* (that is real and worth something), and
they are proved *about the Lean model, not the Go* (so the guarantee stops at
the model boundary). Anyone who tells the story as "we formally verified gate"
has dropped the second half and is now saying something false.

What the model *does* buy you, honestly:

1. The laws are a precise, executable **specification** of what the ladder is
   supposed to mean — archaeology of intent that a pile of example tests only
   gestures at (`docs/report.md:4`).
2. The fixtures are **bounded provenance evidence**: they were translated after
   reading the exact baseline commit and cover the named Go test cases plus
   required edge cases (`docs/report.md:36-41`). Provenance, not conformance —
   more on that distinction in Module 8.
3. Writing the proofs **found two real semantic edges** the example tests and
   the property tests had not surfaced. That is the payoff, and it is next.

---

## 3. The two real findings, and where they came from

The project did more than restate examples. Two concrete edges fell out of
trying to prove things (`docs/report.md:61-68`). You do not need to read the
proofs to understand the findings — that is the point of stating them here.

### Finding 1 — raw-tier rank-tie order dependence

Recall the tier rule is *strictly*-greater replacement (`verify.go:142-144`,
mirrored in Lean at `chooseHigherTier`, `Reduce.lean:23-24`). Now recall how
tier *rank* is computed: `T0`/`T1`/`T2` map to 0/1/2, and **everything else** —
`T3`, an unknown string like `garbage`, even the empty string — maps to rank 3
(`tierRank`, `Domain.lean:48-54`; Go `tier.Rank`, cited at
`docs/source-map.md:12`).

So `T3` and `garbage` have the *same rank*. With strictly-greater replacement,
whichever one appears **first** in the list is the one whose spelling survives.
The composed decision and the composed *rank* are identical either way — but the
raw tier *string* is not:

- `[T3, garbage]` composes to tier `"T3"`.
- `[garbage, T3]` composes to tier `"garbage"`.

That is order dependence in the output. It surfaced when someone tried to prove
"permutation invariance" (reorder the list, get the same answer) and the proof
would not close for the raw tier string. The finding is captured as its own
theorem, `raw_tier_first_max_wins` (`Laws.lean:185-196`), and as frozen fixtures
for both orders (`Examples.lean:52-57`).

**Where it came from and why tests missed it:** the Go property test generator
draws only *valid* tiers, so it never samples the `T3`-vs-`garbage` cross-product
that exposes the tie (`docs/report.md:13-14`). The honest resolution the project
chose: don't claim invariance of the raw spelling. Instead prove invariance of
what actually is invariant — decision and tier *rank* — under an explicitly
named restricted domain, `PermutationDomain` (`Reduce.lean:51-54`,
`permutation_invariant_decision_and_rank`, `Laws.lean:169-183`), and promote the
tie behavior to the separate theorem above. The conformance decision writes this
down: raw tier spelling is *deliberately excluded* from what the model freezes,
because it is not permutation-invariant at rank ties (`docs/source-map.md:17-21`).

### Finding 2 — `TierWithin` unknown/empty candidate at a T3 ceiling

The second finding comes from a *different* slice of `gate` — grant ceilings,
in `capability.go`. A grant carries a maximum tier it authorizes (a "ceiling"),
and `Grant.TierWithin` checks whether a candidate tier is within that ceiling.
The subtlety: it validates the *ceiling* but does **not** validate the
*candidate* (`capability.go:140-148`, cited at `docs/source-map.md:14`; modeled
as `tierWithin`, `TierWithin.lean:6-7`).

Because unknown and empty candidate strings both rank 3 — same as `T3` — the
comparator accepts them under a valid `T3` ceiling. The Lean matrix proves the
whole cross-product (`tierWithinMatrix`, `tierWithin_full_cross_product`,
`TierWithin.lean:10-27`), with the two edge rows called out as their own
theorems: `unknown_candidate_within_t3` and `empty_candidate_within_t3`
(`TierWithin.lean:29-30`).

**The honesty guard on this one is important.** The project did *not* call this a
vulnerability. It wrote a companion note, `Verdict/Reachability.md`, showing that
every *current owned producer path* (triage floor, submitted judgment, readiness,
ci-classify) rejects or pins the tier before it could reach a live run — an
unknown candidate only arrives via "foreign or drifted artifact"
(`Reachability.md:20-26`). The note "labels the semantics and reachability; it
does not label the behavior safe or exploitable" (`Reachability.md:31`). That is
the tone to imitate: state exactly what is proved, state exactly what is not
concluded, and stop.

Neither finding authorizes a Workbench change on its own — any policy response
is "a separately reviewed decision" in Workbench (`docs/report.md:62-68`).

---

## 4. The file map

The Lean lives under `WorkbenchLaws/Verdict/`. Read it in this order; it is a
pipeline, each file importing the ones before it. (The `.lean` files are wired
together in `WorkbenchLaws.lean`, and the build target is declared in
`lakefile.toml`.)

| # | File | What it holds | One-line role |
|---|------|---------------|---------------|
| 1 | `Raw.lean` | `RawVerdict` — four **strings** (producer, decision, tier, source) | The untrusted input, exactly as a foreign/drifted artifact presents it (`Raw.lean:3-11`). |
| 2 | `Domain.lean` | The typed vocabulary: `ProducerClass`, `Decision`, `Refusal`, `ValidVerdict`; parsers `parseProducer`/`parseDecision`; `tierRank`, `validTier`, `isFloorSource` | Turns loose strings into a closed set of known cases — the model's dictionary (`Domain.lean:5-62`). |
| 3 | `Validate.lean` | `validateOne`, `validate` | The gate in front of the reducer: first invalid verdict wins, unknown producer/decision and local-block are refused (`Validate.lean:6-23`). Ports `verify.go:121-131`. |
| 4 | `Reduce.lean` | `chooseHigherTier`, `composedTier`, `composedDecision`, `reduceValid`, `reduce`, `PermutationDomain` | **The heart.** The pure port of Go `Reduce` (`Reduce.lean:23-43`). Go's loop-mutation became a `foldl`. |
| 5 | `Laws.lean` | 9 theorems | The proved laws about the model (see below), plus `#print axioms` for each (`Laws.lean:5-206`). |
| 6 | `Examples.lean` | ~15 `example`s, each proved `by rfl` | Frozen fixtures: named Go test cases retyped as theorems the compiler checks by *computation* (`Examples.lean:13-61`). |
| 7 | `NegativeControls.lean` | 3 mutated reducers + a counterexample theorem for each | Mutation testing where the "test" is a proof: each broken reducer still compiles, and a proved existential witness shows it does the wrong thing (`NegativeControls.lean:5-42`). |
| 8 | `TierWithin.lean` | `tierWithin` + the full ceiling matrix and its theorems | The second slice (grant ceilings), source of Finding 2 (`TierWithin.lean:6-33`). |

The nine laws in `Laws.lean`, in one line each (you are not reading the proofs
yet — just learn what each *claims*):

1. `code_block_dominates` — any code-class block forces `block` (`Laws.lean:5-8`).
2. `missing_floor_never_passes` — no floor ⇒ never `pass` (`Laws.lean:10-14`).
3. `judgment_cannot_launder_missing_floor` — a judgment pass can't rescue a
   floorless set (`Laws.lean:16-19`).
4. `local_block_is_refused` — a local block anywhere makes validation error
   (`Laws.lean:38-49`).
5. `unknown_producer_or_decision_never_authorizes` — unknown producer/decision
   ⇒ error, never a pass (`Laws.lean:51-63`).
6. `tier_is_monotone` — the composed tier rank is ≥ every member's rank
   (`Laws.lean:98-101`).
7. `permutation_invariant_decision_and_rank` — on `PermutationDomain`, reorder
   the list and decision + tier *rank* are unchanged (`Laws.lean:169-183`).
8. `raw_tier_first_max_wins` — Finding 1: raw tier spelling is order-dependent
   at a rank tie (`Laws.lean:185-196`).
9. `unknown_tier_has_top_rank` — any non-valid tier string ranks 3
   (`Laws.lean:103-108`).

Supporting docs, not Lean: `docs/report.md` (the result and stop decision),
`docs/source-map.md` (the Go-rule → Lean-definition → theorem → fixtures table,
plus the conformance boundary), `docs/source-map.json` (machine-readable form),
`Verdict/Reachability.md` (Finding 2's reachability note), and
`docs/evidence/` (`axioms.txt`, `verification.md`).

---

## 5. Running the build and reading its output

The whole thing is checked by one command. Lean and Lake are pinned by
`lean-toolchain` (`leanprover/lean4:v4.32.2`); no Mathlib, core/Std only
(`README.md:9-14`, `docs/evidence/verification.md:11-16`).

```sh
lake build
```

`lake` is Lean's build tool (like `go build` / `cargo build`). If `lake` is not
on your `PATH`, it ships with the toolchain manager `elan` — e.g.
`~/.elan/bin/lake build`. A green run ends with:

```
Build completed successfully (11 jobs).
```

That line **is** the done-check. In Lean, building *is* proof-checking — the
kernel re-verifies every theorem as it compiles the file. There is no separate
"run the tests" step: if `Laws.lean` compiles, every law in it is proved. A
broken proof is a build error, not a red test. (For the whole curriculum, "green
`lake build`" is the definition of done for each module.)

### The `#print axioms` lines

As the build replays `Laws.lean`, `NegativeControls.lean`, and `TierWithin.lean`
it prints one `info:` line per theorem, because each file ends with
`#print axioms <theorem>` directives (`Laws.lean:198-206`,
`NegativeControls.lean:44-46`, `TierWithin.lean:36-40`). These lines are the
**trust report** — they tell you what each proof ultimately leans on. The full
output is frozen at `docs/evidence/axioms.txt`. Two shapes appear:

- `... does not depend on any axioms` — a fully computational proof, standing on
  nothing but Lean's kernel. Example: `raw_tier_first_max_wins` and every
  `TierWithin` matrix theorem (`axioms.txt:12, 15-18`).
- `... depends on axioms: [propext]` (sometimes also `Classical.choice`,
  `Quot.sound`) — these three are **Lean's own standard logical axioms**, not
  anything this project invented. `propext` is propositional extensionality;
  `Quot.sound` and `Classical.choice` show up on the proofs that reason about
  list permutations (`permutation_invariant_decision_and_rank`,
  `tier_is_monotone`) (`axioms.txt:5-19`). Module 6 explains what these mean and
  why relying on them is fine.

The thing you are checking for, and the thing the kickoff banned, is **`sorryAx`**
— the axiom Lean inserts when a proof contains `sorry` (an unfinished hole). Its
absence is the guarantee there are no gaps. The evidence file states it directly:
"No output contains sorryAx. The listed dependencies are Lean's standard logical
axioms; the project declares no axioms of its own" (`axioms.txt:25-27`). The
verification record shows the belt-and-suspenders check too: a grep for
`sorry|admit|axiom` across the `.lean` files returns nothing
(`docs/evidence/verification.md:19-28`).

So the full "is this real?" reading of a green build is: *11 jobs completed, no
`sorryAx` anywhere, and the only axioms are Lean's three standard ones.* That is
the claim — and, per §2, that claim is about the model.

---

## Exercise — the written summary (no Lean)

There is no Lean to write in this module. Instead, write a **10-line summary**
of what this project does and does not prove, in your own words. Then check it
against the project's own stop decision (`docs/report.md:61-68`) and the
"Bounded evidence about Go" section (`docs/report.md:36-46`).

Your summary passes if it makes all of these true — grade yourself line by line:

1. Names what `gate`'s `verify.Reduce` does (composes verdicts into a merge
   decision) and why that matters (it's on the merge-authorization boundary).
2. States that the Lean project is a hand-ported pure model of a narrow slice,
   plus machine-checked laws about the model.
3. States explicitly that the proofs are **about the model, not the running Go**,
   and that Go can drift while proofs stay green.
4. Names the exact frozen commit the model was ported from
   (`6eee6aa…`).
5. Lists the two findings: raw-tier rank-tie order dependence, and the
   `TierWithin` unknown/empty candidate at a T3 ceiling.
6. Says why the property tests missed Finding 1 (the generator draws only valid
   tiers).
7. Distinguishes *provenance/bounded evidence* from *conformance* (fixtures show
   the model matched the read commit; they do not prove equivalence with current
   or future Go).
8. Notes that neither finding, by itself, authorizes a Workbench change.
9. States what a real assurance claim would require (a Gate-owned versioned
   evaluation surface + declared finite-class coverage).
10. Uses the word "model" at least once where a naive summary would have written
    "gate" — as a check that you internalized §2.

If any line of your summary would let a reader walk away believing "they
formally verified gate", rewrite it. That belief is the one failure mode this
module exists to prevent.

---

## Glossary

Terms introduced in this module. Each is given as the programming concept first,
then named. (Later modules formalize the Lean-specific ones.)

- **verdict** — a small record a `gate` verifier emits: producer class,
  decision, tier, source. The unit `Reduce` folds over (`verify.go:102-188`).
- **`Reduce` / the reducer** — the Go function that composes a list of verdicts
  into one merge decision (`verify.go:109-188`).
- **ladder law** — the fixed composition rules `Reduce` enforces in code (code
  block dominates, missing floor never passes, local can't block, unknowns fail
  closed, tiers monotone-max) (`workbench/cmd/gate/CLAUDE.md`).
- **tier / tier rank** — a risk label string (`T0`…`T3`); its *rank* is the
  number `tierRank` maps it to, where every non-`T0/T1/T2` string (incl. `T3`,
  unknown, empty) is rank 3 (`Domain.lean:48-54`).
- **model (vs implementation)** — the Lean `reduceValid` is the *model*; the Go
  `Reduce` is the *implementation*. Proofs bind to the model only. This gap is
  Module 8 (`docs/report.md:32-33`).
- **hand-ported** — a human retyped the Go logic into Lean by reading a fixed
  commit; no automatic extraction or generation connects the two
  (`docs/source-map.md:3-4`).
- **law / theorem** — a stated, machine-checked property of the model. In Lean a
  theorem is checked by building the file (`Laws.lean`).
- **`sorry` / `sorryAx`** — Lean's placeholder for an unfinished proof; it
  injects the `sorryAx` axiom, which `#print axioms` would then report. Absence
  of `sorryAx` = no gaps. Banned in this project (`axioms.txt:25-27`).
- **`#print axioms`** — a Lean directive that reports which axioms a theorem
  depends on; used here as a trust report (`Laws.lean:198-206`).
- **`propext` / `Classical.choice` / `Quot.sound`** — Lean's three *standard*
  logical axioms (not project-invented). Seeing them is expected and fine
  (Module 6) (`axioms.txt`).
- **`lake`** — Lean's build tool; `lake build` compiles *and* proof-checks. A
  green build is the done-check (`README.md:9-14`).
- **fixture (as theorem)** — a concrete example (`Examples.lean`) written as a
  theorem the compiler verifies by evaluation (`by rfl`). Provenance evidence,
  not conformance.
- **negative control / mutation** — a deliberately broken reducer
  (`NegativeControls.lean`) whose wrongness is demonstrated by a proved
  counterexample rather than an expected compile failure.
- **provenance vs conformance** — *provenance*: the model was faithfully copied
  from a known commit (bounded evidence). *conformance*: the model provably
  matches the running Go (not established here) (`docs/source-map.md:22-26`).
- **`PermutationDomain`** — the explicit, named restriction (≤1 judgment, no
  local block) under which reorder-invariance of decision and rank holds
  (`Reduce.lean:51-54`).
- **exit-code contract** — `gate`'s load-bearing seam: 0 pass / 1 blocked /
  2 parked / 3 refused / 4 error (`workbench/cmd/gate/CLAUDE.md`).
