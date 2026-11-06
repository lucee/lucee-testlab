# tests-json-deserialize

`deserializeJSON` parse-path micro-benchmarks, one axis per CFM. The mirror of [tests-json-serialize](../tests-json-serialize/README.md): every `des-` cell whose name matches a `ser-` cell parses exactly the bytes that cell emits, so the two families read as pairs on one payload.

Designed against [spec-json-number-literal-bigdecimal-detour](../../../../lucee-projects/perf/8.0/spec-json-number-literal-bigdecimal-detour.md). Sibling: [tests-json](../tests-json/), 20 shape-based parse cells from the earlier deserialize pass (the one that won `big` +37.9%). Correctness twin in the Lucee repo: `test/functions/DeSerializeJSON.cfc`.

## Why this family exists

`tests-json` covers parse cost by **document shape**: single values, flat, nested, JSON5 surface, big. It has no cell that isolates the **number literal**, and none that is byte-for-byte paired with a serialize cell. Both are what the BigDecimal-detour spec needs.

The target is `CFMLExpressionInterpreter.number()` and the `LNumber` it returns. Every JSON number today goes `String → BigDecimal(DECIMAL128) → LNumber → getValue(): AC lookup → BigDecimal.doubleValue() → Double`, five allocations and a decimal parse to land where `Double.parseDouble` lands in one, and precise math is off by default. The interpreter already resolved `preciseMath` once at `interpret()`; the literal is the one node that ignores it.

| Change under test | Scales with | Cell that maximises it |
| --- | --- | --- |
| Build a `Double` in `number()` when `!preciseMath`, skip `BigDecimal` | number-literal **count** | `des-numbers-int` |
| Drop the per-literal `ThreadLocalPageContext.preciseMath(pc)` in `getValue` | literal count, doubled for negatives (`Negate` looks it up again) | `des-numbers-int`, `des-numbers-negative` |
| No `BigInteger` above 18 digits | **digit count** per literal | `des-numbers-long-digits` |
| Fractional / exponent branches of `number()` | literal shape | `des-numbers-decimal`, `des-numbers-exponent` |

Anything that touches `string()` instead shows up in the two long-strings cells, which are controls here.

## Cells

| CFM | Axis |
| --- | --- |
| `des-numbers-int.cfm` | **headline** — 1000 small integers, nothing else in the document. Byte-identical to `ser-numbers-array` output |
| `des-numbers-quoted.cfm` | **control** — the same 1000 digit runs, quoted, so every value takes `string()` and `number()` is never entered. Exists to be unchanged |
| `des-numbers-negative.cfm` | A/B partner for `-int` — same integers negated, so each literal is wrapped in a `Negate` ref with its own `preciseMath` lookup and `toDoubleValue` |
| `des-numbers-decimal.cfm` | same integer parts with a fixed 5-digit fraction — the scaled `BigDecimal` parse, the shape prices and scores have |
| `des-numbers-long-digits.cfm` | 1000 25-digit integers — above `BigDecimal`'s 18-digit compact `long`, below `DECIMAL128`'s 34, so every literal carries a `BigInteger`. `parseDouble` has no such cliff |
| `des-numbers-exponent.cfm` | `i.5e3` — the exponent branch, negative scale undone in `doubleValue()`. Coverage, not expected to matter |
| `des-wide-struct-200.cfm` | 200 short keys, integer values — half keys, half literals, the realistic mix. Byte-identical to `ser-wide-struct-200` output |
| `des-long-strings-clean.cfm` | 10 keys, ~4KB pure-ASCII values, zero numbers — **second control**, and the char-count headline for `string()`. Pairs with `ser-long-strings-clean` |
| `des-long-strings-escaped.cfm` | same shape, one char in three a backslash escape — `string()`'s `isNext()` ladder. Pairs with `ser-long-strings-escaped` |
| `des-api-response.cfm` | realistic ~830-byte mixed document. Pairs with `ser-api-response` **and** `tests-json/deserialize-api-response` at matched loop count |
| `des-big.cfm` | ~41KB, 500 records, 1000 numbers + 1000 strings + 2500 keys per parse. Pairs with `ser-big`, but **with** an inner loop, which `ser-big` lacks and which made it a 26%-spread cell |

`_lengths.cfm` and `verify-invariance.cfm` are tools, not cells. Neither matches the `des-` filter; `BENCHMARK_FILTER=*` would pick them up as suites and the numbers would be meaningless.

## The pairs that produce ratios

Nothing here means anything as an absolute. Every cell is read against a partner.

- `numbers-int` / `numbers-quoted` → **the whole cost of the number path against the string path on identical digits.** The headline ratio; a `Double` fast path should pull it toward 1. The quoted side carries 2000 extra bytes of quotes, so 1.0 is not the floor
- `numbers-negative` / `numbers-int` → the `Negate` wrapper: a second `preciseMath` resolution and a second `Double.valueOf` per literal
- `numbers-decimal` / `numbers-int` → the fractional branch plus the scaled parse and `doubleValue()` scale handling
- `numbers-long-digits` / `numbers-int` → the `BigInteger` cliff. Expected to be the largest ratio before the change and to collapse after it, because `parseDouble` grows with digit count but has no representation change at 18
- `numbers-exponent` / `numbers-decimal` → the exponent branch on its own
- `wide-struct-200` / `numbers-int` → what share of a key-heavy mixed document the number path is
- `long-strings-escaped` / `long-strings-clean` → `string()`'s escape branching, the parse-side twin of the serialize family's cleanest pair
- **cross-family**, same bytes both sides: `des-numbers-int` / `ser-numbers-array`, `des-wide-struct-200` / `ser-wide-struct-200`, `des-long-strings-clean` / `ser-long-strings-clean`, `des-long-strings-escaped` / `ser-long-strings-escaped`, `des-api-response` / `ser-api-response`, `des-big` / `ser-big`. Parse against serialize for one document. Only valid at matched loop counts, which the defaults are **not** (20 / 5 here, 50 / 10 there), so a pair run sets `JD_LOOP_SMALL=50 JD_LOOP_MID=10`. With that, both families on the same jar and host answer the serialize README's open question about whether the two sides are comparable

**The controls are gates, not data points.** `des-numbers-quoted`, `des-long-strings-clean` and `des-long-strings-escaped` must not move under a number-literal change. If one does, the change reached `string()`, the container walk, or the harness.

## Fixture sizes (8.0.0.188-SNAPSHOT, measured)

