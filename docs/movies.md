# Movies

## One film

```jennifer
def film as tmdb.Movie init tmdb.movie($c, 550);

io.printf("%s (%s)\n", $film.title, tmdb.year($film.releaseDate));
io.printf("%d min, %s\n", $film.runtime, $film.status);
io.printf("%s\n", $film.tagline);
```

A value TMDB does not have reads as zero: an unreleased film has `runtime` 0
and `releaseDate` "", and many films have `budget` and `revenue` 0 because no
figures were filed.

## The detail page in one request

`movieBundle` uses TMDB's `append_to_response` to fetch the film and nine
sub-resources (credits, images, videos, keywords, external ids,
recommendations, similar, reviews, watch providers) in one request:

```jennifer
def b as tmdb.MovieBundle init tmdb.movieBundle($c, 550);

io.printf("%s (%s), directed by %s\n",
    $b.movie.title, tmdb.year($b.movie.releaseDate), tmdb.directorOf($b.credits));

for (def actor in $b.credits.cast) {
    io.printf("  %-24s %s\n", $actor.name, $actor.character);
}
for (def v in $b.videos) {
    if ($v.kind == "Trailer" and $v.official) {
        io.printf("trailer: %s\n", tmdb.videoUrl($v));
    }
}
io.printf("%d posters, %d reviews\n", len($b.images.posters), $b.reviews.totalResults);
```

A part with no data is empty, not missing. The paged parts
(`recommendations`, `similar`, `reviews`) are always page 1, because
`append_to_response` takes no page number; call the individual verb for later
pages.

## Sub-resources

| verb | returns |
| --- | --- |
| `tmdb.movieCredits` | `Credits`: cast in billing order, and crew |
| `tmdb.movieImages` | `Images`: backdrops, posters, logos |
| `tmdb.movieVideos` | `list of Video`: trailers, teasers, clips |
| `tmdb.movieKeywords` | `list of Keyword` |
| `tmdb.movieRecommendations` | `MoviePage`, from viewing behaviour |
| `tmdb.movieSimilar` | `MoviePage`, from shared genres and keywords |
| `tmdb.movieReviews` | `ReviewPage` |
| `tmdb.movieReleaseDates` | `list of ReleaseGroup`, with age ratings |
| `tmdb.movieExternalIds` | `ExternalIds` |
| `tmdb.movieTranslations` | `list of Translation` |
| `tmdb.movieAlternativeTitles` | `list of AlternativeTitle` |
| `tmdb.movieWatchProviders` | `list of WatchOffers` |

`movieImages` sends no `language`, so every localized image comes back; each
`Image` carries the language of its text.

## Directors and other crew

The crew list is unordered.

```jennifer
def credits as tmdb.Credits init tmdb.movieCredits($c, 550);
io.printf("directed by %s\n", tmdb.directorOf($credits));   # the first director, or ""

strings.join(tmdb.directorsOf($credits), " & ");            # every director
tmdb.crewNamed($credits, "Original Music Composer");
tmdb.crewNamed($credits, "Director of Photography");
```

`crewNamed` matches the job case-insensitively. Job names are TMDB's
vocabulary; `tmdb.jobs` lists them by department.

## Release dates and age ratings

A film has several releases per country (premiere, cinema, digital, disc),
and each can carry its own certification:

```jennifer
def groups as list of tmdb.ReleaseGroup init tmdb.movieReleaseDates($c, 550);

for (def g in $groups) {
    for (def r in $g.releases) {
        io.printf("%s %-20s %s %s\n",
            $g.region, tmdb.releaseTypeName($r.kind), $r.date, $r.certification);
    }
}
```

`certificationOf` returns the first non-empty certification for a country, or
"" (a premiere is often unrated where the cinema release is not):

```jennifer
io.printf("US: %s, DE: %s\n",
    tmdb.certificationOf($groups, "US"),
    tmdb.certificationOf($groups, "DE"));
```

Release types are `tmdb.RELEASE_PREMIERE` (1), `RELEASE_THEATRICAL_LIMITED`
(2), `RELEASE_THEATRICAL` (3), `RELEASE_DIGITAL` (4), `RELEASE_PHYSICAL` (5)
and `RELEASE_TV` (6).

## Where to watch

```jennifer
def offers as list of tmdb.WatchOffers init tmdb.movieWatchProviders($c, 550);
def here as tmdb.WatchOffers init tmdb.offersIn($offers, "DE");

for (def p in $here.flatrate) {
    io.printf("stream: %s\n", $p.providerName);
}
for (def p in $here.rent) {
    io.printf("rent:   %s\n", $p.providerName);
}
```

`offersIn` returns a zeroed `WatchOffers` for a country with no offers. The
buckets `flatrate`, `rent`, `buy`, `ads` and `free` are often empty.

> The data is JustWatch's, and TMDB's terms require attributing it when you
> display it. Availability changes weekly; do not cache it for long.

## Curated lists

```jennifer
$c = tmdb.withRegion($c, "DE");

tmdb.nowPlaying($c, 1);        # in cinemas in the client's region
tmdb.upcomingMovies($c, 1);    # opening soon there
tmdb.popularMovies($c, 1);
tmdb.topRatedMovies($c, 1);
tmdb.latestMovie($c);          # the newest record, not a page
```

The four paged lists send the client's region. Without one, TMDB answers for
the United States. `topRatedMovies` applies TMDB's own vote floor; use
[discovery](discovery.md) to choose the floor yourself.

## Collections

A film in a franchise names its collection:

```jennifer
def film as tmdb.Movie init tmdb.movie($c, 11);
if ($film.belongsToCollection.id != 0) {
    def set as tmdb.Collection init tmdb.collection($c, $film.belongsToCollection.id);
    for (def part in $set.parts) {
        io.printf("%s (%s)\n", $part.title, tmdb.year($part.releaseDate));
    }
}
```

See [Collections and lookups](catalog.md).
