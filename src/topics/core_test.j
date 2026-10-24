# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the core topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testClientDefaults() {
    def c as Client init client("eyJhbGciOiJIUzI1NiJ9.token");
    testing.assertEqual($c.token, "eyJhbGciOiJIUzI1NiJ9.token");
    testing.assertEqual($c.apiKey, "");
    testing.assertEqual($c.userToken, "");
    testing.assertEqual($c.language, DEFAULT_LANGUAGE);
    testing.assertEqual($c.region, "");
    testing.assertFalse($c.includeAdult);
    testing.assertEqual($c.timeoutMs, DEFAULT_TIMEOUT_MS);
    testing.assertEqual($c.retries, DEFAULT_RETRIES);
    testing.assertEqual($c.backoffMs, DEFAULT_BACKOFF_MS);
    testing.assertFalse($c.verbose);
}

func testClientTrimsTheToken() {
    testing.assertEqual(client("  abc  ").token, "abc");
}

func testClientRefusesABlankToken() {
    testing.assertThrows("clientWithBlankToken", "tmdb");
}

func clientWithBlankToken() {
    client("   ");
}

func testClientFromApiKey() {
    def c as Client init clientFromApiKey("0123456789abcdef0123456789abcdef");
    testing.assertEqual($c.apiKey, "0123456789abcdef0123456789abcdef");
    testing.assertEqual($c.token, "");
    testing.assertFalse(hasBearer($c));
    testing.assertThrows("apiKeyClientWithBlankKey", "tmdb");
}

func apiKeyClientWithBlankKey() {
    clientFromApiKey("");
}

func testBuildersReturnCopies() {
    def c as Client init client("t");
    def other as Client init withLanguage($c, "de-DE");
    testing.assertEqual($c.language, DEFAULT_LANGUAGE);
    testing.assertEqual($other.language, "de-DE");
}

func testWithLanguageAcceptsBothShapes() {
    testing.assertEqual(withLanguage(client("t"), "de").language, "de");
    testing.assertEqual(withLanguage(client("t"), "pt-BR").language, "pt-BR");
    testing.assertEqual(withLanguage(client("t"), "  fr-FR  ").language, "fr-FR");
}

func testWithLanguageRefusesRubbish() {
    testing.assertThrows("languageWithTooManyParts", "tmdb");
    testing.assertThrows("languageWithBadRegion", "tmdb");
    testing.assertThrows("languageThatIsBlank", "tmdb");
}

func languageWithTooManyParts() {
    withLanguage(client("t"), "de-DE-x");
}

func languageWithBadRegion() {
    withLanguage(client("t"), "de-DEU");
}

func languageThatIsBlank() {
    withLanguage(client("t"), "  ");
}

func testWithRegionUppercasesAndAllowsUnset() {
    testing.assertEqual(withRegion(client("t"), "de").region, "DE");
    testing.assertEqual(withRegion(withRegion(client("t"), "DE"), "").region, "");
    testing.assertThrows("regionWithThreeLetters", "tmdb");
}

func regionWithThreeLetters() {
    withRegion(client("t"), "DEU");
}

func testWithUserTokenAndPredicates() {
    def c as Client init client("app");
    testing.assertTrue(hasBearer($c));
    testing.assertFalse(hasUser($c));
    def signedIn as Client init withUserToken($c, "  user  ");
    testing.assertTrue(hasUser($signedIn));
    testing.assertEqual($signedIn.userToken, "user");
    testing.assertEqual(activeToken($signedIn), "user");
    testing.assertEqual(activeToken($c), "app");
    testing.assertFalse(hasUser(withUserToken($signedIn, "")));
}

func testWithAdultAndVerbose() {
    testing.assertTrue(withAdult(client("t"), true).includeAdult);
    testing.assertTrue(isVerbose(setVerbose(client("t"), true)));
    testing.assertFalse(isVerbose(client("t")));
}

