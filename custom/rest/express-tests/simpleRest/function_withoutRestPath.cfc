component restpath="/function-without-rest-path" rest="true" {
	remote String function hello() httpmethod="GET" {
		return "hello-method-withoutrestpath";
	}
}
