component restpath="/ldev5324" rest="true" {

	remote function getApplicationName() restPath="getApplicationName" httpMethod="GET" {
		return "applicationName:" & getApplicationSettings().name;
	}

	remote function getNoMethod() restPath="noMethod" {
		return "no method!";
	}

	remote function wrongMethod() restPath="wrongMethod" httpMethod="GET" {
		return "wrongMethod";
	}

	remote function multipleMethods() restPath="multipleMethods" httpMethod="GET,POST" {
		return CGI.REQUEST_METHOD;
	}

	remote function getStudent (
			required string name restArgSource="Path",
			required numeric age restArgSource="Path"
		) returnType="student" restPath="{name}-{age}" {
		var studentObj = createObject("component", "student").init(arguments.name, arguments.age);
		return studentObj;
	}

}