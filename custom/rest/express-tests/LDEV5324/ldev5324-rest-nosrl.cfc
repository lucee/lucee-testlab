component restpath="/ldev5324nosrl" rest="true" {

	remote function getApplicationName() restPath="getApplicationName" httpMethod="GET" {
		return "applicationName:" & getApplicationSettings().name;
	}

	remote function getNoMethod() restPath="noMethod" {
		return "no method!";
	}

}