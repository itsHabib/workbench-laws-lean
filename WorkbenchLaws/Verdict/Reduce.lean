import WorkbenchLaws.Verdict.Validate

namespace WorkbenchLaws.Verdict

def isCodeBlock (v : ValidVerdict) : Bool :=
  v.producer == .code && v.decision == .block

def isFloor (v : ValidVerdict) : Bool :=
  v.producer == .code && isFloorSource v.source

def isEscalation (v : ValidVerdict) : Bool := v.decision == .escalate

def isJudgment (v : ValidVerdict) : Bool := v.producer == .judgment

def hasCodeBlock (vs : List ValidVerdict) : Bool := vs.any isCodeBlock
def hasFloor (vs : List ValidVerdict) : Bool := vs.any isFloor
def hasEscalation (vs : List ValidVerdict) : Bool := vs.any isEscalation

/-- Last judgment wins, matching the pointer replacement in verify.Reduce. -/
def lastJudgmentDecision (vs : List ValidVerdict) : Option Decision :=
  ((vs.filter isJudgment).getLast?).map (·.decision)

def chooseHigherTier (current candidate : String) : String :=
  if tierRank candidate > tierRank current then candidate else current

/-- Strictly-greater replacement retains the first spelling at a rank tie. -/
def composedTier (vs : List ValidVerdict) : String :=
  vs.foldl (fun current v => chooseHigherTier current v.tier) "T0"

def composedDecision (vs : List ValidVerdict) : Decision :=
  if hasCodeBlock vs then
    .block
  else if !hasFloor vs then
    .escalate
  else match lastJudgmentDecision vs with
    | some d => d
    | none => if hasEscalation vs then .escalate else .pass

def reduceValid (vs : List ValidVerdict) : ComposedVerdict :=
  { decision := composedDecision vs, tier := composedTier vs }

def reduce (raws : List RawVerdict) : Except Refusal ComposedVerdict := do
  return reduceValid (← validate raws)

def judgmentCount (vs : List ValidVerdict) : Nat :=
  (vs.filter isJudgment).length

def noLocalBlock (vs : List ValidVerdict) : Bool :=
  !(vs.any fun v => v.producer == .local && v.decision == .block)

/-- The accepted-input restrictions inherited from the Go property generator.
    Unknown tiers are intentionally unrestricted. -/
def PermutationDomain (vs : List ValidVerdict) : Prop :=
  judgmentCount vs ≤ 1 ∧ noLocalBlock vs = true

end WorkbenchLaws.Verdict
