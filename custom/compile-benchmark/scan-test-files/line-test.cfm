
<cfscript>
// Line 3: comment
// Line 4: comment

// Line 6: function starts
function conditionalFunction( required numeric value ) {
	// Line 8: comment
	// Line 9: comment
	// Line 10: comment
	var result = 0;     // Line 11: var declaration
	if ( arguments.value > 10 ) {   // Line 12: if statement
		result = arguments.value * 2;   // Line 13: assignment
	}   // Line 14: closing brace
	return result;  // Line 15: return
}

// Line 18: test call
systemOutput( conditionalFunction( 15 ), true );
</cfscript>
