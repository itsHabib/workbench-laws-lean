import WorkbenchLaws.Verdict.Raw

namespace WorkbenchLaws.Verdict

inductive ProducerClass where
  | code
  | local
  | judgment
  deriving DecidableEq, Repr

inductive Decision where
  | pass
  | escalate
  | block
  deriving DecidableEq, Repr

inductive Refusal where
  | unknownProducer
  | unknownDecision
  | localBlock
  deriving DecidableEq, Repr

structure ValidVerdict where
  producer : ProducerClass
  decision : Decision
  tier : String
  source : String
  deriving DecidableEq, Repr

structure ComposedVerdict where
  decision : Decision
  /-- Raw tier spelling, retained to model Go's first-strict-maximum rule. -/
  tier : String
  deriving DecidableEq, Repr

def parseProducer : String → Option ProducerClass
  | "code" => some .code
  | "local" => some .local
  | "judgment" => some .judgment
  | _ => none

def parseDecision : String → Option Decision
  | "pass" => some .pass
  | "escalate" => some .escalate
  | "block" => some .block
  | _ => none

/-- Gate's tier.Rank: every string other than T0/T1/T2 has rank 3. This
    deliberately includes T3, unknown strings, and the empty string. -/
def tierRank : String → Nat
  | "T0" => 0
  | "T1" => 1
  | "T2" => 2
  | _ => 3

def validTier : String → Bool
  | "T0" | "T1" | "T2" | "T3" => true
  | _ => false

/-- The sole source classification used by the model. Every value except the
    one literal enrichment source counts as floor when the producer is code. -/
def isFloorSource (source : String) : Bool := source != "ci-classify"

end WorkbenchLaws.Verdict