Serialized input length and top-level element count, from `_lengths.cfm`. The paired fixtures match the serialize README's output table byte for byte (`numbersInt` 3,894 = `numbersArray`, `longStringsClean` 41,072, `longStringsEscaped` 57,122, `wideStruct200` 2,385, `apiResponse` 833, `big` 41,212), which is the proof the cross-family pairs parse what the other side emits.

| Fixture | Bytes | Elements |
| --- | ---: | ---: |
| `numbersInt` | 3,894 | 1000 |
| `numbersQuoted` | 5,894 | 1000 |
| `numbersNegative` | 4,894 | 1000 |
| `numbersDecimal` | 9,894 | 1000 |
| `numbersLongDigits` | 26,001 | 1000 |
| `numbersExponent` | 7,894 | 1000 |
| `wideStruct200` | 2,385 | 200 |
| `longStringsClean` | 41,072 | 10 |
| `longStringsEscaped` | 57,122 | 10 |
| `apiResponse` | 833 | 4 |
| `big` | 41,212 | 500 |

## Baseline — 8.0.0.188-SNAPSHOT, JDK 25, 32 threads, 30k never / 10k once, loops 20 / 5

`run-baseline.bat baseline nojfr` twice against the same stashed `lucee-baseline.jar`, then `alloc`. `never` pass.

| Cell | run 1 (ms) | run 2 (ms) | spread | GC pause |
| --- | ---: | ---: | ---: | ---: |
| `des-api-response` | 244 | 233 | 4.6% | 9ms |
| `des-long-strings-clean` | 1,858 | 1,841 | 0.9% | 46ms |
| `des-long-strings-escaped` | 2,282 | 2,257 | 1.1% | 58ms |
| `des-wide-struct-200` | 2,365 | 2,345 | 0.9% | 49ms |
| `des-numbers-quoted` **(control)** | 4,634 | 4,656 | **0.5%** | 95ms |
| `des-numbers-int` | 5,015 | 5,026 | **0.2%** | 97ms |
| `des-numbers-negative` | 5,664 | 5,677 | **0.2%** | 123ms |
| `des-numbers-exponent` | 6,237 | 6,283 | 0.7% | 133ms |
| `des-numbers-decimal` | 6,812 | 6,827 | **0.2%** | 145ms |
| `des-big` | 8,645 | 8,680 | 0.4% | 270ms |
| `des-numbers-long-digits` | 14,067 | 14,084 | **0.1%** | 275ms |

**Spread is under 1.1% on every cell except `api-response`**, which is at the harness floor and stays unusable on its own. Every number cell is at or under 0.7%, so a 2% delta on the number axis is real. The `alloc` run tracked `nojfr` within 1 to 3% on all cells except `api-response` (+75%, floor cell, JFR overhead dominates), so the alloc capture is representative of what it measures.

### The ratios

| Pair | Ratio | Reading |
| --- | ---: | --- |
| `numbers-int` / `numbers-quoted` | **1.08x** | the whole BigDecimal detour on small ints is ~8% over the string path on the same digits. Smaller than the smoke run's 1.17x suggested. This is the "how big is it really" answer for the common case: real, small |
| `numbers-negative` / `numbers-int` | 1.13x | the `Negate` wrapper's second lookup and second `toDoubleValue`. Bigger than the detour itself on plain ints |
| `numbers-decimal` / `numbers-int` | 1.36x | the fractional branch and scaled parse, at 2.5x the bytes per literal, so partly volume |
| `numbers-long-digits` / `numbers-int` | **2.80x** | the `BigInteger` cliff, at 6.7x the bytes. The one place the detour is expensive per literal, and it grows as the ratio between the two grew from 2.64x at `once` to 2.80x at `never` |
| `numbers-exponent` / `numbers-decimal` | 0.92x | the exponent branch is cheaper than a fraction of equal value: fewer chars per literal |
| `wide-struct-200` / `numbers-int` | 0.47x | 200 keys + 200 literals costs under half of 1000 literals |
| `long-strings-escaped` / `long-strings-clean` | 1.23x | `string()`'s escape ladder on 39% more bytes, so mostly volume, same conclusion as the serialize side |

**What the pairs say before the alloc capture is read.** On small integers the detour is an 8% tax on a numbers-only document, and on a real mixed document (`wide-struct-200`, `big`) it is a fraction of that. On long-digit literals it is 2.8x. So the fast path is worth having for the shape it hurts, and the value-invariance corpus is what makes it safe; nobody should expect it to move `des-big` by much on wall time.

### Where the allocations actually are

`run-baseline.bat baseline alloc`, `jd-baseline-alloc.jfr` in the archive dir with the analysis files beside it. Weighted TLAB + sampled bytes, so read shares, not the absolute GB. One JVM runs all 11 cells, so this is family-wide attribution; the six number cells are 6 of 11 and dominate it by design.

| Owner | Share of all alloc bytes | What it is |
| --- | ---: | --- |
| everything under `CFMLExpressionInterpreter.number()` | **47%** | the number-literal detour, before `getValue()` |
| `LNumber.getValue()` → `Double.valueOf` | 4% | the final `Double`, 91% of it reached via `RefUtil.getValue` (array / struct element evaluation) |
| `ParserString.init` → two `char[]` | **19%** | `text[]` plus `lcText[]` for the whole document, 4 bytes per input char. Not a number-literal cost: every `deserializeJSON` pays it on the whole input. Prior art: `sourcecode-api-refactor.md` already notes `ParserString` carries its own `char[]` + `lcText[]` |
| `LStringBuilder` (`<init>` / `append` / `getValue`) | ~8% | `string()`'s per-value builder, the quoted / long-strings cells |

Inside `number()`'s 47%, by class:

| Class | Share of `number()` bytes | Site |
| --- | ---: | --- |
| `byte[]` | 36% | the `new StringBuilder(6)` backing array (`AbstractStringBuilder.<init>`), its growth on any literal over 6 chars (`Arrays.copyOf`, so every decimal and every long-digit literal), and the `String` bytes from `rtn.toString()` (`copyOfRange`). Owner frames: `number()` 224 GB, `digit()` 115 GB |
| `char[]` | 22% | **`BigDecimal(String, MathContext)` calls `val.toCharArray()`** (`StringLatin1.toChars`, 154 GB) and then allocates its own coefficient `char[]` (50 GB). Two full copies of every literal's digits, neither of which the spec listed |
| `java.math.BigDecimal` | 18% | `Caster.toBigDecimal`, 100% of all `BigDecimal` allocation in the run |
| `java.lang.String` | 10% | `StringBuilder.toString()` in `number()` |
| `LNumber` | 7% | the ref object itself |
| `BigInteger` + `int[]` | 6% | the 25-digit cell only. `BigInteger.parseInt` / `destructiveMulAdd` are also 6k CPU samples, so this is the 2.8x |
| `StringBuilder` | <1% | |

