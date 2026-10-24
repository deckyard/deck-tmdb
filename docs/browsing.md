# Trending, vocabularies and changes

Endpoints that describe the catalogue as a whole; none takes an id.

## Trending

```jennifer
for (def item in tmdb.trendingAll($c, tmdb.TREND_DAY, 1).results) {
    io.printf("%-8s %s\n", tmdb.mediaKindName($item.kind), $item.title);
}

tmdb.trendingMovies($c, tmdb.TREND_WEEK, 1);
tmdb.trendingShows($c, tmdb.TREND_DAY, 1);
tmdb.trendingPeople($c, tmdb.TREND_WEEK, 1);
```

The window is `tmdb.TREND_DAY` (last 24 hours) or `tmdb.TREND_WEEK` (last 7
days); anything else throws. Trending follows views, ratings and list activity
and changes faster than `popularMovies`.

## Genres

Films and series number genres differently (`28` is Action for films, `10759`
"Action & Adventure" for series). List rows carry only `genreIds`; fetch the
vocabulary once and resolve against an index:

```jennifer
def index as map of string to string init tmdb.genreIndex(tmdb.movieGenres($c));

for (def m in tmdb.popularMovies($c, 1).results) {
    io.printf("%-40s %s\n", $m.title, strings.join(tmdb.genreNames($index, $m.genreIds), ", "));
}
```

`genreNames` skips ids the index does not know. `tmdb.showGenres` is the
series vocabulary.

## Certifications

```jennifer
def systems as list of tmdb.CertificationGroup init tmdb.movieCertifications($c);

for (def rating in tmdb.certificationsIn($systems, "DE")) {
    io.printf("%-6s %d  %s\n", $rating.certification, $rating.order, $rating.meaning);
}
```

`order` rises with strictness; sort a picker on it. These are the values
`tmdb.ratedFor` and `tmdb.ratedUpTo` take in [discovery](discovery.md).
`tmdb.showCertifications` is the series table.

## Watch providers

```jennifer
for (def country in tmdb.providerRegions($c)) {
    io.printf("%s %s\n", $country.code, $country.englishName);
}

for (def p in tmdb.movieProviders($c, "DE")) {
    io.printf("%4d %-28s priority %d\n", $p.providerId, $p.providerName, $p.displayPriority);
}
```

`providerRegions` lists the countries with provider data: the valid watch
regions for `availableOn` and for `offersIn`. `movieProviders` and
`showProviders` list the services in a country, or in every country for `""`.
A provider id is the same in every country. `displayPriority` is TMDB's
suggested order, lowest first.

> This is JustWatch data. TMDB's terms require attribution when you display
> it.

## Change feeds

The change feeds tell a mirror which records to re-fetch. Each entry is an id
and an adult flag:

```jennifer
def changed as tmdb.ChangePage init tmdb.changedMovies($c, "", "", 1);
io.printf("%d films changed in the default window\n", $changed.totalResults);

for (def entry in $changed.results) {
    if (not $entry.adult) {
        refresh(tmdb.movie($c, $entry.id));
    }
}
```

With both dates `""` TMDB returns the last 24 hours. It keeps 14 days of
history and rejects a wider range. Dates are `YYYY-MM-DD`; anything else
throws before the request.

```jennifer
tmdb.changedMovies($c, "2026-08-01", "2026-08-08", 1);
tmdb.changedShows($c, "", "", 1);
tmdb.changedPeople($c, "", "", 1);
```

`Configuration.changeKeys` (from `tmdb.configuration`) lists the fields TMDB
tracks.
