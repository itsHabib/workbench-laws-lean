/-
Module 1 — Lean is a programming language.  EXERCISES.

Fill each `sorry` / TODO, then check your work by opening this file in an editor
with the Lean extension, or from the repo root:

    export PATH="$HOME/.elan/bin:$PATH"
    lake env lean docs/learn/modules/01-lean-is-a-language/Exercises.lean

Every `#guard` below must elaborate with no error once your answer is right; a
wrong answer makes the command report a failure. `#eval` just prints. None of
this is a proof — it is functional code the compiler runs for you. Solutions
are in `Solutions.lean` next door (peek only after trying).

This file is intentionally NOT part of `lake build` (the `sorry` holes are for
you), so it never turns the project red while you work.
-/
import WorkbenchLaws.Verdict.Reduce

open WorkbenchLaws.Verdict

namespace LearnEx

def valid (producer : ProducerClass) (decision : Decision)
    (tier source : String) : ValidVerdict :=
  { producer, decision, tier, source }

def codeBlock : ValidVerdict := valid .code .block "T0" "readiness"
def codePass  : ValidVerdict := valid .code .pass "T2" "readiness"
def escT3     : ValidVerdict := valid .code .escalate "T3" "triage-floor"
def opJudge   : ValidVerdict := valid .judgment .pass "T0" "operator"

/-! ## Exercise 1 (trivial) — predict, then run

Before evaluating: what decision and tier does `reduceValid` produce for
`[codeBlock, codePass]`? Write your prediction in a comment, then run the
`#eval` and confirm. Hint: `composedDecision` (Reduce.lean:30-37) and
`composedTier` (Reduce.lean:27-28). -/

-- My prediction: decision = ?, tier = ?
#eval reduceValid [codeBlock, codePass]

/-! ## Exercise 2 (trivial) — fill one line

Return `true` exactly when the decision is `.block`. Replace `sorry`. -/

def isBlock (d : Decision) : Bool := sorry

#guard isBlock .block = true
#guard isBlock .escalate = false

/-! ## Exercise 3 (trivial) — predict a fold

Predict the output for `[codePass, escT3]` (remember `tierRank` sends T3 to 3),
then run it. -/

-- My prediction: decision = ?, tier = ?
#eval reduceValid [codePass, escT3]

/-! ## Exercise 4 (real) — write `countEscalations`

Count the verdicts whose decision is `.escalate`. `isEscalation` already exists
at `Reduce.lean:11`. Use `List.filter` + `List.length`, or a `List.foldl`. -/

def countEscalations (vs : List ValidVerdict) : Nat := sorry

#guard countEscalations [codeBlock, escT3, opJudge, escT3] = 2
#guard countEscalations [] = 0

/-! ## Exercise 5 (real) — port `knownDecision` from Go

Go, `workbench/cmd/gate/internal/verify/verify.go:77-79`:

    func knownDecision(d string) bool {
        return d == DecisionBlock || d == DecisionEscalate || d == DecisionPass
    }

Port it as a total `String → Bool`. The three names are "block", "escalate",
"pass". The empty string must return `false` (fail closed). -/

def knownDecision (d : String) : Bool := sorry

#guard knownDecision "block" = true
#guard knownDecision "pass" = true
#guard knownDecision "" = false
#guard knownDecision "approved" = false

/-! ## Exercise 6 (STRETCH, optional) — `hasFloor` as a fold

`hasFloor` in the model is `vs.any isFloor` (Reduce.lean:16). Rewrite the same
predicate as an explicit `List.foldl` that ORs a running Bool, mirroring Go's
`hasCode` accumulator. Then the `#guard`s check it agrees with the library. -/

def hasFloorFold (vs : List ValidVerdict) : Bool := sorry

def ciClassify : ValidVerdict := valid .code .pass "T0" "ci-classify"

#guard hasFloorFold [codePass] = true
#guard hasFloorFold [ciClassify] = false      -- enrichment source is not a floor
#guard hasFloorFold [codeBlock, ciClassify] = hasFloor [codeBlock, ciClassify]

end LearnEx
