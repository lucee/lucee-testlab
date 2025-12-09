package org.lucee.test.slowstartup;

import lucee.runtime.PageContext;
import lucee.runtime.exp.PageException;
import lucee.runtime.ext.function.Function;

/**
 * BIF: IsSlowStartupReady()
 * Returns true if the slow startup hook has completed initialization.
 * If called before startup completes, returns false (or throws if startup never ran).
 */
public class IsSlowStartupReady implements Function {

	private static final long serialVersionUID = 1L;

	public static Boolean call( PageContext pc ) throws PageException {
		return SlowStartupHook.isStartupComplete();
	}
}
