<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.nested10 );
	}
	// drill down to confirm depth
	x = r;
	for ( i = 1; i <= 10; i++ ) x = x[ 1 ];
	if ( x != 1 ) throw "nested-10 failed: [#x#]";
</cfscript>
