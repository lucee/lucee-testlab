<cfscript>
	// CFWheels test runner wrapper for lucee/script-runner
	// Uses internalRequest() to call the wheels runner, triggering Application.cfc lifecycle

	TAB = chr(9);
	NL = chr(10);

	// Determine the webroot (where this file lives is in tests/, so webroot is parent)
	webroot = getDirectoryFromPath(getCurrentTemplatePath());
	// Remove trailing tests/ to get project root
	webroot = reReplace(webroot, "tests[/\\]?$", "");

	systemOutput("Webroot: #webroot#", true);

	// Load datasource config from .CFConfig.json
	cfconfigPath = expandPath(".CFConfig.json");
	if (fileExists(cfconfigPath)) {
		systemOutput("Loading datasource config from #cfconfigPath#", true);

		cfconfigData = deserializeJSON(fileRead(cfconfigPath));

		// Add mappings dynamically based on webroot
		cfconfigData["mappings"] = {
			"/wheels": {
				"physical": webroot & "core/src/wheels",
				"primary": "physical",
				"topLevel": "true",
				"readOnly": "false"
			},
			"/vendor": {
				"physical": webroot & "templates/base/src/vendor",
				"primary": "physical",
				"topLevel": "true",
				"readOnly": "false"
			},
			"/testbox": {
				"physical": webroot & "core/src/wheels/testbox",
				"primary": "physical",
				"topLevel": "true",
				"readOnly": "false"
			},
			"/tests": {
				"physical": webroot & "tests",
				"primary": "physical",
				"topLevel": "true",
				"readOnly": "false"
			}
		};

		configImport(
			type: "server",
			data: cfconfigData,
			password: "admin"
		);
		systemOutput("Datasources and mappings configured", true);

		// Log the mappings for debugging
		for (mapping in cfconfigData.mappings) {
			systemOutput("  Mapping #mapping# -> #cfconfigData.mappings[mapping].physical#", true);
		}
	} else {
		systemOutput("WARNING: .CFConfig.json not found at #cfconfigPath#", true);
	}

	// Verify datasource is available
	try {
		dbinfo type="Version" datasource="wheelstestdb" name="dbVersion";
		systemOutput("Database connected: #dbVersion.database_productname# #dbVersion.database_version#", true);
	} catch (any e) {
		systemOutput("ERROR: Could not connect to wheelstestdb datasource: #e.message#", true);
		rethrow;
	}

	systemOutput("", true);
	systemOutput("=============================================================", true);
	systemOutput("CFWheels Test Suite", true);
	systemOutput("Lucee Version: #server.lucee.version#", true);
	systemOutput("Java Version: #server.java.version#", true);
	systemOutput("=============================================================", true);
	systemOutput("", true);

	request._start = getTickCount();

	// Call the wheels test runner via internalRequest - this triggers Application.cfc
	systemOutput("Calling /wheels/tests_testbox/runner.cfm via internalRequest()...", true);

	response = internalRequest(
		template: "/wheels/tests_testbox/runner.cfm",
		method: "GET",
		urls: { format: "json", cli: true }
	);

	systemOutput("Response status: #response.status#", true);

	// Parse the JSON response
	try {
		result = deserializeJSON(response.fileContent);
	} catch (any e) {
		systemOutput("ERROR: Failed to parse JSON response", true);
		systemOutput("Response content: #left(response.fileContent, 2000)#", true);
		throw(
			message: "Failed to parse test runner response",
			detail: e.message,
			cause: e
		);
	}

	// Output summary
	systemOutput("", true);
	systemOutput("=============================================================", true);
	systemOutput("Test Results Summary", true);
	systemOutput("=============================================================", true);
	systemOutput("Bundles/Suites/Specs: #result.totalBundles#/#result.totalSuites#/#result.totalSpecs#", true);
	systemOutput("Passed:  #result.totalPass#", true);
	systemOutput("Failed:  #result.totalFail#", true);
	systemOutput("Errored: #result.totalError#", true);
	systemOutput("Skipped: #result.totalSkipped#", true);
	systemOutput("Duration: #NumberFormat((getTickCount() - request._start) / 1000)# seconds", true);
	systemOutput("=============================================================", true);

	// Output failures/errors
	if (result.totalFail > 0 || result.totalError > 0) {
		systemOutput("", true);
		systemOutput("FAILURES AND ERRORS:", true);
		for (bundle in result.bundleStats) {
			if (bundle.totalFail > 0 || bundle.totalError > 0) {
				systemOutput("", true);
				systemOutput("Bundle: #bundle.name#", true);
				for (suite in bundle.suiteStats) {
					if (suite.totalFail > 0 || suite.totalError > 0) {
						for (spec in suite.specStats) {
							if (spec.status == "Failed" || spec.status == "Error") {
								systemOutput(TAB & spec.status & ": #spec.name#", true);
								if (len(spec.failMessage)) {
									systemOutput(TAB & TAB & spec.failMessage, true);
								}
							}
						}
					}
				}
			}
		}
	}

	// Write results to artifact file
	dir = getDirectoryFromPath(getCurrentTemplatePath()) & "artifacts/";
	if (!directoryExists(dir)) {
		directoryCreate(dir);
	}

	reportFile = dir & server.lucee.version & "-" & server.java.version & "-results.json";
	systemOutput("Writing test results to #reportFile#", true);

	result["javaVersion"] = server.java.version;
	fileWrite(reportFile, serializeJSON(result));

	// Fail the build if there were failures or errors
	fails = result.totalFail + result.totalError;
	if (fails > 0) {
		throw "#fails# test(s) failed or errored";
	} else if (result.totalPass == 0) {
		throw "No tests passed - check if tests were found";
	}
</cfscript>
