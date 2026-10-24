# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the client, request plumbing, shared validation and JSON readers.
# Spliced into tmdb.j via include - not a standalone module.

/**
 * Host both API generations answer on.
 *
 * v3 and v4 are two path prefixes (`/3/...`, `/4/...`) on this one host,
 * reached with the same bearer token.
 */
export def const API_BASE as string init "https://api.themoviedb.org";

/**
 * Page where a user approves a v4 request token.
 *
 * `approvalUrl` appends `?request_token=...` to it.
 */
export def const APPROVAL_BASE as string init "https://www.themoviedb.org/auth/access";

/**
 * Per-request idle timeout of a fresh client, in milliseconds.
 */
export def const DEFAULT_TIMEOUT_MS as int init 15000;

/**
 * Times a fresh client retries a 429 or 5xx before giving up.
 *
 * The `http` retry policy honours a numeric `Retry-After`, which TMDB
 * sends with a 429.
 */
export def const DEFAULT_RETRIES as int init 2;

/**
 * Base delay of a fresh client before a retry, in milliseconds.
 */
export def const DEFAULT_BACKOFF_MS as int init 500;

/**
 * Largest response body the client reads, in bytes (16 MiB).
 *
 * TMDB replies are kilobytes; `/movie/{id}/watch/providers` for a popular
 * film is the only one that nears a megabyte. The cap stops an endpoint
 * from making the interpreter read an unbounded body into memory.
 */
export def const MAX_RESPONSE_BYTES as int init 16777216;

/**
 * The `language` a fresh client sends.
 *
 * An ISO 639-1 code, optionally `-` and an ISO 3166-1 region (`en-US`,
 * `de-DE`, `pt-BR`). It decides translated titles, overviews, genre names
 * and which localized artwork comes first.
 */
export def const DEFAULT_LANGUAGE as string init "en-US";

/**
 * Highest page number TMDB serves.
 *
 * Every paginated endpoint stops at page 500 whatever `total_pages` says;
 * the server answers page 501 with a 400, and this deck refuses it before
 * sending. Narrow the query instead, with `discover`.
 */
export def const MAX_PAGE as int init 500;

/**
 * The kind of a row in a mixed result set.
 *
 * Multi-search, trending, find and list replies mix films, series and
 * people in one array, told apart by a `media_type` string; this is that
 * string as a value to `match` on. `Show` is `"tv"` on the wire. `Unknown`
 * covers "" and any `media_type` TMDB adds later.
 *
 * @example
 *   match ($item.kind) {
 *       when Movie { io.printf("film: %s\n", $item.title); }
 *       when Show { io.printf("series: %s\n", $item.title); }
 *       else { }
 *   }
 */
export def enum MediaKind {
    Movie,
    Show,
    Person,
    Episode,
    Season,
    Unknown
};

/**
 * A configured TMDB caller.
 *
 * A plain value: no socket, no mutable state. Every builder
 * (`withLanguage`, `withRegion`, `withUserToken`, `setVerbose` ...)
 * returns a copy to keep: `$c = tmdb.setVerbose($c, true);`.
 *
 * - `token` is the API Read Access Token from the TMDB account settings,
 *   a bearer JWT accepted by v3 and v4. Use this one.
 * - `apiKey` is the legacy v3 key, sent as an `api_key` query parameter.
 *   It reaches v3 only; a v4 verb refuses it locally instead of sending a
 *   request that would come back 401. It is sent only when no bearer
 *   token is set.
 * - `userToken` is minted by the approval flow in `auth` and stands for a
 *   person. Once set it replaces `token` on every request, because it
 *   carries both the read and the write scope.
 *
 * @field token {string} the API read access token, "" when unset
 * @field apiKey {string} the legacy v3 API key, "" when unset
 * @field userToken {string} a v4 user access token, "" when unset
 * @field language {string} the `language` parameter, e.g. "en-US"
 * @field region {string} two-letter release region, e.g. "US"; "" to omit
 * @field includeAdult {bool} whether search and discovery return adult titles
 * @field timeoutMs {int} per-request idle timeout in milliseconds
 * @field retries {int} retry budget for a 429 / 5xx
 * @field backoffMs {int} base delay between retries, in milliseconds
 * @field verbose {bool} print each request, credentials redacted
 */
export def struct Client {
    token as string,
    apiKey as string,
    userToken as string,
    language as string,
    region as string,
    includeAdult as bool,
    timeoutMs as int,
    retries as int,
    backoffMs as int,
    verbose as bool
};

/**
 * Build a client around a TMDB API read access token.
 *
 * The token is the long `eyJ...` string labelled API Read Access Token
 * under Settings -> API at <https://www.themoviedb.org/settings/api>, not
 * the 32-character API key. It authenticates v3 and v4. Surrounding
 * whitespace is trimmed.
 *
 * @param readAccessToken {string} the API read access token
 * @return {Client} a client with `en-US` defaults and no user token
 * @throws {Error} kind "tmdb" when the token is blank
 * @example
 *   def c as tmdb.Client init tmdb.client("eyJhbGciOiJIUzI1NiJ9...");
 */
export func client(readAccessToken as string) {
    def token as string init ensureText($readAccessToken, "read access token");
    def c as Client init blankClient();
    $c.token = $token;
    return $c;
}

/**
 * Build a v3-only client around the legacy API key.
 *
 * The 32-character key is sent as an `api_key` query parameter. Every
 * `/3` endpoint works; every v4 verb (`auth`, `account`, the custom lists)
 * refuses locally, because v4 accepts only a bearer token. Prefer `client`.
 *
 * @param apiKey {string} the 32-character v3 key
 * @return {Client} a v3-only client
 * @throws {Error} kind "tmdb" when the key is blank
 */
