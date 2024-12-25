<cfscript>
	dir = getDirectoryFromPath( getCurrentTemplatePath() ) & "artifacts";
	files = directoryList( dir );
	
	q = queryNew( "version,java,type,time,runs,inspect,memory,throughput,_min,_max,_avg,_med,error,raw,_perc,pageparts" );
	for ( f in files ){
		systemOutput ( f, true );
		json = deserializeJson( fileRead( f ) );

		json.run.java = listFirst( json.run.java, "." );

		memory = 0;
		for ( m in json.memory.usage ){
			if ( isNumeric( json.memory.usage[ m ] ) )
				memory += json.memory.usage[ m ];
		}
		json.run.memory = int( memory / 1024 / 1024 );

		for ( r in json.data ){
			StructAppend( r, json.run );
			r.throughput = int( r.runs / ( r.time / 1000 ) );
			row = queryAddRow( q );
			QuerySetRow( q, row, r );
		}
	}

	runs = q.runs;

	benchmarkUtils = new benchmarkUtils();
	_logger= benchmarkUtils._logger;

	filter = benchmarkUtils.getTests( server.system.environment.BENCHMARK_FILTER ?: "");
	longestSuiteName = filter.longestSuiteName;
	suites = filter.suites;

	_logger( "## Summary Report" );

	loop list="never,once" item="inspect" {
		loop list="#filter.suites#" item="type" {
			```
			<cfquery name="q_rpt" dbtype="query">
				select	version, java, time, 
						throughput, _perc, _min, _avg, _med, _max, memory, error
				from	q
				where	type = <cfqueryparam value="#type#">
						and inspect = <cfqueryparam value="#inspect#">
				order	by (throughput+0) desc
			</cfquery>
			```

			benchmarkUtils.dumpTable( q_rpt, type, inspect, replace(type,"-", " ", "all") & " - " & UCase( inspect ) );
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