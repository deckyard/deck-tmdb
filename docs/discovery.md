# Discovery

Discovery filters the catalogue by criteria (*Japanese animation from the
nineties, over a thousand votes, best rated first*); [search](searching.md)
ranks by words a person typed.

TMDB names many discovery parameters differently on the two catalogues: films
filter on `primary_release_date.gte` and sort by `title.asc`, series on
`first_air_date.gte` and `name.asc`. The server ignores a parameter from the
wrong catalogue without an error. A `DiscoverFilter` therefore stores the
deck's own criterion names, and `discoverMovies` or `discoverShows` translates
them when the request is built.

```jennifer
def f as tmdb.DiscoverFilter init tmdb.sortedBy(
    tmdb.withMinVotes(
        tmdb.releasedBetween(
            tmdb.withGenres(tmdb.discoverFilter(), [16]),
            "1990-01-01",
            "1999-12-31"),
        1000),
    tmdb.SORT_RATING_DESC);

for (def m in tmdb.discoverMovies($c, $f, 1).results) {
    io.printf("%.1f  %s (%s)\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}
```

Every builder returns a copy, so one base filter can be specialized several
ways:

```jennifer
def base as tmdb.DiscoverFilter init tmdb.withMinVotes(
    tmdb.sortedBy(tmdb.discoverFilter(), tmdb.SORT_RATING_DESC), 500);

def nineties as tmdb.DiscoverFilter init tmdb.releasedBetween($base, "1990-01-01", "1999-12-31");
def recent as tmdb.DiscoverFilter init tmdb.releasedBetween($base, "2020-01-01", "");
```

## Criteria

### Genres, keywords, companies

