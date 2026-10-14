# http-proxy

Does Lucee's HTTP traffic go through the configured proxy? Covers the internal downloaders (extensions, Maven / javasettings, update checks), `cfhttp` and javasettings, against real squid proxies and an httpbin target.

Each check records ok / error / elapsed; `summary.sh` judges them per scenario (worked, went through the proxy, failed with a broken proxy) and exits 1 on any miss, so CI goes red until Lucee honours the proxy everywhere.

## Running

Needs Docker, `jq`, `ant` and a [script-runner](https://github.com/lucee/script-runner) checkout next to this repo (or `SCRIPT_RUNNER=/path/to/script-runner`).

```bash
./run.sh 8.0/snapshot/jar good
./run.sh /path/to/lucee-8.0.0.0-SNAPSHOT.jar deadport
JAVA_HOME=/path/to/jdk-21 ./run.sh 6.2/snapshot/jar good
./summary.sh
```

script-runner runs Lucee on ant's JVM: 6.2 needs Java 21. `summary.sh` prints a markdown table per version and source from whatever is in `test-output/http-proxy`.

CI: `.github/workflows/http-proxy.yml`, 6.2, 7.0, 7.1 and 8.0 snapshots, every scenario with `.CFConfig.json`, then every source with `good`, summary tables in the job summary, results as an artifact.

### Versions

- **8.0**: Maven repos come from `.CFConfig.json` `maven.repository` / `snapshotRepository`, which replace Central, so a bypassing download fails hard.
- **6.2, 7.0, 7.1**: no repo config, only `LUCEE_MAVEN_DEFAULT_REPOSITORIES`, which goes before Central. A bypassing download fails on `testlab-maven`, then quietly succeeds from Central (slower). The mirror and squid logs show it: proxied requests reach the mirror from a squid container, bypasses don't reach it at all.
- `LUCEE_PROXY_*` env vars, `getMavenRepository()` and an unversioned `mavenLoad` are 8.0 only.
- Extensions come from the extension provider (`extension.lucee.org`, https) before 8.0, from Maven on 8.0. Ajax (`6E2CB28F-98FB-4B51-B6BE6C64ADF35473` 1.0.0.8) is on both and not bundled in any jar.
- Test snapshots, not stables: 7.0.5.41 never loads the server proxy from `.CFConfig.json`, fixed by LDEV-6548.

Output goes to `<repo>/test-output/http-proxy/<label>/<scenario>/`:

- `results.json`: one entry per check (`name`, `ok`, `detail` / `error`, `ms`)
- `run.txt`: script-runner output, all Lucee logs at `info` on the console (`LOG_LEVEL=debug` for more)
- `squid.log`, `squid-auth.log`: access log lines written during the run
- `.CFConfig.json`: the generated config for the scenario

Each run gets a unique Lucee working dir and an empty `user.home`, so nothing is served from a Maven or extension cache.

## Infra

`run.sh` starts these if they aren't running, all on the docker network `testlab`:

| Container | Port | What |
| --- | --- | --- |
| `testlab-squid` | 3138 | squid, no auth |
| `testlab-squid-auth` | 3139 | squid, basic auth `lucee` / `secret` |
| `testlab-httpbin` | 8091 | httpbin, the cfhttp target |
| `testlab-maven` | 8092 | nginx caching mirror of Maven Central over plain http (`maven/nginx.conf`) |

**Only reachable through the proxy.** With a proxy configured, the config points Lucee at `http://testlab-maven/maven2/` (as `maven.repository` and `maven.snapshotRepository`, replacing Central and Sonatype) and cfhttp at `http://testlab-httpbin`. Those names only resolve inside the docker network, so a request that goes through squid works, and one that bypasses the proxy fails straight away with `UnknownHostException`. The `none` control uses the published ports on `localhost` instead, which proves the fake itself works. The Lucee Maven repository is always added to the repo list, but it doesn't serve Central artifacts (404), so it can't give a false pass.

**Attribution.** Plain http through squid logs the full URL, so `squid.log` shows every POM, jar and metadata request. `maven.log` is the mirror's access log: the client is a squid container when proxied, the docker gateway when direct, plus `HIT` / `MISS`.

**The mirror** caches everything forever (metadata too), so runs are repeatable and Central sees each file once. The cache is the named volume `testlab-maven-cache`; nginx's cache doesn't work on a Docker Desktop (Windows) bind mount, every request is a `MISS`. `MAVEN_CACHE_DIR=/some/dir` bind-mounts a host dir instead, for CI caching on Linux. It replaces Central's `Set-Cookie` with a fixed Cloudflare-style `__cf_bm` cookie, so the HttpClient cookie WARN reproduces without Central.

Both squids add an `X-Testlab-Proxy` request header, and httpbin's `/anything` echoes it back, so a cfhttp check can tell whether it went direct or via which proxy. IPv6 is disabled in the squids and the mirror, because on Docker Desktop names can resolve to unreachable v6 addresses first and squid doesn't fall back.

The extension provider and update checks (`*.lucee.org`) still go to the real internet, over https, so for those squid only logs `CONNECT host:443`.

## Scenarios

| Scenario | Proxy in `.CFConfig.json` |
| --- | --- |
| `none` | none (control) |
| `good` | squid, no auth |
| `auth` | auth squid, correct creds |
| `wrongpass` | auth squid, wrong password |
| `nocreds` | auth squid, no creds |
| `deadport` | `localhost:3199`, nothing listening |
| `badhost` | `proxy.invalid`, unresolvable |

## Scope

6.2, 7.0, 7.1 and 8.0 snapshots, through the CI matrix.

Done so far:

- server proxy loaded (`getProxyData()`)
- extension install from `.CFConfig.json`: ajax (250 KB, not bundled in any jar), declared by id + version. The 8.0 results below used markdown, which is Maven only and needs 7.0.0.395+. On 8.0, resolving an id goes through the extension listing (the repo's `org/lucee/` directory page, then `maven-metadata.xml` for each extension), so that path is covered too. 8.0's default config also downloads the unbundled markdown and smb extensions and the JDBC drivers' Maven dependencies at startup; under a proxy those fail with `there is no endpoint for [org.lucee:markdown-extension:1.0.0.2-RC]`, which hides the cause.
- `mavenLoad` pinned (POM + jar) and unversioned (metadata read)
- `cfhttp` to an http target, with and without the `proxyServer` attributes
- proxy config sources (`SOURCE=`): `.CFConfig.json` via `-Dlucee.base.config`, `LUCEE_BASE_CONFIG`, the context dir, `LUCEE_PROXY_*` env vars (8.0 derives them from the config keys, earlier versions don't have them), env vars vs `.CFConfig.json`, and Application.cfc `this.proxy`
- fake Maven reachable only through the proxy, so a bypassing download fails hard

To do:

- Extension installs via `LUCEE_EXTENSIONS` and the deploy dir
- javasettings in `.CFConfig.json`, `this.javasettings`, `createObject( "java", ..., javasettings )`
- Update / extension provider checks
- cfhttp precedence: the `proxyServer` attribute wins, then `this.proxy` (when it has a `server`), then the server proxy. `proxyServer=""` can't opt out.
- Which proxy app-level javasettings uses
- Proxy includes / excludes
- HTTPS targets, cross-host redirects
- Credential leaks: cfhttp basic-auth reaching the proxy, proxy creds reaching the target

Out for now: webservices, cfschedule, cffeed, AI engines, JVM `-Dhttp(s).proxyHost`.

## Findings

What's broken so far.

6.2, 7.0, 7.1 snapshots:

- **Extension installs bypass the proxy.** With the good proxy, ajax installs, but squid sees no `CONNECT` to the extension provider.
- **`mavenLoad` bypasses the proxy**, falling back to Central direct: 0 mirror requests with a proxy configured, 3.7 s on 6.2 against 350 ms direct.

8.0:

- **Maven artifact downloads ignore the proxy.** `MavenUtil.download` builds a fresh `HttpClients.createDefault()` per repo tried: no proxy, no pooling, and the default cookie spec, which is where every cookie WARN comes from. Every POM and jar bypasses the proxy, so `mavenLoad` and extension Maven dependencies fail behind one.
- **`HTTPEngine` callers that pass a null proxy go direct**, instead of falling back to the server proxy. This covers extension `.lex` downloads, Maven metadata and the extension provider. A local fix exists, see the working-copy results below.
- **`HTTPEngineBasic` never sends proxy credentials**, only target credentials. Fixed locally along with the null-proxy fallback.
- **The extension install hides its cause.** `DeployHandler.downloadExtension` only says `Failed to load extension: [...]`. `downloadExtensionFromMaven` returns null without logging why, even when the `.lex` itself downloaded fine through the proxy.
- **The cause is hidden at startup too.** Under a proxy, 8.0's default config fails with `there is no endpoint for [org.lucee:markdown-extension:1.0.0.2-RC]`, and the unversioned `mavenLoad` only says `No versions found`.
- **cfhttp precedence quirks.** `proxyServer=""` can't opt out of the server proxy, and `this.proxy` replaces the server proxy rather than merging with it.
- **Repository `type` is read from the `label` key** when building Maven repositories from config, so a configured `type` is ignored.
- **`PAC.java` is a dead stub** holding a hardcoded customer PAC script.

To check: `RepoReader` (snapshot metadata) and which HTTP client the update / provider checks use.

## Results

### Working copy, `HTTPEngine` proxy fallback

8.0 working copy (`8.0.0.0-SNAPSHOT`), `SOURCE=cfconfig`, 2026-10-14. The local change:

- `HTTPEngine` falls back to the server proxy when a caller passes a null proxy.
- `HTTPEngine.getAsString` passes the server proxy.
- `HTTPResource` keeps its own proxy, or none.
- `HTTPEngineBasic` sends the proxy credentials.

| Check | none | good | auth | deadport |
| --- | --- | --- | --- | --- |
| extension from config | ok | fails | fails | fails |
| mavenLoad pinned | ok | fails | fails | fails |
| mavenLoad latest | ok | fails at the POM | fails at the POM | fails at the metadata, through the dead proxy |
| cfhttp, no attrs | direct | via squid | via squid-auth (407 then 200) | connection failure |
| cfhttp, `proxyServer` attr | | via squid | via squid-auth (407 then 200) | connection failure |
| squid lines | 0 | 24 | 48 (half 407) | 0 |
| mirror requests | 56 direct | 9 via squid | 9 via squid-auth | 0 |
| cookie WARNs | 41 | 0 | 0 | 0 |

Now proxied: the extension `.lex` HEAD and GET requests (markdown, smb, mysql, s3), `org/lucee/maven-metadata.xml` and each extension's metadata, `commons-csv` metadata, and the `CONNECT` to `maven.lucee-services.com`. With auth, each request gets a 407 and then a 200, so the proxy credentials are sent.

Still direct: every POM and jar, through `MavenUtil.download`, which fails with `UnknownHostException: testlab-maven`. That takes out the Maven dependencies of the s3, smb and mysql extensions (commons-logging, bcprov, protobuf) and both `mavenLoad` checks. `mavenLoad latest` now resolves the version (1.14.1) through the proxy, then fails on the POM.

Markdown's `.lex` downloaded through squid, but the install still fails, with no cause logged (see Findings).

### Fake Maven, reachable only through the proxy

8.0 snapshot (`8.0.0.234-SNAPSHOT`), `SOURCE=cfconfig`, 2026-10-14:

| Check | none | good | auth | deadport |
| --- | --- | --- | --- | --- |
| extension from config | ok | **fails** | **fails** | fails |
| mavenLoad pinned | ok | **fails** | **fails** | fails |
| mavenLoad latest | ok | **fails** | **fails** | fails |
| cfhttp, no attrs | direct | via squid | via squid-auth (407 then 200) | connection failure |
| cfhttp, `proxyServer` attr | | via squid | via squid-auth (407 then 200) | connection failure |
| mirror requests | 39 direct | 0 | 0 | 0 |
| cookie WARNs | 38 | 0 | 0 | 0 |

With a working proxy every internal download fails: `http://testlab-maven/maven2/: UnknownHostException: testlab-maven; Lucee Maven repository: 404`. Lucee resolves the repo host itself and never asks the proxy. The pinned load's error names each repo's cause; the unversioned one still only says "No versions found".

`mavenLoad` pinned from a warm mirror: 51 ms, against ~800 ms from Central.

### Config sources

8.0 snapshot, `good` scenario, against real Central (before the fake):

| Source | Server proxy | cfhttp, no attrs |
| --- | --- | --- |
| `cfconfig` | `:3138` | via squid |
| `baseconfig` | `:3138` (needs the script-runner fix: an empty `-Dlucee.base.config` used to hide `LUCEE_BASE_CONFIG` on 7.0+) | via squid |
| `context` | `:3138` | via squid |
| `env` | `:3138` | via squid |
| `env-vs-cfconfig` | `:3138`, the env vars win over the config's dead `:3199` | via squid |
| `app` | none, `this.proxy` `:3138` | via squid |

### Against real Central

8.0 snapshot (`8.0.0.234-SNAPSHOT`), 2026-10-14, before the fake Maven:

| Check | none | good | auth | deadport |
| --- | --- | --- | --- | --- |
| server proxy | none | `:3138` | `:3139` + user | `:3199` |
| extension from config | ok | ok | ok | ok |
| mavenLoad pinned | ok | ok | ok | ok |
| mavenLoad latest | ok | ok | ok | ok |
| cfhttp, no attrs | direct | via squid | via squid-auth (407 then 200) | connection failure |
| cfhttp, `proxyServer` attr | | via squid | via squid-auth (407 then 200) | connection failure |
| squid `CONNECT` lines | 0 | 0 | 0 | 0 |
| cookie WARNs | 38 | 38 | 38 | 38 |

cfhttp honours the server proxy. Every internal download bypasses it: no `CONNECT` to Maven Central in any scenario, and everything still resolves with a dead proxy. The cookie WARN is `Invalid cookie header ... Domain=maven.org` from HttpClient's default cookie spec rejecting Cloudflare's `__cf_bm` `Expires` format. With a dead proxy the downloads only showed up as bypassing because they still worked; the fake Maven above makes them fail instead.