func testTimeoutRetriesAndBackoff() {
    testing.assertEqual(withTimeout(client("t"), 3000).timeoutMs, 3000);
    # 0 means "restore the default", not "no timeout"
    testing.assertEqual(withTimeout(client("t"), 0).timeoutMs, DEFAULT_TIMEOUT_MS);
    testing.assertEqual(withRetries(client("t"), 0).retries, 0);
    testing.assertEqual(withRetries(client("t"), 7).retries, 7);
    testing.assertEqual(withBackoff(client("t"), 0).backoffMs, DEFAULT_BACKOFF_MS);
    testing.assertEqual(withBackoff(client("t"), 2500).backoffMs, 2500);
    testing.assertThrows("negativeTimeout", "tmdb");
    testing.assertThrows("negativeRetries", "tmdb");
    testing.assertThrows("negativeBackoff", "tmdb");
}

func negativeTimeout() {
    withTimeout(client("t"), -1);
}

func negativeRetries() {
    withRetries(client("t"), -1);
}

func negativeBackoff() {
    withBackoff(client("t"), -1);
}

func testRequestHeadersCarryTheActiveToken() {
    def headers as map of string to string init requestHeaders(client("app"));
    testing.assertEqual($headers["Accept"], "application/json");
    testing.assertEqual($headers["Authorization"], "Bearer app");
    testing.assertEqual(
        requestHeaders(withUserToken(client("app"), "user"))["Authorization"],
        "Bearer user");
    # a key-authenticated client sends no Authorization at all
    testing.assertFalse(maps.has(requestHeaders(clientFromApiKey("k")), "Authorization"));
}

func testRequestPolicyMirrorsTheClient() {
    def c as Client init withBackoff(withRetries(withTimeout(client("t"), 1234), 5), 999);
    def policy as http.Options init requestPolicy($c);
    testing.assertEqual($policy.timeoutMs, 1234);
    testing.assertEqual($policy.maxRetries, 5);
    testing.assertEqual($policy.backoffMs, 999);
    testing.assertEqual($policy.maxBytes, MAX_RESPONSE_BYTES);
    testing.assertEqual($policy.maxRedirects, 3);
}

func testRestClientIsBoundToTheApiHost() {
    def r as rest.Client init restClient(client("t"));
    testing.assertEqual($r.baseUrl, API_BASE);
    testing.assertEqual($r.headers["Authorization"], "Bearer t");
}

func testWithCredentialOnlyAddsTheLegacyKey() {
    testing.assertFalse(maps.has(withCredential(client("t"), {}), "api_key"));
    testing.assertEqual(withCredential(clientFromApiKey("k"), {})["api_key"], "k");
    # a bearer token wins; the key is not sent alongside it
    def both as Client init withUserToken(clientFromApiKey("k"), "user");
    testing.assertFalse(maps.has(withCredential($both, {}), "api_key"));
    # the caller's parameters survive
    testing.assertEqual(withCredential(clientFromApiKey("k"), {"page": "2"})["page"], "2");
}

func testWithCredentialDoesNotMutateTheCallersMap() {
    def params as map of string to string init {"page": "1"};
    withCredential(clientFromApiKey("k"), $params);
    testing.assertFalse(maps.has($params, "api_key"));
}

func testIsSecret() {
    testing.assertTrue(isSecret("api_key"));
    testing.assertTrue(isSecret("access_token"));
    testing.assertTrue(isSecret("request_token"));
    testing.assertTrue(isSecret("session_id"));
    testing.assertFalse(isSecret("page"));
    testing.assertFalse(isSecret("query"));
}

func testRequestLineRedactsCredentials() {
    def line as string init requestLine(
        "GET",
        API_BASE + "/3/movie/550",
        {"api_key": "supersecret", "language": "en-US"});
    testing.assertContains($line, "api_key=<redacted>");
    testing.assertContains($line, "language=en-US");
    testing.assertFalse(strings.contains($line, "supersecret"));
}

func testRequestLineWithoutParameters() {
    testing.assertEqual(
        requestLine("GET", API_BASE + "/3/configuration", {}),
        "GET " + API_BASE + "/3/configuration");
}

func testRequestLineFormEncodesValues() {
    testing.assertContains(
        requestLine("GET", API_BASE + "/3/search/movie", {"query": "blade runner"}),
        "query=blade+runner");
}

func testQueryString() {
    testing.assertEqual(queryString({}), "");
    testing.assertEqual(queryString({"page": "2"}), "?page=2");
}

