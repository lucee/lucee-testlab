<cfscript>
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	systemOutput ( dir, true );
	files = directoryList( path=dir, filter="*-results.json" );

	runs = [];

	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );
		q = queryNew( "time,suite,spec,suiteSpec" );

		for ( i=1; i <= len(json.bundleStats); i++ ){
			bundle = json.bundleStats[i];
			for (j = 1; j <= len(bundle.suiteStats); j++){
				s = bundle.suiteStats[ j ];
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
		}

		arrayAppend( runs, {
			"java": json.javaVersion,
			"version": json.CFMLEngineVersion,
			"totalDuration": json.totalDuration,
			"stats": queryToStruct(q, "suiteSpec")
		});
	};

	if ( IsEmpty( runs ) ) throw "No json report files found?";

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

		var sortedRuns = duplicate(runs);

		arraySort(
			sortedRuns,
			function (e1, e2){
				return compare(e1.version & e1.java, e2.version & e2.java);
			}
		); // sort runs by oldest version to newest version


		var hdr = [ "Suite / Spec" ];
		var div = [ "---" ];
		loop array=sortedRuns item="local.run" {
			arrayAppend( hdr, run.version & " " & listFirst(run.java,".") );
			arrayAppend( div, "---:" ); // right align as they are all numeric
		}

		// diff column, first run vs last run
		arrayAppend( hdr, "Difference (oldest vs newest)" );
		arrayAppend( div, "---:" ); // right align as they are all numeric

		_logger( "" );
		_logger( "|" & arrayToList( hdr, "|" ) & "|" );
		_logger( "|" & arrayToList( div, "|" ) & "|" );

		// now sort the tests by the difference in time between the first run and last run

		var suiteSpecs = [];
		var suiteSpecsDiff = {};

		loop collection=runs[1].stats key="title" value="test" {
			// difference between the test time for the newest version minus oldest version
			var diff = sortedRuns[arrayLen(runs)].stats[test.suiteSpec].time - sortedRuns[1].stats[test.suiteSpec].time;
			try {
				var percentage = int( ( sortedRuns[1].stats[test.suiteSpec].time / sortedRuns[arrayLen(runs)].stats[test.suiteSpec].time ) * 100 );
			} catch (e){
				var percentage = "err"; // probably div by zero
			}
			ArrayAppend( suiteSpecs, {
				suiteSpec: test.suiteSpec,
				diff: diff,
				percentage: percentage
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
			// force long names to wrap without breaking markdown
			ArrayAppend( row, REReplace( wrap(test.suiteSpec, 70), "\n", " ", "ALL") );
			loop array=sortedRuns item="local.run" {
				if ( structKeyExists( run.stats, test.suiteSpec ) )
					arrayAppend( row, numberFormat( run.stats[test.suiteSpec].time ) );
				else
					arrayAppend( row, "");
			}
			if ( test.diff eq 0 ) {
				arrayAppend( row, numberFormat( test.diff ) );
			} else {
				arrayAppend( row, numberFormat( test.diff ) & " (" & test.percentage & "%)" );
			}
			_logger( "|" & arrayToList( row, "|" ) & "|" );
			row = [];
		}

		_logger( "" );
	}

</cfscript>