So per small-integer literal the current path allocates: a `StringBuilder` and its `byte[]`, a `String` and its `byte[]`, a `char[]` from `toCharArray`, a `BigDecimal`, an `LNumber`, and a `Double`. Eight objects, plus `Arrays.copyOf` growth and a `BigInteger` + `int[]` above 18 digits. A `Double` built straight off the `ParserString` range needs the `Double` and the ref: **roughly 85% of `number()`'s bytes, about 40% of everything this family allocates**. Even the lazy version, `Double.parseDouble(rtn.toString())` keeping the `StringBuilder` and `String`, removes the `char[]` and `BigDecimal` halves, about 45% of `number()`'s bytes.

CPU, `jdk.ExecutionSample`, 138k samples: frames matching `LNumber|BigDecimal|BigInteger|Negate` appear in **26%** of all stacks. `BigDecimal.<init>` alone is **18% of leaf samples**, the hottest leaf in the recording after the VT carrier plumbing. `LNumber.getValue` is under 5.9% of stacks (leaf 0, it is fully inlined: the `preciseMath` lookup, `doubleValue()` and `Double.valueOf` are its inlinees). `Negate.getValue` is 1.1k samples, 0.8%.

**Reading the two together.** Wall time says 8% on small ints; allocation says 47% of bytes and 26% of CPU samples. Both are right: on a virtual-thread harness with a young gen sized for it, TLAB bumps are nearly free until GC, and the number cells' GC pause (97 to 275 ms per 30k) is small against their wall time. This is the usual shape for an allocation-removal fix: lead with alloc rate, GC and the long-digit cell, not with `des-numbers-int`'s ms.

**`ParserString.init` is the bigger single allocator on the deserialize path and is out of this family's scope.** 19% of all bytes for the two whole-document `char[]` copies, more than `BigDecimal` and `toCharArray` combined. It is per document, not per literal, so it scales with `des-big` and `des-long-strings-*`, and it is the parser's design (lower-cased shadow array for case-insensitive matching) rather than a leak. Recorded here so it isn't rediscovered; a fix is a `ParserString` change, not a number-literal one.

## Comparator caveat for every arm below

`lucee-baseline.jar` was built at 17:28 from a working copy that then kept moving. Against `lucee-flag-only.jar` (18:50) the core lco differs in `KeyImpl`, `ArgumentIntKey`, `IKStorageValue`, `StorageValue`, `ConfigAdmin`, `CFMLEngineImpl`, `RHExtension`, `ExtensionMetadata`, `SpoolerEngineImpl`, `JavaConverter`, `Base64Encoder` and the three lars, and the loader differs in `BundleWiringImpl` (felix patch) with `BootDelegation.class` gone. So a delta between a `baseline` run and any later arm is **the arm plus whatever else changed in the tree**, and the 1,000 `ClassNotFoundException`s that appear in every post-baseline capture (`BundleWiringImpl.findClassOrResourceByDelegation` for core classes) are the loader change, not the interpreter. Check the two jars' lco listings differ only in the classes under test before quoting a delta; `unzip -l` on `core/core.lco` is enough. The gross effects in the `double-literal` arm (`FDBigInteger`, +41% on `long-digits`) are far too large to be this, the 1.5-3% in `flag-only` is not.

## Arm: `Double.valueOf(String)` literal — regressed, not kept in this form

Tag `double-literal`, stashed `lucee-double-literal.jar`, same 30k / 10k shape, two runs plus `alloc`. `number()` passed the interpreter's already-resolved `preciseMath` into `LNumber`, which stored `preciseMath ? Caster.toBigDecimal(s) : Double.valueOf(s)` and returned it from `getValue()` with no thread-local lookup; `Negate` took the flag the same way. Corpus fingerprint **identical** (`82cb8f4c…`), filtered `mvn test` green, so the value surface held. The timing did not.

| Cell | baseline mean | double-literal r1 / r2 | delta |
| --- | ---: | ---: | ---: |
| `des-numbers-long-digits` | 14,075 | 19,857 / 19,875 | **+41%** |
| `des-numbers-negative` | 5,670 | 6,224 / 6,259 | **+10%** |
| `des-numbers-decimal` | 6,820 | 6,412 / 6,399 | -6.1% |
| `des-numbers-exponent` | 6,260 | 6,000 / 5,989 | -4.2% |
| `des-numbers-int` | 5,020 | 4,996 / 4,980 | -0.6%, flat |
| `des-numbers-quoted` **(control)** | 4,645 | 4,679 / 4,646 | flat |
| `des-big` | 8,662 | 8,535 / 8,629 | -0.9%, flat |
| `des-wide-struct-200` | 2,355 | 2,355 / 2,363 | flat |

Both regressions are in the captures, `jd-double-literal-alloc-pair-diff.txt` and the files beside it.

**`Double.parseDouble` is the wrong primitive.** `FloatingDecimal.readJavaFormatString` allocates an `ASCIIToBinaryBuffer` and a digits `char[]` on *every* call (135 GB of buffers, one per literal, plus 110 GB of `byte[]` now charged to `LNumber.<init>`), so on small ints it swapped one allocation set for another and the cell stayed flat. Above ~15 significant digits it leaves its fast path for the `FDBigInteger` correction loop: 130 GB of `FDBigInteger`, `int[]` +175 GB (24 → 199 GB), and `copyDigits` / `rightInplaceSub` / `cmp` as new hot leaves, 28% of all exec samples matching `FloatingDecimal|FDBigInteger`. Only `long-digits` hits that path and it is the whole +41%. `BigDecimal`'s `BigInteger` parse was the cheaper route for long literals. Net family allocation went **up**: BigDecimal -171 GB, BigInteger -29, `char[]` -222, against `ASCIIToBinaryBuffer` +135, `FDBigInteger` +130, `int[]` +175, `byte[]` +108, `LNumber` +39 (a second field took the object from 16 to 24 bytes).

**The `negative` regression is a JIT boundary shift, not the flag.** `Caster.toDoubleValue` appears as a non-inlined frame in the build (1.2k samples, all called from `Negate.getValue`; 0 in the baseline). Making `preciseMath` a final field shrank `Negate.getValue` enough that C2 stopped inlining the large `Caster.toDoubleValue(Object)` into it, so every negative literal now pays a real call plus the instanceof ladder. `ModernApplicationContext.getPreciseMath` did drop out of the profile (-1.8% of samples), which is what the lookup removal was worth on its own.

