<cfscript>    
    a = queryNew( "id,name" );
    loop times="10"{
        r = queryAddRow( a );
        querySetCell(a, "id", r, r)
    }
    // all these underlying methods are syncronized
    queryAddColumn( a,"type" );
    queryDeleteColumn( a, "type" );
    m = getMetadata( a );
    QuerySort( a, "id", "desc" );
    queryDeleteRow( a );
</cfscript>