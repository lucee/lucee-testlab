<cfscript>
    a = queryNew( "id,name,created,updated" );
    loop times="10" {
        r = queryAddRow( a );
        querySetCell(a, "id", repeatString(r,18), r);
        querySetCell(a, "name", repeatString(r,18), r);
    }
    loop times=5 {
        a.toString();
    }
</cfscript>