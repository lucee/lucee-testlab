<cfscript>
	// frame.function access triggers getFunctionName() per frame; baseline for renderName()
	f0 = () => f1();
	f1 = () => f2();
	f2 = () => f3();
	f3 = () => f4();
	f4 = () => f5();
	f5 = () => f6();
	f6 = () => f7();
	f7 = () => f8();
	f8 = () => { throw "boom"; };

	try {
		f0();
	} catch ( any e ) {
		ctx = e.tagContext;
		loop array=ctx item="frame" {
			len( frame.function ?: "" );
		}
	}
</cfscript>
