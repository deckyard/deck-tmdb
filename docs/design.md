<!-- SPDX-License-Identifier: LGPL-3.0-only -->
<!-- SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev> -->

# Design

## Scope

`@deckyard/tmdb` is a typed client for The Movie Database™ API: the v3
catalogue (search, discovery, films, series, seasons, episodes, people,
collections, companies, networks, keywords, reviews, images, videos, watch
providers, trending, change feeds, lookups by external id) and v4 user
authentication, account collections and custom lists, all through one
`Client`. Replies are folded into structs.

Not in scope:

- **Downloading images.** The deck builds image and video URLs
  (`/configuration` sizes checked per image kind); fetching the bytes is the
  caller's choice.
- **Caching and rate-limit bookkeeping.** TMDB™'s limits are answered by
  retrying 429 with backoff; a cache belongs to the application.
- **Endpoints without a typed verb.** `call`, `callPost`, `callPut` and
  `callDelete` reach them and return decoded JSON.

## Decisions

- **A deck, not core.** TMDB is one vendor's API; the deck builds on the
  bundled `rest`, `http` and `uri` modules.
- **One `Client` value, copied by builders.** Credentials, language, region,
  adult flag, timeout, retries, backoff and verbose mode live in `Client`;
  every `with*` builder returns a changed copy. `client`, `clientFromApiKey`
  and `clientFromEnv` (`TMDB_ACCESS_TOKEN`, `TMDB_API_KEY`, `TMDB_USER_TOKEN`,
  `TMDB_LANGUAGE`, `TMDB_REGION`, `TMDB_VERBOSE`) construct one.
- **Credentials.** A user token, when set, is preferred over the read access
  token because it carries both scopes; either goes in an `Authorization:
  Bearer` header. The legacy `api_key` query parameter is used only when no
  bearer token exists, and works on `/3` only. v4 verbs refuse locally when
  the bearer token or user token they need is missing, rather than drawing a
  401.
- **Topics layout.** `src/tmdb.j` includes one topic per API area
  (`core`, `model`, `images`, `search`, `discover`, `movies`, `shows`,
  `people`, `catalog`, `browse`, `auth`, `account`, `userlists`), each with an
  overlay beside it.
- **Discover filters in deck terms.** `DiscoverFilter` stores the deck's key
  names and translates them per catalogue at request time (release date for
  films, first air date for series; `title` or `name` sorts). A criterion the
  catalogue lacks, such as a network on a film, throws instead of being
  silently ignored by TMDB. Only the `SORT_*` constants are translated; another
  sort string is sent verbatim.
- **Body verbs bypass `rest`.** v4 removals put a JSON body on `DELETE`, which
  `rest.delete` cannot send, so body verbs use `http.send` directly.
- **Pages capped at the API's own limit.** TMDB serves at most `MAX_PAGE`
  (500) pages and answers page 501 with a 400; the deck refuses it locally
  and stops paging at 500 whatever `total_pages` says. The `*All` helpers take
  a page budget.
- **Bundles through `append_to_response`.** `movieBundle`, `showBundle` and
  `personBundle` fetch a record with its sub-resources in one request; their
  paged members are page 1. Series append `aggregate_credits`, because
  `credits` holds only the regular cast.
- **Lenient JSON reading, strict arguments.** TMDB writes absent values as
  `null` and mixes number and string ids, so readers default to "", 0 or
  false and stringify numeric ids. Arguments are checked before any request:
  ids must be positive (season and episode numbers may be 0, the specials),
  dates `YYYY-MM-DD`, image sizes from the configuration's list for that kind.
- **Media kinds.** `MediaKind` names the wire values (`tv` for a series,
  `tv_season`, `tv_episode`). Lists hold a kind plus an id because the film
  and series id spaces overlap.

## Errors

- Every error of kind `"tmdb"` is a `TmdbError`: `status` is the HTTP status
  of a refusal, `statusCode` TMDB's own `status_code` from the body (7 an
  invalid key, 34 not found); both are 0 for a bad argument, a missing
  credential or a transport failure.
- A refusal's message names the method, URL, `HTTP <status>` and TMDB's
  `status_message`; with no message in the body it gives a hint for the
  status instead.
- A reply over the transport's size cap stays kind `"limit"`.
- A transport failure (refused, reset, unreachable, DNS, TLS, a close
  before any reply) is the `http` module's `net.NetError`, kind `"net"`,
  passed on unchanged so its `reason`, `sent` and `replied` stay readable.
- Any other failure of the exchange, such as a timeout, is rewrapped as a
  `TmdbError` with status 0.

## Security and limits

- HTTPS only, to `API_BASE` (`https://api.themoviedb.org`); there is no
  plain-http option.
- Caller-supplied paths for the `call*` verbs are checked: a leading slash is
  required, and `//`, `..`, `?`, `#` and whitespace are refused, so a path
  cannot send the bearer token to another host. Account ids are checked the
  same way, and an all-digit id is refused (v4 wants the hex account object
  id).
- Transport policy per request: idle timeout `DEFAULT_TIMEOUT_MS` (15 s),
  `DEFAULT_RETRIES` (2) retries of 429 and 5xx with `DEFAULT_BACKOFF_MS`
  (500 ms) backoff, at most 3 redirects, replies capped at
  `MAX_RESPONSE_BYTES` (16 MiB).
- Verbose mode prints each request line with `api_key`, `access_token`,
  `request_token` and `session_id` redacted; the bearer token travels in a
  header and is never printed.

## Testing and validation

- Network-free overlays (243 tests) cover builders, argument checks, headers,
  query strings, the verbose transcript, error interpretation, the discover
  translation table, URL building and every JSON fold, fed with reply bodies
  taken from TMDB's documentation and kept inline in the overlays.
- The verbs themselves are thin and are not exercised against a server, fake
  or live.
- Every example needs a live credential, so CI only parses and lints them.
  `examples/lists.j` writes to the account (creates, edits and deletes a
  list); `examples/auth.j` runs the approval flow interactively.

## Known limitations and open questions

- No loopback fake covers the request path end to end; transport behaviour
  is tested through its helpers (one test points the GET path at a closed
  loopback port).
- Genre ids differ between films and series, and image size lists differ per
  image kind; the deck checks sizes but leaves genre ids to the caller.

## Dependencies on the interpreter

- Floor `jennifer >=0.28.0` (the calls 0.29.0 removes are replaced by their 0.28.0 forms), the release that carries every library and
  module the deck uses; the default binary for the verbs (`jennifer-tiny`
  stubs `net`).
- The bundled `rest`, `http` (options, retries, size cap) and `uri` modules.
- Thrown structs classified by kind (`jennifer` `6abf345`, the error-struct
  work of M28.51 to M28.57), and transport failures as `net.NetError`
  (M28.65).
