<cfscript>
	// function(){} literal — pair with arrow + named to isolate parser-path cost
	arrayMap( application.arr1k, function( x ) { return x * 2; } );
</cfscript>
