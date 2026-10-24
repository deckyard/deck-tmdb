# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the v4 user approval flow.
# Spliced into tmdb.j via include - not a standalone module.
#
#   1. `requestToken`  - ask for a token to be approved
#   2. `approvalUrl`   - the person opens it in a browser and approves
#   3. `accessToken`   - trade the approved token for a user access token
#
# Apply the result with `withUserToken`; the `account` and list verbs need
# it. An access token does not expire: store it like a password and end it
# with `logout`.

/**
 * A request token waiting for a person to approve it.
 *
 * Not a credential: it authenticates nothing and expires 15 minutes after
 * it is minted. Pass it to `approvalUrl`, then to `accessToken`.
 *
 * @field requestToken {string} the token to have approved
 * @field success {bool} whether TMDB issued it
 * @field statusCode {int} TMDB's status code
 * @field statusMessage {string} TMDB's status text
 */
export def struct RequestToken {
    requestToken as string,
    success as bool,
    statusCode as int,
    statusMessage as string
};

/**
 * A person's user access token and v4 account id.
 *
 * A credential: it carries the read and write scopes of the approving
 * account and does not expire. Keep it out of source, logs and URLs.
 *
 * @field accessToken {string} the token to pass to `withUserToken`
 * @field accountId {string} the v4 account object id the `account` verbs take,
 *        not the numeric v3 account id
 * @field success {bool} whether the trade succeeded
 * @field statusCode {int} TMDB's status code
 * @field statusMessage {string} TMDB's status text
 */
export def struct AccessToken {
    accessToken as string,
    accountId as string,
    success as bool,
    statusCode as int,
    statusMessage as string
};

/**
 * Step 1: mint a request token for a person to approve.
 *
 * Signed with the application token, so it works before anyone signs in.
 * The token expires in 15 minutes; mint it when the person is ready.
 *
 * @param c {Client} a client with the application read access token
 * @return {RequestToken} the token to send for approval
 * @throws {Error} kind "tmdb" when the client has no bearer token, or on a
 *                 transport failure
 * @example
 *   def pending as tmdb.RequestToken init tmdb.requestToken($c);
 *   io.printf("approve at: %s\n", tmdb.approvalUrl($pending.requestToken));
 */
export func requestToken(c as Client) {
    return requestTokenBody($c, json.map());
}

/**
 * Step 1, with a URL TMDB redirects to after approval.
 *
 * TMDB appends `?request_token=...&approved=true` to `redirectTo`: a web
 * callback route or a custom-scheme link. Without a redirect the person
 * stays on a TMDB page and has to come back by hand.
 *
 * @param c {Client} a client with the application read access token
 * @param redirectTo {string} the URL or custom-scheme link to return to
 * @return {RequestToken} the token to send for approval
 * @throws {Error} kind "tmdb" on a blank redirect, no bearer token, or a
 *                 transport failure
 */
export func requestTokenWithRedirect(c as Client, redirectTo as string) {
    def body as json.Value init json.set(
        json.map(),
        "/redirect_to",
        ensureText($redirectTo, "redirect URL"));
    return requestTokenBody($c, $body);
}

/**
 * Step 2: the TMDB URL where a person approves a request token.
 *
 * Builds a string and sends nothing. The token becomes usable once the
 * person allows the application on that page.
 *
 * @param token {string} the `requestToken` from step 1
 * @return {string} the approval URL
 * @throws {Error} kind "tmdb" when the token is blank
 */
export func approvalUrl(token as string) {
    def value as string init ensureText($token, "request token");
    return APPROVAL_BASE + "?request_token=" + uri.encode($value);
}

/**
 * Step 3: trade an approved request token for a user access token.
 *
 * Signed with the application token; the approved request token is the
 * proof. Fails while the token is unapproved, so call it after the person
 * comes back, not on a timer.
 *
 * @param c {Client} a client with the application read access token
 * @param approvedToken {string} the request token, once approved
 * @return {AccessToken} the user access token and v4 account id
 * @throws {Error} kind "tmdb" on a blank or unapproved token, no bearer
 *                 token, or a transport failure
 * @example
 *   def granted as tmdb.AccessToken init tmdb.accessToken($c, $pending.requestToken);
 *   $c = tmdb.withUserToken($c, $granted.accessToken);
 */
export func accessToken(c as Client, approvedToken as string) {
    requireBearer($c, "accessToken");
    def body as json.Value init json.set(
        json.map(),
        "/request_token",
        ensureText($approvedToken, "request token"));
    def reply as json.Value init apiPost(appClient($c), "/4/auth/access_token", $body);
    return AccessToken{
        accessToken: nodeString($reply, "/access_token"),
        accountId: nodeString($reply, "/account_id"),
        success: nodeBool($reply, "/success"),
        statusCode: nodeInt($reply, "/status_code"),
        statusMessage: nodeString($reply, "/status_message")
    };
}

/**
 * Invalidate a user access token at TMDB.
 *
 * Dropping a token locally leaves it valid wherever it was logged or
 * backed up; this ends it. The client is unchanged: follow with
 * `withUserToken($c, "")`.
 *
 * @param c {Client} a client with the application read access token
 * @param userToken {string} the access token to invalidate
 * @return {StatusResponse} TMDB's answer
 * @throws {Error} kind "tmdb" on a blank token, no bearer token, or a
 *                 transport failure
 */
export func logout(c as Client, userToken as string) {
    requireBearer($c, "logout");
    def body as json.Value init json.set(
        json.map(),
        "/access_token",
        ensureText($userToken, "user access token"));
    return statusFrom(apiDelete(appClient($c), "/4/auth/access_token", $body));
}

/**
 * POST `/4/auth/request_token` and fold the reply.
 *
 * @param c {Client} the client
 * @param body {json.Value} the request body, `json.map()` for none
 * @return {RequestToken} the folded reply
 * @throws {Error} kind "tmdb" when the client has no bearer token
 * @internal
 */
func requestTokenBody(c as Client, body as json.Value) {
    requireBearer($c, "requestToken");
    def reply as json.Value init apiPost(appClient($c), "/4/auth/request_token", $body);
    return RequestToken{
        requestToken: nodeString($reply, "/request_token"),
        success: nodeBool($reply, "/success"),
        statusCode: nodeInt($reply, "/status_code"),
        statusMessage: nodeString($reply, "/status_message")
    };
}

/**
 * A copy of the client with the user token dropped.
 *
 * The approval flow must be signed by the application, even when a user
 * token is already on the client (a second sign-in on a shared client).
 *
 * @param c {Client} the client
 * @return {Client} the copy, signing as the application
 * @internal
 */
func appClient(c as Client) {
    def next as Client init $c;
    $next.userToken = "";
    return $next;
}
