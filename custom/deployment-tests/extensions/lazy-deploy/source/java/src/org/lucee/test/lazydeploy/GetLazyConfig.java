package org.lucee.test.lazydeploy;

import lucee.runtime.PageContext;
import lucee.runtime.exp.PageException;
import lucee.runtime.ext.function.Function;

/**
 * Simple BIF that returns OK.
 * This extension has NO startup hook - it relies purely on lazy loading.
 *
 * If this function is available on first request, the extension was
 * deployed successfully. But there's no guarantee of pre-initialisation.
 */
public class GetLazyConfig implements Function {

	private static final long serialVersionUID = 1L;

	public static String call( PageContext pc ) throws PageException {
		// Simple test - just return OK
		// The fact this function exists proves the extension was loaded
		return "LazyConfig OK - extension loaded without startup hook";
	}
}
