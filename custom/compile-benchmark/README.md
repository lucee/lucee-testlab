# CFML Compile Benchmark

Measures CFML compilation time across major open-source codebases.

## Prerequisites

- Java 11+
- Ant
- script-runner (`D:/work/script-runner`)

## Building Lucee (LDEV-5832 branch)

```bash
cd /d/work/lucee7.1 && ant -f loader/build.xml fast
```

Output JAR: `D:/work/lucee7.1/loader/target/lucee-7.1.0.9-ALPHA.jar`

## Usage

**Important:** Run from `/d/work` directory, use forward slashes in paths.

### Basic run (all codebases) with published Lucee

```bash
cd /d/work && ant -buildfile "D:/work/script-runner/build.xml" \
  -DluceeVersion="7.1.0.9-ALPHA" \
  -Dwebroot="D:/work/lucee-testlab/custom/compile-benchmark" \
  -Dexecute="index.cfm" \
  -DpreCleanup=true \
  2>&1 | tee /d/work/lucee-testlab/custom/compile-benchmark/test-output/run-published.txt
```

### Using local build

```bash
cd /d/work && ant -buildfile "D:/work/script-runner/build.xml" \
  -DluceeJar="D:/work/lucee7.1/loader/target/lucee-7.1.0.9-ALPHA.jar" \
  -Dwebroot="D:/work/lucee-testlab/custom/compile-benchmark" \
  -Dexecute="index.cfm" \
  -DpreCleanup=true \
  2>&1 | tee /d/work/lucee-testlab/custom/compile-benchmark/test-output/run-local.txt
```

### Filter to specific codebase

Use `COMPILE_FILTER` env var to compile only matching codebases:

```bash
cd /d/work && COMPILE_FILTER=lucee-docs ant -buildfile "D:/work/script-runner/build.xml" \
  -DluceeVersion="7.1.0.9-ALPHA" \
  -Dwebroot="D:/work/lucee-testlab/custom/compile-benchmark" \
  -Dexecute="index.cfm" \
  -DpreCleanup=true \
  2>&1 | tee /d/work/lucee-testlab/custom/compile-benchmark/test-output/run-lucee-docs.txt
```

Available filters: `lucee-docs`, `MasaCMS`, `Preside`, `coldbox-platform`, `commandbox-src`, `TestBox`, `wheels`

### With JFR profiling

```bash
cd /d/work && COMPILE_FILTER=MasaCMS ant -buildfile "D:/work/script-runner/build.xml" \
  -DluceeJar="D:/work/lucee7.1/loader/target/lucee-7.1.0.9-ALPHA.jar" \
  -Dwebroot="D:/work/lucee-testlab/custom/compile-benchmark" \
  -Dexecute="index.cfm" \
  -DpreCleanup=true \
  -DFlightRecording=true \
  -DFlightRecordingSettings="D:/work/lucee-testlab/custom/compile-benchmark/bytecode-profile.jfc" \
  2>&1 | tee /d/work/lucee-testlab/custom/compile-benchmark/test-output/jfr-run.txt
```

JFR output path is printed in the run output.

## Analyzing JFR output

```bash
jfr print --events jdk.ExecutionSample recording.jfr | grep -A20 "lucee.transformer"
```

## Projects Benchmarked

| Project | Files | Notes |
|---------|-------|-------|
| coldbox-platform | ~1,077 | MVC framework |
| commandbox-src | ~415 | CLI tool |
| lucee-docs | ~128 | Documentation site |
| MasaCMS | ~1,007 | CMS |
| Preside-CMS | ~2,691 | Enterprise CMS |
| TestBox | ~166 | Testing framework |
| wheels | ~1,213 | MVC framework |

## Results Storage

Results are saved to `results/` as JSON files named `{version}-{timestamp}.json`.
Test output goes to `test-output/` (gitignored).
