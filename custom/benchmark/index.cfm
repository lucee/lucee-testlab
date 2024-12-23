<cfscript>
	never_runs = int( ( server.system.environment.BENCHMARK_CYCLES ?: 25 ) * 1000);
	once_runs = int( ( server.system.environment.BENCHMARK_ONCE_CYCLES ?: 0.5) * 1000)
	warmup_runs = 1000; // ensure level 4 compilation
	setting requesttimeout=never_runs+once_runs;
	warmup = [];

	filter = server.system.environment.BENCHMARK_FILTER ?: "";
	if ( len( trim( filter ) ) ){
		testDir = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/tests";
		availableSuites = DirectoryList( testDir, true, "path" )
		suites = [];
		for ( suite in availableSuites ){
			if ( suite contains filter )
				arrayAppend( suites, listFirst( listLast( suite, "/\" ), "." ) );
		}
	} else {
		suites = application.testSuite;
	}
	
	longestName =  [];
	arrayEach( suites, function( item ){
		arrayAppend( longestName, len( item ) );
	});
	longestSuiteName = arrayMax( longestName );
	suites = suites.toList();

	results = {
		data = [],
		run = {
			version: server.lucee.version,
			java: server.java.version
		}
	};
	/*
	configImport( {
			"debuggingEnabled": false,
			"executionLog": {
				"class": "lucee.runtime.engine.ConsoleExecutionLog",
				"arguments": {
					"min-time": 100,
					"snippet": true,
					"stream-type": "out",
					"unit": "micro"
				},
				"enabled": true
			},
			"debuggingTemplate": false
		}, 
		"server",
		"admin"
	);
	*/

	ArraySet( warmup, 1, warmup_runs, 0 );

	_memBefore = reportMem( "", {}, "before", "HEAP" );
	errorCount = 0;
	units = "micro";

	appSettings = getApplicationSettings();
	systemOutput("Precise Math: " & (appSettings.preciseMath ?: "not supported"), true);
	// max_threads = 0; // use lucee default
	// max_threads = int(createObject("java", "java.lang.Runtime").getRuntime().availableProcessors() * 2);
	// systemOutput("Using [#max_threads#] parallel threads", true);
	systemOutput("Sleeping for 5s, allow server to startup and settle", true);
	systemOutput( getCpuUsage() );
	sleep( 5000 ); // initial time to settle

	loop list="once,never" item="inspect" {
		systemOutput("", true);
		configImport( {"inspectTemplate": inspect }, "server", "admin" );
		if (inspect eq "never")
			runs = never_runs;
		else
			runs = once_runs;

		loop list="#suites#" item="type" {
			template = "/tests/#type#.cfm";
			suiteName = LJustify( type, longestSuiteName ); // lines up output
			runError = "";
			arr = [];
			s = 0;
			ArraySet( arr, 1, runs, 0 );
			try {
				systemOutput( "Warmup #suiteName#, inspect: [#inspect#]", true );
				ArrayEach( warmup, function( item ){
					_internalRequest(
						template: template
					);
				}, true);
				systemOutput( "Sleeping 2s first, after warmup", true );
				sleep( 2000 ); // time to settle
				
				systemOutput( "Running #suiteName# [#numberFormat( runs/1000 )#k-#inspect#]", true );
				s = getTickCount(units);

				runAborted = false;
				maxElapsedThreshold = 1 * 1000 * 1000; // in micro seconds, see units!
			
				ArrayEach( arr, function( item, idx, _arr ){
					if (runAborted) return;
					var start = getTickCount(units);
					_internalRequest(
						template: template
					);
					var elapsed = getTickCount(units) - start;
					arguments._arr[ arguments.idx ] = elapsed;
					if (!runAborted && elapsed > maxElapsedThreshold){
						runAborted = true;
						 var mess = "[#suiteName#] was waaay too slow [#elapsed/1000#], aborting";
						 _logger( mess );
						 throw mess;
					}
				}, true);
			} catch ( e ){
				systemOutput( e, true );
				echo(e);
				_logger( e.message );
				runError = e.message;
				errorCount++;
			}

			time = getTickCount(units)-s;

			_logger( "Running #suiteName# [#numberFormat( runs )#-#inspect#] took #numberFormat( time/1000 )# ms, or #numberFormat(runs/(time/1000/1000))# per second" );
			ArrayAppend( results.data, {
				time: time/1000,
				inspect: inspect,
				type: type,
				_min: decimalFormat( arrayMin( arr ) / 1000 ),
				_max: decimalFormat( arrayMax( arr ) / 1000 ),
				_avg: decimalFormat( arrayAvg( arr ) / 1000 ),
				_med: decimalFormat( arrayMedian( arr ) / 1000 ),
				error: runError,
				runs: arrayLen( arr ),
				raw: arr
			});
		}
	}

	_logger( message="" );
	_logger( message="-------test run complete------" );
	
	_memStat = reportMem( "", _memBefore.usage, "before", "HEAP" );

	for ( r in _memStat.report )
		_logger( r );
	_logger( message="-------trigger GC------" );
	createObject( "java", "java.lang.System" ).gc();
	_memStatGC = reportMem( "", _memBefore.usage, "before", "HEAP" );
	for ( r in _memStatGC.report )
		_logger( r );
	_logger( "" );

	results.memory=_memStat;
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts/";
	if (!directoryExists( dir ))
		directoryCreate( dir );
	reportFile = dir & server.lucee.version & "-" & server.java.version & "-results.json";
	_logger( message="Writing report to #reportFile#" );
	
	fileWrite( reportFile, results.toJson() );

	_logger( message="-------dump logs------" );

	logs = {};
	loop list="exception.log,application.log" item="logFile"{
		log = expandPath( '{lucee-server}/logs/#logFile#' );
		if ( fileExists( log ) ){
			systemOutput( "", true );
			systemOutput( "--------- #logFile#-----------", true );
			_log = fileRead( log );
			logs [ _log ] = trim( _log );
			systemOutput( _log, true );
		} else {
			systemOutput( "--------- no #logFile# [#log#]", true );
		}
	}

	_logger( message="-------finished dumping logs------" );

	if ( errorCount > 0 )
		_logger( message="#errorCount# benchmark(s) failed", throw=true );

	function _logger( string message="", boolean throw=false ){
		systemOutput( arguments.message, true );
		if ( !len( server.system.environment.GITHUB_STEP_SUMMARY?:"" ))
			return;
		if ( !FileExists( server.system.environment.GITHUB_STEP_SUMMARY  ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "#### #server.lucee.version# ");
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, server.system.environment.toJson());
		}

		if ( arguments.throw ) {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> [!WARNING]" & chr(10) );
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> #arguments.message##chr(10)#");
			throw arguments.message;
		} else {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, " #arguments.message##chr(10)#");
		}

	}

	struct function reportMem( string type, struct prev={}, string name="", filter="" ) {
		var qry = getMemoryUsage( type );
		var report = [];
		var used = { name: arguments.name };
		querySort(qry,"type,name");
		loop query=qry {
			if ( len( arguments.filter ) and arguments.filter neq qry.type )
				continue;
			if (qry.max == -1)
				var perc = 0;
			else
				var perc = int( ( qry.used / qry.max ) * 100 );
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			//if(qry.max<0 || qry.used<0 || perc<90) 	continue;
			var rpt = replace(ucFirst(qry.type), '_', ' ')
				& " " & qry.name & ": " & numberFormat(perc) & "%, " & numberFormat( qry.used / 1024 / 1024 ) & " Mb";
			if ( structKeyExists( arguments.prev, qry.name ) ) {
				var change = numberFormat( (qry.used - arguments.prev[ qry.name ] ) / 1024 / 1024 );
				if ( change gt 0 ) {
					rpt &= ", (+ " & change & "Mb )";
				} else if ( change lt 0 ) {
					rpt &= ", ( " & change & "Mb )";
				}
			}
			arrayAppend( report, rpt );
			used[ qry.name ] = qry.used;
		}
		return {
			report: report,
			usage: used
		};
	}
</cfscript>