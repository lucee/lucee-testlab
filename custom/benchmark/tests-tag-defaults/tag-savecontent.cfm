<cfscript>
	for ( i = 1; i <= 100; i++ ) {
		savecontent variable="x" {
			echo( i );
		}
	}
	echo( x );
</cfscript>
