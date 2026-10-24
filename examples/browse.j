#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# browse example - trending, the genre and certification vocabularies,
# watch providers, and the change feed.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/browse.j

use io;
use strings;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

io.printf("trending today\n");
for (def item in tmdb.trendingAll($c, tmdb.TREND_DAY, 1).results) {
    io.printf(
        "  %-8s %-44s %s\n",
        tmdb.mediaKindName($item.kind),
        $item.title,
        tmdb.year($item.releaseDate));
}

# fetch the genre list once and resolve ids against it, not per row
def index as map of string to string init tmdb.genreIndex(tmdb.movieGenres($c));
io.printf("\npopular films, with their genres named\n");
for (def m in tmdb.popularMovies($c, 1).results) {
    io.printf("  %-40s %s\n", $m.title, strings.join(tmdb.genreNames($index, $m.genreIds), ", "));
}

io.printf("\nGerman film certifications, gentlest first\n");
for (def rating in tmdb.certificationsIn(tmdb.movieCertifications($c), "DE")) {
    io.printf("  %-6s %d  %s\n", $rating.certification, $rating.order, $rating.meaning);
}

io.printf("\nthe first ten streaming services in Germany\n");
def shown as int init 0;
for (def p in tmdb.movieProviders($c, "DE")) {
    if ($shown >= 10) {
        break;
    }
    io.printf("  %4d %s\n", $p.providerId, $p.providerName);
    $shown = $shown + 1;
}

# the feed a mirror runs off: an id and an adult flag, nothing more
def changed as tmdb.ChangePage init tmdb.changedMovies($c, "", "", 1);
io.printf("\n%d films changed in the last 24 hours\n", $changed.totalResults);