export func clientFromApiKey(apiKey as string) {
    def key as string init ensureText($apiKey, "API key");
    def c as Client init blankClient();
    $c.apiKey = $key;
    return $c;
}

/**
 * Build a client from the TMDB_* environment variables.
 *
 * Reads `TMDB_ACCESS_TOKEN`, falling back to `TMDB_API_KEY`, then applies
 * `TMDB_USER_TOKEN`, `TMDB_LANGUAGE` and `TMDB_REGION` when they are set.
 * `TMDB_VERBOSE` set to `1`, `true`, `yes` or `on` (any case) turns on
 * verbose mode. Every value is trimmed; a blank one counts as unset.
 *
 * @return {Client} a client configured from the environment
 * @throws {Error} kind "tmdb" when neither token nor key is set, or when
 *                 `TMDB_LANGUAGE` or `TMDB_REGION` is malformed
 * @example
 *   # TMDB_ACCESS_TOKEN=eyJ... jennifer run app.j
 *   def c as tmdb.Client init tmdb.clientFromEnv();
 */
export func clientFromEnv() {
    def token as string init strings.trim(os.getEnv("TMDB_ACCESS_TOKEN"));
    def key as string init strings.trim(os.getEnv("TMDB_API_KEY"));
    if ($token == "" and $key == "") {
        raiseError("no credentials in the environment - set TMDB_ACCESS_TOKEN " +
            "(the API read access token from " +
            "https://www.themoviedb.org/settings/api) or TMDB_API_KEY");
    }
    def c as Client init blankClient();
    if ($token != "") {
        $c.token = $token;
    } else {
        $c.apiKey = $key;
    }
    def user as string init strings.trim(os.getEnv("TMDB_USER_TOKEN"));
    if ($user != "") {
        $c = withUserToken($c, $user);
    }
    def lang as string init strings.trim(os.getEnv("TMDB_LANGUAGE"));
    if ($lang != "") {
        $c = withLanguage($c, $lang);
    }
    def region as string init strings.trim(os.getEnv("TMDB_REGION"));
    if ($region != "") {
        $c = withRegion($c, $region);
    }
    $c.verbose = verboseFromEnv();
    return $c;
}

/**
 * A copy of the client that asks for another language.
 *
 * Decides translated titles, overviews, taglines, genre names and which
 * localized artwork comes first. A bare language (`"de"`) is accepted; a
 * pair (`"de-DE"`) also picks regional spelling.
 *
 * @param c {Client} the client to copy
 * @param language {string} two or three letters, optionally `-` and a region
 * @return {Client} the copy
 * @throws {Error} kind "tmdb" when the tag is blank or not `xx`, `xxx`,
 *                 `xx-YY` or `xxx-YY`
 */
export func withLanguage(c as Client, language as string) {
    def tag as string init ensureText($language, "language");
    if (not isLanguageTag($tag)) {
        raiseError("the language must look like \"en\" or \"en-US\", got \"" + $tag + "\"");
    }
    def next as Client init $c;
    $next.language = $tag;
    return $next;
}

/**
 * A copy of the client pinned to a release region.
 *
 * The region picks the "primary" release dates, certifications and watch
 * providers, so `nowPlaying` answers with what is in cinemas there rather
 * than in the United States. The code is trimmed and upper-cased.
 *
 * @param c {Client} the client to copy
 * @param region {string} a two-letter ISO 3166-1 code, e.g. "DE"; "" to unset
 * @return {Client} the copy
 * @throws {Error} kind "tmdb" when the code is neither empty nor two letters
 */
export func withRegion(c as Client, region as string) {
    def code as string init strings.upper(strings.trim($region));
    if ($code != "" and not isCountryCode($code)) {
        raiseError("the region must be a two-letter country code, got \"" + $code + "\"");
    }
    def next as Client init $c;
    $next.region = $code;
    return $next;
}

/**
 * A copy of the client acting for a signed-in user.
 *
 * Takes the token the approval flow in `auth` mints. Once set it replaces
 * the application token on every request, which the v4 account and list
 * verbs need.
 *
 * @param c {Client} the client to copy
 * @param userToken {string} a v4 user access token, or "" to drop it
 * @return {Client} the copy
 * @example
 *   def granted as tmdb.AccessToken init tmdb.accessToken($c, $approved);
 *   $c = tmdb.withUserToken($c, $granted.accessToken);
 */
export func withUserToken(c as Client, userToken as string) {
    def next as Client init $c;
    $next.userToken = strings.trim($userToken);
    return $next;
}

/**
 * A copy of the client that includes or excludes adult titles.
 *
 * Off by default. It sets the `include_adult` flag search and discovery
 * send; nothing else is affected.
 *
 * @param c {Client} the client to copy
 * @param enabled {bool} true to include adult titles
 * @return {Client} the copy
 */
export func withAdult(c as Client, enabled as bool) {
    def next as Client init $c;
    $next.includeAdult = $enabled;
    return $next;
}

/**
 * A copy of the client with another per-request idle timeout.
 *
 * @param c {Client} the client to copy
 * @param timeoutMs {int} idle timeout in milliseconds; 0 restores the default
 * @return {Client} the copy
 * @throws {Error} kind "tmdb" when the timeout is negative
 */
export func withTimeout(c as Client, timeoutMs as int) {
    if ($timeoutMs < 0) {
        raiseError("the timeout must not be negative");
    }
    def next as Client init $c;
    if ($timeoutMs == 0) {
        $next.timeoutMs = DEFAULT_TIMEOUT_MS;
    } else {
        $next.timeoutMs = $timeoutMs;
    }
    return $next;
}

