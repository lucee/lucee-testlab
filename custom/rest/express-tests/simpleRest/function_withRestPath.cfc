component restpath="/function-with-rest-path" rest="true" {
	remote String function hello() httpmethod="GET" restpath="hello" {
		return "hello-method-withrestpath";
	}
}
