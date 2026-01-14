component {
    this.name="bench-runner";

    function onApplicationStart(){
        application.testSuite = [
            "hello-world"
            , "json"
            , "db"
            , "qoq-hsqldb"
            , "qoq-native"
            , "qoq-mixed"
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
            , "resource-util"
            , "directoryList"
            , "qrcode-createObject-emptyInit"
            , "properties"
            , "replaceNoCase"
        ];
    }

    function onRequestStart(){
        inspectTemplates();
    }
}