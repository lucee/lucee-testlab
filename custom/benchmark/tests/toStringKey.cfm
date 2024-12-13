<cfscript>
    samples = {
        key: createObject("java", "lucee.runtime.type.KeyImpl").init("zac")
    }
    for (s in samples){
        loop times=1000000 {
            echo(samples[s].toString());
        }
    }
</cfscript>