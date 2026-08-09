import WorkbenchLaws.Verdict.Reduce

namespace WorkbenchLaws.Verdict

theorem code_block_dominates (vs : List ValidVerdict)
    (h : hasCodeBlock vs = true) :
    (reduceValid vs).decision = .block := by
  simp [reduceValid, composedDecision, h]

theorem missing_floor_never_passes (vs : List ValidVerdict)
    (h : hasFloor vs = false) :
    (reduceValid vs).decision ≠ .pass := by
  cases hBlock : hasCodeBlock vs <;>
    simp [reduceValid, composedDecision, h, hBlock]

theorem judgment_cannot_launder_missing_floor (vs : List ValidVerdict)
    (hFloor : hasFloor vs = false) :
    (reduceValid vs).decision ≠ .pass :=
  missing_floor_never_passes vs hFloor

private theorem validate_error_of_member
    (raw : RawVerdict) (raws : List RawVerdict)
    (hMember : raw ∈ raws) (hBad : ∃ refusal, validateOne raw = .error refusal) :
    ∃ refusal, validate raws = .error refusal := by
  induction raws with
  | nil => simp at hMember
  | cons head tail ih =>
      simp only [List.mem_cons] at hMember
      rcases hMember with rfl | hTail
      · obtain ⟨refusal, hError⟩ := hBad
        exact ⟨refusal, by unfold validate; rw [hError]; rfl⟩
      · cases hHead : validateOne head with
        | error refusal => exact ⟨refusal, by unfold validate; rw [hHead]; rfl⟩
        | ok verdict =>
            obtain ⟨refusal, hError⟩ := ih hTail
            exact ⟨refusal, by unfold validate; rw [hHead, hError]; rfl⟩

theorem local_block_is_refused
    (raw : RawVerdict) (raws : List RawVerdict)
    (hMember : raw ∈ raws)
    (hProducer : raw.producer = "local")
    (hDecision : raw.decision = "block") :
    ∃ refusal, validate raws = .error refusal := by
  apply validate_error_of_member raw raws hMember
  rcases raw with ⟨producer, decision, tier, source⟩
  simp at hProducer hDecision
  subst producer
  subst decision
  exact ⟨.localBlock, by rfl⟩

theorem unknown_producer_or_decision_never_authorizes
    (raw : RawVerdict) (raws : List RawVerdict)
    (hMember : raw ∈ raws)
    (hUnknown : parseProducer raw.producer = none ∨ parseDecision raw.decision = none) :
    ∃ refusal, reduce raws = .error refusal := by
  have hOne : ∃ refusal, validateOne raw = .error refusal := by
    rcases hUnknown with hProducer | hDecision
    · exact ⟨.unknownProducer, by unfold validateOne; rw [hProducer]; rfl⟩
    · cases hProducer : parseProducer raw.producer with
      | none => exact ⟨.unknownProducer, by unfold validateOne; rw [hProducer]; rfl⟩
      | some producer => exact ⟨.unknownDecision, by unfold validateOne; rw [hProducer, hDecision]; rfl⟩
  obtain ⟨refusal, hValidate⟩ := validate_error_of_member raw raws hMember hOne
  exact ⟨refusal, by unfold reduce; rw [hValidate]; rfl⟩

private theorem tierRank_choose_ge_left (current candidate : String) :
    tierRank current ≤ tierRank (chooseHigherTier current candidate) := by
  simp only [chooseHigherTier]
  split <;> omega

private theorem tierRank_choose_ge_right (current candidate : String) :
    tierRank candidate ≤ tierRank (chooseHigherTier current candidate) := by
  simp only [chooseHigherTier]
  split <;> omega

private theorem tierRank_fold_ge_start (start : String) (vs : List ValidVerdict) :
    tierRank start ≤ tierRank (vs.foldl (fun current v => chooseHigherTier current v.tier) start) := by
  induction vs generalizing start with
  | nil => simp
  | cons head tail ih =>
      simp only [List.foldl_cons]
      exact Nat.le_trans (tierRank_choose_ge_left start head.tier)
        (ih (chooseHigherTier start head.tier))

private theorem tierRank_fold_ge_member (start : String) (vs : List ValidVerdict)
    (v : ValidVerdict) (hMember : v ∈ vs) :
    tierRank v.tier ≤ tierRank (vs.foldl (fun current x => chooseHigherTier current x.tier) start) := by
  induction vs generalizing start with
  | nil => simp at hMember
  | cons head tail ih =>
      simp only [List.mem_cons] at hMember
      simp only [List.foldl_cons]
      rcases hMember with hEq | hTail
      · subst v
        exact Nat.le_trans (tierRank_choose_ge_right start head.tier)
          (tierRank_fold_ge_start (chooseHigherTier start head.tier) tail)
      · exact ih (chooseHigherTier start head.tier) hTail

theorem tier_is_monotone (vs : List ValidVerdict) (v : ValidVerdict)
    (hMember : v ∈ vs) :
    tierRank v.tier ≤ tierRank (reduceValid vs).tier := by
  exact tierRank_fold_ge_member "T0" vs v hMember

