#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# core example - building a client, tuning it, verbose mode, and the
# generic escape hatch.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/core.j

use io;
use json;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
io.printf("reaches v4: %t, acting for a user: %t\n", tmdb.hasBearer($c), tmdb.hasUser($c));

# every builder returns a copy - keep the result
$c = tmdb.withLanguage($c, "de-DE");
$c = tmdb.withRegion($c, "DE");
$c = tmdb.withTimeout($c, 10000);
$c = tmdb.withRetries($c, 3);
$c = tmdb.withBackoff($c, 1000);
$c = tmdb.setVerbose($c, true);

# verbose prints one line per request; the bearer token rides in a header
# and never appears, and an api_key parameter prints as <redacted>
def film as tmdb.Movie init tmdb.movie($c, 550);
io.printf("%s (%s)\n", $film.title, tmdb.year($film.releaseDate));
io.printf("%s\n", $film.overview);

# the escape hatch: any path, decoded but not folded
def raw as json.Value init tmdb.call($c, "/3/movie/550/lists", {"page": "1"});
io.printf("in %d public lists\n", json.asInt($raw, "/total_results"));

# an unsafe path is refused before anything is sent
try {
    tmdb.call($c, "/3/../4/account/x/lists", {});
} catch (e) {
    io.printf("refused: %s\n", $e.message);
}
