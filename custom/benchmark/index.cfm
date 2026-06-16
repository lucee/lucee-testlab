<cfscript>
	never_runs = int( ( server.system.environment.BENCHMARK_CYCLES ?: 25) * 1000);
	once_runs = int( ( server.system.environment.BENCHMARK_ONCE_CYCLES ?: 0.5) * 1000)
	warmup_runs = int( server.system.environment.BENCHMARK_WARMUP_CYCLES ?: 1000); // ensure level 4 compilation
	setting requesttimeout=never_runs+once_runs;
	warmup = [];

	systemOutput("LUCEE_THREADS_MAXDEFAULT: "
		 & getSystemPropOrEnvVar("LUCEE.THREADS.MAXDEFAULT"), true);

	benchmarkUtils = new benchmarkUtils();
	_logger= benchmarkUtils._logger;
	reportMem = benchmarkUtils.reportMem;

	httpEndpoint = server.system.environment.LUCEE_TESTLAB_HTTP_ENDPOINT ?: "";
	useHttp = len( trim( httpEndpoint ) ) > 0;
	disableMemoryReporting = true;// useHttp; // disable memory reporting when using HTTP mode

	// Get remote version when using HTTP endpoint
	if ( useHttp ) {
		cfhttp( url=httpEndpoint & "/tests/httpMemStat/version.cfm", method="GET", result="versionResult", throwonerror=true );
		remoteVersion = trim( versionResult.fileContent );
		systemOutput( "Remote server version: #remoteVersion#", true );
	}

	// Wrapper function to handle internal or HTTP requests
	function _request( required string template ) {
		if ( useHttp ) {
			// Use HTTP request to external endpoint
			cfhttp( url=httpEndpoint & arguments.template, method="GET", result="local.httpResult", throwonerror=true );
			return httpResult;
		} else {
			// Use internal request
			return _internalRequest( template=arguments.template );
		}
	}

	// Wrapper function to get GC stats (count + pause time)
	function _getGcStats() {
		if ( useHttp ) {
			cfhttp( url=httpEndpoint & "/tests/httpMemStat/index.cfm?gc=true", method="GET", result="local.httpResult", throwonerror=true );
			return { count: val( httpResult.fileContent ), timeMs: 0 };
		} else {
			return benchmarkUtils.getGcStats();
		}
	}

	exeLog = server.system.environment.EXELOG ?: "";
	if (exeLog eq "console") {
		systemOutput("Console Execution Log enabled, only doing single rounds, due to verbosity", true);
		never_runs = 1;
		once_runs = 1;
		warmup_runs = 1;
		configImport( {
				"debuggingEnabled": false,
				"executionLog": {
					"class": "lucee.runtime.engine.ConsoleExecutionLog",
					"arguments": {
						"min-time": 10000, // ns
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
	} else if (exeLog eq "debug") {
		if ( benchmarkUtils.checkMinLuceeVersion( 6, 2 ) ) {
			systemOutput("Debugging Execution Log enabled", true);
			exeLogger = new exeLogger("admin");
			exeLogger.enableExecutionLog(
				class="lucee.runtime.engine.DebugExecutionLog",
				args={
					"unit": "micro"
					, "min-time": 100
				},
				maxlogs=never_runs // default is just 10! 
			);
		} else {
			systemOutput("Debugging Execution Log not available for this version", true);
			exeLog = ""; // unsupported
		}
		
	}
	if (false){
		configImport( {
			"loggers": {
				"datasource": {
				"appender": "resource",
				"appenderArguments": {
					"path": "{lucee-config}/logs/datasource.log"
				},
				"level": "debug",
				"layout": "classic"
				}
			}
		}, "server", "admin");
	}

	testDir = server.system.environment.BENCHMARK_TEST_DIR ?: "tests";
	filter = benchmarkUtils.getTests( filter=server.system.environment.BENCHMARK_FILTER ?: "", testDir=testDir );
	longestSuiteName = filter.longestSuiteName;
	suites = filter.suites;

	results = {
		data = [],
		run = {
			version: useHttp ? remoteVersion : server.lucee.version,
			java: server.java.version
		}
	};

	ArraySet( warmup, 1, warmup_runs, 0 );

	_memBefore = disableMemoryReporting ? {} : reportMem( "", {}, "before", "HEAP" );
	errorCount = 0;
	units = "micro";

	appSettings = getApplicationSettings();
	systemOutput("Precise Math: " & (appSettings.preciseMath ?: "not supported"), true);
	// max_threads = 0; // use lucee default
	max_threads = int(createObject("java", "java.lang.Runtime").getRuntime().availableProcessors() );
	systemOutput("Using [#max_threads#] parallel threads", true);
	systemOutput("Sleeping for 5s, allow server to startup and settle", true);
	systemOutput( getCpuUsage() );
	sleep( 5000 ); // initial time to settle
	_logger("");
	benchmarkVersion = useHttp ? remoteVersion : server.lucee.version;
	_logger( "Starting benchmarking #benchmarkVersion# at #dateTimeFormat(now(), "long")#" );
	_logger( message="" );
	_logger( message="```" );

	run_startTime = getTickCount();
	_getGcStats();
	loop list="once,never" item="inspect" {
		_logger( "" );
		configImport( {"inspectTemplate": inspect }, "server", "admin" );
		if (inspect eq "never")
			runs = never_runs;
		else
			runs = once_runs;

		loop list="#suites#" item="type" {
			template = "/#testDir#/#type#.cfm";
			suiteName = LJustify( type, longestSuiteName ); // lines up output
			runError = "";
			arr = [];
			s = 0;
			ArraySet( arr, 1, runs, 0 );
			try {
				systemOutput( "Warmup #suiteName#, inspect: [#inspect#]", true );
				ArrayEach( warmup, function( item ){
					_request( template=template );
				}, true, max_threads);
				//systemOutput( "Sleeping 2s first, after warmup", true );
				//sleep( 2000 ); // time to settle
				
				// duplicate output here, but it's useful when a test regresses to see where it's hanging
				runsDisplay = runs < 1000 ? runs : numberFormat( runs/1000 ) & "k";
				systemOutput( "Running #suiteName# [#runsDisplay#-#inspect#]", true );
				s = getTickCount(units);

				runAborted = false;
				maxElapsedThreshold = 5 * 1000 * 1000; // in micro seconds, see units!

				if (exeLog eq "debug") {
					exeLogger.purgeExecutionLog();
				}
				createObject( "java", "java.lang.System" ).gc();
				testMemStatStart = disableMemoryReporting ? {} : reportMem( "", {}, "before", "HEAP" );
				testGCStart = _getGcStats();
			
				ArrayEach( arr, function( item, idx, _arr ){
					if (runAborted) return;
					var start = getTickCount(units);
					_request( template=template );
					var elapsed = getTickCount(units) - start;
					arguments._arr[ arguments.idx ] = elapsed;
					if (!runAborted && elapsed > maxElapsedThreshold){
						runAborted = true;
						 var mess = "[#suiteName#] was waaay too slow [#elapsed/1000#], aborting";
						 _logger( mess );
						 _logger( "--- pool snapshot at stall ---" );
						// _logger( serializeJson(var=GetSystemMetrics(), compact=false) );
						 throw mess;
					}
				}, true, max_threads);

			} catch ( _e ){
				e = benchmarkUtils.cleanException(_e);
				lastOkRound = arrayFind(arr, function(item) { return item == 0; });
				_logger( "------- Exception occurred around round [#lastOkRound#]" );
				//systemOutput(SerializeJson(var=GetSystemMetrics(), compact=false), true);
				echo(_e); // for running in browser
				systemOutput( e, true );
				_logger( message=e.stacktrace, console=false );
				runError = e.message;
				errorCount++;
			}
			// note this is without doing a GC
			testMemStatEnd = disableMemoryReporting ? {} : reportMem( "", testMemStatStart.usage, "before", "HEAP" );
			testMemoryUsage = disableMemoryReporting ? 0 : benchmarkUtils.getTotalMemoryUsage( testMemStatEnd.usage );
			testGCEnd = _getGcStats();
			testGCCount = testGCEnd.count - testGCStart.count - ( useHttp ? 1 : 0 );
			testGCTimeMs = testGCEnd.timeMs - testGCStart.timeMs;
			time = getTickCount( units ) - s;

			completedRuns = arrayLen( arrayFilter( arr, function( item ) { return item != 0; } ) );
			targetRuns = arrayLen( arr );

			runsDisplay = runs < 1000 ? runs : numberFormat( runs/1000 ) & "k";
			_logger( "#( completedRuns eq targetRuns ? 'Finished' : 'Errored' )# #suiteName# [#runsDisplay#-#inspect#] took #numberFormat( time/1000 )# ms, "
				& "#numberFormat( completedRuns/(time/1000/1000) )# per second"
				& ( completedRuns neq targetRuns ? " (#completedRuns# of #targetRuns# completed)" : "" )
				& ( disableMemoryReporting ? "" : ", final memory #numberFormat(testMemoryUsage)# Mb" )
				& ", with GCs: #testGCCount# (#testGCTimeMs#ms)"
			);
			result = {
				time: time / 1000,
				inspect: inspect,
				type: type,
				testMemory: testMemoryUsage,
				gcCount: testGCCount,
				gcTimeMs: testGCTimeMs,
				_min: decimalFormat( arrayMin( arr ) / 1000 ),
				_max: decimalFormat( arrayMax( arr ) / 1000 ),
				_avg: decimalFormat( arrayAvg( arr ) / 1000 ),
				_med: decimalFormat( arrayMedian( arr ) / 1000 ),
				error: runError,
				runs: completedRuns,
				targetRuns: targetRuns,
				raw: arr
			}
			if (exeLog eq "debug" && inspect eq "never") {
				pp = getTickCount();
				q_exeLog = exeLogger.getDebugLogsCombined( getDirectoryFromPath( getCurrentTemplatePath() ) & "/#testDir#/" );
				systemOutput( "getDebugLogsCombined took #numberFormat(getTickCount()-pp)#ms", true );
				if ( q_exeLog.recordCount > 0 ){
					result.exeLog = QueryToStruct( q_exeLog, "key" );
					queryDeleteColumn( q_exeLog, "path" );
					queryDeleteColumn( q_exeLog, "startline" );
					queryDeleteColumn( q_exeLog, "endline" );
					benchmarkUtils.dumpTable( q=q_exeLog, console=false );
				}
			}
			ArrayAppend( results.data, result );
		}
	}

	results.run.totalDuration = getTickCount() - run_startTime;
	_logger( message="```" );
	_logger( message="" );
	_logger( message="-------test run complete------" );

	if ( !disableMemoryReporting ) {
		_memStat = reportMem( "", _memBefore.usage, "before", "HEAP" );

		for ( r in _memStat.report )
			_logger( r );
		_logger( message="-------trigger GC------" );
		createObject( "java", "java.lang.System" ).gc();
		_memStatGC = reportMem( "", _memBefore.usage, "before", "HEAP" );
		for ( r in _memStatGC.report )
			_logger( r );
		_logger( "" );
	}

	results.gcStats = _getGcStats();
	totalGCCount = results.data.reduce( function( acc, item ) { return acc + item.gcCount; }, 0 );
	totalGCTimeMs = results.data.reduce( function( acc, item ) { return acc + item.gcTimeMs; }, 0 );
	_logger( "Total GC count across all tests: #totalGCCount# (#totalGCTimeMs#ms pause)" );
	results.totalGCCount = totalGCCount;
	results.totalGCTimeMs = totalGCTimeMs;
	if ( !disableMemoryReporting )
		results.memory=_memStat;
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts/";
	if (!directoryExists( dir ))
		directoryCreate( dir );

	reportVersion = useHttp ? remoteVersion : server.lucee.version;
	reportFile = GetTempFile( dir=dir, prefix=(reportVersion & "-" & server.java.version), extension="json" );
	_logger( message="Writing report to [#reportFile#]" );
	
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
			//systemOutput( _log, true );
		} else {
			systemOutput( "--------- no #logFile# [#log#]", true );
		}
	}
	_logger( message="-------finished dumping logs------" );

	do_heap_dump =  server.system.environment.BENCHMARK_HEAPDUMP ?: false;
	if ( do_heap_dump ){
		_logger( "" );
		_logger( message="-------heap dump------" );
		logs = "";
		_log = "";
		results = "";
		result = "";
		arr = "";
		for (v in variables){
			if (!isCustomFunction(variables[v]))
				systemOutput(v & ": " & len(variables[v]), true);
		}

		application name="bench";
		applicationStop();

		admin
			action="purgeExpiredSessions"
			type="server"
			password="admin";

		_logger( message="-------trigger GC------" );
		createObject( "java", "java.lang.System" ).gc();
		if ( structKeyExists( _memBefore, "usage" ) ) {
			_memStatGC = reportMem( "", _memBefore.usage, "before", "HEAP" );
			for ( r in _memStatGC.report )
				_logger( r );
			_logger( "" );
		}

		dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "heapdumps/";
		if ( !directoryExists( dir ) )
			directoryCreate( dir );

		dumpFile = dir & "heapdump-#lsDateTimeFormat(now(),'yyyy-mm-dd-HH-nn-ss')#.hprof";
		systemOutput( "Dumping heap to #dumpFile#", true );

		admin 
			type="server"
			password="admin"
			action="heapDump" 
			destination=dumpfile;
			live=true; // TODO avoid // in URL
	}
	_logger( message="" );
	_logger( message="```" );	
	_logger(SerializeJson(var=GetSystemMetrics(), compact=false));
	_logger( message="```" );
	_logger( message="" );
	
	

	private function getPoolStats() {
		return createObject( "java", "lucee.commons.net.http.httpclient.HTTPEngine4Impl" )
			.getConnectionPoolStats();
	}

	try {
		_logger(SerializeJson(var=getPoolStats(), compact=false));
	} catch (e) {
		//ignore
	}


	if ( errorCount > 0 )
		_logger( message="#errorCount# benchmark(s) failed", throw=true );

</cfscript>
