component restpath="/simpleRest" rest="true" {
	/**
	 * @httpmethod GET
	 * @restPath   info
	 */
	remote string function getInfo() {
		return getCurrentTemplatePath();
	}
}