func testLocaleAndPageParams() {
    def c as Client init withRegion(client("t"), "DE");
    testing.assertEqual(localeParams($c)["language"], DEFAULT_LANGUAGE);
    testing.assertEqual(pageParams($c, 3)["page"], "3");
    testing.assertEqual(regionParams($c, 1)["region"], "DE");
    # no region set means the parameter is omitted, not sent empty
    testing.assertFalse(maps.has(regionParams(client("t"), 1), "region"));
    # a client with no language sends none
    def bare as Client init client("t");
    $bare.language = "";
    testing.assertEqual(len(localeParams($bare)), 0);
}

func testEnsurePageBounds() {
    testing.assertEqual(ensurePage(1), 1);
    testing.assertEqual(ensurePage(MAX_PAGE), MAX_PAGE);
    testing.assertThrows("pageZero", "tmdb");
    testing.assertThrows("pageBeyondTheCeiling", "tmdb");
}

func pageZero() {
    ensurePage(0);
}

func pageBeyondTheCeiling() {
    ensurePage(MAX_PAGE + 1);
}

func testEnsureIdAndNumber() {
    testing.assertEqual(ensureId(550, "movie"), 550);
    testing.assertThrows("idZero", "tmdb");
    # season 0 is the specials, so a 0 is legal where an id is not
    testing.assertEqual(ensureNumber(0, "season"), 0);
    testing.assertThrows("negativeSeason", "tmdb");
}

func idZero() {
    ensureId(0, "movie");
}

func negativeSeason() {
    ensureNumber(-1, "season");
}

func testEnsureText() {
    testing.assertEqual(ensureText("  hi  ", "thing"), "hi");
    testing.assertThrows("blankText", "tmdb");
}

func blankText() {
    ensureText("\t\n ", "thing");
}

func testEnsurePathAcceptsRealPaths() {
    testing.assertEqual(ensurePath("/3/movie/550"), "/3/movie/550");
    testing.assertEqual(ensurePath("  /4/list/1/items  "), "/4/list/1/items");
}

func testEnsurePathRefusesUnsafePaths() {
    testing.assertThrows("blankPath", "tmdb");
    testing.assertThrows("pathWithoutLeadingSlash", "tmdb");
    testing.assertThrows("pathWithProtocolRelativeHost", "tmdb");
    testing.assertThrows("pathWithTraversal", "tmdb");
    testing.assertThrows("pathWithQuery", "tmdb");
    testing.assertThrows("pathWithFragment", "tmdb");
    testing.assertThrows("pathWithSpace", "tmdb");
}

func blankPath() {
    ensurePath("  ");
}

func pathWithoutLeadingSlash() {
    ensurePath("3/movie/550");
}

func pathWithProtocolRelativeHost() {
    ensurePath("//evil.example/3/movie/550");
}

func pathWithTraversal() {
    ensurePath("/3/../4/account");
}

func pathWithQuery() {
    ensurePath("/3/movie/550?api_key=leak");
}

func pathWithFragment() {
    ensurePath("/3/movie/550#x");
}

func pathWithSpace() {
    ensurePath("/3/movie/5 50");
}

func testCallRefusesAnUnsafePath() {
    testing.assertThrows("callWithTraversal", "tmdb");
}

func callWithTraversal() {
    call(client("t"), "/3/../4/account/x/lists", {});
}

func testIsCountryCode() {
    testing.assertTrue(isCountryCode("US"));
    testing.assertTrue(isCountryCode("de"));
    testing.assertFalse(isCountryCode("USA"));
    testing.assertFalse(isCountryCode("U"));
    testing.assertFalse(isCountryCode("U1"));
    testing.assertFalse(isCountryCode(""));
}

func testIsLanguageTag() {
    testing.assertTrue(isLanguageTag("en"));
    testing.assertTrue(isLanguageTag("en-US"));
    testing.assertTrue(isLanguageTag("cmn"));
    testing.assertFalse(isLanguageTag("e"));
    testing.assertFalse(isLanguageTag("engl"));
    testing.assertFalse(isLanguageTag("en-USA"));
    testing.assertFalse(isLanguageTag("en-US-x"));
}

