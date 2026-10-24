# Examples

One `jennifer run` script per topic. Each imports the deck from the checkout
(`../src/tmdb.j`) and calls the live API, so it needs a read access token (the
long `eyJ...` **API Read Access Token** from
<https://www.themoviedb.org/settings/api>):

```sh
TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/search.j
```

CI only parse-checks them.

| example | shows | writes? |
| --- | --- | --- |
| [`core.j`](core.j) | building and tuning a client, verbose mode, `tmdb.call` | no |
| [`search.j`](search.j) | the seven searches, multi-search, paging | no |
| [`discover.j`](discover.j) | the filter builder and its wire parameters | no |
| [`movies.j`](movies.j) | a film bundle, credits, ratings, where to watch | no |
| [`shows.j`](shows.j) | a series, its seasons, an episode, aggregate credits | no |
| [`people.j`](people.j) | a person, their filmography, their photographs | no |
| [`catalog.j`](catalog.j) | collections, companies, networks, keywords, `find` | no |
| [`browse.j`](browse.j) | trending, genres, certifications, providers, changes | no |
| [`images.j`](images.j) | the configuration, image and video URLs | no |
| [`auth.j`](auth.j) | the v4 approval flow, end to end | no¹ |
| [`account.j`](account.j) | a signed-in person's collections | no |
| [`lists.j`](lists.j) | creating, filling, editing and deleting a list | **yes** |

¹ `auth.j` mints a user access token and prints it; it changes no data.

## Examples that need a signed-in user

`account.j` and `lists.j` also need a user access token. `auth.j` prints an
approval URL, waits while you approve it, then prints the access token and the
account object id:

```sh
TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/auth.j

export TMDB_ACCESS_TOKEN=eyJ...
export TMDB_USER_TOKEN=eyJ...
export TMDB_ACCOUNT_ID=4bc8892a017a3c0f92000002

jennifer run examples/account.j
jennifer run examples/lists.j
```

`lists.j` creates a list named *deck-tmdb example*, fills it, edits it and
deletes it. If it fails part-way, the list stays in your account; delete it
there or re-run.

## Environment variables

| variable | effect |
| --- | --- |
| `TMDB_ACCESS_TOKEN` | the application read access token |
| `TMDB_API_KEY` | the legacy v3 key, used only when there is no access token |
| `TMDB_USER_TOKEN` | a user access token, for the account and list examples |
| `TMDB_LANGUAGE` | e.g. `de-DE`: translated titles and overviews |
| `TMDB_REGION` | e.g. `DE`: release dates, certifications, cinema listings |
| `TMDB_VERBOSE` | `1` prints every request, credentials redacted |
| `TMDB_ACCOUNT_ID` | read by `account.j` only, not by the deck |

```sh
TMDB_LANGUAGE=de-DE TMDB_REGION=DE TMDB_VERBOSE=1 jennifer run examples/movies.j
```
