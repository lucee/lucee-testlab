package org.lucee.test.slowstartup;

import lucee.runtime.PageContext;
import lucee.runtime.exp.PageException;
import lucee.runtime.ext.function.Function;

/**
 * BIF: GetSlowStartupTimestamp()
 * Returns the timestamp when the slow startup hook completed.
 * Returns 0 if startup hasn't completed yet.
 */
public class GetSlowStartupTimestamp implements Function {

	private static final long serialVersionUID = 1L;

	public static Long call( PageContext pc ) throws PageException {
		return SlowStartupHook.getStartupTimestamp();
	}
}
