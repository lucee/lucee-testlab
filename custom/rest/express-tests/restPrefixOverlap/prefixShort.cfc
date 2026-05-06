// Case 1: Prefix collision -- short prefix
// Pairs with prefixLong.cfc (restpath="/api/v1")
// /api          -> this CFC's ping
// /api/v1       -> EXPECTED: prefixLong wins (longest match), Lucee bug: this shadows prefixLong
component restpath="/api" rest="true" {

	remote struct function ping() httpmethod="GET" restpath="ping" {
		return { "handler": "prefixShort", "method": "ping" };
	}
}
