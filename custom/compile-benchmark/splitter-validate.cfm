<cfscript>
// SourceCodeSplitter corpus validation
// Pass 1: detect-only (raw splitter speed)
// Pass 2: detect + reconstruct (correctness check + breakdown stats)

import lucee.transformer.util.SourceCode;
import lucee.transformer.util.SourceCodeSplitter;

projects = [
	{ name: "coldbox-platform", path: "D:\work\coldbox-platform" },
	{ name: "commandbox-src",   path: "D:\work\commandbox-src" },
	{ name: "MasaCMS",          path: "D:\work\MasaCMS" },
	{ name: "Preside-CMS",      path: "D:\work\Preside-CMS" },
	{ name: "TestBox",          path: "D:\work\TestBox" },
	{ name: "wheels",           path: "D:\work\wheels" },
	{ name: "lucee-context",    path: "D:\work\lucee8\core\src\main\cfml\context" },
	{ name: "lucee-spreadsheet",path: "D:\work\lucee-spreadsheet" },
	{ name: "lucee-docs",       path: "D:\work\lucee-docs" },
	{ name: "lucee-data-provider", path: "D:\work\lucee-data-provider" },
	{ name: "lucee-ast-to-cfml",  path: "D:\work\lucee-ast-to-cfml\samples" }
];

filterProjects = server.system.environment.COMPILE_FILTER ?: "";
if ( len( filterProjects ) ) {
	projects = projects.filter( function( p ) {
		return listFindNoCase( filterProjects, p.name );
	});
}

kinds = [ "SCRIPT_MODE", "CF_TAG", "HTML", "CFOUTPUT", "CFOUTPUT_EXPR", "TAG_ISLAND", "COMMENT_LINE", "COMMENT_BLOCK", "COMMENT_CFML", "WHITESPACE" ];

// ── Pass 1: detect only ───────────────────────────────────────────────────────
systemOutput( "=".repeat( 80 ), true );
systemOutput( "Pass 1 — detect only (raw splitter speed)", true );
systemOutput( "=".repeat( 80 ), true );

totalFiles = 0;
startAll   = getTickCount();

for ( project in projects ) {
	if ( !directoryExists( project.path ) ) { systemOutput( "SKIP: #project.name#", true ); continue; }
	files        = directoryList( project.path, true, "path", "*.cfm|*.cfc" );
	projectStart = getTickCount();
	for ( filePath in files ) {
		totalFiles++;
		isCfc = lCase( listLast( filePath, "." ) ) == "cfc";
		src      = fileRead( filePath );
		sc       = createObject( "java", "lucee.transformer.util.SourceCode" ).init( javacast( "null", "" ), src, false );
		splitter = createObject( "java", "lucee.transformer.util.SourceCodeSplitter" ).init( sc );
		regions  = splitter.detect( isCfc );
	}
	systemOutput( "#lJustify( project.name, 20 )#: #arrayLen( files )# files in #numberFormat( getTickCount() - projectStart )# ms", true );
}

systemOutput( "", true );
systemOutput( "TOTAL: #totalFiles# files in #numberFormat( getTickCount() - startAll )# ms (detect only)", true );
systemOutput( "=".repeat( 80 ), true );
systemOutput( "", true );

// ── Pass 2: detect + reconstruct ─────────────────────────────────────────────
systemOutput( "=".repeat( 80 ), true );
systemOutput( "Pass 2 — detect + reconstruct (correctness + breakdown)", true );
systemOutput( "=".repeat( 80 ), true );

totalFiles    = 0;
totalMismatch = 0;
totalErrors   = 0;
startAll      = getTickCount();
totals        = {};
for ( k in kinds ) totals[ k ] = 0;
totalChars = 0;

for ( project in projects ) {
	if ( !directoryExists( project.path ) ) { systemOutput( "SKIP: #project.name#", true ); continue; }
	files           = directoryList( project.path, true, "path", "*.cfm|*.cfc" );
	projectMismatch = 0;
	projectErrors   = 0;
	projectStart    = getTickCount();

	for ( filePath in files ) {
		totalFiles++;
		isCfc = lCase( listLast( filePath, "." ) ) == "cfc";
		try {
			src      = fileRead( filePath );
			sc       = createObject( "java", "lucee.transformer.util.SourceCode" ).init( javacast( "null", "" ), src, false );
			splitter = createObject( "java", "lucee.transformer.util.SourceCodeSplitter" ).init( sc );
			regions  = splitter.detect( isCfc );

			totalChars += len( src );
			for ( r in regions ) {
				k = r.kind.name();
				if ( structKeyExists( totals, k ) ) totals[ k ] += ( r.end - r.start );
			}

			reconstructed = "";
			prev = 0;
			for ( r in regions ) {
				reconstructed &= mid( src, prev + 1, r.start - prev );
				reconstructed &= mid( src, r.start + 1, r.end - r.start );
				prev = r.end;
			}
			reconstructed &= mid( src, prev + 1, len( src ) - prev );

			if ( reconstructed != src ) {
				projectMismatch++;
				totalMismatch++;
				diffPos = 0;
				for ( ch = 1; ch <= min( len( src ), len( reconstructed ) ); ch++ ) {
					if ( mid( src, ch, 1 ) != mid( reconstructed, ch, 1 ) ) { diffPos = ch; break; }
				}
				systemOutput( "MISMATCH: #filePath#", true );
				systemOutput( "  src=#len( src )# recon=#len( reconstructed )# firstDiff=#diffPos# regions=#arrayLen( regions )#", true );
			}
		} catch ( e ) {
			projectErrors++;
			totalErrors++;
			systemOutput( "ERROR: #filePath#", true );
			systemOutput( "  #e.message#", true );
		}
	}

	duration = getTickCount() - projectStart;
	status   = ( projectMismatch + projectErrors ) == 0 ? "OK" : "#projectMismatch# mismatches, #projectErrors# errors";
	systemOutput( "#lJustify( project.name, 20 )#: #arrayLen( files )# files in #numberFormat( duration )# ms — #status#", true );
}

systemOutput( "", true );
systemOutput( "=".repeat( 80 ), true );
systemOutput( "TOTAL: #totalFiles# files, #totalMismatch# mismatches, #totalErrors# errors in #numberFormat( getTickCount() - startAll )# ms", true );
systemOutput( "=".repeat( 80 ), true );
systemOutput( "", true );

systemOutput( "Region kind breakdown (#numberFormat( totalChars )# total chars):", true );
for ( k in kinds ) {
	chars = totals[ k ];
	pct   = totalChars > 0 ? numberFormat( chars * 100 / totalChars, "99.9" ) : "0.0";
	systemOutput( "  #lJustify( k, 16 )# #lJustify( numberFormat( chars ), 12 )# #pct#%", true );
}
gapChars = totalChars;
for ( k in kinds ) gapChars -= totals[ k ];
gapPct = totalChars > 0 ? numberFormat( gapChars * 100 / totalChars, "99.9" ) : "0.0";
systemOutput( "  #lJustify( 'BOUNDARY', 16 )# #lJustify( numberFormat( gapChars ), 12 )# #gapPct#%", true );
systemOutput( "=".repeat( 80 ), true );
</cfscript>
