#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# account example - a signed-in person's collections.
#
# Read-only, but it needs a user access token and the account object id
# that came back with it - run examples/auth.j to mint one.
#
#   TMDB_ACCESS_TOKEN=eyJ... TMDB_USER_TOKEN=eyJ... \
#   TMDB_ACCOUNT_ID=4bc8892a017a3c0f92000002 jennifer run examples/account.j

use io;
use os;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
def id as string init os.getEnv("TMDB_ACCOUNT_ID");

if (not tmdb.hasUser($c) or $id == "") {
    io.printf("set TMDB_USER_TOKEN and TMDB_ACCOUNT_ID - see examples/auth.j\n");
    exit 1;
}

def watchlist as tmdb.MoviePage init tmdb.watchlistMovies($c, $id, 1, tmdb.ACCOUNT_SORT_ADDED_DESC);
io.printf("watchlist: %d films\n", $watchlist.totalResults);
for (def m in $watchlist.results) {
    io.printf("  %-44s %s\n", $m.title, tmdb.year($m.releaseDate));
}

def favourites as tmdb.MoviePage init tmdb.favoriteMovies(
    $c,
    $id,
    1,
    tmdb.ACCOUNT_SORT_RATING_DESC);
io.printf("\nfavourites: %d films\n", $favourites.totalResults);
for (def m in $favourites.results) {
    io.printf("  %.1f  %s\n", $m.voteAverage, $m.title);
}

def rated as tmdb.ShowPage init tmdb.ratedShows($c, $id, 1, "");
io.printf("\nrated: %d series\n", $rated.totalResults);

# personal, unlike movieRecommendations: computed from everything the
# account has rated, favourited and listed
io.printf("\nrecommended for you\n");
for (def m in tmdb.recommendedMovies($c, $id, 1).results) {
    io.printf("  %.1f  %-44s %s\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}

# the v3 account id is a different thing, and saying so is worth doing
try {
    tmdb.favoriteMovies($c, "548", 1, "");
} catch (e) {
    io.printf("\nrefused: %s\n", $e.message);
}