Genre ids come from `tmdb.movieGenres` or `tmdb.showGenres`; the catalogues
number them differently (`28` is Action for films, `10759` "Action &
Adventure" for series).

```jennifer
$f = tmdb.withGenres($f, [878, 53]);     # science fiction AND thriller
$f = tmdb.withAnyGenre($f, [27, 53]);    # horror OR thriller
$f = tmdb.withoutGenres($f, [99]);       # no documentaries
```

`withGenres` and `withAnyGenre` set the same criterion, so the later call
replaces the earlier one.

Keywords ("time loop", "based on novel") are finer than genres; find their ids
with `tmdb.searchKeywords`. `withKeywords` is AND, `withAnyKeyword` OR, and
they replace each other the same way.

```jennifer
def tags as tmdb.KeywordPage init tmdb.searchKeywords($c, "time loop", 1);
$f = tmdb.withKeywords($f, [$tags.results[0].id]);
```

A studio often has several company ids (distributor, production arm,
predecessor), so `withCompanies` is OR:

```jennifer
$f = tmdb.withCompanies($f, [41077]);       # A24
$f = tmdb.withoutCompanies($f, [420]);
```

### Dates, ratings, runtime

```jennifer
$f = tmdb.releasedBetween($f, "1990-01-01", "1999-12-31");   # YYYY-MM-DD, inclusive
$f = tmdb.releasedBetween($f, "2020-01-01", "");             # "" leaves an end open
$f = tmdb.releasedInYear($f, 1999);
$f = tmdb.ratedAtLeast($f, 7.5);
$f = tmdb.ratedAtMost($f, 9.5);
$f = tmdb.withMinVotes($f, 1000);
$f = tmdb.runningBetween($f, 0, 100);                        # minutes; 0 = no bound
```

`releasedBetween` throws when both ends are empty or the window is inverted.
Films filter on the primary release date, series on the first-air date.

Set a vote floor with `ratedAtLeast`: a title with one ten-star vote averages
10. A few hundred votes removes the noise; a few thousand leaves the
well-known titles.

### Language and origin

```jennifer
$f = tmdb.inOriginalLanguage($f, "ja");   # made in Japanese
$f = tmdb.fromCountry($f, "KR");          # made in South Korea
```

`inOriginalLanguage` is the language a title was made in. The language of the
returned metadata is the client's (`tmdb.withLanguage`).

### Where to watch

Provider catalogues differ by country, so `availableOn` requires a two-letter
watch region, as TMDB does. `notAvailableOn` only takes effect alongside
`availableOn`, which sets that region.

```jennifer
$f = tmdb.availableOn($f, [8], "DE");                       # on Netflix in Germany
$f = tmdb.withMonetization($f, [tmdb.MONETIZATION_FLATRATE]);
$f = tmdb.notAvailableOn($f, [9]);
```

Provider ids come from `tmdb.movieProviders` or `tmdb.showProviders`.
`MONETIZATION_FLATRATE` means included in a subscription; the others are
`MONETIZATION_FREE`, `MONETIZATION_ADS`, `MONETIZATION_RENT` and
`MONETIZATION_BUY`.

### Age ratings (films only)

A certification belongs to one country's system, so the country is required.

```jennifer
$f = tmdb.ratedFor($f, "US", "PG-13");     # exactly PG-13
$f = tmdb.ratedUpTo($f, "US", "PG-13");    # PG-13 or gentler: G, PG, PG-13
```

`tmdb.movieCertifications` lists every country's system.

### People (films only)

```jennifer
$f = tmdb.withPeople($f, [1245]);   # cast or crew
$f = tmdb.withCast($f, [819]);      # appeared in
$f = tmdb.withCrew($f, [7467]);     # worked on
```

### Series only

```jennifer
$f = tmdb.withNetworks($f, [49]);                              # HBO
$f = tmdb.withShowStatus($f, tmdb.SHOW_STATUS_RETURNING);      # 0..5
$f = tmdb.withShowType($f, tmdb.SHOW_TYPE_MINISERIES);         # 0..6
```

## Sorting

The `SORT_*` constants are translated per catalogue: `SORT_NEWEST` becomes
`primary_release_date.desc` for films and `first_air_date.desc` for series,
`SORT_TITLE_ASC` becomes `title.asc` or `name.asc`.

| constant | order |
| --- | --- |
| `tmdb.SORT_POPULARITY_DESC` | most popular first (TMDB's default) |
| `tmdb.SORT_POPULARITY_ASC` | least popular first |
| `tmdb.SORT_RATING_DESC`, `tmdb.SORT_RATING_ASC` | by mean rating |
| `tmdb.SORT_VOTES_DESC` | most votes first |
| `tmdb.SORT_NEWEST`, `tmdb.SORT_OLDEST` | by release or first-air date |
| `tmdb.SORT_TITLE_ASC`, `tmdb.SORT_TITLE_DESC` | alphabetical |
| `tmdb.SORT_REVENUE_DESC` | highest box office (films only) |

Any other string is sent unchanged.

## Wrong-catalogue criteria throw

A film-only criterion run on series, or a series-only one run on films, throws
instead of being dropped:

```jennifer
def f as tmdb.DiscoverFilter init tmdb.withNetworks(tmdb.discoverFilter(), [49]);
tmdb.discoverMovies($c, $f, 1);
# Error{kind: "tmdb"}: withNetworks filters series, and this filter is being run
# against the film catalogue - build a separate filter for discoverMovies
```

## Inspecting the wire parameters

`tmdb.filterParams` translates a filter for one catalogue without sending it
(`false` for films, `true` for series):

```jennifer
def wire as map of string to string init tmdb.filterParams($f, false);
for (def name in $wire) {
    io.printf("%s=%s\n", $name, $wire[$name]);
}
```

The client's `language`, `page`, `include_adult` and (films only) `region` are
added at request time and are not in the map.

## Running a filter

```jennifer
def films as tmdb.MoviePage init tmdb.discoverMovies($c, $f, 1);
def series as tmdb.ShowPage init tmdb.discoverShows($c, $g, 1);

# several pages, at most 5 requests
def best as list of tmdb.MovieSummary init tmdb.discoverMoviesAll($c, $f, 5);
def shows as list of tmdb.ShowSummary init tmdb.discoverShowsAll($c, $g, 5);
```

## Example

Korean thrillers since 2015, rated 7 or more by at least 250 voters, on a
flat-rate service in Germany:

```jennifer
def f as tmdb.DiscoverFilter init tmdb.discoverFilter();
$f = tmdb.withGenres($f, [53]);
$f = tmdb.fromCountry($f, "KR");
$f = tmdb.releasedBetween($f, "2015-01-01", "");
$f = tmdb.ratedAtLeast($f, 7.0);
$f = tmdb.withMinVotes($f, 250);
$f = tmdb.availableOn($f, [8, 337, 350], "DE");
$f = tmdb.withMonetization($f, [tmdb.MONETIZATION_FLATRATE]);
$f = tmdb.sortedBy($f, tmdb.SORT_RATING_DESC);

for (def m in tmdb.discoverMoviesAll($c, $f, 2)) {
    io.printf("%.1f  %s (%s)\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}
```
