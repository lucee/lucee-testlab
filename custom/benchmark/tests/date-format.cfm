<cfscript>
    // see https://luceeserver.atlassian.net/browse/LDEV-2853 date formatting is syncronized
    d =  createDate(randRange(1900,2024),randRange(1,12),randRange(1,28))
    df = DateFormat( d );

    if ( d != df )
        throw "dates don't match? [#d#] and [#df#]"; 
</cfscript>