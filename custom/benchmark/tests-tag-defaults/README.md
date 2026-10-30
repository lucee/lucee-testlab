# Tag attribute defaults

Microbenchmarks for the per-tag-call lookup of `this.tag` defaults in `PageContextImpl.setup()`. Spec: `luceee-projects/runtime/request/tag-attribute-defaults-key-per-tag-use.md`.

- `tag-silent`, `tag-mixed`: an app with two defaults (Preside's shape), neither for the tags used, so every tag call looks up the map and misses. Each request builds a new Modern AC, so the lazy `this.tag` parse is in the numbers too.
- `../tests-tag-nodefaults/`: the same pages in an app without `this.tag`. The map is `null`, so these should be flat across jars.

Every page runs 100 iterations of tags that compile to `pc.use()` (`cfsilent`, `cflock`, `cfsavecontent`). Inline-compiled tags (`cfif`, `cfloop`, `cfoutput`, …) never look up defaults.

The control is a sibling dir, not a subfolder: the harness lists the suite dir recursively but builds the template as `/<testDir>/<suite>.cfm`, so a subfolder's pages 404.

```sh
./dino run --app testlab --app-dir ../lucee-testlab/custom/benchmark --env BENCHMARK_TEST_DIR=tests-tag-defaults --env BENCHMARK_FILTER=* ...
./dino run --app testlab --app-dir ../lucee-testlab/custom/benchmark --env BENCHMARK_TEST_DIR=tests-tag-nodefaults --env BENCHMARK_FILTER=* ...
```
