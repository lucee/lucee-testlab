<cfscript>
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	files = directoryList( dir );

	runs = [];

	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );

		suiteStats = json.bundleStats[1].suitestats;

		q = queryNew( "time,suite,spec,suiteSpec" );
		for ( s in suiteStats ){
			for ( p in s.specStats ){
				row = queryAddRow( q );
			  //  querySetCell(q, "java", json.javaVersion, row);
			  //  querySetCell(q, "version", json.CFMLEngineVersion, row);
				querySetCell(q, "spec", p.name, row);
				querySetCell(q, "suite", s.name, row);
				querySetCell(q, "suiteSpec", s.name & ", " & p.name, row);
				querySetCell(q, "time", p.totalDuration, row);
			}
		}

		arrayAppend( runs, {
			"java": json.javaVersion,
			"version": json.CFMLEngineVersion,
			"totalDuration": json.totalDuration,
			"stats": queryToStruct(q, "suiteSpec")
		});
	}
	// dump(runs);

	_logger( "## Summary Report" );

	reportRuns( runs );

	reportTests( runs );

	function _logger( string message="", boolean throw=false ){
		if ( !structKeyExists( server.system.environment, "GITHUB_STEP_SUMMARY" ) ){
			systemOutput( arguments.message, true );
			return;
		}

		if ( !FileExists( server.system.environment.GITHUB_STEP_SUMMARY ) ){
			fileWrite( server.system.environment.GITHUB_STEP_SUMMARY, "#### #server.lucee.version# ");
			//fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, server.system.environment.toJson());
		}

		if ( arguments.throw ) {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> [!WARNING]" & chr(10) );
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "> #arguments.message##chr(10)#");
			throw arguments.message;
		} else {
			fileAppend( server.system.environment.GITHUB_STEP_SUMMARY, "#arguments.message##chr(10)#");
		}

	}

	function reportRuns( srcRuns ) localmode=true {

		var runs = duplicate( srcRuns );
		arraySort(
			runs,
			function (e1, e2){
				if (e1.totalDuration lt e2.totalDuration) return -1;
				else if (e1.totalDuration gt e2.totalDuration) return 1;
				return 0;
			}
		); // fastest to slowest

		var hdr = [ "Version", "Java", "Time" ];
		var div = [ "---", "---", "---:" ];
		_logger( "" );
		_logger( "|" & arrayToList( hdr, "|" ) & "|" );
		_logger( "|" & arrayToList( div, "|" ) & "|" );

		var row = [];
		loop array=runs item="local.run" {
			ArrayAppend( row, run.version );
			ArrayAppend( row, run.java );
			arrayAppend( row, numberFormat( run.totalDuration ) );
			_logger( "|" & arrayToList( row, "|" ) & "|" );
			row = [];
		}

		_logger( "" );
	}


	function reportTests( runs ) localmode=true {

		var hdr = [ "Test" ];
		var hdr2 = [ "" ];

		var div = [ "---" ];
		loop array=runs item="local.run" {
			arrayAppend( hdr, run.version );
			arrayAppend( hdr2, run.java );
			arrayAppend( div, "---:" ); // right align as they are all numeric
		}

		// diff column, first run vs last run
		arrayAppend( hdr, "diff" );
		arrayAppend( hdr2, "" );
		arrayAppend( div, "---:" ); // right align as they are all numeric

		_logger( "" );
		_logger( "|" & arrayToList( hdr, "|" ) & "|" );
		_logger( "|" & arrayToList( hdr2, "|" ) & "|" );
		_logger( "|" & arrayToList( div, "|" ) & "|" );

		// now sort the tests by the difference in time between the first run and last run

		var suiteSpecs = [];
		var suiteSpecsDiff = {};

		loop collection=runs[1].stats key="title" value="test" {
			var diff = runs[arrayLen(runs)].stats[test.suiteSpec].time-runs[1].stats[test.suiteSpec].time;
			ArrayAppend( suiteSpecs, {
				suiteSpec: test.suiteSpec,
				diff: diff
			});
			suiteSpecsDiff[test.suiteSpec] = diff;
		}

		arraySort(
			suiteSpecs,
			function (e1, e2){
				if (e1.diff gt e2.diff) return -1;
				else if (e1.diff lt e2.diff) return 1;
				return 0;
			}
		); // sort by performance regression

		var row = [];
		loop array=suiteSpecs item="test" {
			ArrayAppend( row, test.suiteSpec );
			loop array=runs item="local.run" {
				if ( structKeyExists( run.stats, test.suiteSpec ) )
					arrayAppend( row, numberFormat( run.stats[test.suiteSpec].time ) );
				else
					arrayAppend( row, "");
			}
			arrayAppend( row, numberFormat( test.diff ) );
			_logger( "|" & arrayToList( row, "|" ) & "|" );
			row = [];
		}

		_logger( "" );
	}

</cfscript>