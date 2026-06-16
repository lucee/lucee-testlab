<cfscript>
	// loose-typed named UDF — fair floor vs trivial (both skip per-call arg casts)
	arrayMap( application.arr1k, application.utils.looseDoubler );
</cfscript>
