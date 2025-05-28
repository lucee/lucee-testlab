<cfscript>
	// testing perf regression introduced in 5.4.5.13
	// https://luceeserver.atlassian.net/browse/LDEV-4155
	myText = fileRead("res/sampleText.txt");
	myText = ReplaceNoCase(myText, "[br]", "<br>", "ALL");
</cfscript>