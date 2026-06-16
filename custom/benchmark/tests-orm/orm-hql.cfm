<cfscript>
	ORMExecuteQuery( "FROM BasicEntity WHERE status = :status ORDER BY score", { status: "active" } );
</cfscript>
