import WorkbenchLaws.Verdict.Reduce

namespace WorkbenchLaws.Verdict

/-- Mutation 1: absence of a deterministic floor is allowed to pass. -/
def reduceWithoutFloorCheck (vs : List ValidVerdict) : Decision :=
  if hasCodeBlock vs then .block
  else match lastJudgmentDecision vs with
    | some d => d
    | none => if hasEscalation vs then .escalate else .pass

theorem missing_floor_mutation_has_counterexample :
    ∃ vs : List ValidVerdict, hasFloor vs = false ∧ reduceWithoutFloorCheck vs = .pass := by
  exact ⟨[], rfl, rfl⟩

/-- Mutation 2: local blocks survive validation. -/
def validateOneAllowLocalBlock (raw : RawVerdict) : Except Refusal ValidVerdict := do
  let producer ← match parseProducer raw.producer with
    | some producer => pure producer
    | none => throw .unknownProducer
  let decision ← match parseDecision raw.decision with
    | some decision => pure decision
    | none => throw .unknownDecision
  return { producer, decision, tier := raw.tier, source := raw.source }

theorem local_block_mutation_has_counterexample :
    ∃ raw : RawVerdict,
      rawIsLocalBlock raw = true ∧ (validateOneAllowLocalBlock raw).isOk = true := by
  exact ⟨{ producer := "local", decision := "block", tier := "T0", source := "review" }, rfl, rfl⟩

/-- Mutation 3: judgment is applied after code-block dominance. -/
def reduceWithBrokenDominance (vs : List ValidVerdict) : Decision :=
  match lastJudgmentDecision vs with
  | some d => d
  | none => if hasCodeBlock vs then .block else composedDecision vs

theorem dominance_mutation_has_counterexample :
    ∃ vs : List ValidVerdict,
      hasCodeBlock vs = true ∧ reduceWithBrokenDominance vs = .pass := by
  let block : ValidVerdict := { producer := .code, decision := .block, tier := "T0", source := "readiness" }
  let pass : ValidVerdict := { producer := .judgment, decision := .pass, tier := "T0", source := "operator" }
  exact ⟨[block, pass], rfl, rfl⟩

#print axioms missing_floor_mutation_has_counterexample
#print axioms local_block_mutation_has_counterexample
#print axioms dominance_mutation_has_counterexample

end WorkbenchLaws.Verdict
