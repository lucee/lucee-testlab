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
        ];
    }

    function onRequestStart(){
        inspectTemplates();
    }
}