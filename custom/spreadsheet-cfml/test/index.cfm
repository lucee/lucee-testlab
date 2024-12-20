<cfscript>
	paths = [ "root.test.suite" ];
	try{
		headline = "Lucee #server.lucee.version# / Java #server.java.version#";

		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "## " & headline & chr(10) );
			//fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, report );
		} else {
			systemOutput( headline, true );
		}

		setting requesttimeout=10000;
		testRunner = New testbox.system.TestBox();
		result = testRunner.runRaw( bundles=paths );
		reporter = testRunner.buildReporter( "text" );
		report = reporter.runReport( results=result, testbox=testRunner, justReturn=true );
		
		failure = ( result.getTotalFail() + result.getTotalError() ) > 0;

//		#(failure?':x:':':heavy_check_mark:')#
		systemOutput( report, true );

		dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts/";
		if (!directoryExists( dir ))
			directoryCreate( dir );
		reporter = testRunner.buildReporter( "json" );
		reportFile = dir & server.lucee.version & "-" & server.java.version & "-results.json";
		systemOutput( "Writing testbox stats to #reportFile#", true );

		report = reporter.runReport( results=result, testbox=testRunner, justReturn=true );
		report = deserializeJSON(report);
		report["javaVersion"] = server.java.version;
		
		fileWrite( reportFile, serializeJson(report) );

		exeTime = "Test Execution time: #DecimalFormat( result.getTotalDuration() /1000 )# s";
		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, 
				chr(10) & exeTime);
		}

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

		if ( failure ) {
			error = "TestBox could not successfully execute all testcases: #result.getTotalFail()# tests failed; #result.getTotalError()# tests errored.";
			if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
				fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, chr(10) & "#### " & error );
			} else {
				systemOutput( error, true );
			}
			throw error;
		}
	}
	catch( any exception ){
		systemOutput( exception, true );
		rethrow;
	}

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
</cfscript>