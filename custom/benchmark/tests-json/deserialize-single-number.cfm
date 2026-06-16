<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.singleNumber );
	}
	if ( r != 12345.678 ) throw "single-number failed: [#r#]";
</cfscript>