func testIsLetterAndIsDigits() {
    testing.assertTrue(isLetter("a"));
    testing.assertTrue(isLetter("Z"));
    testing.assertFalse(isLetter("1"));
    testing.assertFalse(isLetter("-"));
    testing.assertTrue(isDigits("0"));
    testing.assertTrue(isDigits("1977"));
    testing.assertFalse(isDigits(""));
    testing.assertFalse(isDigits("19a7"));
}

func testMediaKindNames() {
    testing.assertEqual(mediaKindName(MediaKind.Movie), "movie");
    testing.assertEqual(mediaKindName(MediaKind.Show), "tv");
    testing.assertEqual(mediaKindName(MediaKind.Person), "person");
    testing.assertEqual(mediaKindName(MediaKind.Episode), "tv_episode");
    testing.assertEqual(mediaKindName(MediaKind.Season), "tv_season");
    testing.assertEqual(mediaKindName(MediaKind.Unknown), "");
}

func testParseMediaKind() {
    testing.assertTrue(parseMediaKind("movie") == MediaKind.Movie);
    testing.assertTrue(parseMediaKind("TV") == MediaKind.Show);
    testing.assertTrue(parseMediaKind("  person  ") == MediaKind.Person);
    testing.assertTrue(parseMediaKind("tv_episode") == MediaKind.Episode);
    testing.assertTrue(parseMediaKind("tv_season") == MediaKind.Season);
    # an unrecognized discriminator must not abort a page fold
    testing.assertTrue(parseMediaKind("podcast") == MediaKind.Unknown);
    testing.assertTrue(parseMediaKind("") == MediaKind.Unknown);
}

func testMediaKindRoundTrip() {
    for (def kind in ["movie", "tv", "person", "tv_episode", "tv_season"]) {
        testing.assertEqual(mediaKindName(parseMediaKind($kind)), $kind);
    }
}

func testYear() {
    testing.assertEqual(year("1999-10-15"), "1999");
    testing.assertEqual(year("  1977-05-25 "), "1977");
    # "" is what TMDB writes for an unknown date; it must not throw
    testing.assertEqual(year(""), "");
    testing.assertEqual(year("199"), "");
    testing.assertEqual(year("nope-10-15"), "");
}

func testBoolParamAndBoolToInt() {
    testing.assertEqual(boolParam(true), "true");
    testing.assertEqual(boolParam(false), "false");
    testing.assertEqual(boolToInt(true), 1);
    testing.assertEqual(boolToInt(false), 0);
}

func testTruthyWord() {
    for (def word in ["1", "true", "TRUE", " yes ", "on"]) {
        testing.assertTrue(truthyWord($word));
    }
    for (def word in ["0", "false", "no", "", "maybe"]) {
        testing.assertFalse(truthyWord($word));
    }
}

func testParseIntOrZero() {
    testing.assertEqual(parseIntOrZero(" 42 "), 42);
    testing.assertEqual(parseIntOrZero("nope"), 0);
    testing.assertEqual(parseIntOrZero(""), 0);
}

func testParseFloatOrZero() {
    testing.assertEqual(parseFloatOrZero(" 8.4 "), 8.4);
    testing.assertEqual(parseFloatOrZero("nope"), 0.0);
}

func testFloatToIntOrZero() {
    testing.assertEqual(floatToIntOrZero(8.9), 8);
    testing.assertEqual(floatToIntOrZero(-2.5), -2);
    # a JSON number wider than int64 answers 0 rather than aborting the fold
    testing.assertEqual(floatToIntOrZero(1.0e300), 0);
}

func testItemPointerAndPointerToken() {
    testing.assertEqual(itemPointer("/results", 3), "/results/3");
    testing.assertEqual(itemPointer("", 0), "/0");
    testing.assertEqual(pointerToken("US"), "US");
    testing.assertEqual(pointerToken("CA-QC"), "CA-QC");
    testing.assertEqual(pointerToken("a/b"), "a~1b");
    testing.assertEqual(pointerToken("a~b"), "a~0b");
}

func testNodeStringCoercions() {
    def doc as json.Value init json.decode('{
        "s": "text", "i": 42, "f": 1.5, "b": true, "n": null, "l": [1]
    }');
    testing.assertEqual(nodeString($doc, "/s"), "text");
    testing.assertEqual(nodeString($doc, "/i"), "42");
    testing.assertEqual(nodeString($doc, "/b"), "true");
    testing.assertEqual(nodeString($doc, "/n"), "");
    testing.assertEqual(nodeString($doc, "/l"), "");
    testing.assertEqual(nodeString($doc, "/missing"), "");
}

