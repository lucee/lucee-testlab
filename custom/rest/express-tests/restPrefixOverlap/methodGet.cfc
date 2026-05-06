// Case 3: Method spillover -- GET only on parent
// Pairs with methodPost.cfc (restpath="/orders/items" POST)
// GET  /orders        -> this CFC
// POST /orders/items  -> EXPECTED: methodPost wins, but if matcher picks this CFC first
//                        and finds no POST handler, request 404/405s instead of falling through
component restpath="/orders" rest="true" {

	remote struct function list() httpmethod="GET" {
		return { "handler": "methodGet", "method": "list" };
	}
}
