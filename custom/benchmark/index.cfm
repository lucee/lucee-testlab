<cfscript>
	runs = server.system.environment.BENCHMARK_CYCLES ?: 2500;

	setting requesttimeout=runs;
	warmup = []

	results = {
		data = [],
		run = {
			version: server.lucee.version,
			java: server.java.version,
			runs: runs
		}
	};

	ArraySet( warmup, 1, 25, 0 );

	_memBefore = reportMem( "", {}, "before", "HEAP" );
	errorCount = 0;
	units = "micro";

	appSettings = getApplicationSettings();
	systemOutput("Precise Math: " & (appSettings.preciseMath ?: "not supported"), true);

	systemOutput("Sleeping for 5s, allow server to startup and settle", true);
	systemOutput("", true);
	sleep( 5000 ); // initial time to settle

	loop list="once,never" item="inspect" {
		configImport( {"inspectTemplate": inspect }, "server", "admin" );

		loop list="#application.testSuite.toList()#" item="type" {
			template = "/tests/#type#.cfm";
			runError = "";
			arr = [];
			s = 0;
			ArraySet( arr, 1, runs, 0 );
			try {
				systemOutput( "Warmup #type#, inspect: [#inspect#]", true );
				ArrayEach( warmup, function( item ){
					_internalRequest(
						template: template
					);
				}, true );
				systemOutput( "Sleeping 2s first, after warmup", true );
				sleep( 2000 ); // time to settle

				systemOutput( "Running #type# [#numberFormat( runs )#] times, inspect: [#inspect#]", true );
				s = getTickCount(units);
			
				ArrayEach( arr, function( item, idx, _arr ){
					var start = getTickCount(units);
					_internalRequest(
						template: template
					);
					arguments._arr[ arguments.idx ] = getTickCount(units) - start;
				}, true);
			} catch ( e ){
				systemOutput( e, true );
				echo(e);
				_logger( e.message );
				runError = e.message;
				errorCount++;
			}

			time = getTickCount(units)-s;

			_logger( "Running #type# [#numberFormat( runs )#] times, inspect: [#inspect#] took #numberFormat( time/1000 )# ms, or #numberFormat(runs/(time/1000/1000))# per second" );
			ArrayAppend( results.data, {
				time: time/1000,
				inspect: inspect,
				type: type,
				_min: decimalFormat( arrayMin( arr )/ 1000 ),
				_max: decimalFormat( arrayMax( arr )/ 1000 ),
				_avg: decimalFormat( arrayAvg( arr )/ 1000 ),
				error: runError
			});
		}
	}

	_logger( message="" );
	_logger( message="-------test run complete------" );

	_memStat = reportMem( "", _memBefore, "before", "HEAP" );

	for ( r in _memStat.report )
		_logger( r );

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