func testNodeIntCoercions() {
    def doc as json.Value init json.decode('{
        "i": 42, "f": 8.9, "s": "7", "bad": "x", "b": true, "n": null
    }');
    testing.assertEqual(nodeInt($doc, "/i"), 42);
    testing.assertEqual(nodeInt($doc, "/f"), 8);
    testing.assertEqual(nodeInt($doc, "/s"), 7);
    testing.assertEqual(nodeInt($doc, "/bad"), 0);
    testing.assertEqual(nodeInt($doc, "/b"), 1);
    testing.assertEqual(nodeInt($doc, "/n"), 0);
    testing.assertEqual(nodeInt($doc, "/missing"), 0);
}

func testNodeFloatCoercions() {
    def doc as json.Value init json.decode('{"f": 8.4, "i": 8, "s": "7.5", "bad": "x"}');
    testing.assertEqual(nodeFloat($doc, "/f"), 8.4);
    testing.assertEqual(nodeFloat($doc, "/i"), 8.0);
    testing.assertEqual(nodeFloat($doc, "/s"), 7.5);
    testing.assertEqual(nodeFloat($doc, "/bad"), 0.0);
    testing.assertEqual(nodeFloat($doc, "/missing"), 0.0);
}

func testNodeBoolAcceptsBothV3AndV4Spellings() {
    def doc as json.Value init json.decode('{
        "t": true, "f": false, "one": 1, "zero": 0, "s": "true", "n": null, "fl": 1.0
    }');
    testing.assertTrue(nodeBool($doc, "/t"));
    testing.assertFalse(nodeBool($doc, "/f"));
    # the v4 list endpoints write their flags as 1 / 0
    testing.assertTrue(nodeBool($doc, "/one"));
    testing.assertFalse(nodeBool($doc, "/zero"));
    testing.assertTrue(nodeBool($doc, "/s"));
    testing.assertTrue(nodeBool($doc, "/fl"));
    testing.assertFalse(nodeBool($doc, "/n"));
    testing.assertFalse(nodeBool($doc, "/missing"));
}

func testNodeLengthAndItem() {
    def doc as json.Value init json.decode('{"l": [{"id": 1}, {"id": 2}], "s": "x"}');
    testing.assertEqual(nodeLength($doc, "/l"), 2);
    testing.assertEqual(nodeLength($doc, "/s"), 0);
    testing.assertEqual(nodeLength($doc, "/missing"), 0);
    testing.assertEqual(nodeInt(nodeItem($doc, "/l", 1), "/id"), 2);
}

func testNodeStringAndIntLists() {
    def doc as json.Value init json.decode('{"names": ["a", "b"], "ids": [1, 2, 3]}');
    testing.assertEqual(nodeStringList($doc, "/names"), ["a", "b"]);
    testing.assertEqual(nodeIntList($doc, "/ids"), [1, 2, 3]);
    testing.assertEqual(nodeStringList($doc, "/missing"), []);
    testing.assertEqual(nodeIntList($doc, "/missing"), []);
}

func testNodeFieldList() {
    def doc as json.Value init json.decode('{"rows": [{"name": "a"}, {"name": "b"}]}');
    testing.assertEqual(nodeFieldList($doc, "/rows", "name"), ["a", "b"]);
}

func testNodeKeys() {
    def doc as json.Value init json.decode('{"results": {"US": 1, "CA-QC": 2}, "l": [1]}');
    testing.assertEqual(nodeKeys($doc, "/results"), ["US", "CA-QC"]);
    testing.assertEqual(nodeKeys($doc, "/l"), []);
    testing.assertEqual(nodeKeys($doc, "/missing"), []);
}

func testStatusMessagePrefersTmdbsOwnSentence() {
    testing.assertEqual(
        statusMessage('{"success": false, "status_code": 7, "status_message": "Invalid API key."}'),
        "Invalid API key.");
    testing.assertEqual(statusMessage("<html>gateway timeout</html>"), "");
    testing.assertEqual(statusMessage('{}'), "");
}

