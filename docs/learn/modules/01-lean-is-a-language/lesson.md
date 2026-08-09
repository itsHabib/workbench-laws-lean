# Module 1 — Lean is a programming language

**Prereqs:** Module 0 (you can give the 5-minute tour of this repo).
**Time:** ~25 min read, ~45 min exercises.
**Goal:** Before any logic, proofs, or type theory, see that Lean is a *typed
functional language you can already mostly read.* By the end you will have
walked the two core files of this project — `Domain.lean` and `Reduce.lean` —
as ordinary programs, and seen that `composedDecision` is nothing but Go's
`verify.Reduce` rewritten in a pure functional style.

Everything in this module is code that runs. There is not a single proof here.
We deliberately ignore every line that starts with `theorem` or `example` — that
is Module 2. Today Lean is just Elixir/Rust/Gleam with unfamiliar punctuation.

> **How to run the snippets.** From the repo root:
> ```
> export PATH="$HOME/.elan/bin:$PATH"
> lake build          # compiles the model AND this module's Solutions.lean
> ```
> Open `Exercises.lean` in an editor with the Lean extension to work
> interactively, or run one file directly:
> ```
> lake env lean docs/learn/modules/01-lean-is-a-language/Exercises.lean
> ```

---

## 0. Two commands that just run code

Lean has a REPL-ish facility built into the source file. Two commands do all the
work in this module:

- `#eval e` — evaluate `e` and print it. This is your `iex>` / `dbg!` / `fmt.Println`.
- `#guard e` — evaluate the boolean (or decidable) `e`; if it is not `true`, the
  **build fails**. It is a compile-time-checked assertion. Not a proof — it
  checks one concrete input, exactly like a table-test row. A proof checks *all*
  inputs at once, and that is Module 2's whole story.

You will see both throughout `Solutions.lean`, and every one of them is checked
when you run `lake build`. That is the point of wiring this module into the
build: the teaching code cannot silently rot.

```lean
#eval reduceValid [codeBlock, codePass]
#guard reduceValid [codeBlock, codePass] = { decision := .block, tier := "T2" }
```
*(both live in `Solutions.lean`, Exercise 1)*

---

## 1. `def` — a function

Open `WorkbenchLaws/Verdict/Domain.lean`. The very first function-ish thing is
`tierRank` at `Domain.lean:50`:

```lean
def tierRank : String → Nat
  | "T0" => 0
  | "T1" => 1
  | "T2" => 2
  | _ => 3
```

Read it in your own vocabulary:

- `def tierRank` — define a function named `tierRank`. Same as Go's `func`,
  Rust's `fn`, Elixir's `def`.
- `: String → Nat` — its type. Takes a `String`, returns a `Nat` (a
  non-negative integer — think `uint`). The arrow `→` is exactly `func(string) int`.
- The `| pattern => result` lines are a `match` written directly as the function
  body — like an Elixir multi-clause function head, or Rust's `match` sugar. `_`
  is the catch-all, same as Go's `default:` or Rust's `_`.

So `tierRank` is: match the string; T0/T1/T2 map to 0/1/2; **everything else** —
"T3", "garbage", the empty string — maps to 3. Run it:

```lean
#eval tierRank "T2"   -- 2
#eval tierRank "T3"   -- 3
#eval tierRank ""     -- 3
```

