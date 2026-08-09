/-
Module 1 — Lean is a programming language.  SOLUTIONS.

This file is compiled by `lake build` (the `Solutions` lib target in
lakefile.toml), so every definition and every `#guard` here is checked by the
toolchain on each build. Nothing in this file is a proof or a tactic — it is
ordinary functional code plus two commands that RUN it:

  * `#eval e`   prints the value of `e`.
  * `#guard e`  evaluates the Bool/decidable `e` and FAILS the build if it is
                not true. It is a runtime assertion the compiler runs for us —
                not a proof about all inputs (that is Module 2+).

We reuse the learner's own model rather than reinventing it. Everything below
imports the real types and functions from `WorkbenchLaws/Verdict/`.
-/
import WorkbenchLaws.Verdict.Reduce

open WorkbenchLaws.Verdict

namespace Learn

/-! ## Fixture builders

`valid` mirrors the helper in `WorkbenchLaws/Verdict/Examples.lean:9`. It just
fills a `ValidVerdict` structure (the record defined at `Domain.lean:23`) so the
exercises can name test inputs compactly. -/

def valid (producer : ProducerClass) (decision : Decision)
    (tier source : String) : ValidVerdict :=
  { producer, decision, tier, source }

def codeBlock : ValidVerdict := valid .code .block "T0" "readiness"
def codePass  : ValidVerdict := valid .code .pass "T2" "readiness"
def escT3     : ValidVerdict := valid .code .escalate "T3" "triage-floor"
def opJudge   : ValidVerdict := valid .judgment .pass "T0" "operator"

/-! ## Exercise 1 (trivial) — predict, then run

A code block dominates every other verdict (`composedDecision`,
`Reduce.lean:30-37`). The composed tier is the first strict maximum by rank
(`composedTier`, `Reduce.lean:27-28`): "T2" has rank 2, "T0" rank 0, so "T2"
wins. Predicted output: `{ decision := block, tier := "T2" }`. -/

#eval reduceValid [codeBlock, codePass]
#guard reduceValid [codeBlock, codePass] = { decision := .block, tier := "T2" }

/-! ## Exercise 2 (trivial) — fill one line

`isBlock` is a one-line predicate on the `Decision` sum type (`Domain.lean:11`).
Compare with `.block` using structural equality `==` (available because
`Decision` derives `DecidableEq`). -/

def isBlock (d : Decision) : Bool := d == .block

#guard isBlock .block = true
#guard isBlock .escalate = false

/-! ## Exercise 3 (trivial) — predict a fold

`tierRank` (`Domain.lean:50`) sends T0/T1/T2 to 0/1/2 and EVERYTHING else — T3,
unknown strings, the empty string — to 3. So the escalate-T3 verdict raises the
composed tier to "T3" (rank 3), and the decision (no floor is missing here, no
code block) becomes escalate. Predicted: `{ decision := escalate, tier := "T3" }`. -/

#eval reduceValid [codePass, escT3]
#guard reduceValid [codePass, escT3] = { decision := .escalate, tier := "T3" }

/-! ## Exercise 4 (real) — write `countEscalations`

Count how many verdicts carry the `escalate` decision. Two equally good
spellings; both use ordinary `List` operations the learner already knows from
Elixir's `Enum`. `isEscalation` already exists at `Reduce.lean:11`. -/

def countEscalations (vs : List ValidVerdict) : Nat :=
  (vs.filter isEscalation).length

-- The fold spelling, for comparison: start at 0, add 1 per escalation.
def countEscalations' (vs : List ValidVerdict) : Nat :=
  vs.foldl (fun acc v => if isEscalation v then acc + 1 else acc) 0

#eval countEscalations [codeBlock, escT3, opJudge, escT3]   -- 2
#guard countEscalations [codeBlock, escT3, opJudge, escT3] = 2
#guard countEscalations [] = 0
#guard countEscalations' [codeBlock, escT3, opJudge, escT3] = 2

/-! ## Exercise 5 (real) — port `knownDecision` from Go

Go, `workbench/cmd/gate/internal/verify/verify.go:77-79`:

    func knownDecision(d string) bool {
        return d == DecisionBlock || d == DecisionEscalate || d == DecisionPass
    }

The port is a near-transliteration: a total `String → Bool`. Note this operates
on the RAW string, exactly like the Go helper — it is the "is this one of the
three names the ladder defines?" check that fails closed on the zero value "". -/

def knownDecision (d : String) : Bool :=
  d == "block" || d == "escalate" || d == "pass"

#guard knownDecision "block" = true
#guard knownDecision "pass" = true
#guard knownDecision "" = false          -- the fail-closed zero value
#guard knownDecision "approved" = false

-- The model already has the Option-returning cousin: `parseDecision`
-- (`Domain.lean:42`) returns `some`/`none` instead of a Bool. `knownDecision`
-- is exactly "did parse succeed?", so the two agree on every string:
#guard knownDecision "escalate" = (parseDecision "escalate").isSome
#guard knownDecision "nonsense" = (parseDecision "nonsense").isSome

/-! ## Exercise 6 (STRETCH, optional) — `hasFloor` as a fold

`hasFloor` in the model (`Reduce.lean:16`) is `vs.any isFloor`. Rewrite the same
predicate as an explicit left fold that ORs a running Bool — the same shape as
Go's `hasCode` accumulator (`verify.go:120,139-141`). Then `#guard` that your
fold agrees with the library's `.any` version on sample inputs. -/

def hasFloorFold (vs : List ValidVerdict) : Bool :=
  vs.foldl (fun acc v => acc || isFloor v) false

def ciClassify : ValidVerdict := valid .code .pass "T0" "ci-classify"

-- `isFloor` (Reduce.lean:8) is code-class AND source ≠ "ci-classify", so a
-- lone ci-classify verdict is NOT a floor — the enrichment carve-out.
#guard hasFloorFold [codePass] = true
#guard hasFloorFold [ciClassify] = false
#guard hasFloorFold [] = false
-- Agreement with the library spelling on each sample:
#guard hasFloorFold [codePass] = hasFloor [codePass]
#guard hasFloorFold [ciClassify] = hasFloor [ciClassify]
#guard hasFloorFold [codeBlock, ciClassify] = hasFloor [codeBlock, ciClassify]

/-! ## Lesson demonstrations

Every `#eval` / `#guard` shown in the prose of `lesson.md` also lives here, so
the toolchain checks each claim the lesson makes. -/

-- §1 def / tierRank
#eval tierRank "T2"                     -- 2
#eval tierRank "T3"                     -- 3
#eval tierRank ""                       -- 3

-- §3 structure construction: brace form is what `valid` desugars to.
def codeBlockBrace : ValidVerdict :=
  { producer := .code, decision := .block, tier := "T0", source := "readiness" }
#guard codeBlockBrace = codeBlock
#eval codeBlock.decision                -- Decision.block

-- §4 Option
#eval parseProducer "judgment"          -- some judgment
#eval parseProducer "nope"              -- none

-- §7 the whole reducer
#eval reduceValid [codeBlock, codePass] -- { decision := block, tier := "T2" }

end Learn

