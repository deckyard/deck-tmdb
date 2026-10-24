# Searching

Search ranks titles by how well they match words a person typed. It does not
filter by criteria; that is [discovery](discovery.md).

| you have | use |
| --- | --- |
| words a person typed | search |
| criteria chosen in a form | [discovery](discovery.md) |
| an id from another site | `tmdb.find`, see [Catalogue](catalog.md) |

## The seven searches

```jennifer
def films as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);
def series as tmdb.ShowPage init tmdb.searchShows($c, "the office", 1);
def people as tmdb.PersonPage init tmdb.searchPeople($c, "tom hanks", 1);
def mixed as tmdb.MediaPage init tmdb.searchMulti($c, "alien", 1);
def sets as tmdb.CollectionPage init tmdb.searchCollections($c, "star wars", 1);
def studios as tmdb.CompanyPage init tmdb.searchCompanies($c, "a24", 1);
def tags as tmdb.KeywordPage init tmdb.searchKeywords($c, "time loop", 1);
```

A blank query throws. Titles also match on their alternative titles, so
*Die Verurteilten* finds *The Shawshank Redemption*.

## By year

```jennifer
tmdb.searchMoviesInYear($c, "the thing", 1982, 1);   # not the 2011 one
tmdb.searchShowsInYear($c, "the office", 2005, 1);   # not the British one
```

Films filter on the primary release year (the original theatrical release),
series on the first-air year. A year outside 1800..2200 throws.

## Multi-search

`searchMulti` returns films, series and people in one ranked list. Each row
carries its `kind`; `onlyMovies`, `onlyShows` and `onlyPeople` split them:

```jennifer
def hits as tmdb.MediaPage init tmdb.searchMulti($c, "alien", 1);

for (def m in tmdb.onlyMovies($hits.results)) {
    io.printf("film   %s (%s)\n", $m.title, tmdb.year($m.releaseDate));
}
for (def s in tmdb.onlyShows($hits.results)) {
    io.printf("series %s (%s)\n", $s.title, tmdb.year($s.releaseDate));
}
for (def p in tmdb.onlyPeople($hits.results)) {
    io.printf("person %s (%s)\n", $p.title, $p.knownForDepartment);
}
```

A `MediaItem` fills `title` from `title` or `name`, and `releaseDate` from
`release_date` or `first_air_date`. Fields of another kind (`profilePath` on a
film, `video` on a person) are zero.

Or `match` on the kind:

```jennifer
for (def item in $hits.results) {
    match ($item.kind) {
        when Movie { showFilm($item); }
        when Show { showSeries($item); }
        when Person { showPerson($item); }
        else { }
    }
}
```

## People with the same name

A person row's `knownFor` holds the titles TMDB associates with them:

```jennifer
for (def p in tmdb.searchPeople($c, "chris evans", 1).results) {
    def known as list of string init [];
    for (def title in $p.knownFor) {
        $known[] = $title.title;
    }
    io.printf("%-20s %s\n", $p.name, strings.join($known, ", "));
}
```

## Paging

A search page holds 20 rows. `tmdb.morePages` is the loop condition; it also
stops at page 500, past which TMDB serves nothing whatever `totalPages` says:

```jennifer
def page as int init 1;
def hits as tmdb.MoviePage init tmdb.searchMovies($c, "alien", $page);
def found as list of tmdb.MovieSummary init [];

while (true) {
    for (def m in $hits.results) {
        $found[] = $m;
    }
    if (not tmdb.morePages($hits.page, $hits.totalPages)) {
        break;
    }
    $page = $page + 1;
    $hits = tmdb.searchMovies($c, "alien", $page);
}
```

`searchMoviesAll` and `searchShowsAll` run that loop with a page budget,
stopping at the last page, the budget or page 500. A budget of 3 is at most 3
requests and 60 rows; a budget below 1 throws.

```jennifer
def found as list of tmdb.MovieSummary init tmdb.searchMoviesAll($c, "alien", 3);
```

## Search, then fetch

A search row is a summary: `genreIds` instead of named genres, and no
runtime, budget or credits. Fetch the record for those:

```jennifer
def hits as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);
if (len($hits.results) == 0) {
    io.printf("nothing found\n");
    exit 1;
}
def film as tmdb.MovieBundle init tmdb.movieBundle($c, $hits.results[0].id);
io.printf("%s, directed by %s\n", $film.movie.title, tmdb.directorOf($film.credits));
```

## Limits

- No relevance score; the order is TMDB's and weights popularity.
- No spelling correction; a typo finds nothing.
- The only filter is `include_adult`, from the client (`tmdb.withAdult`).
  `searchCompanies` and `searchKeywords` send neither it nor the language.
