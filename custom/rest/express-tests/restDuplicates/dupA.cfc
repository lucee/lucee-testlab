// Case 4: Identical restPath -- A
// Pairs with dupB.cfc (same restpath="/dup")
// EXPECTED: undefined? error? last-wins? first-wins?  This is the question.
component restpath="/dup" rest="true" {

	remote struct function ping() httpmethod="GET" restpath="ping" {
		return { "handler": "dupA", "method": "ping" };
	}

	remote struct function onlyA() httpmethod="GET" restpath="onlyA" {
		return { "handler": "dupA", "method": "onlyA" };
	}
}
