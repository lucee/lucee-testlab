/**
 * Scan compiled CFML bytecode for line number issues using ASM
 * Uses JVM LineNumberTable (always present) - no debugger mode required
 */
component {

	/**
	 * Scan a directory of compiled classes for line number issues
	 * @classDir Directory containing .class files
	 * @return struct with scan results
	 */
	public struct function scanDirectory( required string classDir ) {
		if ( !directoryExists( classDir ) ) {
			return { error: "Directory not found: #classDir#" };
		}

		var classFiles = directoryList( classDir, true, "path", "*.class" );
		var totalFiles = classFiles.len();
		systemOutput( "Found #totalFiles# class files to scan", true );

		// Thread-safe collections for parallel processing
		var filesWithIssues = createObject( "java", "java.util.concurrent.ConcurrentLinkedQueue" ).init();
		var scannedCount = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init( 0 );
		var issueCount = createObject( "java", "java.util.concurrent.atomic.AtomicInteger" ).init( 0 );

		// Scan files in parallel
		classFiles.each( function( classFile ) {
			var count = scannedCount.incrementAndGet();
			if ( count mod 1000 == 0 ) {
				systemOutput( "  Progress: #count#/#totalFiles# files scanned...", true );
			}

			var fileResult = scanClassFile( classFile );
			var issues = findLineNumberIssues( fileResult.lineNumbers );

			if ( issues.len() > 0 ) {
				issueCount.addAndGet( issues.len() );
				filesWithIssues.add( {
					file: classFile,
					issues: issues
				} );
			}
		}, true, 20 ); // parallel=true, maxThreads=20

		// Convert queue to array
		var issuesArray = [];
		var iter = filesWithIssues.iterator();
		while ( iter.hasNext() ) {
			issuesArray.append( iter.next() );
		}

		return {
			scannedFiles: totalFiles,
			filesWithIssues: issuesArray.len(),
			totalIssues: issueCount.get(),
			issues: issuesArray
		};
	}

	/**
	 * Scan a single class file for line numbers
	 */
	public struct function scanClassFile( required string classFile ) {
		var bytes = fileReadBinary( classFile );
		var text = getBytecodeText( bytes );

		return {
			lineNumbers: extractLineNumbers( text ),
			className: extractClassName( text )
		};
	}

	/**
	 * Extract JVM LineNumberTable entries from bytecode text
	 * Format: LINENUMBER <line> <label>
	 */
	public array function extractLineNumbers( required string text ) {
		var entries = [];
		var lines = listToArray( text, chr( 10 ) );
		var currentMethod = "";

		for ( var i = 1; i <= lines.len(); i++ ) {
			var line = trim( lines[ i ] );

			// Track current method
			if ( reFindNoCase( "^\s*(public|private|protected|static|final|synchronized|native|abstract|\s)*\s*\w+\s*\(", lines[ i ] )
				&& find( ")", lines[ i ] ) && !find( "=", lines[ i ] ) ) {
				currentMethod = extractMethodName( lines[ i ] );
			}

			// Look for LINENUMBER entries
			if ( reFindNoCase( "^\s*LINENUMBER\s+(\d+)\s+(\w+)", line ) ) {
				var match = reFindNoCase( "LINENUMBER\s+(\d+)\s+(\w+)", line, 1, true );
				if ( match.len.len() > 2 ) {
					entries.append( {
						line: int( mid( line, match.pos[ 2 ], match.len[ 2 ] ) ),
						label: mid( line, match.pos[ 3 ], match.len[ 3 ] ),
						method: currentMethod
					} );
				}
			}
		}

		return entries;
	}

	/**
	 * Find line number issues - same label assigned to different lines
	 */
	public array function findLineNumberIssues( required array lineNumbers ) {
		var issues = [];
		var byMethod = {};

		for ( var entry in lineNumbers ) {
			if ( !byMethod.keyExists( entry.method ) ) {
				byMethod[ entry.method ] = {};
			}
			var labelMap = byMethod[ entry.method ];

			if ( labelMap.keyExists( entry.label ) ) {
				var prevLine = labelMap[ entry.label ];
				if ( prevLine != entry.line ) {
					issues.append( {
						method: entry.method,
						label: entry.label,
						lines: [ prevLine, entry.line ],
						description: "Label " & entry.label & " mapped to lines " & prevLine & " and " & entry.line
					} );
				}
			}
			labelMap[ entry.label ] = entry.line;
		}

		return issues;
	}

	/**
	 * Get bytecode text using ASM TraceClassVisitor
	 */
	private string function getBytecodeText( required binary classBytes ) {
		var ClassReader = createObject( "java", "org.objectweb.asm.ClassReader" );
		var TraceClassVisitor = createObject( "java", "org.objectweb.asm.util.TraceClassVisitor" );
		var PrintWriter = createObject( "java", "java.io.PrintWriter" );
		var StringWriter = createObject( "java", "java.io.StringWriter" );

		var reader = ClassReader.init( classBytes );
		var sw = StringWriter.init();
		var pw = PrintWriter.init( sw );
		var visitor = TraceClassVisitor.init( javaCast( "null", "" ), pw );

		reader.accept( visitor, 0 );
		pw.flush();

		return sw.toString();
	}

	/**
	 * Extract class name from bytecode text
	 */
	private string function extractClassName( required string text ) {
		var match = reFind( "class\s+([^\s]+)", text, 1, true );
		if ( match.len.len() > 1 && match.len[ 2 ] > 0 ) {
			return mid( text, match.pos[ 2 ], match.len[ 2 ] );
		}
		return "unknown";
	}

	/**
	 * Extract method name from declaration line
	 */
	private string function extractMethodName( required string line ) {
		var match = reFind( "(\w+)\s*\([^\)]*\)", line, 1, true );
		if ( match.len.len() > 0 && match.len[ 1 ] > 0 ) {
			return mid( line, match.pos[ 1 ], match.len[ 1 ] );
		}
		return "unknown";
	}

	/**
	 * Pretty print scan results
	 */
	public void function printResults( required struct result ) {
		systemOutput( "", true );
		systemOutput( "=== Bytecode Line Number Scan Results ===", true );
		systemOutput( "Files scanned: #result.scannedFiles#", true );
		systemOutput( "Files with issues: #result.filesWithIssues#", true );
		systemOutput( "Total issues: #result.totalIssues#", true );
		systemOutput( "", true );

		if ( result.issues.len() > 0 ) {
			systemOutput( "!!! LINE NUMBER ISSUES FOUND !!!", true );
			for ( var fileIssue in result.issues ) {
				systemOutput( "  File: #fileIssue.file#", true );
				for ( var issue in fileIssue.issues ) {
					systemOutput( "    - #issue.description#", true );
				}
			}
		} else {
			systemOutput( "No line number issues found", true );
		}
	}

}
