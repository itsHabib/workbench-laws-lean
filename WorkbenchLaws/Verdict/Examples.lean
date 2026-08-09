import WorkbenchLaws.Verdict.Reduce

namespace WorkbenchLaws.Verdict.Examples
open WorkbenchLaws.Verdict

def raw (producer decision tier source : String) : RawVerdict :=
  { producer, decision, tier, source }

def valid (producer : ProducerClass) (decision : Decision) (tier source : String) : ValidVerdict :=
  { producer, decision, tier, source }

-- verify_test.go:206-217, with the judgment override attempt retained.
example : (reduce [raw "code" "block" "T0" "readiness",
                   raw "judgment" "pass" "T0" "operator"]) =
    .ok { decision := .block, tier := "T0" } := by rfl

-- verify_test.go:167-190: no floor, including judgment pass, never passes.
example : (reduce []) = .ok { decision := .escalate, tier := "T0" } := by rfl
example : (reduce [raw "local" "pass" "T0" "review-consolidation",
                   raw "judgment" "pass" "T0" "operator"]) =
    .ok { decision := .escalate, tier := "T0" } := by rfl

-- verify_test.go:73-80: local block is a structural refusal.
example : (reduce [raw "local" "block" "T0" "review-consolidation"]) =
    .error .localBlock := by rfl

-- verify_test.go:138-160: unknown producer and decision are refused.
example : (reduce [raw "remote-model" "pass" "T0" "mystery"]) =
    .error .unknownProducer := by rfl
example : (reduce [raw "code" "" "T0" "readiness"]) =
    .error .unknownDecision := by rfl

-- Review-required ordered multi-invalid fixtures: first invalid wins.
example : validate [raw "code" "approved" "T0" "first",
                    raw "remote-model" "pass" "T0" "second"] =
    .error .unknownDecision := by rfl
example : validate [raw "remote-model" "pass" "T0" "first",
                    raw "code" "approved" "T0" "second"] =
    .error .unknownProducer := by rfl

-- Any non-ci-classify source, including an arbitrary string, is a floor.
example : reduce [raw "code" "pass" "T0" "arbitrary-source"] =
    .ok { decision := .pass, tier := "T0" } := by rfl

-- Code-block dominance is source-blind, including the enrichment source.
example : reduce [raw "code" "block" "T0" "ci-classify"] =
    .ok { decision := .block, tier := "T0" } := by rfl

-- verify_test.go:785-798 plus the review-required rank-tie pair.
example : reduce [raw "code" "pass" "garbage" "triage-floor"] =
    .ok { decision := .pass, tier := "garbage" } := by rfl
example : reduce [raw "code" "pass" "T3" "readiness",
                  raw "code" "pass" "garbage" "triage-floor"] =
    .ok { decision := .pass, tier := "T3" } := by rfl
example : reduce [raw "code" "pass" "garbage" "triage-floor",
                  raw "code" "pass" "T3" "readiness"] =
    .ok { decision := .pass, tier := "garbage" } := by rfl

-- Empty is an unknown tier string and therefore also has rank 3.
example : reduce [raw "code" "pass" "" "readiness"] =
    .ok { decision := .pass, tier := "" } := by rfl

end WorkbenchLaws.Verdict.Examples
