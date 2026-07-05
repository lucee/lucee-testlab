<cfscript>
// Compile Benchmark - measures CFML compilation time for various codebases
// Uses admin createArchive to force compilation of all templates

projects = [
	{ name: "coldbox-platform", path: "D:\work\coldbox-platform" },
	{ name: "commandbox-src", path: "D:\work\commandbox-src" },
	{ name: "MasaCMS", path: "D:\work\MasaCMS" },
	{ name: "Preside-CMS", path: "D:\work\Preside-CMS" },
	{ name: "TestBox", path: "D:\work\TestBox" },
	{ name: "wheels", path: "D:\work\wheels" },
	{ name: "lucee-context", path: "D:\work\lucee8\core\src\main\cfml\context" },
	{ name: "lucee-spreadsheet", path: "D:\work\lucee-spreadsheet" },
	{ name: "lucee-docs", path: "D:\work\lucee-docs" },
	{ name: "lucee-data-provider", path: "D:\work\lucee-data-provider" },
	{ name: "lucee-test", path: "D:\work\lucee8\test" },
	{ name: "lucee-ast-samples", path: "D:\work\lucee-ast-to-cfml\samples" }
];

// Filter by env var if set
filterProjects = server.system.environment.COMPILE_FILTER ?: "";
if ( len( filterProjects ) ) {
	projects = projects.filter( function( p ) {
		return listFindNoCase( filterProjects, p.name );
	});
}

systemOutput( "=".repeat( 80 ), true );
systemOutput( "CFML Compile Benchmark - Lucee #server.lucee.version#", true );
systemOutput( "=".repeat( 80 ), true );
systemOutput( "", true );

// Admin password is already set to "admin" by script-runner
adminPwd = "admin";

// Filter to valid projects and count files
validProjects = [];
for ( project in projects ) {
	if ( !directoryExists( project.path ) ) {
		systemOutput( "SKIP: #project.name# - path not found: #project.path#", true );
		continue;
	}
	project.cfmFiles = directoryList( project.path, true, "path", "*.cfm" );
	project.cfcFiles = directoryList( project.path, true, "path", "*.cfc" );
	project.files = duplicate( project.cfmFiles );
	arrayAppend( project.files, project.cfcFiles, true );
	project.fileCount = arrayLen( project.files );
	project.cfmCount = arrayLen( project.cfmFiles );
	project.cfcCount = arrayLen( project.cfcFiles );
	project.mappingName = "/" & lCase( project.name );
	arrayAppend( validProjects, project );
}

// Create all mappings at once using configImport
mappings = {};
for ( p in validProjects ) {
	mappings[ p.mappingName ] = {
		physical: p.path,
		toplevel: true,
		primary: "physical",
		inspect: "never"
	};
}

configImport( { mappings: mappings }, "server", adminPwd );

systemOutput( "Created #structCount( mappings )# mappings", true );
systemOutput( "", true );

results = [];

// Helper to get total GC count across all collectors
function getGCCount() {
	var gcBeans = createObject( "java", "java.lang.management.ManagementFactory" ).getGarbageCollectorMXBeans();
	var total = 0;
	for ( var bean in gcBeans ) {
		total += bean.getCollectionCount();
	}
	return total;
}

// Pre-warm OS page cache so compile-loop reads hit RAM, not disk.
// Removes cold-cache run-to-run variance from the measurement. Opt-out via
// COMPILE_WARMUP_CACHE=0 when you specifically want to measure cold-start.
warmupEnabled = ( server.system.environment.COMPILE_WARMUP_CACHE ?: "1" ) != "0";
if ( warmupEnabled ) {
	warmStart = getTickCount();
	warmFiles = 0;
	for ( project in validProjects ) {
		arrayEach( project.files, function( f ) {
			fileReadBinary( f );
		}, true );
		warmFiles += arrayLen( project.files );
	}
	systemOutput( "--- page cache warmed: #numberFormat( warmFiles )# files across #arrayLen( validProjects )# projects in #getTickCount() - warmStart# ms ---", true );
} else {
	systemOutput( "--- page cache pre-warm SKIPPED (COMPILE_WARMUP_CACHE=0) ---", true );
}

