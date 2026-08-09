# TierWithin comparator and reachability

Rows are candidate tier strings; columns are validated grant ceilings. This is
the result of the modeled comparator, not a claim that every row is reachable
through current producer paths.

| Candidate | T0 | T1 | T2 | T3 |
|---|---:|---:|---:|---:|
| T0 | true | true | true | true |
| T1 | false | true | true | true |
| T2 | false | false | true | true |
| T3 | false | false | false | true |
| `garbage` | false | false | false | true |
| empty string | false | false | false | true |

The comparator result follows from `Grant.TierWithin`: it validates the
ceiling and compares ranks, but it does not validate the candidate
(`capability.go:140-148`). Unknown and empty candidates rank 3.

| Producer path | Current check at baseline | Unknown candidate reaches live run? |
|---|---|---|
| triage floor | `parseFloorOutput` rejects invalid tier (`verify/floor.go:15-27`) | No through this owned path |
| submitted judgment | `ValidateJudgment` requires a valid tier and ceiling bound (`verify/judge.go:203-208`) | No through this owned path |
| readiness | verdict pins `T0` (`verify/readiness.go:209-215`) | No through this owned path |
| ci-classify | verdict construction pins `T0` (`verify/ciclassify.go:369`) | No through this owned path |
| foreign or drifted artifact | reducer preserves unknown tier strings | This is the path required by the comparator row |

The two facts belong together: unknown/empty candidates compare within T3 at
the comparator, while current owned producer paths prevent those candidates
from reaching a live run. This report labels the semantics and reachability;
it does not label the behavior safe or exploitable.
