<cfscript>
    key =createObject("java", "lucee.runtime.type.KeyImpl").init("am_I_slow");
    
    loop times=100 {
        key.toString();
    }
</cfscript>