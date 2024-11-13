<cfscript>
    samples = {
        arr: [1,2,3],
        st: [a:1,b:2,c:3],
        string: "lucee",
        number: 123
    }
    for (s in samples){
        echo(samples[s].toString());
    }
</cfscript>