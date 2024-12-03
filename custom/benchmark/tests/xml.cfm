<cfscript>
    xml = xmlNew();
    xml.XmlRoot = xmlElemNew( xml, "sampleXml" );
    xml.sampleXml.XmlText = "This is root node text";
    xmlSearch( xml, "/sampleXml" );
    str = toString( xml );
    xmlParse( str );
</cfscript>