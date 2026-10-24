#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# movies example - one film, its bundle, its ratings and where to watch it.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/movies.j

use io;
use strings;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.withRegion(tmdb.clientFromEnv(), "DE");
def cfg as tmdb.Configuration init tmdb.configuration($c);

# one request for the whole detail page: film + nine sub-resources
def b as tmdb.MovieBundle init tmdb.movieBundle($c, 550);

io.printf("%s (%s)\n", $b.movie.title, tmdb.year($b.movie.releaseDate));
io.printf(
    "%d min, %s, directed by %s\n",
    $b.movie.runtime,
    $b.movie.status,
    tmdb.directorOf($b.credits));
io.printf("%s\n", $b.movie.tagline);
io.printf("%s\n\n", $b.movie.overview);

def genres as list of string init [];
for (def g in $b.movie.genres) {
    $genres[] = $g.name;
}
io.printf("genres:  %s\n", strings.join($genres, ", "));
io.printf("poster:  %s\n", tmdb.posterUrl($cfg, $b.movie.posterPath, "w500"));
io.printf("imdb:    https://www.imdb.com/title/%s/\n", $b.externalIds.imdbId);

io.printf("\ntop billing\n");
def shown as int init 0;
for (def actor in $b.credits.cast) {
    if ($shown >= 6) {
        break;
    }
    io.printf("  %-24s %s\n", $actor.name, $actor.character);
    $shown = $shown + 1;
}

io.printf("\ntrailers\n");
for (def v in $b.videos) {
    if ($v.kind == "Trailer") {
        io.printf("  %-40s %s\n", $v.name, tmdb.videoUrl($v));
    }
}

# release dates carry the age ratings, one per country
def groups as list of tmdb.ReleaseGroup init tmdb.movieReleaseDates($c, 550);
io.printf(
    "\nrated %s in the US, %s in Germany\n",
    tmdb.certificationOf($groups, "US"),
    tmdb.certificationOf($groups, "DE"));

# offersIn is safe to walk even where there are no offers at all
def here as tmdb.WatchOffers init tmdb.offersIn($b.watchOffers, "DE");
io.printf(
    "\nin Germany: %d subscription, %d rental, %d purchase services\n",
    len($here.flatrate),
    len($here.rent),
    len($here.buy));
for (def p in $here.flatrate) {
    io.printf("  %s\n", $p.providerName);
}

io.printf("\nin cinemas here now\n");
for (def m in tmdb.nowPlaying($c, 1).results) {
    io.printf("  %-44s %s\n", $m.title, tmdb.year($m.releaseDate));
}
