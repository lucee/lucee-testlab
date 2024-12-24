<cfscript>
    // see https://luceeserver.atlassian.net/browse/LDEV-2853 date formatting is syncronized
    test = {
        truth: [
            createDate(randRange(1900,2024),randRange(1,12),randRange(1,28))
        ]
    };
    json = serializeJSON( test );
    st = deserializeJSON( json );

    if ( DateCompare( st.truth[ 1 ], test.truth[ 1 ] ) neq 0 )
        throw "dates don't match? [#st.truth[1]#] and [#test.truth[ 1 ]#]"; 
</cfscript>