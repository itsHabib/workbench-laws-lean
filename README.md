# Workbench Gate verdict laws (Lean Phase 0)

This is an independent Lean 4 model of a narrow slice of Gate at Workbench
commit `6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1`. It proves laws of the model;
it is not production authority and nothing consumes its output to permit a
merge.

## Build

Lean and Lake are pinned by `lean-toolchain`; Mathlib is not used.

```sh
lake build
```

The model, proofs, and frozen examples live under `WorkbenchLaws/Verdict`.
The experiment result is in `docs/report.md`; provenance and conformance
boundaries are in `docs/source-map.md` and `docs/source-map.json`.
