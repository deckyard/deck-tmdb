# Recipes

Complete programs. Each runs as written with a token in the environment:

```sh
TMDB_ACCESS_TOKEN=eyJ... jennifer run recipe.j
```

## A film detail page in one request

```jennifer
#!/usr/bin/env -S jennifer run
use io;
use strings;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
def cfg as tmdb.Configuration init tmdb.configuration($c);

def hits as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner 2049", 1);
if (len($hits.results) == 0) {
    io.printf("nothing found\n");
    exit 1;
}

def b as tmdb.MovieBundle init tmdb.movieBundle($c, $hits.results[0].id);

io.printf("%s (%s)\n", $b.movie.title, tmdb.year($b.movie.releaseDate));
io.printf("%d min - directed by %s\n", $b.movie.runtime, tmdb.directorOf($b.credits));
io.printf("%s\n\n", $b.movie.overview);

io.printf("poster:  %s\n", tmdb.posterUrl($cfg, $b.movie.posterPath, "w500"));
for (def v in $b.videos) {
    if ($v.kind == "Trailer" and $v.official) {
        io.printf("trailer: %s\n", tmdb.videoUrl($v));
        break;
    }
}

io.printf("\ncast\n");
def shown as int init 0;
for (def actor in $b.credits.cast) {
    if ($shown >= 8) {
        break;
    }
    io.printf("  %-26s %s\n", $actor.name, $actor.character);
    $shown = $shown + 1;
}

def here as tmdb.WatchOffers init tmdb.offersIn($b.watchOffers, "DE");
if (len($here.flatrate) > 0) {
    def names as list of string init [];
    for (def p in $here.flatrate) {
        $names[] = $p.providerName;
    }
    io.printf("\nstreaming in DE: %s\n", strings.join($names, ", "));
}
```

## Thrillers on a subscription service in one country

```jennifer
#!/usr/bin/env -S jennifer run
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.withRegion(tmdb.clientFromEnv(), "DE");

def f as tmdb.DiscoverFilter init tmdb.discoverFilter();
$f = tmdb.withGenres($f, [53]);
$f = tmdb.ratedAtLeast($f, 7.0);
$f = tmdb.withMinVotes($f, 500);
$f = tmdb.availableOn($f, [8, 337, 350], "DE");
$f = tmdb.withMonetization($f, [tmdb.MONETIZATION_FLATRATE]);
$f = tmdb.sortedBy($f, tmdb.SORT_RATING_DESC);

for (def m in tmdb.discoverMoviesAll($c, $f, 2)) {
    io.printf("%.1f  %-44s %s\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}
```

## A season's episode guide

```jennifer
#!/usr/bin/env -S jennifer run
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

def hits as tmdb.ShowPage init tmdb.searchShows($c, "severance", 1);
def series as tmdb.Show init tmdb.show($c, $hits.results[0].id);

io.printf("%s - %s, %d seasons\n\n", $series.name, $series.status, $series.numberOfSeasons);

for (def entry in $series.seasons) {
    if ($entry.seasonNumber == 0) {
        continue;
    }
    def s as tmdb.Season init tmdb.season($c, $series.id, $entry.seasonNumber);
    io.printf("%s (%s)\n", $s.name, $s.airDate);
    for (def e in $s.episodes) {
        io.printf("  %dx%02d  %-40s %s  %.1f\n",
            $e.seasonNumber, $e.episodeNumber, $e.name, $e.airDate, $e.voteAverage);
    }
    io.printf("\n");
}
```

## A person's directing filmography, newest first

```jennifer
#!/usr/bin/env -S jennifer run
use io;
use lists;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

def found as tmdb.PersonPage init tmdb.searchPeople($c, "greta gerwig", 1);
def who as tmdb.PersonSummary init $found.results[0];

def credits as tmdb.PersonCredits init tmdb.personCombinedCredits($c, $who.id);
def directed as list of tmdb.PersonCredit init tmdb.creditsInDepartment($credits, "Directing");

io.printf("%s directed %d titles\n\n", $who.name, len($directed));

# newest first: collect the years, sort them, then print by year
def years as list of string init [];
for (def one in $directed) {
    $years[] = tmdb.year($one.releaseDate);
}
def previous as string init "-";
for (def y in lists.reverse(lists.sort($years))) {
    if ($y == $previous) {
        continue;
    }
    $previous = $y;
    for (def one in $directed) {
        if (tmdb.year($one.releaseDate) == $y) {
            io.printf("%s  %s\n", $y, $one.title);
        }
    }
}
```

