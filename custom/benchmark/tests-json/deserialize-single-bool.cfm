<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.singleBool );
	}
	if ( !r ) throw "single-bool failed: [#r#]";
</cfscript>
