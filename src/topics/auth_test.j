# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the auth topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testApprovalUrl() {
    testing.assertEqual(
        approvalUrl("abc123"),
        "https://www.themoviedb.org/auth/access?request_token=abc123");
    testing.assertEqual(approvalUrl("  abc123  "), APPROVAL_BASE + "?request_token=abc123");
}

func testApprovalUrlEncodesTheToken() {
    # a request token is a JWT and carries no reserved characters, but the
    # value comes off the wire, so it is encoded rather than trusted
    testing.assertContains(approvalUrl("a+b/c"), "a%2Bb%2Fc");
    testing.assertFalse(strings.contains(approvalUrl("a+b/c"), "a+b/c"));
}

func testApprovalUrlRefusesABlankToken() {
    testing.assertThrows("approvalUrlWithNoToken", "tmdb");
}

func approvalUrlWithNoToken() {
    approvalUrl("   ");
}

func testAppClientDropsAnyUserToken() {
    # the approval flow is the application talking *about* a person, so a
    # user token already on the client must not sign these requests
    def signedIn as Client init withUserToken(client("app"), "someone");
    testing.assertEqual(activeToken($signedIn), "someone");
    testing.assertEqual(activeToken(appClient($signedIn)), "app");
    testing.assertEqual(appClient($signedIn).token, "app");
    # and the caller's client is untouched
    testing.assertEqual($signedIn.userToken, "someone");
}

func testTheAuthVerbsNeedABearerCredential() {
    # a legacy key client cannot reach v4 at all
    testing.assertThrows("requestTokenOnAKeyClient", "tmdb");
    testing.assertThrows("accessTokenOnAKeyClient", "tmdb");
    testing.assertThrows("logoutOnAKeyClient", "tmdb");
}

func requestTokenOnAKeyClient() {
    requestToken(clientFromApiKey("k"));
}

func accessTokenOnAKeyClient() {
    accessToken(clientFromApiKey("k"), "approved");
}

func logoutOnAKeyClient() {
    logout(clientFromApiKey("k"), "user");
}

func testTheAuthVerbsValidateTheirArguments() {
    testing.assertThrows("requestTokenWithNoRedirect", "tmdb");
    testing.assertThrows("accessTokenWithNoRequestToken", "tmdb");
    testing.assertThrows("logoutWithNoToken", "tmdb");
}

func requestTokenWithNoRedirect() {
    requestTokenWithRedirect(client("t"), "  ");
}

func accessTokenWithNoRequestToken() {
    accessToken(client("t"), "");
}

func logoutWithNoToken() {
    logout(client("t"), "   ");
}

func testTheErrorExplainsWhichCredentialIsMissing() {
    try {
        requestToken(clientFromApiKey("k"));
        testing.assertTrue(false);
    } catch (e) {
        testing.assertContains($e.message, "v4 endpoint");
        testing.assertContains($e.message, "read access token");
    }
}
