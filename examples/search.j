#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# search example - the seven searches, multi-search, and paging.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/search.j

use io;
use strings;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

def films as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);
io.printf("%d films match \"blade runner\"\n", $films.totalResults);
for (def m in $films.results) {
    io.printf("  %-44s %s  %.1f\n", $m.title, tmdb.year($m.releaseDate), $m.voteAverage);
}

# the year disambiguates a remake from its original
io.printf("\nthe 1982 \"The Thing\":\n");
for (def m in tmdb.searchMoviesInYear($c, "the thing", 1982, 1).results) {
    io.printf("  %s (%s)\n", $m.title, tmdb.year($m.releaseDate));
}

# known_for is what makes a person picker usable
io.printf("\npeople called \"chris evans\":\n");
for (def p in tmdb.searchPeople($c, "chris evans", 1).results) {
    def known as list of string init [];
    for (def title in $p.knownFor) {
        $known[] = $title.title;
    }
    io.printf("  %-22s %s\n", $p.name, strings.join($known, ", "));
}

# one ranked list across all three catalogues, split apart again
def mixed as tmdb.MediaPage init tmdb.searchMulti($c, "alien", 1);
io.printf(
    "\n\"alien\": %d films, %d series, %d people on page 1\n",
    len(tmdb.onlyMovies($mixed.results)),
    len(tmdb.onlyShows($mixed.results)),
    len(tmdb.onlyPeople($mixed.results)));

for (def item in $mixed.results) {
    io.printf(
        "  %-8s %-40s %s\n",
        tmdb.mediaKindName($item.kind),
        $item.title,
        tmdb.year($item.releaseDate));
}

# the paging loop, written once
def all as list of tmdb.MovieSummary init tmdb.searchMoviesAll($c, "alien", 3);
io.printf("\n%d films over three pages\n", len($all));

# collections, companies and keywords have their own searches
io.printf("\ncollections: %s\n", tmdb.searchCollections($c, "star wars", 1).results[0].name);
io.printf("companies:   %s\n", tmdb.searchCompanies($c, "a24", 1).results[0].name);
io.printf("keywords:    %s\n", tmdb.searchKeywords($c, "time loop", 1).results[0].name);
