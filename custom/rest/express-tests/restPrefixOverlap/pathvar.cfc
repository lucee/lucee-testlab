// Case 2: Path-param vs literal -- path-param CFC
// Pairs with literal.cfc (restpath="/users/me")
// /users/me   -> EXPECTED: literal.cfc wins (JAX-RS rule: literal beats path var)
// /users/123  -> this CFC
component restpath="/users/{id}" rest="true" {

	remote struct function show( string id restArgSource="Path" ) httpmethod="GET" {
		return { "handler": "pathvar", "id": arguments.id };
	}
}
