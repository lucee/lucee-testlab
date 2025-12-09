package org.lucee.test.slowstartup;

import lucee.runtime.config.Config;

/**
 * Test extension startup hook that deliberately sleeps to simulate slow initialization.
 * Used to test LDEV-5478 - deploy folder timing issues.
 */
public class SlowStartupHook {
	private static volatile boolean startupComplete = false;
	private static volatile long startupTimestamp = 0;

	/**
	 * Constructor called by Lucee's startup-hook mechanism.
	 * Deliberately sleeps to widen the timing window for testing.
	 */
	public SlowStartupHook( Config config ) {
		System.out.println( "[slow-startup] Hook constructor called, sleeping 5 seconds..." );
		try {
			Thread.sleep( 5000 );
		}
		catch ( InterruptedException e ) {
			Thread.currentThread().interrupt();
		}
		startupTimestamp = System.currentTimeMillis();
		startupComplete = true;
		System.out.println( "[slow-startup] Hook constructor complete at " + startupTimestamp );
	}

	/**
	 * Check if startup has completed.
	 * Called by the BIF to verify the extension is ready.
	 */
	public static boolean isStartupComplete() {
		return startupComplete;
	}

	/**
	 * Get the timestamp when startup completed.
	 */
	public static long getStartupTimestamp() {
		return startupTimestamp;
	}
}
