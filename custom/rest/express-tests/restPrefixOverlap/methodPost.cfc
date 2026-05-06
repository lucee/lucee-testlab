// Case 3: Method spillover -- POST on child path
// Pairs with methodGet.cfc (restpath="/orders" GET)
component restpath="/orders/items" rest="true" {

	remote struct function add() httpmethod="POST" {
		return { "handler": "methodPost", "method": "add" };
	}
}
