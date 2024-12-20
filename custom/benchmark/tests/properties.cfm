<cffunction name="readTexts" access="public" returntype="struct" output="true"
  hint="Read i18n properties file; result[bundleText_ID]='i18n-text'">
	<cfargument name="bundleName" type="string" required="Yes" hint="Bundle name as part of file name: bundleName + '_' + langIsoCode + '.properties'">
	<cfargument name="langIsoCode" type="string" default="de" hint="Language Isocode: de=deutsch, en=english, fr=francais ... as part of file name (see bundleName)">
	<cfargument name="bundleFolder" type="string" default="" hint="Default folder to find properties file in">
	<cfargument name="bUseCache" type="boolean" default="true">

	<cfset var oFis = 0>
	<cfset var oI18N = 0>

	<cfset var sBundleFile = ">
	<cfset var sItem = ">
	<cfset var stKeys = "">
	<cfset var stReturn = {}>

<cfset var start = getTickCount()>

	<cfset sBundleFile = replaceNoCase("#arguments.bundleFolder##arguments.bundleName#_" & arguments.langIsoCode & ".properties", "\", "/", "ALL")>

	<cfset oFis = CreateObject("java", "java.io.FileInputStream")>
	<cfset oI18N = CreateObject("java", "java.util.PropertyResourceBundle")><!--- 'key=value' interpreter --->

	<cfset oFis.init( sBundleFile )>

	<cfset oI18N.init( oFis )>
	<cfset stKeys = oI18N.getKeys()>

	<cfloop condition="#stKeys.hasMoreElements()#">
		<cfset sItem = stKeys.nextElement()>
		<cfset stReturn[sItem] = oI18N.handleGetObject(sItem)>
	</cfloop>

	<cfset oFis.close()>

	<cfoutput>#getTickCount() - start#</cfoutput>

	<cfreturn stReturn>
</cffunction>

<cfset stTexts = readTexts(
	bundleName="cmfmaster",
	langIsoCode="de",
	bundleFolder=expandPath(".") & "/res/",
	bUseCache=false
)>

<cfscript>
	echo(len(stTexts));
	if (len(stTexts) neq 10) throw "Wrong number of properties, got [#len(stTexts)#] expected [10]";
</cfscript>