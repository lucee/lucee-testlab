<cfscript>
	// 5x heavier body, parallel=true — does parallel finally win against veryheavy-seq?
	arrayMap( application.arr100, (x) => {
		var sum = 0;
		for ( var i = 1; i <= 500; i++ ) {
			sum += x * i;
		}
		return sum;
	}, true, 4 );
</cfscript>
