#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# people example - a person, their filmography, and their photographs.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/people.j

use io;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();
def cfg as tmdb.Configuration init tmdb.configuration($c);

def found as tmdb.PersonPage init tmdb.searchPeople($c, "greta gerwig", 1);
if (len($found.results) == 0) {
    io.printf("nobody found\n");
    exit 1;
}

def b as tmdb.PersonBundle init tmdb.personBundle($c, $found.results[0].id);
def p as tmdb.Person init $b.person;

io.printf(
    "%s (%s), born %s in %s\n",
    $p.name,
    tmdb.genderName($p.gender),
    $p.birthday,
    $p.placeOfBirth);
io.printf("known for %s\n", $p.knownForDepartment);
io.printf("imdb: https://www.imdb.com/name/%s/\n", $b.externalIds.imdbId);
if ($b.externalIds.instagramId != "") {
    io.printf("instagram: @%s\n", $b.externalIds.instagramId);
}
io.printf("\n%s\n", $p.biography);

# a filmography is unordered and mixes every job - narrow it
io.printf("\ndirected\n");
for (def one in tmdb.creditsInDepartment($b.credits, "Directing")) {
    io.printf("  %-40s %s\n", $one.title, tmdb.year($one.releaseDate));
}

io.printf("\nappeared in\n");
def shown as int init 0;
for (def role in $b.credits.cast) {
    if ($shown >= 10) {
        break;
    }
    io.printf("  %-40s %-24s %s\n", $role.title, $role.character, tmdb.year($role.releaseDate));
    $shown = $shown + 1;
}

io.printf("\nphotographs\n");
for (def photo in $b.images.profiles) {
    io.printf(
        "  %dx%d  %s\n",
        $photo.width,
        $photo.height,
        tmdb.profileUrl($cfg, $photo.filePath, "w185"));
}
