<cfscript>

	systemOutput( "--- Bundle Test ---- " );
	systemOutput( "--- extensions are loaded on demand, so let's trigger them ---- " );
	systemOutput( "", true );

	systemOutput( "ESAPI", true );
	encodeForHTML( "lucee" );

	systemOutput( "", true );
	systemOutput( "CFZIP", true );
	file = getTempFile( getTempDirectory(), "test", "text" );
	fileWrite( file, "lucee-testlab" );
	zip action="zip" source="#file#" file="#getTempFile(getTempDirectory(), "test", "zip")#";

	systemOutput( "", true );
	systemOutput( "PDF", true );
	isPDFObject( file );

	systemOutput( "", true );
	systemOutput( "Image", true );
	isImageFile( file );

	systemOutput( "", true );
	systemOutput( "S3", true );
	s3exists( bucketName="extension-download", objectName="test", accessKeyId="test", secretAccessKey="test" ); // will throw
	if (structKeyExists(getFunctionList(), "generateArgon2Hash")){
		systemOutput( "", true );
		systemOutput( "Argon", true );
		generateArgon2Hash( "lucee" );
	}

	adminPassword = "admin";
	/*
	for ( env in server.system.environment ) {
		if ( env contains "LUCEE_ADMIN_" ) {
			systemOutput( "ENV VAR #env#: #server.system.environment[ env ]#", true );
		} else {
			// systemOutput( "ENV VAR #env#: ***", true );
		}
	}
	*/

	function checkPassword() {
		try {
			admin action="connect"
					type="server"
					password=adminPassword;
		} catch ( e ) {
			return false;
		}
		return true;
	}

	systemOutput( "see if admin password is set and working : #checkPassword()#", true );

	if (!checkPassword() ) {
		systemOutput( "try updatePassword", true );
		dmin
			action="updatePassword"
			type="server"
			oldPassword=""
			newPassword="#adminPassword#";
	}

	if (!checkPassword() ) {
		systemOutput( "try writing password to #expandPath('{lucee-server}/password.txt')#", true );
		fileWrite( expandPath('{lucee-server}/password.txt'), adminPassword );

		systemOutput( "check password", true );
		admin
			action="checkPassword"
			type="server";	
	}

	systemOutput( "getBundles", true );
	
	admin type="server"
		password=adminPassword
		action="getBundles"
		returnvariable="bundles";

	for ( bundle in bundles ){
		if ( bundle.state != "active" )
		systemOutput( "#chr(9)# #bundle.title#, #bundle.symbolicName#, #bundle.version#, #bundle.state#", true );
	}
	systemOutput( "--- finished ---- " );
</cfscript>