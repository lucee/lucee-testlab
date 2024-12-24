<cfscript>
    // see https://luceeserver.atlassian.net/browse/LDEV-2853 date formatting is syncronized
    d =  createDate(randRange(1900,2024),randRange(1,12),randRange(1,28))
    df = DateFormat( d );
    df1 = DateFormat( d );

    if ( dateCompare( df, df1 ) neq 0 )
        throw "dates don't match? [#df#] and [#df1#]"; 
</cfscript>