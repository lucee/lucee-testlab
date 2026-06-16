<cfscript>
	// 5x heavier body, sequential — pair for parallel-veryheavy break-even probe
	arrayMap( application.arr100, (x) => {
		var sum = 0;
		for ( var i = 1; i <= 500; i++ ) {
			sum += x * i;
		}
		return sum;
	} );
</cfscript>
