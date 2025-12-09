# Deployment Timing Tests Analysis

## Test Run: 20068613208 (LDEV-5955 verified)

### Results Summary - ALL PASSING ✅

| Test | Result |
|------|--------|
| 6.2-snapshot-immediate | PASS |
| 6.2-snapshot-delayed | PASS |
| 6.2-snapshot-stress | PASS |
| 7.0-snapshot-immediate | PASS |
| 7.0-snapshot-delayed | PASS |
| 7.0-snapshot-stress | PASS |
| 7.1-native-immediate | PASS |
| 7.1-native-delayed | PASS |
| 7.1-native-stress | PASS |

### Analysis

**LDEV-5955 fix verified working** - startup hooks now execute across all versions.

Fixes applied to 7.0:
- LDEV-5957: Don't uninstall bundle after registering startup hook
- LDEV-5955: Trigger `config.getStartups()` at load time + after extension install

### Current Status

Startup hooks work. Now we can investigate the actual deploy timing issue (LDEV-5960/LDEV-5478).

The slow-startup extension has a 5-second sleep in its startup hook - this widens the timing window to expose race conditions where requests are served before extensions are ready.

### Next Steps: LDEV-5960 Investigation

Per PLAN-LDEV-5960-deploy-timing.md:

1. **Find where queue mode changes** from BLOCKING to ENABLED in 7.0
2. **Ensure config load completes** (including deployed extensions) before mode change
3. **Add debug logging** to trace timing between deploy and first request
4. **Reproduce the bug** - currently tests pass because startup hooks block, but what if extension doesn't have a startup hook?

Key code locations:
- `ThreadQueueImpl.java` - queue mode constants
- `ConfigServerImpl.java` - initial BLOCKING mode
- `ConfigFactoryImpl.java:224` - where mode changes to ENABLED
- `DeployHandler.java` - deploy folder processing
- `CFMLEngineImpl.java` - startup sequence

### Key Finding: ESAPI Has No Startup Hook

**Root cause identified**: ESAPI extension doesn't have a startup hook!

Flow:

1. Extension deployed (files copied, bundle registered with Felix)
2. Queue becomes ENABLED when first web context created (ConfigFactoryImpl:224)
3. First request calls ESAPI function (e.g., `encodeForHTML`)
4. `FunctionSupport` calls `PropertyDeployer.deployIfNecessary()` which sets system property
5. **BUT** ESAPI's `DefaultSecurityConfiguration` static init may have already run
6. Static init caches `org.owasp.esapi.resources` as null
7. ESAPI throws "ConfigurationException: ESAPI.properties could not be loaded"

**Why our tests pass**: Our slow-startup extension HAS a startup hook that blocks for 5 seconds. The hook runs synchronously during deploy, so by the time queue goes ENABLED, everything is ready.

**The ESAPI fix options**:

1. **Add startup hook to ESAPI extension** - call `PropertyDeployer.deployIfNecessary()` during startup
2. **Use BundleActivator** - OSGi activator runs when bundle starts
3. **Static initialiser in FunctionSupport** - ensure property is set before any ESAPI class loads

### Test Plan: Reproduce Without Startup Hook

Create a test extension WITHOUT a startup hook that:

- Has a BIF that reads a system property
- That system property is set by a lazy deployer (like ESAPI does)
- Demonstrates race condition on first request

This will prove the timing issue exists and give us a test case for fixing it.

---

## Testing Process

### Running Tests

Tests run via GitHub Actions workflow `deployment-tests.yml`.

To trigger a run, push to the repo or manually trigger the workflow.

### Viewing Results

1. Check workflow status:
   ```bash
   gh run list --repo lucee/lucee-testlab --workflow=deployment-tests.yml --limit 5
   ```

2. Download artifacts (logs from failed tests):
   ```bash
   rm -rf D:/work/lucee-testlab/test-output/test-deployment-timing
   mkdir -p D:/work/lucee-testlab/test-output/test-deployment-timing
   gh run download <RUN_ID> --repo lucee/lucee-testlab --dir D:/work/lucee-testlab/test-output/test-deployment-timing
   ```

3. Inspect logs:
   ```bash
   ls D:/work/lucee-testlab/test-output/test-deployment-timing/
   # Each failed job has a lucee-logs-<test-name> folder with:
   # - express/logs/catalina.out
   # - express/lucee-server/context/logs/*.log
   ```

### Test Matrix

| Test Name | Extension | Has Startup Hook | Expected Result |
|-----------|-----------|------------------|-----------------|
| 6.2-snapshot-* | slow-startup | YES | PASS |
| 7.0-snapshot-* | slow-startup | YES | PASS |
| 7.1-native-* | slow-startup | YES | PASS |
| 6.2-lazy-immediate | lazy-deploy | NO | ? (testing LDEV-5960) |
| 7.0-lazy-immediate | lazy-deploy | NO | ? (testing LDEV-5960) |
| 7.0-lazy-delayed | lazy-deploy | NO | ? (testing LDEV-5960) |

### Local gitignore

The `test-output/` directory is excluded via `.git/info/exclude` - don't commit test artifacts.
