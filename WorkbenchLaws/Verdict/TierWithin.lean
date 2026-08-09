import WorkbenchLaws.Verdict.Domain

namespace WorkbenchLaws.Verdict

/-- capability.Grant.TierWithin: validate the ceiling, not the candidate. -/
def tierWithin (candidate ceiling : String) : Bool :=
  validTier ceiling && tierRank candidate ≤ tierRank ceiling

/-- Rows are candidate tiers; columns are ceilings T0, T1, T2, T3. -/
def tierWithinMatrix : List (String × List Bool) :=
  [ ("T0",      [true,  true,  true,  true])
  , ("T1",      [false, true,  true,  true])
  , ("T2",      [false, false, true,  true])
  , ("T3",      [false, false, false, true])
  , ("garbage", [false, false, false, true])
  , ("",        [false, false, false, true])
  ]

theorem tierWithin_full_cross_product :
    tierWithinMatrix =
      [ ("T0", [tierWithin "T0" "T0", tierWithin "T0" "T1", tierWithin "T0" "T2", tierWithin "T0" "T3"])
      , ("T1", [tierWithin "T1" "T0", tierWithin "T1" "T1", tierWithin "T1" "T2", tierWithin "T1" "T3"])
      , ("T2", [tierWithin "T2" "T0", tierWithin "T2" "T1", tierWithin "T2" "T2", tierWithin "T2" "T3"])
      , ("T3", [tierWithin "T3" "T0", tierWithin "T3" "T1", tierWithin "T3" "T2", tierWithin "T3" "T3"])
      , ("garbage", [tierWithin "garbage" "T0", tierWithin "garbage" "T1", tierWithin "garbage" "T2", tierWithin "garbage" "T3"])
      , ("", [tierWithin "" "T0", tierWithin "" "T1", tierWithin "" "T2", tierWithin "" "T3"])
      ] := by rfl

theorem unknown_candidate_within_t3 : tierWithin "garbage" "T3" = true := by decide
theorem empty_candidate_within_t3 : tierWithin "" "T3" = true := by decide
theorem unknown_candidate_not_within_t2 : tierWithin "garbage" "T2" = false := by decide
theorem invalid_ceiling_authorizes_nothing (candidate : String) :
    tierWithin candidate "garbage" = false := by
  simp [tierWithin, validTier]

#print axioms unknown_candidate_within_t3
#print axioms tierWithin_full_cross_product
#print axioms empty_candidate_within_t3
#print axioms unknown_candidate_not_within_t2
#print axioms invalid_ceiling_authorizes_nothing

end WorkbenchLaws.Verdict
