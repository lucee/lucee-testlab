<cfscript>
	// realistic: 5 columns × 100 rows — a paginated listing
	q = queryNew( "id,name,email,status,created", "integer,varchar,varchar,varchar,timestamp" );
	loop times=100 {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", "user_#r#", r );
		querySetCell( q, "email", "user#r#@example.com", r );
		querySetCell( q, "status", r mod 2 ? "active" : "inactive", r );
		querySetCell( q, "created", now(), r );
	}
</cfscript>
<cfset total = 0>
<cfoutput query="q">
	<cfset total += len( name ) + len( email ) + len( status )>
</cfoutput>
