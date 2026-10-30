<cfscript>
	for ( i = 1; i <= 100; i++ ) {
		savecontent variable="x" trim=true {
			echo( i );
		}
	}
	echo( x );
</cfscript>
