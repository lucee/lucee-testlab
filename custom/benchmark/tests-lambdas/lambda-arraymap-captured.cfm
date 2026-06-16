<cfscript>
	// captures outer var; exposes ScopeFactory pool defeat (setBind blocks recycle)
	m = 2;
	arrayMap( application.arr1k, (x) => x * m );
</cfscript>
