<cfscript>
	loop times=#application.innerLoop# {
		r = deserializeJson( application.singleNull );
	}
	if ( !isNull( r ) && r != "" ) throw "single-null failed: [#r#]";
</cfscript>
