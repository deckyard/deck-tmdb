#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# catalog example - collections, companies, networks, keywords, and the
# external-id bridge.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/catalog.j

use io;
use strings;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

# a film names its collection; the collection names its films
def film as tmdb.Movie init tmdb.movie($c, 11);
if ($film.belongsToCollection.id != 0) {
    def set as tmdb.Collection init tmdb.collection($c, $film.belongsToCollection.id);
    io.printf("%s - %d films, in release order\n", $set.name, len($set.parts));
    for (def part in $set.parts) {
        io.printf("  %-44s %s\n", $part.title, tmdb.year($part.releaseDate));
    }
}

def studio as tmdb.CompanyDetails init tmdb.company($c, 41077);
io.printf("\n%s, %s\n", $studio.name, $studio.headquarters);
io.printf("%s\n", $studio.homepage);
io.printf("also trades as: %s\n", strings.join(tmdb.companyAlternativeNames($c, $studio.id), ", "));

# networks are numbered in their own space: network 49 is not company 49
def hbo as tmdb.NetworkDetails init tmdb.network($c, 49);
io.printf("\n%s, %s - %s\n", $hbo.name, $hbo.headquarters, $hbo.homepage);

# keywords are far finer than genres
def tags as tmdb.KeywordPage init tmdb.searchKeywords($c, "time loop", 1);
def tag as tmdb.Keyword init $tags.results[0];
io.printf("\nfilms tagged \"%s\"\n", $tag.name);
for (def m in tmdb.keywordMovies($c, $tag.id, 1).results) {
    io.printf("  %-44s %s\n", $m.title, tmdb.year($m.releaseDate));
}

# a creditId dereferences to the person, the title and the connection
def credits as tmdb.Credits init tmdb.movieCredits($c, 550);
def one as tmdb.CreditDetail init tmdb.credit($c, $credits.cast[0].creditId);
io.printf("\n%s played %s in %s\n", $one.person.name, $one.character, $one.media.title);

# the bridge in from another catalogue
io.printf("\nresolving external ids\n");
for (def id in ["tt0076759", "tt0903747", "nm0000158"]) {
    def hits as tmdb.FindResults init tmdb.findByImdb($c, $id);
    if (len($hits.movies) > 0) {
        io.printf("  %-12s film   %s\n", $id, $hits.movies[0].title);
    } elseif (len($hits.shows) > 0) {
        io.printf("  %-12s series %s\n", $id, $hits.shows[0].title);
    } elseif (len($hits.people) > 0) {
        io.printf("  %-12s person %s\n", $id, $hits.people[0].title);
    } else {
        io.printf("  %-12s no match\n", $id);
    }
}
