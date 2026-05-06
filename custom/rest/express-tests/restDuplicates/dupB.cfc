// Case 4: Identical restPath -- B
// Pairs with dupA.cfc (same restpath="/dup")
component restpath="/dup" rest="true" {

	remote struct function ping() httpmethod="GET" restpath="ping" {
		return { "handler": "dupB", "method": "ping" };
	}

	remote struct function onlyB() httpmethod="GET" restpath="onlyB" {
		return { "handler": "dupB", "method": "onlyB" };
	}
}
