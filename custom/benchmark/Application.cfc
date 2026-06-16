component {
    this.name="bench-runner";

    function onApplicationStart(){
        application.testSuite = [
            "hello-world"
            , "json"
            , "db-insert-select"
            , "qoq-hsqldb"
            , "qoq-native"
            , "json-date"
            , "date-format"
            , "set-cookie"
            , "query-manipulation"
            , "request"
            , "cfc-empty"
            , "cfc-5props"
            , "loops"
            , "primes"
            , "toString"
            , "xml"
            , "member-java"
            , "member-cfml" 
            , "qrcode"
            , "qrcode-createObject"
            , "resource"
            //, "resource-util"
            , "directoryList"
            , "fileReadBinary"
            , "qrcode-createObject-emptyInit"
            , "properties"
            , "replaceNoCase"
            , "column-cfoutput-5x100"
            , "math-functions"
            //, "db-insert"          // duplicate of db
            //, "db-inzert"          // duplicate of db
            , "db-mulitple-insert"
            //, "db-multiple-insert-no-result" // same as db-mulitple-insert minus result
            //, "dba"                // duplicate of db
            //, "dbz-select-named"   // similar to dbz-select
            , "dbz-select"
            , "zzz-hello-world"
            //, "dbz"               // duplicate of db
        ];
    }

    function onRequestStart(){
        inspectTemplates();
    }
}