// Pause to isolate JVM/Lucee startup from compilation in JFR profiles.
// Everything above (OSGi, class loading, mapping init) lands in the startup window.
// The compile loop below is the signal we want to profile cleanly.
systemOutput( "--- startup complete, sleeping 3s before compile loop ---", true );
sleep( 3000 );
systemOutput( "--- compile loop start: #dateTimeFormat( now(), "iso" )# ---", true );

for ( project in validProjects ) {
	// GC before each codebase
	createObject( "java", "java.lang.System" ).gc();
	sleep( 100 );

	gcBefore = getGCCount();

	systemOutput( "Compiling: #project.name# (#numberFormat( project.fileCount )# files)", true );

	// Time the compilation
	startTime = getTickCount();
	compileErrors = {};

	try {
		admin
			action="compileMapping"
			type="server"
			password=adminPwd
			virtual=project.mappingName
			stoponerror="false"
			errorVariable="compileErrors";

		duration = getTickCount() - startTime;
		errorMsg = structCount( compileErrors ) > 0 ? "#structCount( compileErrors )# compile errors" : "";
	} catch ( e ) {
		duration = getTickCount() - startTime;
		errorMsg = e.message;
		systemOutput( "  ERROR: #e.message#", true );
	}

	// Count GCs that occurred during compilation
	gcAfter = getGCCount();
	gcCount = gcAfter - gcBefore;

	result = {
		name: project.name,
		files: project.fileCount,
		cfmFiles: project.cfmCount,
		cfcFiles: project.cfcCount,
		duration: duration,
		filesPerSec: duration > 0 ? int( project.fileCount / ( duration / 1000 ) ) : 0,
		gcCount: gcCount,
		error: errorMsg
	};
	arrayAppend( results, result );

	systemOutput( "  Completed in #numberFormat( duration )# ms (#result.filesPerSec# files/sec, #gcCount# GCs) [cfm: #project.cfmCount#, cfc: #project.cfcCount#]#len( errorMsg ) ? ' - ' & errorMsg : ''#", true );
}

systemOutput( "--- compile loop end: #dateTimeFormat( now(), "iso" )# ---", true );
systemOutput( "", true );
systemOutput( "=".repeat( 80 ), true );
systemOutput( "SUMMARY", true );
systemOutput( "=".repeat( 80 ), true );

totalFiles = 0;
totalCfm = 0;
totalCfc = 0;
totalDuration = 0;

for ( result in results ) {
	totalFiles += result.files;
	totalCfm += result.cfmFiles;
	totalCfc += result.cfcFiles;
	totalDuration += result.duration;
	systemOutput( "#lJustify( result.name, 20 )#: #rJustify( numberFormat( result.duration ), 8 )# ms | #rJustify( numberFormat( result.files ), 6 )# files (cfm: #rJustify( result.cfmFiles, 4 )#, cfc: #rJustify( result.cfcFiles, 4 )#) | #rJustify( numberFormat( result.filesPerSec ), 5 )# files/sec", true );
}

systemOutput( "-".repeat( 80 ), true );
systemOutput( "#lJustify( 'TOTAL', 20 )#: #rJustify( numberFormat( totalDuration ), 8 )# ms | #rJustify( numberFormat( totalFiles ), 6 )# files (cfm: #rJustify( totalCfm, 4 )#, cfc: #rJustify( totalCfc, 4 )#) | #rJustify( numberFormat( int( totalFiles / ( totalDuration / 1000 ) ) ), 5 )# files/sec", true );
systemOutput( "", true );

// Write results to JSON
outputDir = getDirectoryFromPath( getCurrentTemplatePath() ) & "results/";
if ( !directoryExists( outputDir ) )
	directoryCreate( outputDir );

resultFile = outputDir & server.lucee.version & "-" & dateTimeFormat( now(), "yyyy-mm-dd-HHnn" ) & ".json";
fileWrite( resultFile, serializeJSON( {
	version: server.lucee.version,
	java: server.java.version,
	timestamp: now(),
	totalDuration: totalDuration,
	totalFiles: totalFiles,
	results: results
} ) );

systemOutput( "Results written to: #resultFile#", true );
</cfscript>
