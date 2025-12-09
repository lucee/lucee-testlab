# Deployment Timing Tests

Tests for LDEV-5478 / LDEV-5960 - deploy folder timing issues where requests can be served before extensions have fully initialized.

## The Bug

When extensions are placed in the deploy folder before Lucee starts:

1. Lucee processes the deploy folder during startup
2. The queue mode changes from BLOCKING to ENABLED
3. First HTTP request arrives
4. BUT the extension's `onStart()` hook may still be running!

This results in errors like ESAPI's `ConfigurationException` because the extension isn't fully initialized.

## Test Extensions

### slow-startup

A minimal test extension that deliberately sleeps for 5 seconds in its startup hook. This widens the timing window to make the race condition reproducible.

- `IsSlowStartupReady()` - Returns true if startup hook completed
- `GetSlowStartupTimestamp()` - Returns when startup completed (0 if not yet)

## Running Tests

Push to the `deployment-tests` branch, or trigger manually via workflow_dispatch.

The workflow:

1. Builds the test extensions
2. Downloads Lucee Express
3. Copies extension to deploy folder BEFORE starting Lucee
4. Starts Lucee
5. Makes immediate request (no sleep!)
6. Checks if extension is ready

If the bug exists, the test will fail because the first request arrives before the 5-second startup hook completes.

## Related Tickets

- LDEV-5478 - Lucee 7 attempts to serve requests before deployment finishes
- LDEV-5960 - ESAPI ConfigurationException on first request
- LDEV-5808 - Warmup doesn't wait for deploy completion
