#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# discover example - the filter builder, and what it translates to.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/discover.j

use io;
use json;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

# one base filter, specialized down two branches - every builder copies
def base as tmdb.DiscoverFilter init tmdb.sortedBy(
    tmdb.withMinVotes(tmdb.discoverFilter(), 1000),
    tmdb.SORT_RATING_DESC);

def nineties as tmdb.DiscoverFilter init tmdb.releasedBetween(
    tmdb.withGenres($base, [16]),
    "1990-01-01",
    "1999-12-31");

io.printf("best-rated animation of the nineties\n");
for (def m in tmdb.discoverMovies($c, $nineties, 1).results) {
    io.printf("  %.1f  %-44s %s\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}

# the same semantic filter reads differently on each catalogue
io.printf("\nas film parameters:   %s\n", json.encode(tmdb.filterParams($nineties, false)));
io.printf("as series parameters: %s\n", json.encode(tmdb.filterParams($nineties, true)));

# series-only criteria
def hbo as tmdb.DiscoverFilter init tmdb.withShowStatus(
    tmdb.withNetworks(tmdb.discoverFilter(), [49]),
    tmdb.SHOW_STATUS_RETURNING);

io.printf("\nHBO, still in production\n");
for (def s in tmdb.discoverShows($c, $hbo, 1).results) {
    io.printf("  %-44s %s\n", $s.name, tmdb.year($s.firstAirDate));
}

# running a series filter against films is an error, not a shrug
try {
    tmdb.discoverMovies($c, $hbo, 1);
} catch (e) {
    io.printf("\nrefused: %s\n", $e.message);
}

# what can I actually watch tonight?
def tonight as tmdb.DiscoverFilter init tmdb.discoverFilter();
$tonight = tmdb.withGenres($tonight, [53]);
$tonight = tmdb.fromCountry($tonight, "KR");
$tonight = tmdb.ratedAtLeast($tonight, 7.0);
$tonight = tmdb.withMinVotes($tonight, 250);
$tonight = tmdb.availableOn($tonight, [8], "DE");
$tonight = tmdb.withMonetization($tonight, [tmdb.MONETIZATION_FLATRATE]);
$tonight = tmdb.sortedBy($tonight, tmdb.SORT_RATING_DESC);

io.printf("\nKorean thrillers streaming on Netflix in Germany\n");
for (def m in tmdb.discoverMoviesAll($c, $tonight, 2)) {
    io.printf("  %.1f  %-44s %s\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}
