<cfscript>
	// CFWheels test runner wrapper for lucee/script-runner
	// This loads the datasource config and then runs the wheels test suite

	TAB = chr(9);
	NL = chr(13);

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
		for (var mapping in cfconfigData.mappings) {
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

	// Initialize TestBox with the wheels test directory
	testBoxOptions = {
		directory: {
			mapping: "tests.specs",
			recurse: true
		}
	};

	testBox = new testbox.system.TestBox(
		directory: testBoxOptions.directory.mapping,
		recurse: testBoxOptions.directory.recurse
	);

	// Run tests with callbacks for console output
	failedTestCases = [];

	try {
		silent {
			result = testBox.run(
				callbacks: {
					onBundleStart: function(cfc, testResults) {
						var meta = getComponentMetadata(cfc);
						systemOutput(TAB & meta.name & " ", false);
					},
					onBundleEnd: function(cfc, testResults) {
						var bundle = arrayLast(testResults.getBundleStats());

						if (bundle.totalPass eq 0 && (bundle.totalFail + bundle.totalError) eq 0) {
							systemOutput(TAB & " (skipped)", true);
						} else {
							var summary = " (#bundle.totalPass# passed";
							if (bundle.totalSkipped > 0) summary &= ", #bundle.totalSkipped# skipped";
							if (bundle.totalFail > 0) summary &= ", #bundle.totalFail# FAILED";
							if (bundle.totalError > 0) summary &= ", #bundle.totalError# ERRORED";
							summary &= " in #NumberFormat(bundle.totalDuration)#ms)";
							systemOutput(TAB & summary, true);
						}

						// Output failures/errors immediately
						if ((bundle.totalFail + bundle.totalError) > 0) {
							if (!isNull(bundle.suiteStats)) {
								for (var suiteStat in bundle.suiteStats) {
									if (!isNull(suiteStat.specStats)) {
										for (var specStat in suiteStat.specStats) {
											if (!isNull(specStat.failMessage) && len(trim(specStat.failMessage))) {
												arrayAppend(failedTestCases, {
													type: "Failed",
													bundle: bundle.name,
													testCase: specStat.name,
													message: specStat.failMessage
												});
												systemOutput(NL & TAB & "FAILED: " & specStat.name, true);
												systemOutput(TAB & TAB & specStat.failMessage, true);
											}
											if (!isNull(specStat.error) && !isEmpty(specStat.error)) {
												arrayAppend(failedTestCases, {
													type: "Errored",
													bundle: bundle.name,
													testCase: specStat.name,
													message: specStat.error.message ?: "Unknown error"
												});
												systemOutput(NL & TAB & "ERRORED: " & specStat.name, true);
												systemOutput(TAB & TAB & (specStat.error.message ?: "Unknown error"), true);
												if (structKeyExists(specStat.error, "detail") && len(specStat.error.detail)) {
													systemOutput(TAB & TAB & specStat.error.detail, true);
												}
											}
										}
									}
								}
							}
						}

						// Handle global exceptions
						if (!isSimpleValue(bundle.globalException)) {
							systemOutput("Global Bundle Exception:", true);
							systemOutput(TAB & bundle.globalException.type, true);
							systemOutput(TAB & bundle.globalException.message, true);
							if (len(bundle.globalException.detail)) {
								systemOutput(TAB & bundle.globalException.detail, true);
							}
						}
					}
				}
			);
			result = testBox.getResult();
		}

		// Output summary
		systemOutput("", true);
		systemOutput("=============================================================", true);
		systemOutput("Test Results Summary", true);
		systemOutput("=============================================================", true);
		systemOutput("Bundles/Suites/Specs: #result.getTotalBundles()#/#result.getTotalSuites()#/#result.getTotalSpecs()#", true);
		systemOutput("Passed:  #result.getTotalPass()#", true);
		systemOutput("Failed:  #result.getTotalFail()#", true);
		systemOutput("Errored: #result.getTotalError()#", true);
		systemOutput("Skipped: #result.getTotalSkipped()#", true);
		systemOutput("Duration: #NumberFormat((getTickCount() - request._start) / 1000)# seconds", true);
		systemOutput("=============================================================", true);

		// Write results to artifact file
		dir = getDirectoryFromPath(getCurrentTemplatePath()) & "artifacts/";
		if (!directoryExists(dir)) {
			directoryCreate(dir);
		}

		reporter = testBox.buildReporter("json");
		reportFile = dir & server.lucee.version & "-" & server.java.version & "-results.json";
		systemOutput("Writing test results to #reportFile#", true);

		report = reporter.runReport(results: result, testbox: testBox, justReturn: true);
		report = deserializeJSON(report);
		report["javaVersion"] = server.java.version;
		fileWrite(reportFile, serializeJSON(report));

		// Fail the build if there were failures or errors
		fails = result.getTotalFail() + result.getTotalError();
		if (fails > 0) {
			throw "#fails# test(s) failed or errored";
		} else if (result.getTotalPass() eq 0) {
			throw "No tests passed - check if tests were found";
		}

	} catch (any e) {
		systemOutput("", true);
		systemOutput("=============================================================", true);
		systemOutput("TEST RUN FAILED", true);
		systemOutput(e.message, true);
		if (len(e.detail)) {
			systemOutput(e.detail, true);
		}
		systemOutput("=============================================================", true);
		rethrow;
	}
</cfscript>
