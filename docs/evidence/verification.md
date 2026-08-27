# Verification record

Date: 2026-08-08

Baseline source:

- Workbench path: the [workbench repository](https://github.com/itsHabib/workbench)
- Exact commit: `6eee6aa63ff0d7bcaf127b9cdf4f5af748659ac1`
- The live checkout resolved to that same commit during source archaeology.

Toolchain:

- Lean `4.32.2`, commit `f3b06c705e6c85f5314019d5d3baab0fec5b580c`
- Lake `5.0.0-src+f3b06c7`
- No external Lake dependencies and no Mathlib

Checks:

```text
lake clean
lake build
jq empty testdata/verdict-cases.json docs/source-map.json
rg -n '\b(sorry|admit|axiom)\b' --glob '*.lean' .
```

Expected result: the build completes all jobs; both JSON documents parse; the
proof-hole/project-axiom scan returns no matches. The detailed `#print axioms`
output is recorded in `axioms.txt`.
