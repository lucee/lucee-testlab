<cfscript>
    loop times="10"{
        q = QueryNew( "column1,column2", "VarChar,VarChar", [ [ "a", "b" ], [ "c", "d" ] ] );
    }
</cfscript>