/**
 * A copy of the client with another retry budget for a 429 or 5xx.
 *
 * @param c {Client} the client to copy
 * @param retries {int} retries per request, 0 to disable
 * @return {Client} the copy
 * @throws {Error} kind "tmdb" when the budget is negative
 */
export func withRetries(c as Client, retries as int) {
    if ($retries < 0) {
        raiseError("the retry budget must not be negative");
    }
    def next as Client init $c;
    $next.retries = $retries;
    return $next;
}

/**
 * A copy of the client with another base delay between retries.
 *
 * Raise it for a job that walks hundreds of pages: TMDB throttles per
 * address.
 *
 * @param c {Client} the client to copy
 * @param backoffMs {int} base delay in milliseconds; 0 restores the default
 * @return {Client} the copy
 * @throws {Error} kind "tmdb" when the delay is negative
 * @example
 *   $c = tmdb.withBackoff(tmdb.withRetries($c, 5), 2000);
 */
export func withBackoff(c as Client, backoffMs as int) {
    if ($backoffMs < 0) {
        raiseError("the retry backoff must not be negative");
    }
    def next as Client init $c;
    if ($backoffMs == 0) {
        $next.backoffMs = DEFAULT_BACKOFF_MS;
    } else {
        $next.backoffMs = $backoffMs;
    }
    return $next;
}

/**
 * A copy of the client that prints every request it makes.
 *
 * Each request prints one `tmdb> METHOD URL?query` line to stdout. The
 * bearer token rides in a header the line does not show, the `api_key`,
 * `access_token`, `request_token` and `session_id` parameters print as
 * `<redacted>`, and request bodies are never printed, so a transcript is
 * safe to paste into a bug report. `clientFromEnv` reads the initial
 * value from `TMDB_VERBOSE`.
 *
 * @param c {Client} the client to copy
 * @param enabled {bool} true to print requests
 * @return {Client} the copy
 */
export func setVerbose(c as Client, enabled as bool) {
    def next as Client init $c;
    $next.verbose = $enabled;
    return $next;
}

/**
 * Whether the client prints its requests.
 *
 * @param c {Client} the client to inspect
 * @return {bool} the verbose flag
 */
export func isVerbose(c as Client) {
    return $c.verbose;
}

/**
 * Whether the client can reach the v4 endpoints.
 *
 * True with an application read access token or a user access token;
 * false for a client built from a legacy v3 API key.
 *
 * @param c {Client} the client to inspect
 * @return {bool} true when a bearer token is set
 */
export func hasBearer(c as Client) {
    return activeToken($c) != "";
}

/**
 * Whether the client acts for a signed-in user.
 *
 * @param c {Client} the client to inspect
 * @return {bool} true when a user access token is set
 */
export func hasUser(c as Client) {
    return $c.userToken != "";
}

/**
 * GET any TMDB path and return the decoded body.
 *
 * For endpoints or fields this deck has no typed verb for. The credential
 * is applied as for every verb. `path` is everything after the host and
 * must start with one slash; it may not contain `..`, `?`, `#` or
 * whitespace, so query parameters go in `params`.
 *
 * @param c {Client} an API client
 * @param path {string} the request path, e.g. "/3/movie/550/lists"
 * @param params {map of string to string} query parameters, {} for none
 * @return {json.Value} the decoded response body
 * @throws {Error} kind "tmdb" on a bad path, a transport failure, a non-2xx
 *                 status, or a body that is not JSON
 * @example
 *   def v as json.Value init tmdb.call($c, "/3/movie/550/lists", {"page": "1"});
 *   io.printf("in %d lists\n", json.asInt($v, "/total_results"));
 */
export func call(c as Client, path as string, params as map of string to string) {
    return apiGet($c, ensurePath($path), $params);
}

/**
 * POST a JSON body to any TMDB path and return the decoded reply.
 *
 * The path rules are those of `call`.
 *
 * @param c {Client} an API client
 * @param path {string} the request path, e.g. "/4/list"
 * @param body {json.Value} the request body
 * @return {json.Value} the decoded response body
 * @throws {Error} kind "tmdb" on a bad path, a transport failure, a non-2xx
 *                 status, or a body that is not JSON
 */
export func callPost(c as Client, path as string, body as json.Value) {
    return apiPost($c, ensurePath($path), $body);
}

/**
 * PUT a JSON body to any TMDB path and return the decoded reply.
 *
 * The path rules are those of `call`.
 *
 * @param c {Client} an API client
 * @param path {string} the request path, e.g. "/4/list/7"
 * @param body {json.Value} the request body
 * @return {json.Value} the decoded response body
 * @throws {Error} kind "tmdb" on a bad path, a transport failure, a non-2xx
 *                 status, or a body that is not JSON
 */
export func callPut(c as Client, path as string, body as json.Value) {
    return apiPut($c, ensurePath($path), $body);
}

/**
 * DELETE any TMDB path with a JSON body and return the decoded reply.
 *
 * TMDB's v4 removals (list items, logout) carry a body on `DELETE`. Pass
 * `json.map()` for none. The path rules are those of `call`.
 *
 * @param c {Client} an API client
 * @param path {string} the request path, e.g. "/4/list/7/items"
 * @param body {json.Value} the request body, `json.map()` for none
 * @return {json.Value} the decoded response body
 * @throws {Error} kind "tmdb" on a bad path, a transport failure, a non-2xx
 *                 status, or a body that is not JSON
 */
export func callDelete(c as Client, path as string, body as json.Value) {
    return apiDelete($c, ensurePath($path), $body);
}

/**
 * The `media_type` string TMDB writes for a media kind.
 *
 * The inverse of `parseMediaKind`: `Show` is `"tv"`, `Episode` is
 * `"tv_episode"`, `Season` is `"tv_season"`.
 *
 * @param kind {MediaKind} the kind to name
 * @return {string} TMDB's `media_type` string, "" for `Unknown`
 */
