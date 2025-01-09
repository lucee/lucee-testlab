<cfscript>
	never_runs = int( ( server.system.environment.BENCHMARK_CYCLES ?: 25) * 1000);
	once_runs = int( ( server.system.environment.BENCHMARK_ONCE_CYCLES ?: 0.5) * 1000)
	warmup_runs = 1000; // ensure level 4 compilation
	setting requesttimeout=never_runs+once_runs;
	warmup = [];

	benchmarkUtils = new benchmarkUtils();
	_logger= benchmarkUtils._logger;
	reportMem = benchmarkUtils.reportMem;

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

	filter = benchmarkUtils.getTests( server.system.environment.BENCHMARK_FILTER ?: "");
	longestSuiteName = filter.longestSuiteName;
	suites = filter.suites;

	results = {
		data = [],
		run = {
			version: server.lucee.version,
			java: server.java.version
		}
	};

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

	_logger( server.lucee.version );

	run_startTime = getTickCount();
	loop list="once,never" item="inspect" {
		_logger( "" );
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
				//systemOutput( "Sleeping 2s first, after warmup", true );
				//sleep( 2000 ); // time to settle
				
				// duplicate output here, but it's useful when a test regresses to see where it's hanging
				systemOutput( "Running #suiteName# [#numberFormat( runs/1000 )#k-#inspect#]", true );
				s = getTickCount(units);

				runAborted = false;
				maxElapsedThreshold = 1 * 1000 * 1000; // in micro seconds, see units!

				if (exeLog eq "debug") {
					exeLogger.purgeExecutionLog();
				}
			
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
			} catch ( _e ){
				e = benchmarkUtils.cleanException(_e);
				lastOkRound = arrayFind(arr, function(item) { return item != 0; });
				_logger( "------- Exception occurred around round [#lastOkRound#]" );
				echo(_e); // for running in browser
				systemOutput( e, true );
				_logger( message="`" & "``", console=false );
				_logger( message=e.stacktrace, console=false );
				_logger( message="`" & "``", console=false );
				runError = e.message;
				errorCount++;
			}

			time = getTickCount( units ) - s;

			_logger( "Finished #suiteName# [#numberFormat( runs/1000 )#k-#inspect#] took #numberFormat( time/1000 )# ms, or #numberFormat(runs/(time/1000/1000))# per second" );
			result = {
				time: time / 1000,
				inspect: inspect,
				type: type,
				_min: decimalFormat( arrayMin( arr ) / 1000 ),
				_max: decimalFormat( arrayMax( arr ) / 1000 ),
				_avg: decimalFormat( arrayAvg( arr ) / 1000 ),
				_med: decimalFormat( arrayMedian( arr ) / 1000 ),
				error: runError,
				runs: arrayLen( arr ),
				raw: arr
			}
			if (exeLog eq "debug" && inspect eq "never") {
				pp = getTickCount();
				q_exeLog = exeLogger.getDebugLogsCombined( getDirectoryFromPath( getCurrentTemplatePath() ) & "/tests/" );
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
		_memStatGC = reportMem( "", _memBefore.usage, "before", "HEAP" );
		for ( r in _memStatGC.report )
			_logger( r );
		_logger( "" );

		
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

	if ( errorCount > 0 )
		_logger( message="#errorCount# benchmark(s) failed", throw=true );

</cfscript>