func testStatusHint() {
    testing.assertContains(statusHint(401), "token");
    testing.assertContains(statusHint(404), "no such resource");
    testing.assertContains(statusHint(429), "rate limited");
    testing.assertContains(statusHint(503), "retry later");
    testing.assertEqual(statusHint(418), "unexpected status");
}

func testFailureTextUsesTheBodyWhenThereIsOne() {
    def spoken as rest.Response init rest.Response{
        status: 401,
        headers: {},
        body: '{"status_code": 7, "status_message": "Invalid API key: You must be granted a valid key."}'
    };
    def said as string init failureText($spoken);
    testing.assertContains($said, "HTTP 401");
    testing.assertContains($said, "Invalid API key");
    def silent as rest.Response init rest.Response{status: 502, headers: {}, body: "<html>"};
    testing.assertContains(failureText($silent), "TMDB is having trouble");
}

func testDecodeCheckedPassesA2xxThrough() {
    def ok as rest.Response init rest.Response{status: 200, headers: {}, body: '{"id": 550}'};
    testing.assertEqual(nodeInt(decodeChecked($ok, "GET /3/movie/550"), "/id"), 550);
}

func testDecodeCheckedRefusesAnUnhappyStatus() {
    testing.assertThrows("decodeAnUnauthorizedReply", "tmdb");
    testing.assertThrows("decodeANonJsonReply", "tmdb");
}

func decodeAnUnauthorizedReply() {
    decodeChecked(
        rest.Response{status: 401, headers: {}, body: '{"status_message": "no"}'},
        "GET /3/movie/550");
}

func decodeANonJsonReply() {
    decodeChecked(rest.Response{status: 200, headers: {}, body: "not json"}, "GET /3/movie/550");
}

func testDecodeBodyNamesTheRequest() {
    testing.assertThrows("decodeGarbage", "tmdb");
}

func decodeGarbage() {
    decodeBody("<!doctype html>", "GET " + API_BASE + "/3/movie/550");
}

func testRequireBearerAndRequireUser() {
    # a bearer client passes the first gate but not the second
    requireBearer(client("t"), "test");
    testing.assertThrows("requireBearerOnAKeyClient", "tmdb");
    testing.assertThrows("requireUserWithoutAUserToken", "tmdb");
    requireUser(withUserToken(client("t"), "u"), "test");
}

func requireBearerOnAKeyClient() {
    requireBearer(clientFromApiKey("k"), "accountLists");
}

func requireUserWithoutAUserToken() {
    requireUser(client("t"), "accountLists");
}

# A client whose bearer token holds a line break. `http` builds and checks the
# request before it opens a socket, so any verb run with this client fails
# locally with the method and URL it would have requested. That is how the
# verbs with nothing else to validate are tested offline.
func unsendableClient() {
    return client("t\nx");
}

# Run a verb on the unsendable client and hand back the error it raised.
func refusalOf(verb as func) {
    try {
        $verb(unsendableClient());
    } catch (e) {
        return $e;
    }
    return Error{kind: "", message: "the request was not refused"};
}

# Assert that a verb asked for `request` (method and full URL) before it was
# stopped.
func assertRequested(verb as func, request as string) {
    def e as Error init refusalOf($verb);
    testing.assertEqual($e.kind, "tmdb");
    testing.assertContains($e.message, $request + " failed: ");
}

func testUnsendableClientNeverReachesTheSocket() {
    def e as Error init refusalOf(callLists);
    testing.assertContains($e.message, "control character");
}

func callLists(c as Client) {
    call($c, "/3/movie/550/lists", {"page": "1"});
}

func testCallVerbsSendTheMethodAndPathTheyName() {
    assertRequested(callLists, "GET " + API_BASE + "/3/movie/550/lists");
    assertRequested(callPostList, "POST " + API_BASE + "/4/list");
    assertRequested(callPutList, "PUT " + API_BASE + "/4/list/7");
    assertRequested(callDeleteItems, "DELETE " + API_BASE + "/4/list/7/items");
}

func callPostList(c as Client) {
    callPost($c, "/4/list", json.map());
}

func callPutList(c as Client) {
    callPut($c, "/4/list/7", json.map());
}

func callDeleteItems(c as Client) {
    callDelete($c, "/4/list/7/items", json.map());
}