## Resolve IMDb ids to TMDB records

```jennifer
#!/usr/bin/env -S jennifer run
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

for (def id in ["tt0076759", "tt0903747", "nm0000158"]) {
    def hits as tmdb.FindResults init tmdb.findByImdb($c, $id);
    if (len($hits.movies) > 0) {
        io.printf("%-12s film   %s (%s)\n",
            $id, $hits.movies[0].title, tmdb.year($hits.movies[0].releaseDate));
    } elseif (len($hits.shows) > 0) {
        io.printf("%-12s series %s (%s)\n",
            $id, $hits.shows[0].title, tmdb.year($hits.shows[0].releaseDate));
    } elseif (len($hits.people) > 0) {
        io.printf("%-12s person %s\n", $id, $hits.people[0].title);
    } else {
        io.printf("%-12s no match\n", $id);
    }
}
```

## Sign a person in and build them a list

```jennifer
#!/usr/bin/env -S jennifer run
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

# 1. ask for a token, 2. have it approved, 3. trade it in
def pending as tmdb.RequestToken init tmdb.requestToken($c);
io.printf("approve this, then press return:\n  %s\n", tmdb.approvalUrl($pending.requestToken));
io.readLine();

def granted as tmdb.AccessToken init tmdb.accessToken($c, $pending.requestToken);
$c = tmdb.withUserToken($c, $granted.accessToken);
io.printf("signed in as account %s\n", $granted.accountId);

# fill a fresh list from a discovery query
def made as tmdb.StatusResponse init tmdb.createList($c, "Best of the nineties", "", false);

def f as tmdb.DiscoverFilter init tmdb.sortedBy(
    tmdb.withMinVotes(
        tmdb.releasedBetween(tmdb.discoverFilter(), "1990-01-01", "1999-12-31"), 2000),
    tmdb.SORT_RATING_DESC);

def items as list of tmdb.ListItem init [];
for (def m in tmdb.discoverMovies($c, $f, 1).results) {
    $items[] = tmdb.listItem(tmdb.MediaKind.Movie, $m.id);
}

def added as tmdb.ItemsResponse init tmdb.addListItems($c, $made.id, $items);
io.printf("added %d of %d\n", countSucceeded($added), len($items));

def l as tmdb.ListDetails init tmdb.listDetails($c, $made.id, 1);
io.printf("%s: %d titles\n", $l.name, $l.itemCount);

func countSucceeded(answer as tmdb.ItemsResponse) {
    def n as int init 0;
    for (def outcome in $answer.results) {
        if ($outcome.success) {
            $n = $n + 1;
        }
    }
    return $n;
}
```

## Mirror what changed today

```jennifer
#!/usr/bin/env -S jennifer run
use io;
import "@deckyard/tmdb/" as tmdb;

def c as tmdb.Client init tmdb.withBackoff(tmdb.withRetries(tmdb.clientFromEnv(), 5), 2000);

def page as int init 1;
def seen as int init 0;
def batch as tmdb.ChangePage init tmdb.changedMovies($c, "", "", $page);

io.printf("%d films changed\n", $batch.totalResults);

while (true) {
    for (def entry in $batch.results) {
        if ($entry.adult) {
            continue;
        }
        try {
            def film as tmdb.Movie init tmdb.movie($c, $entry.id);
            io.printf("%7d  %s\n", $film.id, $film.title);
            $seen = $seen + 1;
        } catch (e) {
            # a change entry can name a record that has since been deleted
            io.printf("%7d  skipped: %s\n", $entry.id, $e.message);
        }
    }
    if ($page >= 3 or not tmdb.morePages($batch.page, $batch.totalPages)) {
        break;
    }
    $page = $page + 1;
    $batch = tmdb.changedMovies($c, "", "", $page);
}

io.printf("refreshed %d\n", $seen);
```