export func mediaKindName(kind as MediaKind) {
    match ($kind) {
        when Movie { return "movie"; }
        when Show { return "tv"; }
        when Person { return "person"; }
        when Episode { return "tv_episode"; }
        when Season { return "tv_season"; }
        when Unknown { return ""; }
    }
    return "";
}

/**
 * Read a TMDB `media_type` string as a media kind.
 *
 * Case and surrounding whitespace are ignored. Anything unrecognized,
 * "" included, reads as `Unknown` rather than throwing, so a new value
 * from the server does not abort a page fold.
 *
 * @param name {string} a `media_type` string, e.g. "tv"
 * @return {MediaKind} the matching kind, or `Unknown`
 */
export func parseMediaKind(name as string) {
    match (strings.lower(strings.trim($name))) {
        when "movie" { return MediaKind.Movie; }
        when "tv" { return MediaKind.Show; }
        when "person" { return MediaKind.Person; }
        when "tv_episode" { return MediaKind.Episode; }
        when "tv_season" { return MediaKind.Season; }
        else { return MediaKind.Unknown; }
    }
    return MediaKind.Unknown;
}

/**
 * The year of a TMDB `YYYY-MM-DD` date, or "" when there is none.
 *
 * TMDB writes "" for an unknown date; this returns "" for that, or for
 * anything whose first four characters are not digits, instead of
 * throwing.
 *
 * @param date {string} a TMDB date, e.g. "1999-10-15"
 * @return {string} the four-digit year, or ""
 * @example
 *   io.printf("%s (%s)\n", $m.title, tmdb.year($m.releaseDate));
 */
export func year(date as string) {
    def text as string init strings.trim($date);
    if (len($text) < 4) {
        return "";
    }
    def head as string init strings.substring($text, 0, 4);
    if (not isDigits($head)) {
        return "";
    }
    return $head;
}

/**
 * A client with the defaults and no credentials.
 *
 * @return {Client} the zero client, defaults filled in
 * @internal
 */
func blankClient() {
    return Client{
        token: "",
        apiKey: "",
        userToken: "",
        language: DEFAULT_LANGUAGE,
        region: "",
        includeAdult: false,
        timeoutMs: DEFAULT_TIMEOUT_MS,
        retries: DEFAULT_RETRIES,
        backoffMs: DEFAULT_BACKOFF_MS,
        verbose: false
    };
}

/**
 * Throw the deck's error.
 *
 * @param message {string} the failure, as a sentence
 * @throws {Error} kind "tmdb" always
 * @internal
 */
func raiseError(message as string) {
    throw Error{kind: "tmdb", message: $message, file: "", line: 0, col: 0};
}

/**
 * Read `TMDB_VERBOSE` as a flag.
 *
 * @return {bool} true for "1", "true", "yes" or "on", in any case
 * @internal
 */
func verboseFromEnv() {
    def raw as string init strings.lower(strings.trim(os.getEnv("TMDB_VERBOSE")));
    return $raw == "1" or $raw == "true" or $raw == "yes" or $raw == "on";
}

/**
 * The bearer token a request carries.
 *
 * A user access token wins over the application one: it carries both
 * scopes.
 *
 * @param c {Client} the client
 * @return {string} the token, or "" when the client has none
 * @internal
 */
func activeToken(c as Client) {
    if ($c.userToken != "") {
        return $c.userToken;
    }
    return $c.token;
}

/**
 * The headers every request carries.
 *
 * @param c {Client} the client
 * @return {map of string to string} the request headers
 * @internal
 */
func requestHeaders(c as Client) {
    def headers as map of string to string init {"Accept": "application/json"};
    def token as string init activeToken($c);
    if ($token != "") {
        $headers["Authorization"] = "Bearer " + $token;
    }
    return $headers;
}

/**
 * The transport policy a request runs under.
 *
 * @param c {Client} the client
 * @return {http.Options} timeout, body cap, 3 redirects and retry budget
 * @internal
 */
func requestPolicy(c as Client) {
    def policy as http.Options init http.defaultOptions();
    $policy.timeoutMs = $c.timeoutMs;
    $policy.maxRetries = $c.retries;
    $policy.backoffMs = $c.backoffMs;
    $policy.maxRedirects = 3;
    $policy.maxBytes = MAX_RESPONSE_BYTES;
    return $policy;
}

/**
 * The REST client used for one request.
 *
 * @param c {Client} the client carrying the credential and the policy
 * @return {rest.Client} a configured REST client
 * @internal
 */
func restClient(c as Client) {
    def r as rest.Client init rest.client(API_BASE);
    $r.headers = requestHeaders($c);
    $r.options = requestPolicy($c);
    return $r;
}

/**
 * Copy a parameter map, adding `api_key` for a key-only client.
 *
 * A bearer credential rides in a header, so with one the caller's query
 * is returned unchanged.
 *
 * @param c {Client} the client
 * @param params {map of string to string} the caller's parameters
 * @return {map of string to string} the parameters actually sent
 * @internal
 */
func withCredential(c as Client, params as map of string to string) {
    def merged as map of string to string init $params;
    if ($c.apiKey != "" and $c.userToken == "" and $c.token == "") {
        $merged["api_key"] = $c.apiKey;
    }
    return $merged;
}

/**
 * Whether a parameter carries a credential and must never be printed.
 *
 * @param name {string} the parameter name
 * @return {bool} true for `api_key`, `access_token`, `request_token` and
 *                `session_id`
 * @internal
 */
func isSecret(name as string) {
    return $name == "api_key" or $name == "access_token" or $name == "request_token" or
        $name == "session_id";
}

