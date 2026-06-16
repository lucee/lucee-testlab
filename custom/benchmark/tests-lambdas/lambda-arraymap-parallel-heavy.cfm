<cfscript>
	// heavy body, parallel=true — control case; should win against heavy-seq
	arrayMap( application.arr100, (x) => {
		var sum = 0;
		for ( var i = 1; i <= 100; i++ ) {
			sum += x * i;
		}
		return sum;
	}, true, 4 );
</cfscript>
