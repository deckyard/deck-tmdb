# @deckyard/tmdb

A typed Jennifer client for [The Movie Database](https://www.themoviedb.org).

This deck is part of [Deckyard](https://github.com/deckyard), community decks for [Jennifer](https://jennifer-lang.dev/).

```jennifer
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
def hits as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);

for (def m in $hits.results) {
    io.printf("%s (%s)  %.1f\n", $m.title, tmdb.year($m.releaseDate), $m.voteAverage);
}
```

## v3 and v4

TMDB serves two API generations from one host, `https://api.themoviedb.org`.
**v4** (`/4/...`) has bearer authentication, the user approval flow, accounts
and custom lists, but cannot search or describe a film. **v3** (`/3/...`) has
the catalogue: films, series, seasons, episodes, people, credits, images,
videos, genres, discovery and watch providers.

The v4 *API Read Access Token* is a bearer credential both generations accept,
so one `Client` with one token reaches `/3/movie/550` and `/4/list/8175284`
alike.

What the deck does on top of the HTTP API:

- Replies are value-semantic structs. A `null` or missing field reads as `""`,
  `0`, `false` or `[]`, so a struct is always safe to read.
- Films and series share field names: `title` is filled from `title` or
  `name`, `releaseDate` from `release_date` or `first_air_date`, and the
  discovery filter writes `primary_release_date.gte` or `first_air_date.gte`
  as the catalogue needs.
- Arguments are checked before the request: a zero id, a page outside
  1..500, an image size that does not exist for that kind, a path carrying
  `..`.
- Every failure is `Error{kind: "tmdb"}`, carrying TMDB's own
  `status_message` when there is one.
- `tmdb.call`, `tmdb.callPost`, `tmdb.callPut` and `tmdb.callDelete` reach
  any endpoint without a typed verb.

## Coverage

| topic | endpoints |
| --- | --- |
| [Search](searching.md) | movie, tv, person, multi, collection, company, keyword |
| [Discovery](discovery.md) | `/discover/movie`, `/discover/tv`, behind a filter builder |
| [Movies](movies.md) | details, credits, images, videos, keywords, recommendations, similar, reviews, release dates, external ids, translations, alternative titles, watch providers, now playing, popular, top rated, upcoming, latest |
| [Series](shows.md) | details, credits, aggregate credits, images, videos, keywords, content ratings, episode groups, recommendations, similar, reviews, external ids, translations, alternative titles, watch providers, airing today, on the air, popular, top rated, latest |
| [Seasons and episodes](shows.md) | details, credits, aggregate credits, images, videos, external ids |
| [People](people.md) | details, movie / tv / combined credits, images, external ids, popular, latest |
| [Catalogue](catalog.md) | collections, companies, networks, keywords, reviews, credits, `find` |
| [Browsing](browsing.md) | trending, genres, certifications, watch providers, change feeds |
| [Configuration](images.md) | images, countries, languages, primary translations, jobs, time zones |
| [v4 auth](authentication.md) | request token, approval URL, access token, logout |
| [v4 account](account.md) | lists, favourites, ratings, watchlists, recommendations |
| [v4 lists](lists.md) | create, read, update, delete, clear, add and remove items, item status |

[Errors](errors.md) lists what can fail and the messages, [Recipes](recipes.md)
has complete programs, and the [cheatsheet](cheatsheet.md) lists every export.

## Attribution

This product uses the TMDB API but is **not endorsed or certified by TMDB**.
Using the API means agreeing to its
[terms of use](https://www.themoviedb.org/api-terms-of-use), which require you
to attribute TMDB in any application built on it. The watch-provider data is
JustWatch's and carries its own attribution requirement.
