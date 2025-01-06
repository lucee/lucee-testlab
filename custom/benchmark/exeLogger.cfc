component  {

	function init(required string adminPassword){
		variables.adminPassword = arguments.adminPassword;
	};

	function enableExecutionLog( string class, struct args, numeric maxLogs ){
		admin action="UpdateExecutionLog" type="server" password="#variables.adminPassword#"
			class="#arguments.class#" enabled= true
			arguments=arguments.args;
		admin action="updateDebug" type="server" password="#variables.adminPassword#" debug="true" template="true"; // template needs to be enabled to produce debug logs
		admin action="updateDebugSetting" type="server" password="#variables.adminPassword#" maxLogs="#arguments.maxLogs#";
	}

	function disableExecutionLog(class="lucee.runtime.engine.ConsoleExecutionLog"){
		admin action="updateDebug" type="server" password="#variables.adminPassword#" debug="false";

		admin action="UpdateExecutionLog" type="server" password="#variables.adminPassword#" arguments={}
			class="#arguments.class#" enabled=false;
		purgeExecutionLog();
	}

	function purgeExecutionLog(){
		admin action="PurgeDebugPool" type="server" password="#variables.adminPassword#";
	}

	function getLoggedDebugData(){
		var logs = [];
		admin action="getLoggedDebugData" type="server" password="#variables.adminPassword#" returnVariable="logs";
		return logs;
	}

	function getDebugLogsCombined( string baseDir, boolean raw=false ){
		var logs = getLoggedDebugData();
		var parts = QueryNew( "ID,COUNT,MIN,MAX,AVG,TOTAL,PATH,START,END,STARTLINE,ENDLINE,SNIPPET,KEY" );
		var baseDir = arguments.baseDir;
		arrayEach( logs, function( log ){
			log.pageParts = cleanUpExeLog( log.pageParts, baseDir );
		}, true);
		arrayEach( logs, function( log ){
			parts = queryAppend( parts, log.pageParts );
		});
		purgeExecutionLog();
		// avoid qoq problems with reserved words
		loop list="min,max,avg,count,total" index="local.col" {
			QueryRenameColumn( parts, col, "_#col#" );
		}
		if ( arguments.raw || parts.recordCount == 0 ) {
			return parts;
		}
		```
		<cfquery name="local.q" dbtype="query">
			select 	sum(_COUNT) as _count, min(_MIN) as _min, max(_MAX) as _max, avg(_AVG) as _avg, sum(_TOTAL) as _total,
					PATH,SNIPPET,KEY, startLine, endLine
			FROM	parts
			group	BY PATH,SNIPPET,KEY
			order	BY path, startLine
		</cfquery>
		```
		// remove them as they are only needed to order the query
		//queryDeleteColumn(q, "startLine");
		//queryDeleteColumn(q, "endLine");
		return q;
	}


	function cleanUpExeLog( query pageParts, string baseDir ){
		var parts = duplicate( pageParts );
		queryAddColumn( parts, "key" ); //  this is synchronized 
		var r = 0;
		loop query=parts {
			var r = parts.currentrow;
			querySetCell( parts, "path", mid( parts.path[ r ], len( arguments.baseDir ) ), r ); // less verbose
			querySetCell( parts, "key", parts.path[ r ] & ":" & parts.startLine[ r ] & ":" & parts.endLine[ r ], r );
		}
		//var st = QueryToStruct(parts, "key");
		return parts;
	}

	function getDebugLogs() cachedwithin="request" {
		disableExecutionLog();
		enableExecutionLog( "lucee.runtime.engine.DebugExecutionLog",{
			"unit": "milli"
			//"min-time": 100
		});
		local.result = _InternalRequest(
			template : "#uri#/ldev5206.cfm",
			url: "pagePoolClear=true" // TODO cfcs aren't recompiled like cfm templates?
		);
		return getLoggedDebugData();
	}
}
