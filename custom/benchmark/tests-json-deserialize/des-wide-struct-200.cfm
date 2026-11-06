<cfscript>
	// 200 short keys with integer values, byte-identical to ser-wide-struct-200's
	// output. Half the tokens are keys (string() then a struct put), half are number
	// literals, which is the realistic mix a number-literal change lands on. Read
	// against des-numbers-int for the share of a mixed document the number path is,
	// and against ser-wide-struct-200 as the cross-family pair.
	d = application.wideStruct200;
	n = application.jdLoopSmall;
	for ( i = 1; i <= n; i++ ) {
		r = deserializeJson( d );
	}
	if ( structCount( r ) != 200 || r.key200 != 200 ) throw "wide-struct-200 failed";
</cfscript>
