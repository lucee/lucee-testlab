component restpath="/ldev5323root" rest="true" {

	remote function getApplicationName() restpath="getApplicationName" httpmethod="GET" {
		return "applicationName:" & getApplicationSettings().name;
	}

}