#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# shows example - a series, its seasons, one episode, and rolled-up credits.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/shows.j

use io;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

def b as tmdb.ShowBundle init tmdb.showBundle($c, 1399);
def s as tmdb.Show init $b.show;

io.printf("%s (%s-%s)\n", $s.name, tmdb.year($s.firstAirDate), tmdb.year($s.lastAirDate));
io.printf(
    "%s - %d seasons, %d episodes, on %s\n",
    $s.status,
    $s.numberOfSeasons,
    $s.numberOfEpisodes,
    $s.networks[0].name);
io.printf("rated %s in the US\n", tmdb.contentRatingOf($b.contentRatings, "US"));
io.printf("TheTVDB id %d\n\n", $b.externalIds.tvdbId);

# `seasons` is the index into the rest of the catalogue
for (def entry in $s.seasons) {
    io.printf("  %-12s %3d episodes  %s\n", $entry.name, $entry.episodeCount, $entry.airDate);
}

# reach one by number, not by index - season 0 is only there when it exists
def first as tmdb.SeasonSummary init tmdb.seasonOf($s, 1);
io.printf("\nseason 1 has %d episodes\n", $first.episodeCount);

def one as tmdb.Season init tmdb.season($c, $s.id, 1);
for (def e in $one.episodes) {
    io.printf(
        "  %dx%02d  %-36s %s  %.1f\n",
        $e.seasonNumber,
        $e.episodeNumber,
        $e.name,
        $e.airDate,
        $e.voteAverage);
}

# aggregate credits are the only cast list that means anything for a long run
io.printf("\nmost-seen performers\n");
def shown as int init 0;
for (def actor in $b.credits.cast) {
    if ($shown >= 8) {
        break;
    }
    io.printf(
        "  %-24s %-28s %3d episodes\n",
        $actor.name,
        $actor.roles[0].character,
        $actor.totalEpisodeCount);
    $shown = $shown + 1;
}

# guest stars land in `cast` at episode level
def pilot as tmdb.Credits init tmdb.episodeCredits($c, $s.id, 1, 1);
io.printf("\nthe pilot credits %d performers and %d crew\n", len($pilot.cast), len($pilot.crew));

io.printf("\nairing today in Berlin\n");
for (def row in tmdb.airingTodayIn($c, "Europe/Berlin", 1).results) {
    io.printf("  %s\n", $row.name);
}
