<cfscript>
	// 3-deep capture chain; exposes ClosureScope chain depth + scope-swap per level
	outer = ( a ) => {
		return ( b ) => {
			return ( c ) => a * b * c;
		};
	};
	result = outer( 2 )( 3 )( 4 );
</cfscript>
