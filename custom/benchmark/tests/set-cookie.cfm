<cfscript>
    // https://luceeserver.atlassian.net/browse/LDEV-4313
    cookie name="expires-test-numeric" expires="3" value="testlab";
    cookie name="expires-test-date" expires="#dateAdd("d", now(), 1)#" value="testlab";
</cfscript>