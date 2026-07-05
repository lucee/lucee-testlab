<cfscript>
// Standalone test for BytecodeLineScanner
// Compiles a test file and scans its bytecode to verify line numbers

// Create a test CFML file with known line numbers
testDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "scan-test-files/";
if ( !directoryExists( testDir ) )
	directoryCreate( testDir );

// Test file that demonstrates the line number bug
// Lines 11-14 have statements that should each have unique line numbers
testContent = '
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
';

testFile = testDir & "line-test.cfm";
fileWrite( testFile, testContent );
systemOutput( "Created test file: #testFile#", true );

// Compile the test file
adminPwd = "admin";
mappingName = "/scan-test-files";

configImport( {
	mappings: {
		"#mappingName#": {
			physical: testDir,
			toplevel: true,
			primary: "physical",
			inspect: "never"
		}
	}
}, "server", adminPwd );

systemOutput( "Created mapping: #mappingName#", true );

// Force compilation
compileErrors = {};
try {
	admin
		action="compileMapping"
		type="server"
		password=adminPwd
		virtual=mappingName
		stoponerror="false"
		errorVariable="compileErrors";

	if ( structCount( compileErrors ) > 0 ) {
		systemOutput( "Compile errors:", true );
		for ( var key in compileErrors ) {
			systemOutput( "  #key#: #compileErrors[ key ]#", true );
		}
	} else {
		systemOutput( "Compilation successful", true );
	}
} catch ( e ) {
	systemOutput( "Compile failed: #e.message#", true );
	rethrow;
}

// Find the compiled class file
// {lucee-server} already includes /context, so just add /cfclasses
classesDir = expandPath( "{lucee-server}/cfclasses" );
systemOutput( "Classes dir: #classesDir#", true );

// List class files for our mapping
if ( directoryExists( classesDir ) ) {
	classFiles = directoryList( classesDir, true, "path", "*.class" );
	systemOutput( "Found #classFiles.len()# class files total", true );

	// Filter to files related to our test
	testClasses = classFiles.filter( function( f ) {
		return findNoCase( "line_test", f ) || findNoCase( "line-test", f ) || findNoCase( "linetest", f );
	});

	if ( testClasses.len() == 0 ) {
		// Try broader search
		testClasses = classFiles.filter( function( f ) {
			return findNoCase( "scan_test", f ) || findNoCase( "scan-test", f );
		});
	}

	systemOutput( "Found #testClasses.len()# test class files", true );

	// Scan with our scanner
	scanner = new BytecodeLineScanner();

	for ( classFile in testClasses ) {
		systemOutput( "", true );
		systemOutput( "=== Scanning: #listLast( classFile, '/\' )# ===", true );

		scanResult = scanner.scanClassFile( classFile );

		systemOutput( "Class: #scanResult.className#", true );
		systemOutput( "exeLogStart calls found: #scanResult.exeLogCalls.len()#", true );

		if ( scanResult.exeLogCalls.len() > 0 ) {
			systemOutput( "", true );
			systemOutput( "Line numbers in bytecode:", true );
			for ( call in scanResult.exeLogCalls ) {
				systemOutput( "  Line #call.line#, id=#call.id#, method=#call.method#", true );
			}

			// Check for the bug: consecutive calls with same line but different id
			issues = [];
			for ( i = 2; i <= scanResult.exeLogCalls.len(); i++ ) {
				prev = scanResult.exeLogCalls[ i - 1 ];
				curr = scanResult.exeLogCalls[ i ];
				if ( prev.line == curr.line && prev.id != curr.id ) {
					issues.append( "BUG: Line #curr.line# appears twice with different ids (#prev.id#, #curr.id#)" );
				}
			}

			if ( issues.len() > 0 ) {
				systemOutput( "", true );
				systemOutput( "!!! LINE NUMBER ISSUES FOUND !!!", true );
				for ( issue in issues ) {
					systemOutput( "  #issue#", true );
				}
			} else {
				systemOutput( "", true );
				systemOutput( "No duplicate line issues found - line numbers look correct!", true );
			}
		}
	}
} else {
	systemOutput( "Classes directory not found: #classesDir#", true );
}
</cfscript>
