// Case 1: Prefix collision -- long prefix
// Pairs with prefixShort.cfc (restpath="/api")
component restpath="/api/v1" rest="true" {

	remote struct function ping() httpmethod="GET" restpath="ping" {
		return { "handler": "prefixLong", "method": "ping" };
	}
}