/**
 * Render a request for the verbose transcript.
 *
 * @param verb {string} the HTTP method
 * @param url {string} the full URL without a query string
 * @param params {map of string to string} the parameters, secrets included
 * @return {string} one printable line, secrets redacted
 * @internal
 */
func requestLine(verb as string, url as string, params as map of string to string) {
    def parts as list of string init [];
    for (def name in $params) {
        if (isSecret($name)) {
            $parts[] = $name + "=<redacted>";
        } else {
            $parts[] = $name + "=" + uri.encodeForm($params[$name]);
        }
    }
    if (len($parts) == 0) {
        return $verb + " " + $url;
    }
    return $verb + " " + $url + "?" + strings.join($parts, "&");
}

/**
 * Print a request when the client is verbose.
 *
 * @param c {Client} the client
 * @param verb {string} the HTTP method
 * @param url {string} the full URL without a query string
 * @param params {map of string to string} the parameters
 * @internal
 */
func logRequest(c as Client, verb as string, url as string, params as map of string to string) {
    if (not $c.verbose) {
        return;
    }
    def line as string init requestLine($verb, $url, $params);
    io.printf("tmdb> %s\n", $line);
}

/**
 * GET a path and decode the reply.
 *
 * @param c {Client} the client
 * @param path {string} an already-validated path
 * @param params {map of string to string} query parameters
 * @return {json.Value} the decoded body
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 * @internal
 */
func apiGet(c as Client, path as string, params as map of string to string) {
    def query as map of string to string init withCredential($c, $params);
    def url as string init API_BASE + $path;
    logRequest($c, "GET", $url, $query);
    def reply as rest.Response init runGet(restClient($c), $path, $query, $url);
    return decodeChecked($reply, "GET " + $url);
}

/**
 * POST a JSON body and decode the reply.
 *
 * @param c {Client} the client
 * @param path {string} an already-validated path
 * @param body {json.Value} the request body
 * @return {json.Value} the decoded body
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 * @internal
 */
func apiPost(c as Client, path as string, body as json.Value) {
    def url as string init API_BASE + $path;
    def query as map of string to string init withCredential($c, {});
    logRequest($c, "POST", $url, $query);
    def reply as rest.Response init runBody($c, "POST", $path, $query, $body, "POST " + $url);
    return decodeChecked($reply, "POST " + $url);
}

/**
 * PUT a JSON body and decode the reply.
 *
 * @param c {Client} the client
 * @param path {string} an already-validated path
 * @param body {json.Value} the request body
 * @return {json.Value} the decoded body
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 * @internal
 */
func apiPut(c as Client, path as string, body as json.Value) {
    def url as string init API_BASE + $path;
    def query as map of string to string init withCredential($c, {});
    logRequest($c, "PUT", $url, $query);
    def reply as rest.Response init runBody($c, "PUT", $path, $query, $body, "PUT " + $url);
    return decodeChecked($reply, "PUT " + $url);
}

/**
 * DELETE with a JSON body and decode the reply.
 *
 * @param c {Client} the client
 * @param path {string} an already-validated path
 * @param body {json.Value} the request body
 * @return {json.Value} the decoded body
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 * @internal
 */
func apiDelete(c as Client, path as string, body as json.Value) {
    def url as string init API_BASE + $path;
    def query as map of string to string init withCredential($c, {});
    logRequest($c, "DELETE", $url, $query);
    def reply as rest.Response init runBody($c, "DELETE", $path, $query, $body, "DELETE " + $url);
    return decodeChecked($reply, "DELETE " + $url);
}

/**
 * Run a GET, translating any transport error into the deck's own.
 *
 * @param r {rest.Client} the configured REST client
 * @param path {string} the request path
 * @param query {map of string to string} query parameters
 * @param url {string} the full URL, for the error message
 * @return {rest.Response} the raw response, whatever its status
 * @throws {Error} kind "tmdb" wrapping a transport failure
 * @internal
 */
func runGet(r as rest.Client, path as string, query as map of string to string, url as string) {
    try {
        return rest.get($r, $path, $query);
    } catch (e) {
        raiseError("GET " + $url + " failed: " + $e.message);
    }
    return rest.Response{status: 0, headers: {}, body: ""};
}

/**
 * Run a request that carries a body, translating a transport error.
 *
 * Uses `http.send` rather than a `rest` verb because TMDB's v4 removals
 * put a JSON body on a `DELETE`, which `rest.delete` cannot send. All
 * three body verbs take this one path.
 *
 * @param c {Client} the client
 * @param method {string} the HTTP method
 * @param path {string} the request path
 * @param query {map of string to string} query parameters
 * @param body {json.Value} the request body
 * @param what {string} the method and URL, for the error message
 * @return {rest.Response} the raw response, whatever its status
 * @throws {Error} kind "tmdb" wrapping a transport failure
 * @internal
 */
func runBody(
    c as Client,
    method as string,
    path as string,
    query as map of string to string,
    body as json.Value,
    what as string) {
    def url as string init API_BASE + $path + queryString($query);
    def headers as map of string to string init requestHeaders($c);
    $headers["Content-Type"] = "application/json;charset=utf-8";
    try {
        def r as http.Response init http.send(
            $method,
            $url,
            $headers,
            json.encode($body),
            requestPolicy($c));
        return rest.Response{status: $r.status, headers: $r.headers, body: $r.body};
    } catch (e) {
        raiseError($what + " failed: " + $e.message);
    }
    return rest.Response{status: 0, headers: {}, body: ""};
}

/**
 * Render a query string, empty map included.
 *
 * @param params {map of string to string} the parameters
 * @return {string} "?k=v&..." or "" when there is nothing to send
 * @internal
 */
func queryString(params as map of string to string) {
    if (len($params) == 0) {
        return "";
    }
    return "?" + uri.buildQuery($params);
}

