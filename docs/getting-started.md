# Installing and importing

## Install

```sh
jvc add @deckyard/tmdb
```

This vendors the deck to `vendor/deckyard/tmdb/`. Without `jvc`, unpack the
`src/` subtree of a release archive (`deckyard-tmdb-<version>.tar.gz`) there.
Then import it:

```jennifer
import "@deckyard/tmdb/" as tmdb;
```

From a checkout, import the file directly:

```jennifer
import "./src/tmdb.j" as tmdb;
```

The entry module declares `# pragma-jennifer-capability: net`, so it needs
the default `jennifer` binary; `jennifer-tiny` refuses to load it rather than
failing at the first request.

## Get a token

[Settings -> API](https://www.themoviedb.org/settings/api) on a TMDB account
shows two credentials (the page does not work well on mobile; use a desktop
browser):

| TMDB calls it | looks like | reaches |
| --- | --- | --- |
| **API Read Access Token** | `eyJhbGciOiJIUzI1NiJ9.eyJhdWQ...` | v3 **and** v4 |
| API Key | `0123456789abcdef0123456789abcdef` | v3 only |

Use the read access token. Only it reaches the account and list endpoints.

## Build a client

```jennifer
def c as tmdb.Client init tmdb.client("eyJhbGciOiJIUzI1NiJ9...");
```

To keep the token out of source:

```jennifer
# TMDB_ACCESS_TOKEN=eyJ... jennifer run app.j
def c as tmdb.Client init tmdb.clientFromEnv();
```

`clientFromEnv` reads `TMDB_ACCESS_TOKEN`, falling back to `TMDB_API_KEY`, and
applies `TMDB_USER_TOKEN`, `TMDB_LANGUAGE` and `TMDB_REGION` when they are set.
`TMDB_VERBOSE` set to `1`, `true`, `yes` or `on` turns on verbose mode. It
throws when neither credential is set, or when `TMDB_LANGUAGE` or
`TMDB_REGION` is malformed.

With the legacy key, everything under `/3` works and every v4 verb throws
locally instead of sending a request that would come back `401`:

```jennifer
def c as tmdb.Client init tmdb.clientFromApiKey("0123456789abcdef0123456789abcdef");
```

## Configure it

A `Client` is a plain value with no socket. Every builder returns a copy, so
assign the result:

```jennifer
$c = tmdb.withLanguage($c, "de-DE");   # translated titles and overviews
$c = tmdb.withRegion($c, "DE");        # release dates, certifications, cinemas
$c = tmdb.withAdult($c, false);        # the default
$c = tmdb.withTimeout($c, 10000);      # ms; 0 restores 15000
$c = tmdb.withRetries($c, 3);          # default 2
$c = tmdb.withBackoff($c, 1000);       # ms; 0 restores 500
```

- **Language** (`en`, `de-DE`, `pt-BR`; default `en-US`) decides translated
  titles, overviews, taglines, genre names and which localized artwork ranks
  first.
- **Region** (`DE`, `GB`; default none) decides which release dates and
  certifications count as primary, and so what `nowPlaying` and
  `upcomingMovies` return.

## First request

```jennifer
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
def film as tmdb.Movie init tmdb.movie($c, 550);

io.printf("%s (%s)\n", $film.title, tmdb.year($film.releaseDate));
io.printf("%d minutes, rated %.1f by %d people\n",
    $film.runtime, $film.voteAverage, $film.voteCount);
io.printf("%s\n", $film.overview);
```

## Verbose mode

Verbose mode prints one line per request to stdout. The bearer token travels
in a header and is not printed; `api_key`, `access_token`, `request_token` and
`session_id` parameters print as `<redacted>`. Request bodies are never
printed.

```jennifer
$c = tmdb.setVerbose($c, true);
tmdb.searchMovies($c, "blade runner", 1);
# tmdb> GET https://api.themoviedb.org/3/search/movie?language=en-US&page=1&query=blade+runner&include_adult=false
```

## Rate limits and retries

TMDB answers a throttled request with `429` and a `Retry-After` header. A
fresh client retries a 429 or 5xx twice with exponential backoff from a 500 ms
base, honouring a numeric `Retry-After`. Give a job that walks hundreds of
pages more room:

```jennifer
$c = tmdb.withBackoff(tmdb.withRetries($c, 5), 2000);
```

## Endpoints without a typed verb

`tmdb.call` sends a GET to any path and returns the decoded `json.Value`. It
also reaches fields a struct does not carry:

```jennifer
def raw as json.Value init tmdb.call($c, "/3/movie/550/lists", {"page": "1"});
io.printf("in %d lists\n", json.asInt($raw, "/total_results"));
```

It applies the credential, timeout and retry policy, and refuses a path that
does not start with `/`, starts with `//`, or contains `..`, `?`, `#` or
whitespace, so the credential cannot be sent elsewhere. Query parameters go in
the map. `tmdb.callPost`, `tmdb.callPut` and `tmdb.callDelete` send a JSON
body; pass `json.map()` for none.
