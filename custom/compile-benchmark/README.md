# CFML Compile Benchmark

Measures CFML compilation time across major open-source codebases via `admin action=compileMapping`. Same corpus (~11,624 files across 12 projects) is compiled per invocation and the per-project + total timings are recorded in JSON.

The primary way to run this is via **`compile-bench.sh`** at `/d/work/lucee8/test-output/jfr/`, which handles the paired base+build capture + JFR slicing + jfrblaster pair-diff + README generation for you. Ad-hoc single-jar invocation is documented below for cases where you don't have a baseline (e.g. one-off profiling).

## Prerequisites

- JDK 25 (`C:\Program Files\Eclipse Adoptium\jdk-25.0.3.9-hotspot`)
- Ant
- script-runner (`D:/work/script-runner`)
- For paired workflow: existing baseline dir under `/d/work/lucee8/test-output/jfr/<VER>-<basetag>/` containing `lucee-<VER>.jar`

## Building Lucee

```bash
cd /d/work/lucee8/loader && ant fast
```

Output JAR: `D:/work/lucee8/loader/target/lucee-<version>.jar` (`compile-bench.sh` rebuilds this for you).

## Paired workflow (the main path)

```bash
# Bare-metal on Windows — subject to host thermal + I/O noise
/d/work/lucee8/test-output/jfr/compile-bench.sh <tag> <baseline-tag>

# Same runs, but inside a Linux container to isolate from Windows noise.
# Also runs the bytecode-equivalence check (BytecodeCompare.cfc) automatically.
USE_DOCKER=1 /d/work/lucee8/test-output/jfr/compile-bench.sh <tag> <baseline-tag>

# Halve wall time by skipping the no-JFR sides (JFR-only pair-diff still works)
USE_DOCKER=1 SKIP_NOJFR=1 /d/work/lucee8/test-output/jfr/compile-bench.sh <tag> <baseline-tag>
```

Both modes produce the same artifacts under `/d/work/lucee8/test-output/jfr/<VER>-<tag>/`:

- `base-lucee-compile-j25.jfr` + `.txt` + `-slice.jfr` — baseline JFR + run log + JFR sliced to its compile window
- `lucee-compile-j25.jfr` + `.txt` + `-slice.jfr` — build-side equivalents
- `lucee-compile-j25-slice-pair-diff.txt` — jfrblaster pair-diff output
- `README.md` — formatted report (also mirrored to `test-output/jfr/LATEST.md`)
- `working-copy.diff` — `git diff -- '*.java'` at capture time
- `lucee-<VER>.jar` — build jar copied into the archive
- `docker-log.txt` — (USE_DOCKER=1 only) progressive per-step log written live during the run
- `bytecode-check.txt` — (USE_DOCKER=1 only) ASM-based bytecode-equivalence report

The docker testbed at `/d/testbeds/compile-benchmark/` bakes all 12 codebases into a Linux image so bind-mount I/O jitter doesn't skew timings. See its README for build instructions.

## Ad-hoc single-jar invocation

For quick smoke runs or profiling without a baseline:

```bash
VER=8.0.0.169-SNAPSHOT
cd /d/work && JAVA_HOME='C:\Program Files\Eclipse Adoptium\jdk-25.0.3.9-hotspot' \
  ant -buildfile "D:/work/script-runner/build.xml" \
  -DluceeJar="D:/work/lucee8/loader/target/lucee-${VER}.jar" \
  -Dwebroot="D:/work/lucee-testlab/custom/compile-benchmark" \
  -Dexecute="index.cfm" -DpreCleanup=true \
  2>&1 | tee D:/work/lucee-testlab/custom/compile-benchmark/test-output/run.txt
```

Add JFR:

```bash
  -DFlightRecording=true \
  -DFlightRecordingSettings="./compile-cold.jfc"
```

JFR lands at `D:/work/script-runner/logs/<TIMESTAMP>-j25.jfr` — you copy it into the archive dir yourself.

Filter to a single codebase (fast iteration):

```bash
COMPILE_FILTER=MasaCMS ant ...
```

The docker testbed accepts the same env vars via `./run.sh --jar <path> --tag <tag> --filter MasaCMS`.

Available filter names: `coldbox-platform`, `commandbox-src`, `MasaCMS`, `Preside-CMS`, `TestBox`, `wheels`, `lucee-context`, `lucee-spreadsheet`, `lucee-docs`, `lucee-data-provider`, `lucee-test`, `lucee-ast-samples`.

## Projects benchmarked

| Project | Files (cfm+cfc) | Notes |
|---------|-------|-------|
| coldbox-platform | ~1,089 | MVC framework |
| commandbox-src | ~415 | CLI tool |
| MasaCMS | ~1,007 | CMS |
| Preside-CMS | ~2,692 | Enterprise CMS |
| TestBox | ~208 | Testing framework (docker warmup target) |
| wheels | ~1,679 | MVC framework |
| lucee-context | ~201 | Lucee built-in context |
| lucee-spreadsheet | ~314 | Extension |
| lucee-docs | ~134 | Documentation site |
| lucee-data-provider | ~84 | Data provider extension |
| lucee-test | ~3,712 | Lucee's own test suite |
| lucee-ast-samples | ~89 | Edge-case parser fixtures |
| **TOTAL** | **~11,624** | |

## Notes

- **JDK 25 only.** JDK 21 gives a different JFR profile and different timings.
- **Alloc metrics are more stable than wall-clock** (~15-20% variance run-to-run). Lead with `jfrblaster pair-diff` and `inline-report` against alloc/exec-sample movers rather than the `duration` column in the JSON summary.
- **`compile-bench.sh` docker mode adds a warmup + 5s steady-state sleep** before the real bench — closer to bare-metal thermal state at run start.
- **OS page-cache pre-warm runs before every bench (default on).** `index.cfm` parallel-reads every corpus source via `arrayEach(files, fileReadBinary, true)` before the 3s startup sleep. ~170ms for 11,624 files on the docker path. Removes cold-cache read variance so first-run-of-session TOTALs match steady-state runs (empirically: 13.3s → 11.3s on the first full-corpus JFR run). Opt out with `COMPILE_WARMUP_CACHE=0` when you specifically want to measure cold-start behaviour instead of steady-state compile CPU/alloc. The warmup pass does not affect the cache-write path (writes go to a `preCleanup` fresh dir) — see `compile-io-and-lookups.md` for the split.
- **Bytecode-check runs automatically in docker mode** — the README's `Bytecode equivalence: ✓/✗` line surfaces any surprise changes to compile output.

## Results storage

JSON results per invocation: `results/<version>-<timestamp>.json` (host-local, gitignored under this dir).

JFR + full analysis archive: `D:/work/lucee8/test-output/jfr/<version>-<descriptor>/` (per bare-metal `compile-bench.sh` convention).

Test output: `test-output/` (gitignored).