/**
 * Decode a reply, refusing a non-2xx status first.
 *
 * TMDB explains a refusal in the body (`status_message`), so the error
 * carries that sentence: "Invalid API key: You must be granted a valid
 * key." rather than "HTTP 401".
 *
 * @param reply {rest.Response} the raw response
 * @param what {string} the method and URL, for the error message
 * @return {json.Value} the decoded body
 * @throws {Error} kind "tmdb" on a non-2xx status or a body that is not JSON
 * @internal
 */
func decodeChecked(reply as rest.Response, what as string) {
    if ($reply.status < 200 or $reply.status >= 300) {
        raiseError($what + " failed: " + failureText($reply));
    }
    return decodeBody($reply.body, $what);
}

/**
 * Explain a refusal, preferring TMDB's own sentence.
 *
 * @param reply {rest.Response} the unhappy response
 * @return {string} the reason, always naming the status code
 * @internal
 */
func failureText(reply as rest.Response) {
    def status as string init "HTTP " + convert.toString($reply.status);
    def said as string init statusMessage($reply.body);
    if ($said != "") {
        return $status + ": " + $said;
    }
    return $status + ": " + statusHint($reply.status);
}

/**
 * The `status_message` out of an error body, "" when there is none.
 *
 * @param body {string} the raw response body
 * @return {string} TMDB's own explanation, or ""
 * @internal
 */
func statusMessage(body as string) {
    try {
        def doc as json.Value init json.decode($body);
        if (json.has($doc, "/status_message")) {
            return json.asString($doc, "/status_message");
        }
        return "";
    } catch (e) {
        return "";
    }
}

/**
 * The usual TMDB cause of an HTTP status, for a body with no message.
 *
 * @param status {int} the HTTP status code
 * @return {string} a sentence naming the usual cause
 * @internal
 */
func statusHint(status as int) {
    match ($status) {
        when 401 { return "the token or API key is missing, wrong, or lacks the scope"; }
        when 403 { return "the credential is valid but not allowed to do this"; }
        when 404 { return "no such resource"; }
        when 422 { return "TMDB rejected the request body"; }
        when 429 { return "the credential is being rate limited"; }
        when 500, 502, 503, 504 { return "TMDB is having trouble; retry later"; }
        else { return "unexpected status"; }
    }
    return "unexpected status";
}

/**
 * Decode a response body, naming the request when it is not JSON.
 *
 * @param body {string} the raw response body
 * @param what {string} the method and URL, for the error message
 * @return {json.Value} the decoded document
 * @throws {Error} kind "tmdb" when the body is not JSON
 * @internal
 */
func decodeBody(body as string, what as string) {
    try {
        return json.decode($body);
    } catch (e) {
        raiseError($what + " did not answer JSON: " + $e.message);
    }
    return json.map();
}

/**
 * Refuse a client that cannot reach v4.
 *
 * @param c {Client} the client to check
 * @param what {string} the operation that needs a bearer token
 * @throws {Error} kind "tmdb" when only a legacy API key is configured
 * @internal
 */
func requireBearer(c as Client, what as string) {
    if (activeToken($c) != "") {
        return;
    }
    raiseError($what + " is a v4 endpoint and needs an API read access token - " +
        "the legacy api_key parameter only works on v3. Get the token under " +
        "Settings -> API at https://www.themoviedb.org/settings/api");
}

/**
 * Refuse a client that is not acting for a signed-in user.
 *
 * @param c {Client} the client to check
 * @param what {string} the operation that needs a user token
 * @throws {Error} kind "tmdb" when no user access token is set
 * @internal
 */
func requireUser(c as Client, what as string) {
    requireBearer($c, $what);
    if ($c.userToken == "") {
        raiseError($what + " acts on behalf of a person, so it needs a user access " +
            "token - run the approval flow (requestToken / approvalUrl / accessToken) " +
            "and apply the result with withUserToken");
    }
}

/**
 * Refuse a blank string, trimming it otherwise.
 *
 * @param value {string} the value to check
 * @param what {string} what it is, for the message
 * @return {string} the trimmed value
 * @throws {Error} kind "tmdb" when the value is blank
 * @internal
 */
func ensureText(value as string, what as string) {
    def trimmed as string init strings.trim($value);
    if ($trimmed == "") {
        raiseError("the " + $what + " must not be empty");
    }
    return $trimmed;
}

/**
 * Refuse anything that is not a plausible TMDB object id.
 *
 * @param id {int} the id to check
 * @param what {string} what it identifies, for the message
 * @return {int} the same id
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func ensureId(id as int, what as string) {
    if ($id <= 0) {
        raiseError("the " + $what + " id must be positive, got " + convert.toString($id));
    }
    return $id;
}

/**
 * Refuse a page number TMDB will not serve.
 *
 * Pages start at 1 and stop at `MAX_PAGE`; asking for 0 or 501 is a 400
 * from the server, so it is caught here where the message can say why.
 *
 * @param page {int} the requested page
 * @return {int} the same page
 * @throws {Error} kind "tmdb" when the page is outside 1..MAX_PAGE
 * @internal
 */
func ensurePage(page as int) {
    if ($page < 1) {
        raiseError("the page must be 1 or more, got " + convert.toString($page));
    }
    if ($page > MAX_PAGE) {
        raiseError("TMDB serves at most " + convert.toString(MAX_PAGE) +
            " pages of any result set, got " + convert.toString($page) +
            " - narrow the query instead");
    }
    return $page;
}

/**
 * Refuse a negative season or episode number.
 *
 * Season 0 is real (TMDB files specials there), so the floor is 0, not 1
 * as in `ensureId`.
 *
 * @param number {int} the season or episode number
 * @param what {string} what it numbers, for the message
 * @return {int} the same number
 * @throws {Error} kind "tmdb" when the number is negative
 * @internal
 */