This is a faithful port of Gate's `tier.Rank` in Go. The comment at
`Domain.lean:48-49` records the design choice on purpose: the `_ => 3` bucket
deliberately swallows unknown tiers, and that fact becomes load-bearing much
later (Module 7's headline finding lives right here).

A `def` with an ordinary argument list looks like what you expect. From
`Reduce.lean:5`:

```lean
def isCodeBlock (v : ValidVerdict) : Bool :=
  v.producer == .code && v.decision == .block
```

`(v : ValidVerdict)` is a named parameter with its type — like `v ValidVerdict`
in Go. `.producer` is field access. `==` is structural equality. `&&` is
boolean and. The `.code` / `.block` are enum values (next section). Nothing here
would surprise you in Rust.

---

## 2. `inductive` — a sum type (your enum)

`Domain.lean:11`:

```lean
inductive Decision where
  | pass
  | escalate
  | block
  deriving DecidableEq, Repr
```

This is a **sum type**: a type that is exactly one of a fixed set of cases. You
know this shape cold:

| Lean | Rust | Gleam | Elixir (idiom) |
|------|------|-------|----------------|
| `inductive Decision` | `enum Decision` | `pub type Decision` | atoms `:pass` etc. |
| `\| pass` | `Pass,` | `Pass` | `:pass` |

`Decision` has three values: `Decision.pass`, `Decision.escalate`,
`Decision.block`. When Lean already knows the type from context you may drop the
prefix and write `.block` — that is the leading-dot shorthand you saw in
`isCodeBlock`. Same idea as Swift's `.block` or Rust letting you `use` the
variants.

`deriving DecidableEq, Repr` is `#[derive(PartialEq, Debug)]`. `DecidableEq`
gives you `==` and `=`; `Repr` gives you a printable form so `#eval` can show it.
(There is a deeper meaning to `DecidableEq` — it is *why* `#guard ... = ...`
works — but treat it as `derive(Eq)` for now.)

The file defines three of these enums back to back:

- `ProducerClass` (`Domain.lean:5`) — `code | local | judgment`. Who emitted the
  verdict. In Gate's Go these are string constants; the model makes them a
  closed sum so an unknown producer is *unrepresentable* rather than merely
  rejected at runtime.
- `Decision` (`Domain.lean:11`) — `pass | escalate | block`. The ladder's rungs.
- `Refusal` (`Domain.lean:17`) — `unknownProducer | unknownDecision | localBlock`.
  The three ways validation can reject an input. These mirror Go's
  `ErrUnknownProducer` / `ErrUnknownDecision` / `ErrLocalBlock` at
  `verify.go:83-95`.

A sum type is "OR": a `Decision` is pass **or** escalate **or** block. The next
section is "AND".

---

## 3. `structure` — a record (your struct)

`Domain.lean:23`:

```lean
structure ValidVerdict where
  producer : ProducerClass
  decision : Decision
  tier : String
  source : String
  deriving DecidableEq, Repr
```

A **product type**: a bundle of named fields, all present at once. This is a Go
`struct`, a Rust `struct { }`, a Gleam record. A `ValidVerdict` *is* a producer
**and** a decision **and** a tier **and** a source.

Construct one with brace syntax; access fields with a dot:

```lean
def codeBlock : ValidVerdict :=
  { producer := .code, decision := .block, tier := "T0", source := "readiness" }

#eval codeBlock.decision   -- Decision.block
```

`:=` is assignment (Lean uses `:=` for "is defined as", and `=` for the
proposition "these are equal" — keep them distinct; more in Module 3). Field
punning works: if you have local values named `producer`, `decision`, etc., you
can write `{ producer, decision, tier, source }` and Lean fills each field from
the like-named value. That is exactly what the fixture helper does
(`Examples.lean:9`, and `Learn.valid` in `Solutions.lean`):

```lean
def valid (producer : ProducerClass) (decision : Decision)
    (tier source : String) : ValidVerdict :=
  { producer, decision, tier, source }
```

The other record in the file is the *output* type, `ComposedVerdict`
(`Domain.lean:30`): just a `decision` and a `tier` — what the whole reduction
boils a list of verdicts down to.

`RawVerdict` (`Raw.lean:6`) is a third record — four `String` fields — modeling a
verdict *exactly as an untrusted artifact presents it*, before any parsing. The
whole pipeline is `RawVerdict` (strings) → validate → `ValidVerdict` (typed) →
reduce → `ComposedVerdict`.

---

## 4. Pattern matching + `Option` (your `(T, ok)` / `Result`)

`Domain.lean:36`:

```lean
def parseProducer : String → Option ProducerClass
  | "code" => some .code
  | "local" => some .local
  | "judgment" => some .judgment
  | _ => none
```

Two things here. First, the `match`-as-body over the string, same as `tierRank`.

Second, the return type `Option ProducerClass`. **`Option` is how a total
function says "maybe no answer"** — the parse might fail. You know this type
under other names:

| Lean | Rust | Go | Gleam | Elixir |
|------|------|----|-------|--------|
| `Option T` | `Option<T>` | `(T, bool)` / `(T, error)` | `Option(t)` | `{:ok, t}`/`:error` |
| `some x` | `Some(x)` | `x, true` | `Some(x)` | `{:ok, x}` |
| `none` | `None` | `zero, false` | `None` | `:error` |

`Option` is itself just an `inductive` in the standard library — `some x | none`
— so you already understand its definition. `parseProducer "code"` is
`some ProducerClass.code`; `parseProducer "remote-model"` is `none`. Run it:

```lean
#eval parseProducer "judgment"   -- some (WorkbenchLaws.Verdict.ProducerClass.judgment)
#eval parseProducer "nope"       -- none
```

`parseDecision` (`Domain.lean:42`) is the identical shape for decisions. These
two are Gate's fail-closed string checks made total: an unrecognized string
yields `none`, and the caller must handle it — the type system will not let you
forget, the way an ignored Go `error` can slip through.

`.isSome` / `.isNone` collapse an `Option` back to a `Bool` when you only care
whether it succeeded. Exercise 5 uses that to show `knownDecision d` and
`(parseDecision d).isSome` agree on every string.

---

## 5. `List` operations (your `Enum` / iterators)

Gate reduces a *slice* of verdicts. The model reduces a `List`. `List` ops in
Lean read like Elixir's `Enum` or Rust's iterator adapters. The model uses four,
all in `Reduce.lean`:

- `.any p` — is `p` true for any element? `Reduce.lean:15`:
  ```lean
  def hasCodeBlock (vs : List ValidVerdict) : Bool := vs.any isCodeBlock
  ```
  This is `Enum.any?/2`, Rust's `.iter().any(...)`, Go's `for … { if … return true }`.
- `.filter p` — keep the elements matching `p`. `Reduce.lean:20` filters to
  judgment verdicts.
- `.getLast?` — the last element as an `Option` (empty list → `none`). The `?`
  suffix is a naming convention for "returns Option". `Reduce.lean:20-21`:
  ```lean
  def lastJudgmentDecision (vs : List ValidVerdict) : Option Decision :=
    ((vs.filter isJudgment).getLast?).map (·.decision)
  ```
  Read right to left: filter to judgments, take the last one (maybe none),
  `.map` over the `Option` to pull out its `.decision`. `(·.decision)` is a
  point-free lambda — `·` is the anonymous argument, so it means
  `fun v => v.decision`. This is the model's "**last judgment wins**", the pure
  version of Go overwriting a `judged *Verdict` pointer each loop iteration
  (`verify.go:155-157`).
- `.foldl f init` — left fold / reduce. This is the important one; it gets its
  own section next.

`List` literals are `[a, b, c]`, and `++` concatenates. `[]` is the empty list.

---

## 6. The fold: where Go's mutation went

Here is the heart of the side-by-side. Gate builds the composed tier by
**mutating an accumulator** in a loop. `verify.go:142-144`:

```go
if tierRank(v.Tier) > tierRank(out.Tier) {
    out.Tier = v.Tier
}
```

`out.Tier` starts at `"T0"` (`verify.go:115`) and is reassigned in place as the
loop finds a strictly-higher-ranked tier. A pure functional language has no
"reassign in place." The same computation becomes a **fold** — you thread the
accumulator through explicitly instead of mutating it. `Reduce.lean:23-28`:

```lean
def chooseHigherTier (current candidate : String) : String :=
  if tierRank candidate > tierRank current then candidate else current

def composedTier (vs : List ValidVerdict) : String :=
  vs.foldl (fun current v => chooseHigherTier current v.tier) "T0"
```

Line these up:

| Go (`verify.go`) | Lean (`Reduce.lean`) |
|------------------|----------------------|
| `out.Tier = "T0"` initial | `"T0"` — the fold's seed |
| `for _, v := range verdicts` | `vs.foldl (fun current v => …)` |
| `if tierRank(v.Tier) > tierRank(out.Tier)` | `if tierRank candidate > tierRank current` |
| `out.Tier = v.Tier` (else: keep) | `then candidate else current` |

`foldl f seed` starts at `seed` and, for each element, replaces the accumulator
with `f accumulator element`. The seed `"T0"` is Go's initial `out.Tier`. The
lambda is Go's loop body. `chooseHigherTier` is Go's `if`. The mutation didn't
disappear — it turned into *the value the fold carries from one step to the
next.* Every mutable-accumulator loop you have ever written is a fold in
disguise; Lean just makes you say so.

The **strictly-greater** comparison (`>`, not `≥`) matters: at a rank tie the
first spelling is retained (comment at `Reduce.lean:26`). Hold that thought —
it is the exact spot Module 7's bug hides.

---

## 7. `composedDecision` is `verify.Reduce`, pure

Now the decision itself, `Reduce.lean:30-37`:

```lean
def composedDecision (vs : List ValidVerdict) : Decision :=
  if hasCodeBlock vs then
    .block
  else if !hasFloor vs then
    .escalate
  else match lastJudgmentDecision vs with
    | some d => d
    | none => if hasEscalation vs then .escalate else .pass
```

Read it as a precedence cascade — and compare with Go's `Reduce`,
`verify.go:109-188`, whose *return statements* encode the same ladder:

1. **A code block dominates.** `if hasCodeBlock vs then .block`.
   Go: the `out.Decision == DecisionBlock` early return at `verify.go:164-167`
   (set at :148-149).
2. **No floor → escalate, never pass.** `else if !hasFloor vs then .escalate`.
   Go: `if !hasCode { out.Decision = DecisionEscalate; … }` at `verify.go:172-176`.
   The comment there — "a judgment pass must not be able to launder a missing
   floor" — is why this branch sits *above* the judgment branch in both.
3. **Otherwise the last judgment wins, if any.** `match lastJudgmentDecision vs`.
   Go: `if judged != nil { out.Decision = judged.Decision; … }` at
   `verify.go:177-181`.
4. **No judgment: escalate if anything escalated, else pass.**
   `if hasEscalation vs then .escalate else .pass`.
   Go: the `len(escalations) > 0` check and the final `all verifiers pass` at
   `verify.go:182-188`.

Same ladder, same order, same fail-closed precedence — one written as mutate-and-
early-return, the other as a nested `if/else` expression that *evaluates to* a
`Decision`. Note the honesty boundary: the Lean version drops Go's `Why` strings,
`Confidence`, and `Subject` (they are outside the Phase-0 slice, per
`Raw.lean:3-5`). The model captures the *authorization-relevant* computation, not
every field Gate carries. That gap is deliberate, and Module 8 is entirely about
what it does and does not let you conclude.

`reduceValid` (`Reduce.lean:39`) just packages the two together:

```lean
def reduceValid (vs : List ValidVerdict) : ComposedVerdict :=
  { decision := composedDecision vs, tier := composedTier vs }
```

Run the whole thing:

```lean
#eval reduceValid [codeBlock, codePass]
-- { decision := block, tier := "T2" }
```

A code block dominates the decision; "T2" (rank 2) beats "T0" (rank 0) for the
tier. That is Exercise 1.

---

## 8. `Except` — the pipeline's `(T, error)`

One type is left. Validation can *fail*, and it reports *which* failure. That is
`Except`, Lean's `Result`. `Validate.lean:6`:

```lean
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
```

`Except E A` is "an `A`, or an error `E`" — precisely Rust's `Result<A, E>` and
Go's `(A, error)`:

| Lean | Rust | Go |
|------|------|----|
| `Except Refusal ValidVerdict` | `Result<ValidVerdict, Refusal>` | `(ValidVerdict, error)` |
| `return x` / `pure x` | `Ok(x)` | `return x, nil` |
| `throw e` | `Err(e)` / `return Err(e)` | `return zero, e` |

The `do` / `←` / `throw` is `do`-notation — the same ergonomic sugar as Rust's
`?` operator or Elixir's `with`. `let producer ← …` means "run this fallible
step; if it threw, short-circuit and propagate the error; otherwise bind the
success value to `producer`." So `validateOne` checks producer, then decision,
then the local-block rule **in that order**, and the *first* failure wins — which
is exactly Go's ordered guard clauses at `verify.go:122-131`. The comment at
`Validate.lean:5` says so out loud: "Checks one verdict in Go's exact order."

`validate` (`Validate.lean:18-23`) walks the whole list with the same `do`-block,
and `reduce` (`Reduce.lean:42-44`) chains validate-then-reduce:

```lean
def reduce (raws : List RawVerdict) : Except Refusal ComposedVerdict := do
  return reduceValid (← validate raws)
```

`(← validate raws)` runs the fallible validation and, on success, feeds the typed
list into `reduceValid`. On failure the whole `reduce` returns that `Refusal`.
This is the model's complete top-level entry point — strings in, either a
`ComposedVerdict` or a `Refusal` out — and it is a pure function with no I/O, no
mutation, no globals.

---

## 9. What you can now read

That is the entire program. Concretely, you can now read — as code —
`Raw.lean`, `Domain.lean`, `Validate.lean`, and `Reduce.lean` end to end, minus
the `PermutationDomain` definition at `Reduce.lean:53` (that `Prop` is Module 2).
Files `Examples.lean`, `Laws.lean`, `NegativeControls.lean`, and `TierWithin.lean`
are the *proofs* — skip them entirely for now, except to notice that each
`example`/`theorem` mentions functions you now understand.

One caveat to carry forward (the honesty thread): running `#eval` and passing
`#guard` tells you the model behaves correctly *on the inputs you tried*. It is a
test, at one point. The reason this project exists — the reason it is Lean and
not just a Go test suite — is the ability to state a claim over *all* inputs and
have it checked. None of that is in this module. Today's win is smaller and
real: the verified code is not a foreign artifact. It is a functional program in
a language you can read.

---

## Exercises

In `Exercises.lean` (fill the `sorry` holes) with answers in `Solutions.lean`.
Grading: T = trivial, R = real, S = optional stretch.

1. **(T)** Predict the `decision` and `tier` for `reduceValid [codeBlock, codePass]`,
   then `#eval` to check.
2. **(T)** Fill the one-line body of `isBlock (d : Decision) : Bool`.
3. **(T)** Predict the output of `reduceValid [codePass, escT3]` (mind `tierRank`
   of "T3"), then run it.
4. **(R)** Write `countEscalations : List ValidVerdict → Nat` using `List.filter`
   + `List.length` (or a `foldl`). `isEscalation` already exists at `Reduce.lean:11`.
5. **(R)** Port Go's `knownDecision` (`verify.go:77-79`) as `String → Bool`.
   Confirm with `#guard` that `""` returns `false` (fail closed) and that it
   agrees with `(parseDecision d).isSome`.
6. **(S, optional)** Rewrite `hasFloor` as an explicit `foldl` over a running
   `Bool` (`hasFloorFold`), mirroring Go's `hasCode` accumulator, and `#guard`
   it agrees with the library's `.any` version on samples.

Done-check: `lake build` is green (it compiles `Solutions.lean`, including every
`#guard`).

---

## Glossary

- **`def`** — defines a function or value. Go `func`, Rust `fn`, Elixir `def`.
- **`inductive`** — a sum type: a value is exactly one of a fixed set of cases.
  Rust `enum`, Gleam custom type. `Option` and `Except` are themselves inductives.
- **`structure`** — a product type / record: named fields all present at once.
  Go/Rust `struct`, Gleam record.
- **sum type / product type** — "OR of cases" vs "AND of fields." `inductive` vs
  `structure`.
- **pattern matching (`| pat => …`)** — dispatch on a value's shape; `_` is the
  catch-all. Rust `match`, Elixir multi-clause heads.
- **`Option T`** — a `T` or nothing (`some x` / `none`). Rust `Option<T>`, Go's
  `(T, bool)`, Elixir `{:ok, x} | :error`.
- **`Except E A`** — an `A` or an error `E` (`return`/`pure` vs `throw`). Rust
  `Result<A, E>`, Go `(A, error)`.
- **`do` / `←` / `throw`** — do-notation: sequence fallible steps, short-circuit
  on the first error. Rust's `?`, Elixir's `with`.
- **`.any` / `.filter` / `.getLast?` / `.map`** — `List` operations. Elixir
  `Enum`, Rust iterator adapters. A trailing `?` in a name signals an `Option`
  result.
- **`foldl f seed`** — left fold: thread an accumulator through the list. The
  pure-functional form of a mutable-accumulator loop.
- **`·` (centered dot)** — anonymous-argument lambda: `(·.decision)` is
  `fun v => v.decision`.
- **`:=` vs `=`** — `:=` is "is defined as" (assignment); `=` is the proposition
  "these are equal." Kept distinct on purpose (Module 3).
- **`#eval`** — evaluate and print an expression. The REPL.
- **`#guard`** — evaluate a boolean/decidable expression and fail the build if it
  is not true. A compile-time-checked assertion at one input — a test, not a proof.
- **`deriving DecidableEq, Repr`** — auto-generate equality and a printable form.
  Rust `#[derive(PartialEq, Debug)]`.
