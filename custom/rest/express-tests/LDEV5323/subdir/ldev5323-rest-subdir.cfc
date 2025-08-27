component restpath="/ldev5323sub" rest="true" {

	remote function getApplicationName() restpath="getApplicationName" httpmethod="GET" {
		return "applicationName:" & getApplicationSettings().name;
	}

}