func ensureNumber(number as int, what as string) {
    if ($number < 0) {
        raiseError("the " + $what + " number must not be negative, got " +
            convert.toString($number));
    }
    return $number;
}

/**
 * Refuse a path that is not a safe TMDB request path.
 *
 * The caller's path lands in the URL verbatim, so a path without a
 * leading slash, starting `//`, or holding `..`, `?`, `#` or whitespace
 * could reshape the request or send the credential to another host.
 *
 * @param path {string} the candidate path
 * @return {string} the trimmed path
 * @throws {Error} kind "tmdb" when the path is blank or unsafe
 * @internal
 */
func ensurePath(path as string) {
    def value as string init ensureText($path, "path");
    if (not strings.startsWith($value, "/")) {
        raiseError("the path must start with a slash, got \"" + $value + "\"");
    }
    if (strings.startsWith($value, "//")) {
        raiseError("the path must not start with two slashes, got \"" + $value + "\"");
    }
    for (def bad in ["..", "?", "#", " ", "\t", "\n", "\r"]) {
        if (strings.contains($value, $bad)) {
            raiseError("the path must not contain \"" + $bad + "\", got \"" + $value +
                "\" - put query parameters in the params map");
        }
    }
    return $value;
}

/**
 * Whether a string is a two-letter country code.
 *
 * @param code {string} the candidate
 * @return {bool} true for exactly two ASCII letters
 * @internal
 */
func isCountryCode(code as string) {
    if (len($code) != 2) {
        return false;
    }
    for (def ch in strings.chars($code)) {
        if (not isLetter($ch)) {
            return false;
        }
    }
    return true;
}

/**
 * Whether a string is a language tag `xx`, `xxx`, `xx-YY` or `xxx-YY`.
 *
 * @param tag {string} the candidate
 * @return {bool} true for two or three letters, optionally dash a region
 * @internal
 */
func isLanguageTag(tag as string) {
    def parts as list of string init strings.split($tag, "-");
    if (len($parts) > 2) {
        return false;
    }
    if (len($parts[0]) != 2 and len($parts[0]) != 3) {
        return false;
    }
    for (def ch in strings.chars($parts[0])) {
        if (not isLetter($ch)) {
            return false;
        }
    }
    if (len($parts) == 1) {
        return true;
    }
    return isCountryCode($parts[1]);
}

/**
 * Whether one code point is an ASCII letter.
 *
 * @param ch {string} a single code point
 * @return {bool} true for a-z and A-Z
 * @internal
 */
func isLetter(ch as string) {
    return ($ch >= "a" and $ch <= "z") or ($ch >= "A" and $ch <= "Z");
}

/**
 * Whether a string is one or more ASCII digits and nothing else.
 *
 * @param text {string} the candidate
 * @return {bool} true when every code point is 0-9 and there is at least one
 * @internal
 */
func isDigits(text as string) {
    if (len($text) == 0) {
        return false;
    }
    for (def ch in strings.chars($text)) {
        if ($ch < "0" or $ch > "9") {
            return false;
        }
    }
    return true;
}

/**
 * The `language` parameter, when the client has one.
 *
 * @param c {Client} the client
 * @return {map of string to string} `{"language": ...}`, or {} when unset
 * @internal
 */
func localeParams(c as Client) {
    def params as map of string to string init {};
    if ($c.language != "") {
        $params["language"] = $c.language;
    }
    return $params;
}

/**
 * The `language` and `page` parameters.
 *
 * @param c {Client} the client
 * @param page {int} the page to ask for
 * @return {map of string to string} the parameters
 * @throws {Error} kind "tmdb" when the page is outside 1..MAX_PAGE
 * @internal
 */
func pageParams(c as Client, page as int) {
    def params as map of string to string init localeParams($c);
    $params["page"] = convert.toString(ensurePage($page));
    return $params;
}

/**
 * The `language`, `page` and `region` parameters.
 *
 * @param c {Client} the client
 * @param page {int} the page to ask for
 * @return {map of string to string} the parameters
 * @throws {Error} kind "tmdb" when the page is outside 1..MAX_PAGE
 * @internal
 */
func regionParams(c as Client, page as int) {
    def params as map of string to string init pageParams($c, $page);
    if ($c.region != "") {
        $params["region"] = $c.region;
    }
    return $params;
}

/**
 * Render a bool as the "true" / "false" TMDB expects in a query.
 *
 * @param value {bool} the flag
 * @return {string} "true" or "false"
 * @internal
 */
func boolParam(value as bool) {
    if ($value) {
        return "true";
    }
    return "false";
}

/**
 * Read a string out of a JSON document, defaulting to "".
 *
 * TMDB writes an absent value as `null` more often than it omits the key,
 * and mixes number and string ids, so a number or bool is stringified.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {string} the value, or "" when absent or null
 * @internal
 */
func nodeString(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return "";
    }
    match (json.typeOf($v, $ptr)) {
        when "string" { return json.asString($v, $ptr); }
        when "int" { return convert.toString(json.asInt($v, $ptr)); }
        when "float" { return convert.toString(json.asFloat($v, $ptr)); }
        when "bool" { return convert.toString(json.asBool($v, $ptr)); }
        else { return ""; }
    }
    return "";
}

/**
 * Read an int out of a JSON document, defaulting to 0.
 *
 * A float is truncated (0 when out of range), a bool reads 1 / 0, a
 * numeric string is parsed.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {int} the value, or 0 when absent or not numeric
 * @internal
 */
