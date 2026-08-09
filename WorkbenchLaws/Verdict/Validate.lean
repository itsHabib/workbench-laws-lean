import WorkbenchLaws.Verdict.Domain

namespace WorkbenchLaws.Verdict

/-- Checks one verdict in Go's exact order: producer, decision, local block. -/
def validateOne (raw : RawVerdict) : Except Refusal ValidVerdict := do
  let producer ← match parseProducer raw.producer with
    | some producer => pure producer
    | none => throw .unknownProducer
  let decision ← match parseDecision raw.decision with
    | some decision => pure decision
    | none => throw .unknownDecision
  if producer == .local && decision == .block then
    throw .localBlock
  return { producer, decision, tier := raw.tier, source := raw.source }

/-- Ordered traversal. The first invalid verdict in list order wins. -/
def validate : List RawVerdict → Except Refusal (List ValidVerdict)
  | [] => pure []
  | raw :: rest => do
      let verdict ← validateOne raw
      let verdicts ← validate rest
      pure (verdict :: verdicts)

def rawIsLocalBlock (raw : RawVerdict) : Bool :=
  raw.producer == "local" && raw.decision == "block"

def rawHasLocalBlock (raws : List RawVerdict) : Bool := raws.any rawIsLocalBlock

def rawHasUnknownProducerOrDecision (raws : List RawVerdict) : Bool :=
  raws.any fun raw => (parseProducer raw.producer).isNone || (parseDecision raw.decision).isNone

end WorkbenchLaws.Verdict
