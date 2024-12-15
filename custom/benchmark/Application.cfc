component {
    this.name="bench-runner";

    function onApplicationStart(){
        application.testSuite = [
            "hello-world"
            , "json"
            , "db"
            , "qoq-hsqldb"
            , "json-date"
            , "date-format"
            , "set-cookie"
            , "query-manipulation"
            , "request"
            , "loops"
            , "primes"
            , "toString"
            , "xml"
            , "member-java"
            , "member-cfml"
        ];
        application.testSuite = [
            "fileReadBinary",
            "qrcode",
            "qrcode-createObject"
        ];
    }

    function onRequestStart(){
        inspectTemplates();
    }
}