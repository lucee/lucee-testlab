<cfscript>
	benchmarkUtils = new benchmarkUtils();
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	files = directoryList( dir );

	q = queryNew( "version,java,type,time,runs,inspect,memory,testMemory,gccount,throughput,"
		& "_min,_max,_avg,_med,error,raw,_perc,exeLog,totalDuration" );

	tests = structNew('ordered');
	runs = [];

	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );

		json.run.java = listFirst( json.run.java, "." );
		json.run.memory = benchmarkUtils.getTotalMemoryUsage( json.memory.usage );
		json.run.gcCount = json.gcCount;

		for ( r in json.data ){
			StructAppend( r, json.run );
			r.throughput = int( r.runs / ( r.time / 1000 ) );
			row = queryAddRow( q );
			QuerySetRow( q, row, r );
			if ( structKeyExists( r, "exeLog" ) ){
				if ( !structKeyExists( tests, r.type ) )
					tests[ r.type ] = [];
				arrayAppend( tests[ r.type ], {
					"java": json.run.java,
					"version": json.run.version,
					// "totalDuration": json.run.totalDuration,
					"stats": r.exeLog
				});
			}
		}
		arrayAppend( runs, {
			"java": json.run.java,
			"version": json.run.version,
			"totalDuration": json.run.totalDuration,
			"memory": json.run.memory,
			"gcCount": json.run.gcCount
		});
	}

	
	_logger= benchmarkUtils._logger;

	filter = benchmarkUtils.getTests( server.system.environment.BENCHMARK_FILTER ?: "");
	longestSuiteName = filter.longestSuiteName;
	suites = filter.suites;

	exeLog = server.system.environment.EXELOG ?: "";

	javaDistribution = server.system.environment.JAVA_DISTRIBUTION ?: "";
	benchmarkCycles = server.system.environment.BENCHMARK_CYCLES ?: "";

	_logger( "## Summary Report" );

	if ( len( exeLog ) && exeLog neq "none" ){
		_logger( "" );
		_logger( "Note: ExecutionLog was set to [#exeLog#], not all versions run with executionLog enabled and it affects overall performance" );
		_logger( "" );
	}
	_logger( "Using Java Distribution: " & javaDistribution );
	_logger( "Never rounds: " & benchmarkCycles & "k" );

	benchmarkUtils.reportRuns( runs );

	// by java version
	```
	<cfquery name="q_java" dbtype="query">
		select	java
		from	q
		group by java
		order by java desc
	</cfquery>
	```

	loop query="q_java" {
		_logger( "#### Summary Report - Java #q_java.java#" );
		benchmarkUtils.reportRuns( runs, java );
	}

	// report out the winners for each benchmark
	winners = {};
	loop list="#filter.suites#" item="type" {
		```
		<cfquery name="q_win" dbtype="query">
			select	version, java, time,
					throughput, _perc, _min, _avg, _med, _max, memory, error
			from	q
			where	type = <cfqueryparam value="#type#">
					and inspect = 'never'
			order	by (throughput+0) desc
		</cfquery>
		```
		if ( !structKeyExists( winners, q_win.version ) )
			winners[q_win.version] = [];
		arrayAppend( winners[ q_win.version ], type );
	}
	_logger( "" );
	_logger( "#### Benchmark Winners by Version");
	_logger( "" );
	hdr = [ "Version", "Test(s)"];
	div = [ "---", "---"];
	_logger( "|" & arrayToList( hdr, "|" ) & "|" );
	_logger( "|" & arrayToList( div, "|" ) & "|" );
	loop collection=winners key="winner" value="wins"{
		_logger("|" & winner & "|"
			& benchmarkUtils.markdownEscape( wrap( arrayToList( wins, ', ' ), 150 ) ) & "|" );
	}
	_logger( "" );

	// report out per test
	loop list="never,once" item="inspect" {
		loop list="#filter.suites#" item="type" {
			```
			<cfquery name="q_rpt" dbtype="query">
				select	version, java, time,
						throughput, _perc, _min, _avg, _med, _max, error, testMemory as memory, gccount as _gc
				from	q
				where	type = <cfqueryparam value="#type#">
						and inspect = <cfqueryparam value="#inspect#">
				order	by (throughput+0) desc
			</cfquery>
			```

			benchmarkUtils.dumpTable( q=q_rpt, title=replace(type,"-", " ", "all") & " - " & UCase( inspect ) );
		}
	}

	if (exeLog == "debug"){
		_logger( "#### Execution Log Cross Reference" );
		_logger( "" );
		if ( structCount( tests ) ){
			for ( type in tests ){
				_logger( "#### " & replace( type, "-", " ", "all" ) );
				_logger( "" );
				runs = tests[ type ];
				benchmarkUtils.reportTests(	runs=runs,
					sectionTitle="Template",
					sectionKey="key",
					detailTitle="Snippet",
					detailKey="snippet",
					statKey=[ "_MIN", "_AVG", "_MAX" ]
				);
			}
		} else {
			_logger( "No exeLog data found" );
		}


	}

</cfscript>
<!--- sigh, github doesn't suport data image urls --->
<!---

<cfquery name="mem_range" dbtype="query">
	select min(memory) as min, max(memory) as max
	from   q
</cfquery>

<cfquery name="throughput_range" dbtype="query">
	select min(throughput) as min, max(throughput) as max
	from   q
</cfquery>



<cfloop list="never,once" item="_inspect">
	<cfchart chartheight="500" chartwidth="1024"
			title="#UCase( _inspect )# Benchmarks - #runs# runs" format="png" name="graph"
			scaleFrom="#throughput_range.min#" scaleTo="#throughput_range.max#">
		<cfchartseries type="line" seriesLabel="Hello World">
			<cfloop query="q">
				<cfif q.type eq "hello-world" and q.inspect eq _inspect>
					<cfchartdata item="#q.version# #q.java#" value="#q.throughput#">
				</cfif>
			</cfloop>
		</cfchartseries>
		<cfchartseries type="line" seriesLabel="Json">
			<cfloop query="q">
				<cfif q.type eq "json" and q.inspect eq _inspect>>
					<cfchartdata item="#q.version# #q.java#" value="#q.throughput#">
				</cfif>
			</cfloop>
		</cfchartseries>
	</cfchart>
	<cfscript>
		_logger( "#### Inspect #UCase( _inspect )# Benchmarks - #runs# runs" );
		_logger( "" );
		_logger( "![Inspect #UCase( _inspect )# Benchmarks](#getImageBase64( graph )#)" );
		_logger( "" );
	</cfscript>
</cfloop>

<cfchart chartheight="500" chartwidth="1024"
		title="Memory Benchmarks - #runs# runs" format="png" name="graph"
		scaleFrom="#mem_range.min#" scaleTo="#mem_range.max#">
	<cfchartseries type="line" seriesLabel="Memory">
		<cfloop query="q">
			<cfif q.type eq "hello-world" and q.inspect eq "never">
				<cfchartdata item="#q.version# #q.java#" value="#q.memory#">
			</cfif>
		</cfloop>
	</cfchartseries>
</cfchart>
<cfscript>
	_logger( "#### Memory Benchmarks - #runs# runs" );
	_logger( "" );
	_logger( "![Memory Benchmarks](#getImageBase64( graph )#)" );
	_logger( "" );
</cfscript>
--->