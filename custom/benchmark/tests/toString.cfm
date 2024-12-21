<cfscript>
    samples = {
        arr: [1,2,3],
        st: [a:1,b:2,c:3],
        string: "lucee",
        number: 123,
        boolean: true,
        short: createObject("java","java.lang.Short").init(1),
        key: createObject("java", "lucee.runtime.type.KeyImpl").init("zzzzz")
    }
    for (s in samples){
        loop times=10 {
            samples[s].toString();
        }
    }
</cfscript>