# Authenticating a user

The catalogue chapters read public data with the application's token. The
account and list endpoints act for a person and need a **user access token**,
which TMDB's v4 approval flow mints in three steps; the second happens in a
browser.

```
  1. requestToken   ->  a token waiting to be approved
  2. approvalUrl    ->  the person approves it on themoviedb.org
  3. accessToken    ->  the approved token is exchanged for a user access token
```

All three verbs, and `logout`, run on the application's read access token:
the deck drops any user token from the client for these calls, and a client
built from the legacy API key throws.

## 1. Request a token

```jennifer
def pending as tmdb.RequestToken init tmdb.requestToken($c);
```

A request token is not a credential. It expires 15 minutes after it is
minted, so request it when the person is ready to approve.

## 2. Send the person to approve it

```jennifer
io.printf("open this and approve:\n  %s\n", tmdb.approvalUrl($pending.requestToken));
```

`approvalUrl` builds the URL (`https://www.themoviedb.org/auth/access?request_token=...`)
and sends nothing.

To have TMDB send the person back, request the token with a redirect:

```jennifer
def pending as tmdb.RequestToken init tmdb.requestTokenWithRedirect(
    $c, "https://example.org/tmdb/callback");
```

After approval TMDB redirects there with
`?request_token=...&approved=true` appended: a web callback route, or a custom
scheme on mobile. Without a redirect the person stays on a TMDB page.

## 3. Exchange it

```jennifer
def granted as tmdb.AccessToken init tmdb.accessToken($c, $pending.requestToken);
$c = tmdb.withUserToken($c, $granted.accessToken);
```

This fails while the token is unapproved, so call it after the person returns,
not on a timer.

| `AccessToken` field | |
| --- | --- |
| `accessToken` | the person's credential; it does not expire until `logout` |
| `accountId` | the v4 account **object id**, a hex string such as `4bc8892a017a3c0f92000002` |

TMDB also has a numeric v3 account id for the same account. The v4 endpoints
take only the object id and answer the numeric one with an unexplained 404,
so the deck refuses an all-digit id before sending.

> The access token carries the read and write scope of that TMDB account.
> Keep it out of source, logs and URLs.

## Using it

Once set with `withUserToken`, the user token replaces the application token
on every request; it has read scope too.

```jennifer
$c = tmdb.withUserToken($c, $granted.accessToken);

def mine as tmdb.ListPage init tmdb.accountLists($c, $granted.accountId, 1);
def watch as tmdb.MoviePage init tmdb.watchlistMovies($c, $granted.accountId, 1, "");
```

`tmdb.hasUser($c)` tells whether a client has a user token. To skip the flow
on later runs, store the token and pass it in the environment, which
`clientFromEnv` reads:

```sh
TMDB_ACCESS_TOKEN=eyJ... TMDB_USER_TOKEN=eyJ... jennifer run app.j
```

## Signing out

Dropping the token locally leaves it valid wherever it was copied. Invalidate
it at TMDB:

```jennifer
tmdb.logout($c, $granted.accessToken);
$c = tmdb.withUserToken($c, "");
```

## Which credential each verb needs

| verbs | credential |
| --- | --- |
| the catalogue: search, discovery, movies, series, people ... | read access token or legacy API key |
| `tmdb.requestToken`, `accessToken`, `logout` | read access token |
| `tmdb.listDetails`, `listItemsAll`, `listItemStatus` on a public list | read access token |
| [Account collections](account.md) and the other [list](lists.md) verbs | user access token |

A verb missing its credential throws locally with a sentence naming what it
needs, instead of sending a request that would come back `401`.
