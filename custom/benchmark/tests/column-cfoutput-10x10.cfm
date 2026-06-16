<cfscript>
	// realistic: 10 columns × 10 rows — a detail table
	q = queryNew( "id,name,email,status,created,updated,role,dept,phone,notes",
		"integer,varchar,varchar,varchar,timestamp,timestamp,varchar,varchar,varchar,varchar" );
	loop times=10 {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", "user_#r#", r );
		querySetCell( q, "email", "user#r#@example.com", r );
		querySetCell( q, "status", r mod 2 ? "active" : "inactive", r );
		querySetCell( q, "created", now(), r );
		querySetCell( q, "updated", now(), r );
		querySetCell( q, "role", "role_#r mod 3#", r );
		querySetCell( q, "dept", "dept_#r mod 4#", r );
		querySetCell( q, "phone", "555-#numberFormat( r, '0000' )#", r );
		querySetCell( q, "notes", repeatString( "x", 50 ), r );
	}
</cfscript>
<cfset total = 0>
<cfoutput query="q">
	<cfset total += len( name ) + len( email ) + len( status ) + len( role ) + len( dept ) + len( phone )>
</cfoutput>
