<cfscript>
	paths = [ "root.test.suite" ];
	try{
		headline = "Lucee #server.lucee.version# / Java #server.java.version#";

		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "##" & headline & chr(10) );
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

		exeTime = "Test Execution time: #DecimalFormat( result.getTotalDuration() /1000 )# s";
		if ( structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, 
				chr(10) & exeTime);
		}

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
</cfscript>