theorem unknown_tier_has_top_rank (tier : String) (h : validTier tier = false) :
    tierRank tier = 3 := by
  have h0 : tier ≠ "T0" := by intro hEq; subst tier; simp [validTier] at h
  have h1 : tier ≠ "T1" := by intro hEq; subst tier; simp [validTier] at h
  have h2 : tier ≠ "T2" := by intro hEq; subst tier; simp [validTier] at h
  simp [tierRank]

private theorem tierRank_choose_eq_max (current candidate : String) :
    tierRank (chooseHigherTier current candidate) =
      max (tierRank current) (tierRank candidate) := by
  simp only [chooseHigherTier]
  split <;> omega

private theorem tierRank_fold_eq_maxFold (start : String) (vs : List ValidVerdict) :
    tierRank (vs.foldl (fun current v => chooseHigherTier current v.tier) start) =
      (vs.map (fun v => tierRank v.tier)).foldl max (tierRank start) := by
  induction vs generalizing start with
  | nil => rfl
  | cons head tail ih =>
      simp only [List.foldl_cons, List.map_cons]
      rw [ih, tierRank_choose_eq_max]

private theorem foldl_max_perm {xs ys : List Nat} (h : xs.Perm ys) (start : Nat) :
    xs.foldl max start = ys.foldl max start := by
  induction h generalizing start with
  | nil => rfl
  | cons head _ ih =>
      simp only [List.foldl_cons]
      exact ih (max start head)
  | swap left right tail =>
      simp only [List.foldl_cons]
      congr 1
      omega
  | trans _ _ ih₁ ih₂ => exact (ih₁ start).trans (ih₂ start)

private theorem perm_eq_of_length_le_one {α : Type} {xs ys : List α}
    (hPerm : xs.Perm ys) (hLength : xs.length ≤ 1) : xs = ys := by
  cases xs with
  | nil =>
      have : ys.length = 0 := by simpa using hPerm.length_eq.symm
      exact List.eq_nil_of_length_eq_zero this |>.symm
  | cons x tail =>
      have hTail : tail = [] := by
        cases tail with
        | nil => rfl
        | cons y rest => simp at hLength
      subst hTail
      cases ys with
      | nil => simp at hPerm
      | cons y rest =>
          have hRest : rest = [] := by
            have hLen : (y :: rest).length = [x].length := hPerm.length_eq.symm
            simpa using hLen
          subst hRest
          have hMem : x ∈ [y] := hPerm.mem_iff.mp (by simp)
          simpa using hMem

private theorem lastJudgmentDecision_perm
    {xs ys : List ValidVerdict} (hPerm : xs.Perm ys)
    (hCount : judgmentCount xs ≤ 1) :
    lastJudgmentDecision xs = lastJudgmentDecision ys := by
  have hFiltered : (xs.filter isJudgment).Perm (ys.filter isJudgment) := hPerm.filter isJudgment
  have hLength : (xs.filter isJudgment).length ≤ 1 := hCount
  have hEq := perm_eq_of_length_le_one hFiltered hLength
  simp [lastJudgmentDecision, hEq]

theorem permutation_invariant_decision_and_rank
    {xs ys : List ValidVerdict}
    (hDomain : PermutationDomain xs)
    (hPerm : xs.Perm ys) :
    (reduceValid xs).decision = (reduceValid ys).decision ∧
    tierRank (reduceValid xs).tier = tierRank (reduceValid ys).tier := by
  have hBlock : hasCodeBlock xs = hasCodeBlock ys := hPerm.any_eq
  have hFloor : hasFloor xs = hasFloor ys := hPerm.any_eq
  have hEscalation : hasEscalation xs = hasEscalation ys := hPerm.any_eq
  have hJudgment := lastJudgmentDecision_perm hPerm hDomain.1
  constructor
  · simp [reduceValid, composedDecision, hBlock, hFloor, hEscalation, hJudgment]
  · simp only [reduceValid, composedTier]
    rw [tierRank_fold_eq_maxFold, tierRank_fold_eq_maxFold]
    exact foldl_max_perm (hPerm.map fun v => tierRank v.tier) 0

theorem raw_tier_first_max_wins :
    let passT3 : ValidVerdict :=
      { producer := .code, decision := .pass, tier := "T3", source := "readiness" }
    let passUnknown : ValidVerdict :=
      { producer := .code, decision := .pass, tier := "garbage", source := "triage-floor" }
    (reduceValid [passT3, passUnknown]).decision =
      (reduceValid [passUnknown, passT3]).decision ∧
    tierRank (reduceValid [passT3, passUnknown]).tier =
      tierRank (reduceValid [passUnknown, passT3]).tier ∧
    (reduceValid [passT3, passUnknown]).tier = "T3" ∧
    (reduceValid [passUnknown, passT3]).tier = "garbage" := by
  decide

#print axioms code_block_dominates
#print axioms missing_floor_never_passes
#print axioms local_block_is_refused
#print axioms unknown_producer_or_decision_never_authorizes
#print axioms tier_is_monotone
#print axioms judgment_cannot_launder_missing_floor
#print axioms permutation_invariant_decision_and_rank
#print axioms raw_tier_first_max_wins
#print axioms unknown_tier_has_top_rank

end WorkbenchLaws.Verdict
