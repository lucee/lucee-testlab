<cfscript>
	// sequential pair for parallel-heavy
	arrayMap( application.arr100, (x) => {
		var sum = 0;
		for ( var i = 1; i <= 100; i++ ) {
			sum += x * i;
		}
		return sum;
	} );
</cfscript>
