<cfscript>
	// named UDF on singleton CFC — closure-free floor (UDFImpl, no EnvUDF)
	arrayMap( application.arr1k, application.utils.doubler );
</cfscript>
