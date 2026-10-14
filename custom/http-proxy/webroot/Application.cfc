component {
	this.name = "http-proxy";

	// SOURCE=app: the scenario's proxy only as this.proxy, the server has none
	if ( server.system.environment.APP_PROXY == "1" && len( server.system.environment.PROXY_HOST ) ) {
		this.proxy = {
			server: server.system.environment.PROXY_HOST,
			port: server.system.environment.PROXY_PORT,
			username: server.system.environment.PROXY_USER,
			password: server.system.environment.PROXY_PASS
		};
	}
}
