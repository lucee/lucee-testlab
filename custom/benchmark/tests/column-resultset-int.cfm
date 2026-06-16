<cfscript>
	// exercises QueryImpl's ResultSet getObject(int) / getString(int) path
	q = queryNew( "id,name,email,status,dept,role,phone,score,created,notes",
		"integer,varchar,varchar,varchar,varchar,varchar,varchar,integer,timestamp,varchar" );
	loop times=100 {
		r = queryAddRow( q );
		querySetCell( q, "id", r, r );
		querySetCell( q, "name", "user_#r#", r );
		querySetCell( q, "email", "user#r#@example.com", r );
		querySetCell( q, "status", "active", r );
		querySetCell( q, "dept", "eng", r );
		querySetCell( q, "role", "dev", r );
		querySetCell( q, "phone", "555-#r#", r );
		querySetCell( q, "score", r * 10, r );
		querySetCell( q, "created", now(), r );
		querySetCell( q, "notes", "notes_#r#", r );
	}

	// access via ResultSet int-indexed methods
	total = 0;
	loop query="q" {
		loop from=1 to=q.getColumnCount() index="c" {
			obj = q.getObject( javaCast( "int", c ) );
			if ( !isNull( obj ) ) total += len( toString( obj ) );
		}
	}
</cfscript>
