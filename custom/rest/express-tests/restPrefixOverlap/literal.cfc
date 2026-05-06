// Case 2: Path-param vs literal -- literal CFC
// Pairs with pathvar.cfc (restpath="/users/{id}")
component restpath="/users/me" rest="true" {

	remote struct function whoami() httpmethod="GET" {
		return { "handler": "literal", "method": "whoami" };
	}
}