func testBodyCallVerbsRefuseAnUnsafePath() {
    testing.assertThrows("callPostWithAQuery", "tmdb");
    testing.assertThrows("callPutWithoutASlash", "tmdb");
    testing.assertThrows("callDeleteToAnotherHost", "tmdb");
}

func callPostWithAQuery() {
    callPost(client("t"), "/4/list?api_key=x", json.map());
}

func callPutWithoutASlash() {
    callPut(client("t"), "4/list/7", json.map());
}

func callDeleteToAnotherHost() {
    callDelete(client("t"), "//evil.example/4/list/7", json.map());
}

# clientFromEnv reads six variables. Each test below sets all six and puts
# the previous values back; an unset variable comes back set to "", which
# getEnv reads the same way.
func tmdbEnv() {
    def saved as map of string to string init {};
    for (def name in [
        "TMDB_ACCESS_TOKEN",
        "TMDB_API_KEY",
        "TMDB_USER_TOKEN",
        "TMDB_LANGUAGE",
        "TMDB_REGION",
        "TMDB_VERBOSE"
    ]) {
        $saved[$name] = os.getEnv($name);
    }
    return $saved;
}

func restoreEnv(saved as map of string to string) {
    for (def name in $saved) {
        os.setEnv($name, $saved[$name]);
    }
}

func setTmdbEnv(token as string, key as string, user as string, lang as string, region as string) {
    os.setEnv("TMDB_ACCESS_TOKEN", $token);
    os.setEnv("TMDB_API_KEY", $key);
    os.setEnv("TMDB_USER_TOKEN", $user);
    os.setEnv("TMDB_LANGUAGE", $lang);
    os.setEnv("TMDB_REGION", $region);
    os.setEnv("TMDB_VERBOSE", "");
}

func testClientFromEnvPrefersTheAccessToken() {
    def saved as map of string to string init tmdbEnv();
    defer restoreEnv($saved);
    setTmdbEnv(" eyJ.app ", "k3y", " eyJ.user ", " de-DE ", "at");
    def c as Client init clientFromEnv();
    testing.assertEqual($c.token, "eyJ.app");
    testing.assertEqual($c.apiKey, "");
    testing.assertEqual($c.userToken, "eyJ.user");
    testing.assertEqual($c.language, "de-DE");
    testing.assertEqual($c.region, "AT");
    testing.assertFalse($c.verbose);
    testing.assertEqual($c.timeoutMs, DEFAULT_TIMEOUT_MS);
}

func testClientFromEnvFallsBackToTheApiKey() {
    def saved as map of string to string init tmdbEnv();
    defer restoreEnv($saved);
    setTmdbEnv("  ", "k3y", "", "", "");
    def c as Client init clientFromEnv();
    testing.assertEqual($c.token, "");
    testing.assertEqual($c.apiKey, "k3y");
    testing.assertFalse(hasBearer($c));
    # unset optional variables leave the defaults alone
    testing.assertEqual($c.userToken, "");
    testing.assertEqual($c.language, DEFAULT_LANGUAGE);
    testing.assertEqual($c.region, "");
}

func testClientFromEnvReadsTheVerboseFlag() {
    def saved as map of string to string init tmdbEnv();
    defer restoreEnv($saved);
    setTmdbEnv("t", "", "", "", "");
    for (def word in ["1", "true", "YES", " on "]) {
        os.setEnv("TMDB_VERBOSE", $word);
        testing.assertTrue(clientFromEnv().verbose);
    }
    for (def word in ["0", "false", "no", ""]) {
        os.setEnv("TMDB_VERBOSE", $word);
        testing.assertFalse(clientFromEnv().verbose);
    }
}

func testClientFromEnvRefusesAMissingOrBadSetting() {
    def saved as map of string to string init tmdbEnv();
    defer restoreEnv($saved);
    setTmdbEnv(" ", " ", "u", "", "");
    testing.assertThrows("clientFromEnvAsIs", "tmdb");
    setTmdbEnv("t", "", "", "english", "");
    testing.assertThrows("clientFromEnvAsIs", "tmdb");
    setTmdbEnv("t", "", "", "", "USA");
    testing.assertThrows("clientFromEnvAsIs", "tmdb");
}

func clientFromEnvAsIs() {
    clientFromEnv();
}
