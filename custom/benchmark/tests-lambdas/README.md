# tests-lambdas

Closure/lambda micro-benchmarks. Each CFM isolates one cost area from the closure invocation hot path so JFR and ABBA runs can pin where time/allocation actually lands.

Designed against the [closure-lambda-microbench](../../../../lucee-projects/runtime/lambas/closure-lambda-microbench.md) spec. Companion specs:

- [closure-lambda-predicate-parity](../../../../lucee-projects/runtime/lambas/closure-lambda-predicate-parity.md) — perf-neutral parity fix
- [closure-lambda-synthetic-name-suppression](../../../../lucee-projects/runtime/lambas/closure-lambda-synthetic-name-suppression.md) — source of the deep-dive items these benches target

## Workloads

| CFM | What it measures |
| --- | --- |
| `lambda-arraymap-trivial.cfm` | Non-capturing `(x)=>x*2` over 1k — per-call EnvUDF machinery |
| `lambda-arraymap-captured.cfm` | `(x)=>x*m` — ScopeFactory pool defeat (setBind blocks recycle) |
| `lambda-arraymap-function.cfm` | `function(x){...}` literal — parser-path control |
| `lambda-arraymap-named.cfm` | Named UDF on singleton CFC — closure-free floor (UDFImpl path) |
| `lambda-arraymap-parallel-short.cfm` | Trivial body + parallel=true — ExecutorService create/teardown cost |
| `lambda-arraymap-parallel-heavy.cfm` | 100-iter inner body + parallel=true — control case for parallel wins |
| `lambda-arraymap-heavy-seq.cfm` | Sequential pair for parallel-heavy |
| `lambda-construct-loop.cfm` | 100 Lambda allocations per cycle, no invocation |
| `lambda-nested-closure.cfm` | 3-deep capture chain — ClosureScope depth |
| `lambda-stack-trace-render.cfm` | 8-frame throw + tagContext format — frame.function rendering cost |

Comparison pairs that produce useful ratios:

- `trivial` vs `named` → lambda overhead delta vs UDFImpl floor
- `captured` vs `trivial` → scope-capture cost
- `function` vs `trivial` → parser-path delta (should be ~zero, runtime is identical)
- `parallel-heavy` vs `heavy-seq` → is parallel worth it for fat bodies
- `parallel-short` vs `trivial` → parallel overhead for short bodies (expected to lose badly)

## Setup

`Application.cfc` seeds at startup:

- `application.arr1k` — 1000 integers
- `application.arr100` — 100 integers
- `application.utils` — singleton CFC with `doubler()` and `heavyDoubler()` named methods

Per-cycle work targets ~50-500µs so the harness's default 25k cycles stays in the seconds range.

## Running

Runner scripts live in `D:\work\lucee-testlab\test-output\benchmark-lambdas\`. Smoke:

```cmd
cd D:\work\lucee-testlab\test-output\benchmark-lambdas
.\run-smoke.bat
```

`run-smoke.bat` defaults to `BENCHMARK_FILTER=lambda-arraymap-trivial` with 1k cycles. Args:

```cmd
.\run-smoke.bat [filter] [cycles-k] [once-cycles-k]
.\run-smoke.bat lambda-arraymap- 25 10        REM full suite, production cycle counts
.\run-smoke.bat lambda-construct-loop 5 5     REM single workload, moderate cycles
```

Output goes to `smoke-<filter>.txt` in the same dir. Look for `Finished <suite>` lines for per-bench timing and `->` markers for service skips.

For ABBA / JFR runs against a branch, model new bat files on `..\benchmark-redis\run-abba-pr16.bat` and `..\benchmark-redis\run-jfr-pr16.bat`. Point `-DluceeJar` at a local `loader\target\lucee-*.jar` for branch comparisons; the default `-DluceeVersion=7.1/snapshot/light` pulls the published snapshot.

## Interpreting results

The harness runs each CFM under two `inspectTemplate` modes (`once` then `never`) — `never` is faster because the per-call inspect check is skipped. Compare like-with-like (never vs never, once vs once) when ABBA-ing.

Don't compare numbers across workloads — `trivial` and `construct-loop` do different things. Each workload's number is meaningful against its own A/B variant only.

`BENCHMARK_CYCLES` and `BENCHMARK_ONCE_CYCLES` are in **thousands** (CYCLES=1 = 1000 runs). `BENCHMARK_WARMUP_CYCLES` is raw count.

## Why each bench exists

The synthetic-name-suppression spec's "Deep dive: closure invocation hot path" catalogues ~10 perf opportunities in cohabiting code that nobody has measured. These benches give JFR signal to rank-order them. Spec proper is ~neutral on perf — the wins are in follow-up tickets the benches will inform.
