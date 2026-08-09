namespace WorkbenchLaws.Verdict

/-- The authority-relevant strings exactly as a foreign or drifted artifact
    presents them to Gate. Confidence and subject are intentionally outside the
    Phase-0 slice. -/
structure RawVerdict where
  producer : String
  decision : String
  tier : String
  source : String
  deriving DecidableEq, Repr

end WorkbenchLaws.Verdict
