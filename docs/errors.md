# Errors

Every failure the deck raises has one shape, so one `catch` covers a bad
argument, a transport failure and a refusal from the server:

```jennifer
Error{kind: "tmdb", message: "...", file: "", line: 0, col: 0}
```

```jennifer
try {
    def film as tmdb.Movie init tmdb.movie($c, 999999999);
    io.printf("%s\n", $film.title);
} catch (e) {
    io.printf("could not read the film: %s\n", $e.message);
}
```

## Sources

**Arguments**, checked before the request:

```
the movie id must be positive, got 0
TMDB serves at most 500 pages of any result set, got 501 - narrow the query instead
a date must look like YYYY-MM-DD, got "1990"
"w9999" is not a poster size - the configuration offers w92, w154, ..., original
withNetworks filters series, and this filter is being run against the film
catalogue - build a separate filter for discoverMovies
```

**The credential.** v4 verbs refuse a client with only a legacy API key;
account and list verbs refuse a client without a user token:

```
accountLists is a v4 endpoint and needs an API read access token - the legacy
api_key parameter only works on v3. Get the token under Settings -> API at
https://www.themoviedb.org/settings/api

accountLists acts on behalf of a person, so it needs a user access token - run
the approval flow (requestToken / approvalUrl / accessToken) and apply the
result with withUserToken
```

**TMDB.** A non-2xx status becomes an error with the method, URL, status and
TMDB's `status_message`:

```
GET https://api.themoviedb.org/3/movie/550 failed: HTTP 401: Invalid API key:
You must be granted a valid key.
```

When the body has no `status_message` (an HTML gateway page, an empty body)
the message gives a hint for the status instead:

| status | hint |
| --- | --- |
| 401 | the token or API key is missing, wrong, or lacks the scope |
| 403 | the credential is valid but not allowed to do this |
| 404 | no such resource |
| 422 | TMDB rejected the request body |
| 429 | the credential is being rate limited |
| 500, 502, 503, 504 | TMDB is having trouble; retry later |
| any other | unexpected status |

A 2xx reply that is not JSON throws with the method and URL and
`did not answer JSON`.

**Transport.** A timeout, DNS failure or TLS error is wrapped with the method
and URL:

```
GET https://api.themoviedb.org/3/movie/550 failed: read timed out
```

## Not errors

- An empty result: a search with no match is a page with empty `results`.
- A missing field: `null` or an absent key reads as `""`, `0`, `false` or
  `[]`.
- A failed item in a bulk list write: `addListItems` reports each item in
  `ItemsResponse.results`; a title already in the list fails as an item, not
  as a request.
- A 429 or 5xx the retry policy absorbed. The error appears only when the
  retry budget (default 2) is spent.

## Retries

Retries apply to `429` and `5xx`, with exponential backoff honouring a numeric
`Retry-After`; other statuses are not retried. The budget is per client:

```jennifer
$c = tmdb.withBackoff(tmdb.withRetries($c, 5), 2000);
```

## Debugging

`tmdb.setVerbose($c, true)` prints each request with credentials redacted
(see [Getting started](getting-started.md#verbose-mode)). To see the raw
reply, use the escape hatch:

```jennifer
def raw as json.Value init tmdb.call($c, "/3/movie/550", {"language": "de-DE"});
io.printf("%s\n", json.encodePretty($raw));
```
