component restpath="/ldev5324multiple" rest="true" {
		// not used, only to check REST endpoint matching
		remote function abc() restPath="abc" httpMethod="POST,DELETE" {
			return CGI.REQUEST_METHOD;
		}
		
		// not used, only to check REST endpoint matching
		remote function lala() restPath="multiple" httpMethod="POST,DELETE" {
			return CGI.REQUEST_METHOD;
		}

		remote function multipleMethods() restPath="multipleMethods" httpMethod="POST,DELETE" {
			return CGI.REQUEST_METHOD;
		}

}