**What the arm settles.** Removing the lookup is real but small (~2% of samples). The allocation win the spec promised is only available if the literal is turned into a `double` **without** going through a `String`-parsing library call: the JDK's parser allocates as much as `BigDecimal` did. That means an exact fast path over the digits the interpreter already has (mantissa in a `long`, decimal exponent, `m * 10^k` with `m < 2^53` and `|k| <= 22`, which is a single correctly-rounded operation), falling back to the existing `BigDecimal` route for everything else so long literals stay at baseline. The negative cell wants the sign folded into the literal when the operand is a bare `LNumber`, so no `Negate` ref and no `toDoubleValue` call at all.

## Arm: `flag-only` — thread `preciseMath` into the literal, keep BigDecimal. Regressed, not kept in this form

Tag `flag-only`, stashed `lucee-flag-only.jar`. `LNumber(String, boolean)` stores the `BigDecimal` as before plus `resolved` and `preciseMath` booleans; `getValue()` reads the stored flag instead of `ThreadLocalPageContext.preciseMath(pc)`; `Negate` takes the flag the same way. Fingerprint identical, filtered `mvn test` green.

**Clean comparator:** `lucee-wc-base.jar`, built from the same working copy with the three files stashed, lco listing differs only in `CFMLExpressionInterpreter`, `LNumber`, `Negate` (verified with `unzip -l`). Interleaved, `BENCHMARK_FILTER=des-numbers`, wc-base / flag-only / wc-base / flag-only:

| Cell | wc-base r1 / r2 | flag-only r5 / r6 | delta |
| --- | ---: | ---: | ---: |
| `int` | 5,596 / 5,607 | 5,762 / 5,757 | **+2.8%** |
| `decimal` | 7,397 / 7,441 | 7,581 / 7,550 | +2.0% |
| `exponent` | 6,800 / 6,807 | 6,969 / 6,983 | +2.5% |
| `negative` | 6,319 / 6,240 | 6,407 / 6,431 | +2.2% |
| `long-digits` | 14,767 / 14,701 | 14,867 / 15,162 | +1.9% |
| `quoted` **(control)** | 4,673 / 4,623 | 4,666 / 4,647 | flat |

**The lookup is gone and the cells got slower.** `frame-search` on the alloc pair: frames matching `getPreciseMath|ThreadLocalPageContext.preciseMath` 9,342 → 96 samples (6.7% of exec samples in the baseline, so the earlier "1.8% leaf" understated the attribution). Yet every number cell is 2-3% slower with the control flat. Two lessons. The exec samples on that getter chain were inlined field loads the sampler over-attributes; they were not 6.7% of wall time. And the only other thing the alloc diff moved is `LNumber` itself, **+48% bytes**: two booleans took the object from 16 to 24 bytes (12-byte header + compressed ref = 16; any extra field crosses to the next 8-byte boundary), on the single hottest Lucee allocation in the family, 90k → 135k weighted events. An extra 8 bytes per literal cost more than the lookup saved. (The earlier `baseline`-vs-`flag-only` family runs said the same thing but were confounded by the working copy moving; the clean pair confirms it.)

**What survives.** Threading the flag is still the right structure, but it must not grow the object. The 16-byte form is a single `Number` field and no booleans: `preciseMath ? bd : Double.valueOf(bd.doubleValue())` at construction, today's `getValue()` computation moved into the constructor, so value-identical by construction, `getValue()` returns the field. The three shared constants stay BigDecimal-backed and `Plus`/`BigPlus` already cast them.

## Arm: `flag-only-v2` — single `Number` field, value decided at construction. Faster everywhere except `negative`

