<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.singleString );
	}
	if ( r != "hello world" ) throw "single-string roundtrip failed: [#r#]";
</cfscript>
