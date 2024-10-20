<cfscript>
    // see https://luceeserver.atlassian.net/browse/LDEV-2853 date formatting is syncronized
    test = {
        truth: [
            now()
        ]
    };
    json = serializeJSON( test );
    st = deserializeJSON( json );

    if ( st.truth[ 1 ] != test.truth[ 1 ] )
        throw "dates don't match? [#st.truth[1]#] and [#test.truth[ 1 ]#]"; 
</cfscript>