# tests-json-serialize

`serializeJSON` write-path micro-benchmarks — one axis per CFM, so an alloc or CPU run can pin which part of the escape-and-append chain a fix actually moved.

Designed against [jsonconverter-escapejs-write-path](../../../../lucee-projects/runtime/jsonconverter-escapejs-write-path.md). Prior art it must be read against: [compact-string-inflation-hotspots](../../../../lucee-projects/runtime/compact-string-inflation-hotspots.md) (the inflation half) and [LDEV-6052](https://luceeserver.atlassian.net/browse/LDEV-6052) (base64). Correctness twins in the Lucee repo: `test/functions/SerializeJSON.cfc`, `test/functions/toBase64.cfc`, `test/functions/BinaryEncode.cfc`.

## Why this family exists

`tests-json` is entirely **deserialize** — 20 parse cells and one roundtrip. That side has had a targeted optimisation pass and won `big` +37.9% / `stupid-big` +39.1%. The **serialize** side has never had one, and has no bench coverage at all. This family is the missing half.

The specific target is `StringUtil.escapeJS`, which runs once per struct key, per query column name and per string value of every `serializeJSON`. Four separable costs sit in it, and each one scales with a *different* property of the payload — which is why this family splits by axis rather than by realistic-looking document.

| Change under test | Scales with | Cell that maximises it |
| --- | --- | --- |
| Presize `StringBuilder` to `len + 2` | escapeJS **call count** | `ser-wide-struct-200`, `ser-query-struct` |
| Drop `str.toCharArray()` | **chars** passed through escapeJS | `ser-long-strings-clean` |
| Escape-class table + no-escape fast path | chars, and **escape density** | `ser-long-strings-clean` vs `-escaped` |
| Appendable overload (no intermediate String) | escapeJS **call count** | `ser-wide-struct-200`, `ser-query-struct` |

## Baseline — 8.0.0.188-SNAPSHOT, JDK 25, 32 threads

`run-baseline.bat baseline nojfr`, 10k never / 1k once, loop counts 50 / 10. Run twice against the same stashed jar to establish run-to-run spread, because without a spread figure no later A/B means anything.

| Cell | run 1 (ms) | run 2 (ms) | spread | GC pause |
| --- | ---: | ---: | ---: | ---: |
| `ser-embedded-json` | 117 | 123 | 5.1% | 4ms |
| `ser-api-response` | 332 | 321 | 3.4% | 5ms |
| `ser-numbers-array` **(control)** | 590 | 577 | 2.3% | 13ms |
| `ser-query-column` | 677 | 678 | **0.1%** | 12ms |
| `ser-nonascii-utf8` | 792 | 824 | 4.0% | 24ms |
| `ser-query-struct` | 1,055 | 1,070 | 1.4% | 19ms |
| `ser-wide-struct-200` | 1,078 | 1,082 | 0.4% | 28ms |
| `ser-nonascii-ascii-charset` | 1,227 | 1,237 | 0.8% | 33ms |
| `ser-long-strings-clean` | 1,720 | 1,727 | **0.4%** | 42ms |
| `ser-long-strings-escaped` | 2,062 | 2,059 | **0.1%** | 50ms |
| `ser-big` | 1,809 | 1,761 | 2.7% | 22ms |
| `ser-binary` | 4,700 | 4,711 | 0.2% | 113ms |

**Spread is ≤5%, and under 2% for every cell that matters to a pair.** The three widest are the three cheapest, which is expected — they are the most dominated by per-cycle harness cost. Anything under ~5% on `embedded-json` / `api-response` / `nonascii-utf8` is noise; on the rest, 2% is real.

## SUPERSEDING: 100k never / 40k once — read this before the 10k tables above

Everything above was measured at **10k never / 1k once**. Re-measured at **100k never / 40k once** (`BENCHMARK_CYCLES=100 BENCHMARK_ONCE_CYCLES=40`), two baseline runs plus one post-6052 run. The 10k tables are kept because they are what the earlier conclusions were drawn from, but **the 100k numbers supersede them** and they revise two claims.

| Cell | base r1 | base r2 | spread | post-6052 | delta |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ser-binary` | 46,192 | 45,895 | **0.6%** | 17,993 | **-61% (2.56x)** |
| `ser-embedded-json` | 975 | 969 | 0.6% | 968 | flat |
| `ser-long-strings-clean` | 16,624 | 16,609 | **0.1%** | 16,792 | +1.0% |
| `ser-nonascii-ascii-charset` | 11,952 | 11,931 | 0.2% | 12,029 | +0.7% |
| `ser-wide-struct-200` | 10,600 | 10,641 | 0.4% | 10,654 | flat |
| `ser-long-strings-escaped` | 20,265 | 20,182 | 0.4% | 20,943 | +3.4% |
| `ser-nonascii-utf8` | 7,542 | 7,576 | 0.5% | 7,669 | +1.4% |
| `ser-numbers-array` **(control)** | 5,417 | 5,364 | 1.0% | 5,371 | flat |
| `ser-query-struct` | 10,856 | 10,204 | **6.4%** | 10,574 | within spread |
| `ser-query-column` | 6,856 | 6,312 | **8.6%** | 6,331 | within spread |
| `ser-api-response` | 1,930 | 1,750 | **9.7%** | 1,992 | within spread |
| `ser-big` | 16,338 | 12,069 | **26%** | 16,552 | **unusable** |

**LDEV-6052 confirmed at 10x the cycles: 2.56x on `ser-binary`, at 0.6% spread.** GC count 627/690 → 235, GC pause ~1,000 ms → 446 ms. That is the one solid result in this family.

### escapeJS leaf changes — `charAt` + nibble table + presize, on top of LDEV-6052

Tag `leaf` / `leaf-100k` / `leaf-100k-r2`, stashed jar `lucee-leaf.jar`, same 100k / 40k shape, two runs. Delta is the r1/r2 mean against the post-6052 column above. Corpus fingerprint identical.

| Cell | leaf r1 | leaf r2 | spread | delta vs post-6052 |
| --- | ---: | ---: | ---: | ---: |
| `ser-long-strings-clean` | 10,147 | 10,126 | 0.2% | **-40%** |
| `ser-nonascii-ascii-charset` | 7,132 | 7,008 | 1.8% | **-41%** |
| `ser-nonascii-utf8` | 5,303 | 5,267 | 0.7% | **-31%** |
| `ser-wide-struct-200` | 8,072 | 8,458 | 4.7% | **-22%** |
| `ser-long-strings-escaped` | 16,920 | 16,690 | 1.4% | **-20%** |
| `ser-embedded-json` | 840 | 825 | 1.8% | -14% |
| `ser-query-struct` | 8,457 | 8,150 | 3.7% | -21% (base spread 6.4%) |
| `ser-query-column` | 5,630 | 5,576 | 1.0% | -11%, inside base spread |
| `ser-api-response` | 1,604 | 1,616 | 0.7% | -19%, inside base spread |
| `ser-numbers-array` **(control)** | 5,352 | 5,336 | 0.3% | flat |
| `ser-binary` (6052 cell) | 17,888 | 17,767 | 0.7% | flat |
| `ser-big` | 11,137 | 11,358 | 2.0% | unusable cell |

Allocation (`alloc` mode, vs `js-post-6052-alloc.jfr`): `char[]` -100%, `String` -51%, `Arrays.copyOf` `byte[]` -22%, `StringBuilder` unchanged (+2%). Pair ratios: escaped/clean 1.22x → **1.67x**, ascii-charset/utf8 1.58x → 1.34x. The `escapeJS` comparator for any further leaf change is `js-post-6052-alloc.jfr`, not the pre-6052 baseline — the working branch carries LDEV-6052.

### escapeJS `StringBuilder` overload — on top of the leaf changes

Tag `overload` / `overload-100k` / `overload-100k-r2`, stashed jar `lucee-overload.jar`. `escapeJS(StringBuilder, …)` writes into the caller's buffer; JSONConverter reaches it through a private `appendEscaped(Appendable, String)` with one `instanceof StringBuilder`. Delta is the r1/r2 mean against the leaf mean above. Corpus fingerprint identical.

| Cell | ov r1 | ov r2 | spread | delta vs leaf | cumulative vs post-6052 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `ser-nonascii-ascii-charset` | 3,681 | 3,701 | 0.5% | **-48%** | **3.26x** |
| `ser-wide-struct-200` | 4,314 | 4,353 | 0.9% | **-48%** | **2.46x** |
| `ser-long-strings-escaped` | 9,297 | 9,188 | 1.2% | **-45%** | 2.27x |
| `ser-embedded-json` | 479 | 505 | 5.3% | -41% | 1.97x |
| `ser-nonascii-utf8` | 3,578 | 3,579 | 0.0% | **-32%** | 2.14x |
| `ser-long-strings-clean` | 7,258 | 7,175 | 1.2% | **-29%** | 2.33x |
| `ser-query-struct` | 7,511 | 7,125 | 5.3% | -12% | 1.44x |
| `ser-query-column` | 5,546 | 5,860 | 5.5% | within spread | — |
| `ser-api-response` | 1,460 | 1,575 | 7.6% | within spread | — |
| `ser-binary` (6052 cell) | 17,950 | 17,997 | 0.3% | +0.8% | — |
| `ser-numbers-array` **(control)** | 5,528 | 5,607 | 1.4% | +4.2% in-family, **+0.8% isolated** | flat |
| `ser-big` | 11,078 | 11,128 | 0.5% | unusable cell | — |

**The control moved 4.2% in the family run and had to be checked.** Isolated (`BENCHMARK_FILTER=ser-numbers-array`), interleaved leaf/overload/leaf/overload at 100k: 5,380 / 5,459 / 5,345 / 5,355 — +0.8% mean, +0.2% on the second pair. Family-run drift after the `alloc` capture, not the helper. Allocation (vs `js-leaf-alloc.jfr`): `StringBuilder` at `escapeJS` gone, `byte[]` -25% (`AbstractStringBuilder.<init>` -94%, `copyOfRange` -36%, `StringUTF16.newBytesFor` -98%), `String` at `toString` -94%, GC pause 852 → 722 ms. GC counts -30–45% on the moved cells.

### UTF-8 `canEncode` skip — on top of the overload

Tag `utf8` / `utf8-100k` / `utf8-100k-r2`, stashed jar `lucee-utf8.jar`. For a UTF-8 encoder `escapeJS` answers `canEncode(c)` as `!Character.isSurrogate(c)` instead of calling the encoder. Fingerprint identical. `UTF_8$Encoder.canEncode` CPU samples 70 → 0 (0.37% of samples), `HeapByteBuffer` -44%. **Timing flat:** `nonascii-utf8` +0.6%. The family run showed long-strings +5–7% and the control -5.6% in the same session; `long-strings-clean` isolated and interleaved (`BENCHMARK_FILTER`) came back 7,235 / 7,140 vs 7,393 / 7,174, +1.3% mean, so that was cross-session drift. Allocation-only result: the fixture's non-ASCII strings are mostly ASCII, so the encoder ran rarely per char and the cell's cost is UTF16 inflation, not `canEncode`.

### Chunked no-escape fast path — on top of the UTF-8 skip. Regressed, not kept in this form

Tag `fastpath` / `fastpath-100k` / `fastpath-100k-r2`, stashed jar `lucee-fastpath.jar`. A 128-entry table classifies ASCII; the loop scans for the next char that needs work, bulk-appends the clean run before it with `append(CharSequence, int, int)`, handles that one char in the existing switch, resumes. A slash stays in the run unless preceded by `<`, the quote not used for wrapping stays in the run. Fingerprint identical. Delta is the r1/r2 mean against the utf8 mean.

| Cell | fp r1 | fp r2 | spread | delta vs utf8 |
| --- | ---: | ---: | ---: | ---: |
| `ser-long-strings-escaped` | 11,790 | 11,739 | 0.4% | **+21%** |
| `ser-nonascii-ascii-charset` | 3,931 | 3,968 | 0.9% | **+6.0%** |
| `ser-long-strings-clean` | 7,129 | 7,000 | 1.8% | **-8.2%** |
| `ser-nonascii-utf8` | 3,644 | 3,602 | 1.2% | +0.7% |
| `ser-wide-struct-200` | 4,371 | 4,334 | 0.9% | flat |
| `ser-embedded-json` | 479 | 472 | 1.5% | +1.2% |
| `ser-numbers-array` **(control)** | 5,356 | 5,339 | 0.3% | +1.8% |
| `ser-binary` (6052 cell) | 18,021 | 18,125 | 0.6% | +0.8% |
| `ser-query-column` | 4,981 | 5,007 | 0.5% | -4.8%, inside base spread |
| `ser-query-struct` | 5,956 | 5,625 | 5.7% | noisy cell |
| `ser-api-response` | 1,526 | 1,457 | 4.6% | within spread |
| `ser-big` | 10,469 | 10,730 | 2.5% | unusable cell |

Two causes, both in the captures. **Dense escapes make short runs:** the escaped fixture unit is 14 chars with five escapes (the cell comment says 1 in 10, it is 1 in 3), so clean runs average two chars, and a bulk append of two bytes pays a range check, a capacity check and an `arraycopy` stub call, more than two inlined `append(char)`. Exec samples: per-char `StringBuilder.append` under `escapeJS` -40%, `ensureCapacitySameCoder` and `appendChars` new, `Arrays.copyOf` under `escapeJS` +538%. **Double `canEncode` under US-ASCII:** the pre-check asks the encoder, then the switch default asks again for the same char (`HeapByteBuffer` +26%). UTF-8 is unaffected because it answers with `isSurrogate`. Allocation otherwise flat, as expected for a CPU-only change. The clean-cell win says bulk copy is right for long runs; the next cut appends runs under 8 chars per char and stops re-testing in the default branch.

### Whole-string clean scan — replaces the chunked fast path. Kept

Tag `wholestring` / `wholestring-100k` / `wholestring-100k-r2`, stashed jar `lucee-wholestring.jar`. Scan with a 128-entry table for the first char that needs work; none → the whole string goes in with one `append(String)`; otherwise the clean prefix goes in with one bulk copy and the rest runs char by char, table lookup then `append(c)` for plain chars, the existing switch for the rest. No length threshold, at most one bulk copy per string, no char tested twice. Fingerprint identical. Two cells were added for this cut: `ser-long-strings-late-escape` (the design's worst case, a 4KB clean value ending in one quote) and `ser-long-strings-sparse` (one escape in 50, realistic prose).

**Isolated interleaved pairs are the evidence.** The same utf8 jar measures 7,693 in-family and 7,117 isolated on `clean`, so a cross-session in-family delta cannot carry a claim at this size. utf8 / wholestring / utf8 / wholestring with `BENCHMARK_FILTER`:

| Cell | utf8 r1 | utf8 r2 | ws r1 | ws r2 | ws spread | delta |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| `ser-long-strings-escaped` | 8,716 | 8,792 | 8,231 | 8,391 | 1.9% | **-5.1%** |
| `ser-nonascii-utf8` | 3,494 | 3,472 | 3,277 | 3,310 | 1.0% | **-5.4%** |
| `ser-long-strings-clean` | 7,117 | 7,120 | 6,914 | 6,940 | 0.4% | **-2.7%** |
| `ser-long-strings-late-escape` | 6,991 | 7,012 | 6,906 | 6,913 | 0.1% | -1.3% |
| `ser-long-strings-sparse` | 7,135 | 7,117 | 7,147 | 7,064 | 1.2% | -0.3% |
| `ser-nonascii-ascii-charset` | 3,690 | 3,653 | 3,533 | 3,639 | 3.0% | -2.3%, inside spread |

Full family, two runs, for the record: `clean` 6,852 / 6,858, `late-escape` 6,849 / 6,875, `sparse` 7,726 / 7,595, `escaped` 10,584 / 10,174 (4% spread, +7% against the earlier-session utf8 in-family mean and contradicted by the isolated pair), `nonascii-utf8` 3,303 / 3,311, `wide-struct-200` 4,248 / 4,228, `numbers-array` 5,343 / 5,289, `binary` 17,518 / 17,576. `api-response` and `big`, the first two cells alphabetically, swung 34% and 13% between runs.

Why the worst case doesn't hurt: `late-escape` pays a full wasted scan and then the whole per-char pass, and still lands 1.3% ahead, because the per-char pass itself got cheaper — one table lookup and an `append(c)` instead of a switch dispatch plus `isISOControl` for every clean char. That same saving on the dense cell's two-thirds clean chars is the `escaped` win. Allocation-neutral (`byte[]` -0.2% against a utf8 capture on the same 14 cells, tag `utf8-14`). `escapeJS` picked up 43 `profile_predicate` recompiles as cells switch between all-clean and dirty, a bench artifact worth knowing about.

### `ser-binary-big` — the quoted base64 concat in `JSONConverter._serialize`. Kept, second cut

New cell for this item: 4MB `byte[]`, 5.6MB base64 out, one call per cycle, `escapeJS` never on the path. Every whole-payload copy is a G1 humongous allocation at this size, so this is a GC-shape cell. It is **not in the family run**: run it with `BENCHMARK_FILTER=ser-binary-big BENCHMARK_CYCLES=10 BENCHMARK_ONCE_CYCLES=2`. A `binary` case was added to the corpus at the same time (61 cases, fingerprint now `63fcd641…`, identical on the jar before and after), because the site's output was pinned by nothing.

**First cut regressed.** Tag `binbig`: `sb.append('"').append(encoded).append('"')` with no presize, **+12%** (17,919 / 17,981 vs 20,206 / 19,957), `Arrays.copyOf` bytes 3x. `StringBuilder` grows to an exact fit when the request exceeds its size and doubles otherwise; the concat produced an exact-length `String` so the builder grew once and nothing followed, while the plain appends land the payload exact-fit and the closing quote then doubles the buffer, an 11.2MB allocation and a 5.6MB copy for the 5.6MB allocation and copy the concat cost. Replacing a concat with appends into a shared builder can cost more than the concat.

**Second cut kept.** Tag `binbig2`: encode to a local, `ensureCapacity(length + encoded.length + 2)` when the target is a `StringBuilder`, then the three appends. Interleaved pairs against the wholestring jar:

| Run | wholestring | binbig2 |
| --- | ---: | ---: |
| pair 1 | 18,486 | 13,425 |
| pair 2 | 17,924 | 11,806 |
| mean | 18,205 | 12,616 (**-31%**) |

The new jar's two runs are 13% apart, so read it as -26% to -34%. JFR GC causes: humongous-allocation collections **812 → 438**, their STW 592 → 393 ms, all pause -33%; the concat's `allocateUninitializedArray` -143.8 GB, `Arrays.copyOf` -2% (the presize growth replaces the old growth one for one). Whole-payload allocations per call 5 → 4; below four needs the payload to stay bytes to the output, which is the Writer path. The harness's per-cell GC counts swing with heap sizing on this cell (58 and 130 on two identical runs) and are not usable here.

The pair ratios held across the 10x change, which is the best evidence they are real:

| Pair | at 10k | at 100k |
| --- | ---: | ---: |
| `escaped` / `clean` | 1.20x | **1.22x** |
| `query-struct` / `query-column` | 1.56x | **1.60x** |
| `ascii-charset` / `utf8` | 1.55x | **1.58x** |
| `wide-struct` / `numbers` | 1.83x | 1.97x |

### Revision 1: `ser-big` is an unreliable cell, and the "neighbour tax" story is withdrawn

`ser-big` shows **26% run-to-run spread on the same jar** (16,338 vs 12,069). It is not a usable cell. It is the only cell with no inner loop — one 41KB serialize per cycle — so per-cycle harness overhead and GC timing dominate it.

That retires the mechanism claimed in the next section. `ser-big`'s apparent 1.4x win from LDEV-6052 at 10k was **noise in an unstable cell**, not a neighbour tax being lifted. Three independent measurements now agree it is flat: isolated at 10k (1,343 vs 1,401), family at 100k (16,338/12,069 vs 16,552), and the fact that LDEV-6052 provably touches nothing `ser-big` executes. Fix the cell (add an inner loop) or drop it.

### Revision 2: four cells are too noisy to carry a claim

`ser-big` 26%, `ser-api-response` 9.7%, `ser-query-column` 8.6%, `ser-query-struct` 6.4%. The other eight are at or under 1%. **Only quote a delta from a cell whose spread you have measured**, and note `query-column`/`query-struct` being noisy weakens the call-count pair — its 1.60x ratio is larger than either cell's spread, so the ratio survives, but a small change to it would not be detectable.

## Historical: the cells-not-independent hypothesis (mechanism withdrawn, see Revision 1)

Found the hard way while validating LDEV-6052. **A cell that allocates heavily taxes every other cell in the same run**, because the whole family shares one JVM.

`ser-big` measured **1,809ms in the family run but 1,343ms alone** on the same baseline jar — a 35% penalty purely from its neighbours. `ser-binary` is the culprit: the old `Base64Encoder` allocated a `char[4]` per 3 input bytes, and warmup plus the `once` pass ran it before `never`/`ser-big` was measured.

The consequence is that LDEV-6052 made `ser-big` look **1.4x faster** in the family run (1,809 → 1,282ms) when it is genuinely **flat** in isolation (1,343 → 1,401ms). The apparent win was the removal of a tax, not a change to `ser-big`'s path — which is obvious in hindsight, since LDEV-6052 does not touch anything `ser-big` executes.

**Rule: any per-cell claim needs an isolation run.**

```cmd
BENCHMARK_FILTER=ser-big  run-baseline.bat <tag>-bigonly nojfr <jar>
```

The family run stays useful for the **pairs** — both halves of a pair pay the same tax, so the ratio survives. It is the absolute per-cell numbers that don't travel. Every absolute in the baseline table above is a family-run number and carries this contamination.

This also means the contamination is not purely an artifact: in production, a request serializing a large binary really does degrade its neighbours through GC and heap pressure. It is just not a claim about the neighbour's own code.

### The ratios

| Pair | Ratio | Reading |
| --- | ---: | --- |
| `long-strings-escaped` / `-clean` | **1.20x** | cost of the per-character escape branching, at identical key count and value length |
| `wide-struct-200` / `numbers-array` | **1.83x** | escapeJS at max call density against a same-sized payload that never calls it |
| `query-struct` / `query-column` | **1.56x** | 400 key calls against 16, same data |
| `nonascii-ascii-charset` / `-utf8` | **1.55x** | `\uXXXX` branch against raw-append-plus-inflate, but on 2.15x the output bytes |

**The smoke run's `query-struct` ≈ `query-column` result was noise.** At 10k cycles they separate cleanly at 1.56x in both runs, so the call-count axis is real and the open question is answered: escapeJS call count does surface. This is why the README said not to read a smoke number.

### Where the allocations actually are

`run-baseline.bat baseline alloc`. Weighted TLAB bytes, so treat the absolute GB figures as sampling-inflated and read only the shares. One JVM runs all 12 cells (14 since the whole-string cut), so this is family-wide attribution.

| Class | Site | Share of that class |
| --- | --- | ---: |
| `char[]` | `Base64Encoder.encodeGroup` | **60%** |
| `char[]` | `String.toCharArray` (`StringLatin1`/`StringUTF16.toChars`) | **40%** |
| `String.toCharArray` | `StringUtil.escapeJS` | **100%** |
| `StringBuilder` | `StringUtil.escapeJS` | **91%** |
| `java.lang.String` | `StringBuilder.toString` | 62% |
| `java.lang.String` | `Integer.toUnsignedString0` | **29%** |
| `Integer.toHexString` | `StringUtil.escapeJS` | **100%** |
| `byte[]` | `Arrays.copyOf` ← `ensureCapacityNewCoder` (**inflation**) | **80%** of copyOf |
| `byte[]` | `Arrays.copyOf` ← `ensureCapacitySameCoder` (plain growth) | 18% of copyOf |
| `ensureCapacityNewCoder` owner | `JSONConverter._serialize` / `_serializeStruct` / `_serializeList` / `_serializeQuery` | — |

Four things fall out of that, one of them unexpected:

- **`escapeJS` owns 100% of `toCharArray` and 91% of all `StringBuilder` allocation** in the run. Nothing else in Lucee calls `toCharArray` at rate. Both of the spec's zero-behaviour-surface changes are aimed at real, dominant sites.
- **`Base64Encoder.encodeGroup` is 60% of all `char[]` bytes** — the `new char[4]` per 3 input bytes, quantified. That is LDEV-6052's target and it is the single largest `char[]` producer in a JSON *serialize* benchmark.
- **The outer-builder inflation dwarfs plain growth, 80% against 18%**, and it is owned by `JSONConverter._serialize*` — the outer document builder, not escapeJS's local one. This is exactly the split `compact-string-inflation-hotspots.md` predicted, now measured. It also means **that doc's Writer-streaming fix outranks everything in the escapeJS spec** on this workload.
- **`Integer.toHexString` is 100% escapeJS and 29% of all `String` allocation** — a fresh `String` per escaped character on the `\uXXXX` branch. This was **not in the spec**; the bench found it.

**Caveat that governs all four:** 2 of the 12 cells at the time were deliberately non-ASCII, so the inflation and `toHexString` shares are properties of this fixture mix, not of production traffic. They prove those paths are very expensive per occurrence. They do not prove how often production hits them — `compact-string-inflation-hotspots.md` is explicit that the preside and wheels soaks are mostly ASCII and showed neither. Do not quote 80% or 29% as a production figure.

## Arm: post-LDEV-6052 — `java.util.Base64`

[LDEV-6052](https://luceeserver.atlassian.net/browse/LDEV-6052) rebased onto 8.0 (`LDEV-6052-rebased-8.0`, two commits on `59b95e84c`) and measured against the stashed `lucee-baseline.jar`. Two `nojfr` runs per arm plus one `alloc` capture.

**The claim, isolated** (`BENCHMARK_FILTER=ser-binary`, so no cross-cell tax on either side):

| | baseline | post-6052 | delta |
| --- | ---: | ---: | ---: |
| `ser-binary` | 4,749 ms | 2,039 ms | **2.33x faster** |
| GC count | 77 | 33 | **-57%** |
| GC pause | 112 ms | 48 ms | **-57%** |

Family-wide allocation (`alloc` capture, class diff):

| Class | events | bytes |
| --- | ---: | ---: |
| `char[]` | 202 k → 90.6 k (**-55%**) | 84.7 → 31.3 GB (**-63%**) |
| `byte[]` | 663 k → 1.1 M (+59%) | 302.7 → 296.1 GB (-2%) |
| whole-run GC pause | 440 → 407 events | 1.0 s → 837 ms (-17%) |

The **-63% `char[]`** lands almost exactly on the 60% share attributed to `Base64Encoder.encodeGroup` in the baseline — the prediction and the measurement agree, which is the best evidence that the attribution method is sound.

The `byte[]` event count rising 59% while bytes fall 2% is the JDK encoder allocating right-sized arrays instead of a doubling `StringBuilder` chain: more allocations, less total garbage, and far fewer large ones (hence the GC halving).

**Every other cell is flat within spread**, which is correct — LDEV-6052 touches nothing else on the serialize path. `ser-big` looked like a 1.4x win in the family run and is not; see the independence warning above. That is the one result worth reading twice.

| CFM | Axis |
| --- | --- |
| `ser-numbers-array.cfm` | **control** — 1000 integers, zero escapeJS calls. Exists to be unchanged; if an escapeJS fix moves this cell, it touched the number/array walk |
| `ser-wide-struct-200.cfm` | **call-count headline** — 200 short ASCII keys, integer values. Maximum escapeJS calls per serialized byte |
| `ser-long-strings-clean.cfm` | **char-count headline** — 10 keys, ~4KB pure-ASCII values needing zero escaping, so the no-escape fast path is reachable |
| `ser-long-strings-escaped.cfm` | A/B partner for the above — same key count, same value length, ~1 char in 10 needs an escape |
| `ser-embedded-json.cfm` | the realistic version of `-escaped` — 20 values, each a JSON document held as a string, so every quote inside is escaped. API passthrough and cached-payload shape |
| `ser-nonascii-utf8.cfm` | **the inflation path** — default UTF-8 encoder `canEncode()`s everything, so chars append raw and the LATIN1 builder inflates to UTF16 |
| `ser-nonascii-ascii-charset.cfm` | A/B partner on identical data — `US-ASCII` makes `canEncode()` false, so chars take `\uXXXX` and nothing inflates |
| `ser-api-response.cfm` | realistic mixed ~830-byte payload. Same fixture shape as `tests-json/deserialize-api-response`, so parse and serialize can be read as a cross-family pair |
| `ser-query-column.cfm` | 50x8 query, `column` format — 16 key calls total |
| `ser-query-struct.cfm` | same query, `struct` format — 400 key calls. 25x the call count on the same data |
| `ser-binary.cfm` | 64KB `byte[]`, matching LDEV-6052's payload size. **Not an escapeJS cell** — binary goes to `Base64Coder.encode`, so this should be flat under escapeJS work and move a lot under LDEV-6052 |
| `ser-big.cfm` | sustained ~41KB output, 500 records. Mirrors `tests-json/deserialize-big`. No inner loop |

`_lengths.cfm` and `verify-invariance.cfm` are tools, not cells — neither matches the default `ser-` filter. If you run with `BENCHMARK_FILTER=*` they will be picked up as suites and the numbers will be meaningless.

## The pairs that produce ratios

Nothing here is meaningful as an absolute. Every cell is meaningful against its partner.

- `long-strings-escaped` / `long-strings-clean` → **the cost of the per-character escape branching**, with key count and value length held constant. The cleanest pair in the family. The escape-class table should narrow it; the no-escape fast path should move only the `clean` side
- `wide-struct-200` / `numbers-array` → the whole cost of escapeJS at maximum call density, against a same-sized payload that never calls it
- `query-struct` / `query-column` → **call count at fixed data**, 400 key calls against 16
- `nonascii-utf8` / `nonascii-ascii-charset` → separates **inflation cost from escape cost** on identical input. Read as a direction, not a clean ratio: the `\uXXXX` branch produces 2.15x the output bytes (20,152 vs 9,352), so the cells are not payload-size-matched. If `ascii-charset` is nonetheless competitive despite doing strictly more per-char work on 2x the output, inflation is the dominant term
- `ser-api-response` vs `tests-json/deserialize-api-response` → **cross-family**, parse vs serialize on one document. The number that says whether the serialize side deserves the same attention the parse side got
- `binary` before/after LDEV-6052 → the `char[4]`-per-triplet encoder plus the `JSONConverter:800` double concat, isolated from everything escapeJS

## Fixture sizes (8.0.0.188-SNAPSHOT, measured)

Serialized output length, so assertions are set from fact rather than guesswork — three of them were wrong on the first smoke run and this is how they got fixed. Regenerate with `_lengths.cfm`.

| Fixture | Default charset | US-ASCII |
| --- | ---: | ---: |
| `numbersArray` | 3,894 | |
| `wideStruct200` | 2,385 | |
| `longStringsClean` | 41,072 | |
| `longStringsEscaped` | 57,122 | |
| `longStringsLateEscape` | 41,092 | |
| `longStringsSparse` | 42,962 | |
| `binaryBig` | 5,592,410 | |
| `embeddedJson` | 1,592 | |
| `nonAsciiValues` | 9,352 | 20,152 |
| `apiResponse` | 833 | |
| `binaryValue` | 87,386 | |
| `big` | 41,212 | |
| `rows` (column) | 4,572 | |
| `rows` (struct) | 7,693 | |

## Setup

`Application.cfc` seeds every fixture as a **live CFML object**, not a serialized string — the inverse of `tests-json`, which seeds strings. `nonAsciiValues` is built with `chr()` so the fixture file itself stays pure ASCII and cannot be corrupted by an editor or a checkout re-encoding it.

Loop counts are in application scope (`jsLoopSmall` / `jsLoopMid`, default 50 / 10, env-overridable as `JS_LOOP_SMALL` / `JS_LOOP_MID`) so all cells retune together. `ser-big` has no inner loop — one serialize already fills a cycle.

**Never read a scope inside a cell's loop body.** The application scope is a `synchronizedMap`, so a fixture read in the loop measures the scope wrapper rather than the cell. Every cell hoists both its fixture and its loop bound into a page variable first — a `for` condition re-evaluates every iteration.

## Running

```cmd
cd D:\work\lucee-testlab\test-output\benchmark-json-serialize
.\run-smoke.bat                                REM whole family, 1k cycles, current loader\target
.\run-smoke.bat ser-long 1 1                   REM one pair
.\run-baseline.bat baseline nojfr              REM measurement run — read these numbers
.\run-baseline.bat baseline alloc              REM TLAB detail for the allocation claims
.\run-verify.bat base                          REM the escapeJS value corpus
```

`run-baseline.bat TAG MODE [jar] [threads]`, MODE = `nojfr` | `jfr` | `alloc`. Both runners pin JDK 25 explicitly and hard-fail if it is missing. `run-baseline.bat` stashes the jar it ran against as `lucee-<TAG>.jar` because `loader\target` is overwritten by the next build and an A/B needs both halves to still exist — pass that jar back as arg 3 to reproduce. The JFR archive is one dir per jar, so a re-capture of an existing jar on another cell set sets `JS_JFR_TAG` to that jar's tag and uses a fresh `TAG` for the file names: `set JS_JFR_TAG=utf8` then `run-baseline.bat utf8-14cells alloc` lands in the `-utf8` dir and stashes nothing new. Unset, `JS_JFR_TAG` is `TAG`.

`BENCHMARK_CYCLES` and `BENCHMARK_ONCE_CYCLES` are in **thousands**; `BENCHMARK_WARMUP_CYCLES` is a raw count.

## JFR modes, and which one answers what

| mode | JFC | good for | not for |
| --- | --- | --- | --- |
| `alloc` | `jfc-high-frequency.jfc` | **the default here.** 1ms sampling, TLAB both sides with stacks, alloc-sample throttle 512/s — best resolution available for allocation and CPU attribution | no provenance events (`ActiveSetting`, `JVMInformation`), `Compilation` at 10ms so no JIT timeline |
| `jit` | `jfc-bench-jit.jfc` | JIT/compile/deopt questions. `jfc-soak-jit`'s breadth (58 events, provenance, `CompilerInlining`, `JitRestart`) with `Compilation` threshold **0** and 1ms sampling | heavier; `Compilation` at 0ms is only affordable on a short run |
| `jfr` | `jfc-soak-jit.jfc` | parity with the preside/wheels soak captures, if a cross-workload comparison is ever wanted | `Compilation` at 100ms, 5ms sampling — strictly worse than `jit` for this family |

**`jfc-bench-jit.jfc` exists because every soak profile thresholds `jdk.Compilation` at 100ms** (`jfc-high-frequency` at 10ms), which is correct for an hour-long run and starves a 30s bench — all four `jit-timeline` milestones come back `n/r`. At threshold 0 the compile event count goes **313 → 9,300** and `compilerQuiet` resolves at ~15s.

### `steady-start` is structurally unavailable in this family

Even at threshold 0, on a 25s-usable homogeneous single-cell run, `jit-timeline` reports:

```text
steady-start: NOT REACHED within recording - deopts never settle
```

Not a capture problem and not run length — `deopt-stacks` puts **78% of deopts in the JDK**, led by `ForkJoinPool.runWorker` (12%) plus `SoftReference.get`, `ConcurrentHashMap.addCount`, `WeakHashMap.expungeStaleEntries`. That is the virtual-thread carrier pool and JDK concurrency plumbing continuously re-profiling, which is inherent to a VT-driven bench harness. Lucee's own code is only 17% of deopts.

**Consequence: window with `--start compilerQuiet`, not `--start steady-start --end steady-end`.** The latter will never resolve here no matter how long the run.

## Interpreting results

**There is no locks mode, deliberately.** Nothing in this family contends on a shared monitor — `escapeJS` touches no static formatter, and every `JSONConverter` is a fresh local instance (~20 construction sites, all local). So the metric is per-call CPU and allocation rate, never monitor counts. This is the opposite of `tests-cachedwithin`, where the whole finding is a shared `DecimalFormat` monitor and calls/s against an integral control is the only honest metric.

**`alloc` mode is where the case actually lives.** Three of the four changes remove allocations rather than instructions — a `char[]`, a `StringBuilder`, an intermediate `String` per call. Throughput may barely move while allocation rate drops hard, and the allocation reduction is the leading indicator. Read `[C`, `[B` and `java.lang.String` TLAB counts, not just ms.

**The control cell is a gate, not a data point.** `ser-numbers-array` must not move. If it does, the change reached beyond the string path.

**Watch the inner-loop scaling before believing a cell.** The cheap cells (`embedded-json`, `api-response`) are dominated by per-cycle harness cost at low cycle counts, and did not scale linearly with a 5x inner-loop increase during smoke. If a cell's time does not respond to its loop count, it is measuring the harness.

## Open questions

Settled by the baseline:

- *Does `query-struct` actually cost more than `query-column`?* **Yes, 1.56x**, reproducible in both runs. Smoke had them level; that was noise. The escapeJS call-count axis surfaces, so the presize and Appendable changes have a real target.
- *Is the inflation term or the escape term dominant on non-ASCII?* **Inflation** — and not in escapeJS's local builder but in the outer `JSONConverter` document builder, at 80% of all `Arrays.copyOf` bytes against plain growth's 18%. The `ascii-charset` cell is 1.55x slower while producing 2.15x the output, so *per output byte* the escape-to-ASCII branch is cheaper than append-raw-and-inflate.

Still open, and the first one is now the most important thing in this family:

- **How much of the 1.20x escaped/clean gap is branching versus output volume?** `longStringsEscaped` serializes to 57,122 bytes against `longStringsClean`'s 41,072 — **39% more output for a 20% slowdown**. So the per-character escape branching may be close to free, with the gap explained by volume alone. A size-matched pair (shorter escaped values, so both sides emit ~41KB) would separate them. **This weakens the case for the escape-class table specifically** and should be resolved before anyone writes it.
- **Is the presize fix worth anything on its own?** Plain growth is 18% of `copyOf` bytes against inflation's 80%, and escapeJS's local builder is only part of that 18%. The change is still free, correct and zero-risk, but the baseline says do not expect it to move a cell.
- **Does the serialize side deserve the parse side's treatment?** `ser-api-response` (332ms) against `tests-json/deserialize-api-response` is the framing number, but the two families use different `innerLoop` values, so the existing numbers are not comparable as they stand. Needs the deserialize half re-run at matched cycles and loop counts on the same jar and host.

## Known gaps

- **Dates.** `JSONConverter:246` escapes `JSONDateFormat.format(...)` output, and date formatting reaches the shared-formatter contention that `tests-cachedwithin` exists to measure. Deliberately no date cell here — it would import that family's monitor problem into a family whose whole premise is that there is no monitor.
- **`preserveCase` / `dotNotationUpperCase`.** Decides whether keys go through `getString()` or `getUpperString()` at `:426` / `:559` / `:636`, and `getUpperString()` may allocate. Not varied; every cell runs at the default. A sibling axis, not built.
- **`JSConverter`.** The other escapeJS caller (5 sites), reached via cfajaxproxy, and the only one that passes a **null** encoder — so it is the only live path that takes the `\uXXXX` branch for ordinary non-ASCII. `ser-nonascii-ascii-charset` reaches the same branch through a charset instead, which is close but not the same call shape. Not covered.
- **The giant-payload case.** `compact-string-inflation-hotspots.md` recorded 120-134MB `ensureCapacityNewCoder` events and 589MB result strings from parallel `serializeJSON` on `tickets.ldev3367_cfc`. `ser-big` at 41KB is nowhere near that, and the Writer-streaming fix that case motivates is out of this family's scope. A `stupid-big` cell would be cheap to add if the outer-builder growth becomes the target.
- **`secureJSON` prefix and `cfajaxproxy` end-to-end.** Both wrap the same converter; neither adds an escapeJS axis.

## The invariance gate

`verify-invariance.cfm` is the reason this family can be used to justify a change to `escapeJS` at all. It is a ~60-case value corpus run under both charsets, printing short outputs verbatim and long ones as length + SHA-1, ending in a single whole-corpus fingerprint.

```cmd
.\run-verify.bat base
REM ... apply the change, ant fast ...
.\run-verify.bat presize
fc verify-base.txt verify-presize.txt
```

**Output must be byte-identical.** This is a serialization surface — apps hash it, store it, diff it and cross-engine-compare it, so a change that alters one escape is breaking even when it is "more correct". `LDEV-4101` is the precedent: `LDEV-3818` tightened base64 decode validation and it came back Critical/breaking-change/regression, `encrypt()` failing on keys generated by older versions, four releases to fix.

Baseline fingerprint on **8.0.0.188-SNAPSHOT**, verified stable across repeat runs:

```text
CORPUS FINGERPRINT sha1=55a3b18f73bcb5ddd06ed112a41094a174c6db88
```

That is the 60-case fingerprint every capture up to `wholestring` was gated on. A `binary` case was added for the `ser-binary-big` item (a `byte[]` value never reaches `escapeJS`, it is base64 in `JSONConverter` and the quoting site had no pin), so the corpus is 61 cases and the fingerprint is `sha1=63fcd6413c973f900b05370b13a4560c422ab49d`, identical on the jar before and after that change (`verify-wholestring-bincase.txt`, `verify-binbig.txt`).

### What the first run already established

The corpus was run against 8.0.0.188 before any change, and three of its results are worth having on record because they turn spec assertions into verified facts.

**Surrogates confirm the char-based iteration.** A surrogate pair emits two independent escapes, `["a😀b"]`, and a lone high surrogate emits `["a\ud83db"]` — **under both charsets**. That is because `canEncode()` on an individual surrogate `char` is false even for UTF-8 (a lone surrogate is not encodable), so surrogates take the `\uXXXX` branch while `é` under UTF-8 does not. Any rewrite that starts reasoning in code points changes these five lines. **Stay char-based.**

**The `\u000` / `\u00` / `\u0` / `\u` length ladder is a US-ASCII-only axis.** Under the default UTF-8 encoder, `canEncode()` is true for `chr(255)` through `chr(4096)`, so they all append raw and never reach the ladder — only ISO controls do. The ladder cases are only meaningful in the US-ASCII half of the output. This is worth knowing before "simplifying" the four-way length test: on the default charset it is nearly cold, and on `JSConverter`'s null-encoder path it is the normal case.

**`chr(0)` does not survive CFML**, so `ctrl-0x00` renders as `["ab"]` — the NUL is gone before `escapeJS` sees it. That case is therefore **not** testing `Character.isISOControl(0)`; `ctrl-0x01` is the lowest control actually exercised. Left in place because the line is still a useful diff anchor, but do not read it as coverage.

### Tool notes

Non-ASCII is rendered as `<U+XXXX>` by the corpus itself rather than printed verbatim. script-runner's stdout goes out in the platform codepage, and the first run turned every non-ASCII char into `?` — two different accents rendered identically, which would have silently hidden a diff in exactly the cases the corpus exists to protect. The SHA-1 is always taken over the raw output, never the safe rendering.

`keyCases` uses `structNew( "ordered" )`. With a plain struct the gate depended on hash iteration order, so a reorder would surface as a diff with nothing to do with escaping.

The corpus deliberately catches and records exceptions rather than rethrowing. That is contrary to the usual rule, and it is correct here: "case X throws Y" is a result to diff, and dying on case 3 of 60 would hide the other 57.
