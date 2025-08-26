/**
 * @restpath /simpleRest
 * @rest     true
 */
component {
	/**
	 * @httpmethod GET
	 * @restPath   info
	 */
	remote struct function getInfo() {
		return getCurrentTemplatePath();
	}
}