Tag `flag-only-v2`, stashed `lucee-flag-only-v2.jar`. The 16-byte form the previous arm asked for: `LNumber(Number)` is the only constructor, `number()` does `BigDecimal bd = Caster.toBigDecimal(rtn.toString()); new LNumber(preciseMath ? bd : Double.valueOf(bd.doubleValue()))`, `getValue()` returns the field, no booleans, no thread-local lookup. `Negate` unchanged from `flag-only` (takes the interpreter's flag). `LNumber.ZERO` removed, it had no callers. Comparator `lucee-wc-base.jar` as before; lco listing differs only in the three classes plus the two regenerated lars (verified with `unzip -l`). Corpus fingerprint identical on both jars (four shapes now, see the invariance gate), filtered `mvn test` 56 pass / 1 skip / 0 fail.

Interleaved, `BENCHMARK_FILTER=des-numbers`, this time starting with the arm: flag-only-v2 / wc-base / flag-only-v2 / wc-base.

| Cell | wc-base r3 / r4 | flag-only-v2 r1 / r2 | delta (30k never) | 10k once, wc-base → v2 |
| --- | ---: | ---: | ---: | ---: |
| `int` | 5,669 / 5,626 | 5,538 / 5,587 | **-1.5%** | 2,004 / 1,932 → 1,707 / 1,733, **-12.6%** |
| `decimal` | 7,554 / 7,466 | 7,331 / 7,372 | -2.1% | 2,641 / 2,691 → 2,595 / 2,598, -2.6% |
| `exponent` | 6,870 / 6,862 | 6,749 / 6,769 | -1.6% | 2,350 / 2,343 → 2,325 / 2,309, -1.2% |
| `long-digits` | 14,878 / 14,703 | 14,402 / 14,456 | -2.4% | 5,072 / 5,005 → 4,867 / 4,872, -3.3% |
| `negative` | 6,264 / 6,266 | 6,757 / 6,803 | **+8.2%** | 2,159 / 2,125 → 2,302 / 2,304, **+7.5%** |
| `quoted` **(control)** | 4,648 / 4,677 | 4,657 / 4,681 | flat | 1,624 / 1,639 → 1,582 / 1,591, -2.8% |

**The lookup removal is worth ~2% on its own once the object stays at 16 bytes.** Same three classes as `flag-only`, same flag threading, and the sign of every number cell flipped from +2-3% to -1.5-2.4% with the control flat; the difference between the two arms is eight bytes per literal and one fewer `Double` per evaluation. The `once` column is larger on `int` (-12.6%, both runs) because that mode re-parses the template per cycle and the interpreter's own literals (the loop bounds and counters in the cell) go through the same `number()`; it is a real effect but the `never` column is the one to quote.

**`negative` regressed 8% and is not explained yet.** `flag-only` had the same `Negate` and was only +2.2% on this cell, in line with its other cells, so the extra 6 points come from what changed in `LNumber` between the two arms: `getValue()` returning a stored `Number` field instead of allocating `Double.valueOf(bd.doubleValue())`. The `double-literal` arm regressed the same cell 10% and its capture showed `Caster.toDoubleValue(Object)` as a non-inlined frame under `Negate.getValue` (1.2k samples, 0 in the baseline). The likely reading is the same boundary: with a `Number`-typed field load feeding it, C2 no longer inlines the `toDoubleValue` ladder into `Negate.getValue` and every negative literal pays a real call plus the `instanceof` chain. That is a hypothesis; there is no capture of this arm yet. A `des-numbers-negative`-only pair (`alloc` capture on both jars, `hot-frames` and `frame-search --regex=toDoubleValue`) would settle it. The cut that sidesteps it, planned anyway for the digit fast path, is to fold the sign into the literal in `negateMinusOp()` when the operand is a bare `LNumber`, so a JSON `-12` is one `LNumber` and no `Negate` ref at all. The fold must negate the converted value, not the digit string: `BigDecimal` has no negative zero, so `-0` must go `Double.valueOf(-bd.doubleValue())` to keep the `0x8000000000000000` bits the corpus records for `neg-zero` and `frac-neg-zero`.

**Not committable on its own** with a regressed cell in the headline family, even though it is the right structure. Either the sign fold lands with it, or the capture shows something cheaper.

The `split` arm below tested the inlining reading directly by giving the field the exact type `Double`: `negative` stayed +6%. So whatever the boundary is, it is not the field's static type.

## Arm: `split` — `LNumber`/`LBigNumber`, `Negate`/`BigNegate`, chosen at parse. Flat, `negative` still +6%

Tag `split`, stashed `lucee-split.jar`. The `Plus`/`BigPlus` pattern the rest of the package already uses: `LNumber` holds a `final Double`, `LBigNumber` a `final BigDecimal` (and the `ONE` / `MINUS_ONE` constants), `Negate` is one `Ref` field with `Double.valueOf(-Caster.toDoubleValue(...))`, `BigNegate` the `Caster.negate(Caster.toBigDecimal(...))` path; `number()` and `negateMinusOp()` pick the class from `preciseMath`. No branch in any `getValue`, no `Number`-typed field, `Negate` back to 16 bytes (`limited` was stored and never read). Comparator `lucee-wc-base.jar`; lco differs only in the five classes plus three regenerated lars. Fingerprint identical (`72c2c20e…`), filtered `mvn test` 56 / 1 skip / 0.

Interleaved, `BENCHMARK_FILTER=des-numbers`, base first this time: wc-base / split / wc-base / split.

| Cell | wc-base r5 / r6 | split r1 / r2 | delta (30k never) | 10k once, wc-base → split |
| --- | ---: | ---: | ---: | ---: |
| `int` | 5,599 / 5,618 | 5,605 / 5,590 | flat | 1,912 / 1,940 → 1,733 / 1,718, **-10%** |
| `decimal` | 7,387 / 7,443 | 7,400 / 7,397 | flat | 2,618 / 2,639 → 2,625 / 2,623, flat |
| `exponent` | 6,793 / 6,824 | 6,834 / 6,801 | flat | 2,301 / 2,337 → 2,308 / 2,326, flat |
| `long-digits` | 14,641 / 14,706 | 14,620 / 14,526 | -0.7% | 4,965 / 5,002 → 4,881 / 4,880, -1.7% |
| `negative` | 6,234 / 6,267 | 6,653 / 6,646 | **+6.4%** | 2,131 / 2,137 → 2,284 / 2,252, **+6.3%** |
| `quoted` **(control)** | 4,658 / 4,642 | 4,695 / 4,690 | +0.9% | 1,607 / 1,623 → 1,637 / 1,613, flat |

**The lookup removal is worth nothing you can measure at 30k.** `flag-only-v2` read -1.5 to -2.4% on the same cells against the same comparator; this arm, functionally identical on the non-precise path, reads flat with the control drifted +0.9%. Take the two together: the per-literal `preciseMath` lookup is worth somewhere between 0 and 2% on a numbers-only document, which is inside what two interleaved pairs can resolve. The `once` column's -10% on `int` repeats (four runs out of four now) and is real: that mode re-parses the template each cycle, so the cell's own CFML literals go through `number()` too.

**`negative` is +6-8% in every arm that stores a ready-made `Double` in the literal** (`double-literal` +10%, `flag-only-v2` +8%, `split` +6%), and only +2% in `flag-only`, which still allocated `Double.valueOf(bd.doubleValue())` per evaluation. Two hypotheses have now been written down and neither is confirmed. The inlining-boundary reading (C2 stops inlining `Caster.toDoubleValue(Object)` into `Negate.getValue`) predicted the typed `Double` field would fix it; it did not. The escape-analysis reading (a fresh `Double` unboxed immediately by `Negate` is scalar-replaced, a stored one is a real 16-byte allocation at parse time) fits the wall time but not the GC counts: `negative` GCs are 95-100 base, 104-108 in `v2`/`split`, but 114 in `flag-only`, which regressed least. Nothing here is settled without the `negative`-only capture. Sign folding in `negateMinusOp()` makes the question irrelevant for JSON either way, since a bare negative literal stops producing a `Negate` ref at all.

**Keep the split regardless.** It is the package's own convention, removes a dead field and a branch, and is the shape the fast path and the sign fold slot into. It is not a perf change on its own and should not be sold as one.

## Arm: `reorder` — `Caster.toDoubleValue(Object)` checks `Double` before `Number`. No effect on `negative`

Tag `reorder`, stashed `lucee-reorder.jar` = `split` plus one line in `Caster.toDoubleValue(Object)`: `if (o instanceof Double) return ((Double) o).doubleValue();` ahead of the `instanceof Number` branch, so the common case is a final-class check and a field load instead of a virtual `Number.doubleValue()` on a type profile shared by every caller in Lucee. Tested the remaining half of the inlining hypothesis: if `Negate` was paying for that virtual call, this removes it. Fingerprint identical, three-way interleave wc-base / split / reorder, twice:

| Cell, 30k never | wc-base r7 / r8 | split r3 / r4 | reorder r1 / r2 |
| --- | ---: | ---: | ---: |
| `int` | 5,655 / 5,599 | 5,566 / *5,045* | 5,546 / 5,561 |
| `decimal` | 7,441 / 7,429 | 7,343 / *6,811* | 7,330 / 7,337 |
| `exponent` | 6,838 / 6,814 | 6,743 / *6,221* | 6,750 / 6,744 |
| `long-digits` | 14,786 / 14,702 | 14,429 / *13,870* | 14,409 / 14,410 |
| `negative` | 6,252 / 6,256 | 6,619 / *6,045* | 6,592 / 6,613 |
| `quoted` **(control)** | 4,659 / 4,640 | 4,661 / 4,682 | 4,651 / 4,650 |

**The reorder changes nothing on this family.** `reorder` and `split r3` agree to within 0.5% on every cell, `negative` included (6,592 / 6,613 against 6,619). The ladder's first branch was not what `Negate` was paying for. Against the comparator the picture is the same as `flag-only-v2`: -1.2 to -2.4% on the four plain number cells, control flat, `negative` **+5.5%**. So the lookup removal is worth ~1.5-2% after all, the earlier flat `split` pair was the low side of the noise, and `negative` is +5.5 to +8% in five arms out of five that store a `Double`.

**`split r4` is an outlier worth keeping.** Every number cell in that session ran 7-9% faster than its twin, `negative` included (6,045, which is *below* the comparator), while the control sat at 4,682, so it is not the machine. One session's JIT landed on a better compiled shape for the number path than the other five sessions did. That is the one piece of evidence that the `negative` gap is a compilation-shape effect rather than fixed work: when the compiler gets it right, the cell is faster than the baseline, not slower. Which decision differs is what the capture has to show; the two guesses so far (field type, `Number.doubleValue` dispatch) are both eliminated.

**Keep or drop the one-liner on its own merits.** It is value-neutral, every `toDoubleValue(Object)` caller in Lucee gets the cheaper common case, and it belongs to the wider `Caster` casting review rather than to this spec.

## Arm: `digitwalk-fold` — digits walked once into a `long`, Clinger fast path, sign folded into the literal. -46% to -66% on every number cell, control flat

Tag `digitwalk-fold`, stashed `lucee-digitwalk-fold.jar` (`lucee-digitwalk.jar` beside it is the same arm before the `isJson` exception fix below and is superseded). Built on the `split` + `reorder` working copy. `number()` no longer builds a `StringBuilder`: `digit()` accumulates the significand into a `long` as it advances, the fraction length becomes `scale`, the exponent branch parses into an `int` (capped at 100,000 so a runaway exponent can't overflow it), and the range `[start, end)` is remembered. With precise math off, when `digits + scale <= 18` and the significand is below 2^53 and `|exp - scale| <= 22`, the value is one `m * 10^k` or `m / 10^-k` on two exact doubles, which is the same single correctly-rounded operation `BigDecimal.doubleValue()` performs on a compact value, so the bits are identical by construction. Everything else, and the whole precise-math path, goes to a new `ParserString.toBigDecimal(start, count, mc)` that calls the `BigDecimal(char[], off, len, mc)` constructor straight off the parser's `text` array: no `String`, no `toCharArray()`, no `trim()`. `negateMinusOp()` folds a leading minus into a bare `LNumber` via `LNumber.negate()`, negated on the primitive so `-0` keeps its sign bit; `Negate` stays for non-literal operands and `BigNegate` for precise math. Comparator `lucee-wc-base.jar`. Fingerprint identical (`72c2c20e…`), full `mvn test` green (LDEV3314 Jacob only).

Designed against the JMH spike in `D:/testbeds/json-number-parse-jmh` (README there), which measured the per-literal conversion in isolation: `number()` as shipped was 19.1 ns / 136 B on a small int, of which the `StringBuilder`, its `byte[]`, the `String`, its `byte[]` and `toCharArray()` were 13.4 ns / 96 B, and `BigDecimal` plus `doubleValue()` about 1.6 ns / 40 B. The digit walk measured 4.1 ns / 0 B. That is why the five earlier arms, which all kept the `String` plumbing and only moved the `BigDecimal`, read -2% at best.

Interleaved, `BENCHMARK_FILTER=des-numbers`, wc-base / digitwalk-fold / wc-base / digitwalk-fold.

| Cell | wc-base r9 / r10 | digitwalk-fold r1 / r2 | delta (30k never) | GCs | 10k once, wc-base → arm |
| --- | ---: | ---: | ---: | ---: | ---: |
| `int` | 5,750 / 5,714 | 2,027 / 2,024 | **-65%** | 90-100 → 36-41 | 1,926 / 1,984 → 781 / 774, **-60%** |
| `negative` | 6,372 / 6,481 | 2,988 / 3,018 | **-53%** | 101-104 → 48-53 | 2,199 / 2,283 → 1,067 / 1,065, **-52%** |
| `decimal` | 7,613 / 7,643 | 2,573 / 2,589 | **-66%** | 115-118 → 43-46 | 2,680 / 2,705 → 1,044 / 1,060, -61% |
| `exponent` | 7,148 / 7,021 | 2,406 / 2,431 | **-66%** | 98-108 → 41-46 | 2,344 / 2,375 → 893 / 912, -62% |
| `long-digits` | 15,360 / 15,146 | 8,271 / 8,279 | **-46%** | 196-220 → 122-126 | 5,057 / 5,070 → 2,801 / 2,819, -44% |
| `quoted` **(control)** | 4,809 / 4,826 | 4,718 / 4,745 | -1.7% | 75-76 → 76-79 | 1,622 / 1,682 → 1,610 / 1,646, flat |

**The "8% detour" was the wrong ratio.** `int` / `quoted` said the number path cost 8% more than the string path on the same digits, and that was read as "the detour is small". It meant the two paths were comparably expensive, and both were mostly `number()` / `string()`. Removing the `String` plumbing from `number()` took the `int` cell down 65%, with the control unchanged; `number()` was most of the cell, not 8% of it.

**`negative` is below the comparator for the first time in six arms, -53%.** Not explained, removed: a JSON `-12` is one `LNumber` and no `Negate` ref, so whatever C2 was doing at the `Negate.getValue` → `Caster.toDoubleValue` boundary no longer runs. The remaining gap to `int` (2,988 vs 2,027) is the extra `LNumber` per literal from `negate()` plus one more byte per literal to parse.

**`long-digits` -46% even though every literal still takes the `BigDecimal` fallback.** The fallback lost the `StringBuilder`, the `Arrays.copyOf` growth past 6 chars, the `String` and the `toCharArray()`; the JMH `bdChars` row had the same 40% gap to `current` on 25 digits. `BigInteger` is still allocated and is now the whole cost of the cell.

**Allocation, `jd-digitwalk-fold-alloc-alloc.jfr`** (this capture is `des-numbers` only; the baseline capture was all 11 cells, so read the class split under `number()`, not the absolute GB). Under `number()`: `Double` 94.7 GB, `LNumber` 65.6, `char[]` 57.5, `BigInteger` 32.6, `BigDecimal` 31.5, `int[]` 22.5. **No `byte[]`, `String` or `StringBuilder` under `number()` at all**; in the baseline those were 340 + 93 + 6 GB and `char[]` was 205. The `Double` moved from `LNumber.getValue` into `number()` because it is now built at parse time. `alloc-blame --class BigDecimal`: 100% of remaining `BigDecimal` allocation is `ParserString.toBigDecimal`, the `long-digits` fallback; the 57.5 GB of `char[]` is `BigDecimal.<init>`'s coefficient array on the same cell. Per small literal the path now allocates the `Double` (24 B) and the `LNumber` (16 B), against eight objects and 176 B before.

CPU, `frame-search --regex="LNumber|BigDecimal|BigInteger|Negate"`: **26% → 14%** of exec samples, and the 14% is entirely `BigDecimal.<init>` / `BigInteger.parseInt` / `destructiveMulAdd` from `long-digits`. `LNumber.getValue` (8,172 samples in the baseline) and `Negate` are gone from the profile; `LNumber.negate` is 1 sample.

**What's now the top allocator.** `alloc-blame --class char[]`: `ParserString.init` is 78% of all `char[]` bytes in this capture (198.7 GB), the two whole-document arrays. It was recorded as out of scope above and is now the biggest single thing on the deserialize path by a wide margin.

**Pair-diff against a like-for-like comparator** (`jd-wc-base-alloc-alloc.jfr`, `des-numbers` only, captured after the fact; `jd-digitwalk-fold-alloc-pair-diff.txt` and the `hot-frames-dleaf` / `exec-sample-diff` / `frame-search-removeSpace` files beside it). Same work both sides, recording 77 s → 45 s. Weighted bytes: `byte[]` -87%, `String` -86%, `StringBuilder` -83%, `BigDecimal` -79%, `char[]` -41%, `Negate` gone. GC events -43%, GC pause total -36%, exec samples -30%, compiles -22%, deopts unchanged. `Double` +33% and `LNumber` +60% by weighted bytes: the per-literal counts are unchanged except one extra `LNumber` per negative literal from `negate()`, so most of that is TLAB sampling re-attribution once the surrounding allocation vanished, not new objects. Leaf CPU: `BigDecimal.<init>` 21.1k → 3.9k samples, `number()` 10.2k → 561, `LNumber.getValue` → `BigDecimal.doubleValue` 2.7k → 0, `getApplicationContext` via `preciseMath` 3.6k → 22.

**Two leaf movers in that diff are attribution skid, not work.** `ParserString.removeSpace` 3.6k → 17.7k samples, all at line 714 (`pos++` inside the whitespace loop) via `comments()`. The fixtures contain no whitespace (`numbersInt` is exactly 2,893 digit bytes + 999 commas + 2 brackets = 3,894), so that loop body never executes; the samples are the PC of the now fully-inlined literal parse being mapped to the nearest debug scope, which moved from `removeSpace:711` (method entry) in the base to `:714` in the build. Same story in reverse for `String.charAt <- ParserString.init` 13.2k → 765: identical code and input both sides. Trust the totals and the allocation deltas on this pair, not method-level leaf shares in code that got small enough to inline.

**A miss worth keeping.** The first build of this arm failed `LDEV4006`: `isJson("blah-0E3611183072")` used to reach `Caster.toBigDecimal(String)`, which turns the `BigDecimal` constructor's `NumberFormatException` ("Exponent overflow.") into a `CasterException`, a `PageException` `isJson` swallows. Calling the constructor directly let the raw `NumberFormatException` escape as a native exception and `isJson` returned the message instead of `false`. The fallback now wraps the constructor and throws the same `CasterException` shape with the original as cause. The corpus did not catch it because every corpus literal parses; the gate for this is the test suite, not the fingerprint.

## Smoke run (1k never / 1k once, 32 threads, loader\target 188-SNAPSHOT, loops 50 / 10)

`run-smoke.bat` defaults, at the original 50 / 10 loop counts (since lowered to 20 / 5, so these ms are 2.5x what the current defaults produce; the ratios are unaffected). **Not a measurement**, a smoke run's job is to show every cell compiles, asserts and lands in a sane band. All 22 cells finished, no errors. `never` ms, for the band check only:

| Cell | ms | reading |
| --- | ---: | --- |
| `des-api-response` | 31 | **at the harness floor.** 10 × 833 bytes per cycle is too little work; the cell measures request setup. Same problem `ser-api-response` had. Needs a higher loop count of its own or is read only as a cross-family pair |
| `des-long-strings-clean` | 167 | |
| `des-long-strings-escaped` | 189 | |
| `des-wide-struct-200` | 234 | |
| `des-numbers-quoted` (control) | 417 | |
| `des-numbers-int` | 486 | |
| `des-numbers-negative` | 554 | |
| `des-numbers-exponent` | 587 | |
| `des-numbers-decimal` | 673 | |
| `des-big` | 697 | in band; the inner loop of 10 is fine |
| `des-numbers-long-digits` | 1,292 | |

First-look ratios, to be confirmed at 100k with a spread figure before anyone quotes them: `int` / `quoted` **1.17x**, `negative` / `int` 1.14x, `decimal` / `int` 1.38x, `long-digits` / `int` **2.66x**, `exponent` / `decimal` 0.87x. The `long-digits` ratio is the `BigInteger` cliff showing up on the first run, at 6.7x the bytes of `int`, so it is not yet separated from raw digit count. The `int` / `quoted` headline being only 1.17x at this cycle count says the number path is not dramatically more expensive than the string path per value on a 1000-element array, which is the "how big is it really" question the spec asks. Do not read more than that into a smoke run.

## Setup

`Application.cfc` seeds every fixture as a **serialized string**, the inverse of `tests-json-serialize`, which seeds live objects. The paired fixtures are built with the same code as the serialize family and then `serializeJson`'d at seed time, so the bytes are what that family's cells emit on the same jar. The number-axis fixtures (`quoted`, `decimal`, `long-digits`, `exponent`) are built by hand as strings, because `serializeJson` would reformat the literals and remove the axis.

Loop counts are in application scope (`jdLoopSmall` / `jdLoopMid`, default **20 / 5**, env-overridable as `JD_LOOP_SMALL` / `JD_LOOP_MID`) so all cells retune together. The defaults are lower than the serialize family's 50 / 10 because parsing costs about 2x serializing the same bytes and 50 blew the per-cycle band (a 100k / 40k run was heading for 25 minutes). **For a cross-family pair the loop counts must match**: set `JD_LOOP_SMALL=50 JD_LOOP_MID=10` for the run, or bring the `JS_` side down, and say which in the log.

**Never read a scope inside a cell's loop body.** The application scope is a `synchronizedMap`, so a fixture read in the loop measures the scope wrapper rather than the cell. Every cell hoists both its fixture and its loop bound into a page variable first.

## Running

```cmd
cd D:\work\lucee-testlab\test-output\benchmark-json-deserialize
.\run-smoke.bat                                REM whole family, 1k cycles, current loader\target
.\run-smoke.bat des-numbers 1 1                REM the number axis only
.\run-baseline.bat baseline nojfr              REM measurement run - read these numbers
.\run-baseline.bat baseline alloc              REM TLAB detail: BigDecimal / BigInteger / LNumber / Double per literal
.\run-verify.bat base                          REM the number-literal corpus
```

`run-baseline.bat TAG MODE [jar] [threads]`, MODE = `nojfr` | `jfr` | `alloc` | `jit`. Both runners pin JDK 25 and hard-fail if it is missing. `run-baseline.bat` stashes the jar it ran against as `lucee-<TAG>.jar` in this dir, because `loader\target` is overwritten by the next build and an A/B needs both halves to still exist; pass that jar back as arg 3 to reproduce.

JFRs go to the lucee8 archive, one dir per jar: `D:\work\lucee8\test-output\jfr\<version>-testlab-json-deserialize-<tag>\`. A re-capture of an existing jar on another cell set sets `JD_JFR_TAG` to that jar's tag and uses a fresh `TAG` for the file names, so the dir stays keyed by the build and not by the run. See `test-output/jfr/README.md` for the convention.

`BENCHMARK_CYCLES` and `BENCHMARK_ONCE_CYCLES` are in **thousands**; `BENCHMARK_WARMUP_CYCLES` is a raw count. `run-baseline.bat` defaults to **30k `never` / 10k `once`**, the family's canonical measurement shape, about 3 minutes a run at the default loop counts. Run the baseline twice on the same stashed jar before reading any delta: without a spread figure no A/B means anything, and the serialize family found four of its twelve cells too noisy to carry a claim.

The JFR mode notes in the serialize README apply unchanged: `alloc` is the default here because the change removes allocations per literal rather than instructions, `jit` is the only mode whose `Compilation` threshold lets `jit-timeline` resolve on a 30s bench, and `steady-start` never resolves in this harness because the virtual-thread carrier pool keeps re-profiling.

## The invariance gate

`verify-invariance.cfm` is the reason this family can justify a change to how a literal becomes a value. It walks 46 numeric literals (small ints, fractions, exponents, the classic hard-to-round doubles, and a digit-count ladder across `BigDecimal`'s 18-digit compact boundary and `DECIMAL128`'s 34-digit rounding boundary), parses each four ways (bare, as an array element, as a struct value, and concatenated with an empty string through `evaluate()`, which reaches the ref's `getString()` instead of `getValue()`), and prints for every result the **Java type**, the **CFML string form** and the **raw IEEE-754 bits** when it is a `Double`. It ends in a single whole-corpus fingerprint.

```cmd
.\run-verify.bat base
REM ... apply the change, ant fast ...
.\run-verify.bat double-literal
fc verify-base.txt verify-double-literal.txt
```

The bits are the point. `toString()` on a double is shortest-repr and hides a 1-ulp difference; two routes to a double are only interchangeable if they agree on all 64 bits for every literal the grammar can produce. The type column catches the other failure: a fast path that hands back a `Long` for `12`, or a `BigDecimal` where a `Double` was, changes `isValid("integer")`, round-trip output and `1` vs `1.0` for every caller.

The corpus runs under the application's `preciseMath` (default off). The precise path is the one a fast-path change leaves alone by design; set `this.preciseMath = true` in `Application.cfc` and re-run for a one-off if a change claims to touch it.

Baseline on 188-SNAPSHOT: `verify-base.txt`, fingerprint `82cb8f4c…` for the original three shapes; `verify-wc-base4.txt`, fingerprint `72c2c20e…`, once the `concat` shape was added (the two are not comparable, the hash covers the whole output). Every one of the 138 `getValue()` results is a `Double`, and the three container shapes agree line for line; the 46 `concat` results are `String`s, as concatenation must produce, and their text matches the `str=` column of the other shapes, including `-0` and `-0.0` printing as `0` while the bits column shows the sign bit is there. Things in that output that look wrong and are not: `1e309` prints its string form as `?` because script-runner's console codepage cannot render the infinity glyph `Caster.toString` produces (the fingerprint hashes the raw output, so it is unaffected); the subnormals print `str=0` because the CFML string form drops them while the bits (`0x1`, `0x10000000000000`) show the parse was exact; `2.2250738585072012e-308` lands on the same bits as the smallest normal, which is the correctly rounded answer, not a collision.

## Open questions and known gaps

- **`negative` +6-8% in the `Double`-storing arms: closed by removal, not explanation.** The `digitwalk-fold` arm folds the sign into the literal so `Negate` is off the JSON path and the cell reads -53%. Why C2 handled `Negate.getValue` over a stored `Double` worse than over a per-evaluation one was never captured; `Negate` still exists for `-someVariable` and the question stands for it, at much lower stakes.
- **`ParserString.init` is now the top allocator on the deserialize path**, 78% of all `char[]` bytes in the `digitwalk-fold` capture. Per document, not per literal; a `ParserString` change, not a number-literal one.
- **`des-api-response` is at the harness floor** (31 ms per 1k cycles). It needs its own loop count, 5-10x `jdLoopMid`, before it can carry a claim on its own. Left at `jdLoopMid` for now so it stays matched to `ser-api-response`, which has the same problem.
- **`preciseMath` on.** Not varied. Under precise math the literal stays a `BigDecimal` and the whole detour is the correct path, so a fast-path change should leave that arm flat. A sibling axis, not built.
- **Integers as `Long`.** A JSON `12` is a `Double 12.0` today. Whether the fast path should produce an integral type is a behaviour question the spec explicitly excludes; the corpus's type column is where it would surface.
- **JSON5 surface** (comments, unquoted keys, trailing commas, leading plus) is `tests-json`'s territory and is not repeated here.
- **Loop-count mismatch with `tests-json`.** That family's `innerLoop` is 10 for every cell; here the number cells run at 20 and the mid cells at 5. No cell is directly comparable to a `tests-json` cell without setting `JD_LOOP_MID=10` for `des-api-response`.