func nodeInt(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return 0;
    }
    match (json.typeOf($v, $ptr)) {
        when "int" { return json.asInt($v, $ptr); }
        when "float" { return floatToIntOrZero(json.asFloat($v, $ptr)); }
        when "bool" { return boolToInt(json.asBool($v, $ptr)); }
        when "string" { return parseIntOrZero(json.asString($v, $ptr)); }
        else { return 0; }
    }
    return 0;
}

/**
 * Read a float out of a JSON document, defaulting to 0.0.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {float} the value, or 0.0 when absent or not numeric
 * @internal
 */
func nodeFloat(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return 0.0;
    }
    match (json.typeOf($v, $ptr)) {
        when "float" { return json.asFloat($v, $ptr); }
        when "int" { return convert.toFloat(json.asInt($v, $ptr)); }
        when "string" { return parseFloatOrZero(json.asString($v, $ptr)); }
        else { return 0.0; }
    }
    return 0.0;
}

/**
 * Read a bool out of a JSON document, defaulting to false.
 *
 * The v4 list endpoints write flags as `1` / `0` where v3 writes `true` /
 * `false`; both read as a bool, as do the words `truthyWord` accepts.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {bool} the flag, or false when absent
 * @internal
 */
func nodeBool(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return false;
    }
    match (json.typeOf($v, $ptr)) {
        when "bool" { return json.asBool($v, $ptr); }
        when "int" { return json.asInt($v, $ptr) != 0; }
        when "float" { return json.asFloat($v, $ptr) != 0.0; }
        when "string" { return truthyWord(json.asString($v, $ptr)); }
        else { return false; }
    }
    return false;
}

/**
 * Length of a JSON list, 0 when the pointer names anything else.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {int} the element count, or 0
 * @internal
 */
func nodeLength(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return 0;
    }
    if (json.typeOf($v, $ptr) != "list") {
        return 0;
    }
    return json.length($v, $ptr);
}

/**
 * Address one element of a JSON list.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @param index {int} the element index
 * @return {json.Value} the element
 * @internal
 */
func nodeItem(v as json.Value, ptr as string, index as int) {
    return json.get($v, $ptr + "/" + convert.toString($index));
}

/**
 * A child pointer, so a fold can address a nested object once.
 *
 * @param ptr {string} the parent pointer
 * @param index {int} the element index
 * @return {string} the child pointer
 * @internal
 */
func itemPointer(ptr as string, index as int) {
    return $ptr + "/" + convert.toString($index);
}

/**
 * Read a JSON list of strings, defaulting to an empty list.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of string} the elements, stringified
 * @internal
 */
func nodeStringList(v as json.Value, ptr as string) {
    def out as list of string init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = nodeString($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Read a JSON list of ints, defaulting to an empty list.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of int} the elements
 * @internal
 */
func nodeIntList(v as json.Value, ptr as string) {
    def out as list of int init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = nodeInt($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Read one field out of every element of a JSON list.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @param field {string} the field to collect from each element
 * @return {list of string} the collected values
 * @internal
 */
func nodeFieldList(v as json.Value, ptr as string, field as string) {
    def out as list of string init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = nodeString($v, itemPointer($ptr, $i) + "/" + $field);
    }
    return $out;
}

/**
 * The keys of a JSON object, empty when the pointer names anything else.
 *
 * Country-keyed replies (`watch/providers`, the certification lists) keep
 * their data in the keys.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer into it
 * @return {list of string} the keys, in document order
 * @internal
 */
func nodeKeys(v as json.Value, ptr as string) {
    if (not json.has($v, $ptr)) {
        return [];
    }
    if (json.typeOf($v, $ptr) != "map") {
        return [];
    }
    return json.keys($v, $ptr);
}

/**
 * Escape one JSON Pointer token per RFC 6901.
 *
 * The keys come from the server (`CA-QC`, `movie:550`); a `~` or `/` in
 * one would otherwise address the wrong node.
 *
 * @param token {string} one pointer token
 * @return {string} the token with `~` and `/` escaped
 * @internal
 */
func pointerToken(token as string) {
    return strings.replace(strings.replace($token, "~", "~0"), "/", "~1");
}

/**
 * Narrow a float to an int, returning 0 instead of throwing.
 *
 * `convert.toInt` raises past the int64 range; one out-of-range field
 * would otherwise abort a whole struct fold.
 *
 * @param value {float} the number to narrow
 * @return {int} the truncated value, or 0 when it does not fit
 * @internal
 */
func floatToIntOrZero(value as float) {
    try {
        return convert.toInt($value);
    } catch (e) {
        return 0;
    }
    return 0;
}

/**
 * Parse an int, returning 0 instead of throwing.
 *
 * @param text {string} the text to parse
 * @return {int} the number, or 0 when it does not parse
 * @internal
 */
func parseIntOrZero(text as string) {
    try {
        return convert.toInt(strings.trim($text));
    } catch (e) {
        return 0;
    }
    return 0;
}

/**
 * Parse a float, returning 0.0 instead of throwing.
 *
 * @param text {string} the text to parse
 * @return {float} the number, or 0.0 when it does not parse
 * @internal
 */
func parseFloatOrZero(text as string) {
    try {
        return convert.toFloat(strings.trim($text));
    } catch (e) {
        return 0.0;
    }
    return 0.0;
}

/**
 * Whether a word is an affirmative.
 *
 * @param text {string} the word
 * @return {bool} true for "1", "true", "yes" and "on", in any case
 * @internal
 */
func truthyWord(text as string) {
    def word as string init strings.lower(strings.trim($text));
    return $word == "1" or $word == "true" or $word == "yes" or $word == "on";
}

/**
 * Map a bool onto 1 / 0.
 *
 * @param value {bool} the flag
 * @return {int} 1 when true, 0 when false
 * @internal
 */
func boolToInt(value as bool) {
    if ($value) {
        return 1;
    }
    return 0;
}
