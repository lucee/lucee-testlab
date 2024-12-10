<cfscript>
    samples = {
        arr: [1,2,3],
        st: [a:1,b:2,c:3],
        string: "lucee",
        number: 123,
        boolean: true,
        short: createObject("java","java.lang.Short").init(1)
    }
    for (s in samples){
        echo(samples[s].toString());
    }
</cfscript>