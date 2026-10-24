#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# images example - the configuration, and turning a path into a URL.
#
# Read-only.
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/images.j

use io;
use strings;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

# fetch this once and keep it - every image URL needs it
def cfg as tmdb.Configuration init tmdb.configuration($c);
io.printf("host:     %s\n", $cfg.secureBaseUrl);
io.printf("posters:  %s\n", strings.join($cfg.posterSizes, " "));
io.printf("profiles: %s\n", strings.join($cfg.profileSizes, " "));
io.printf("stills:   %s\n", strings.join($cfg.stillSizes, " "));

# no request at all, for a script or a first paint
def offline as tmdb.Configuration init tmdb.defaultConfiguration();
io.printf("\noffline:  %s\n", tmdb.posterUrl($offline, "/pB8.jpg", "w342"));

def film as tmdb.Movie init tmdb.movie($c, 550);
io.printf("\nposter:   %s\n", tmdb.posterUrl($cfg, $film.posterPath, "w500"));
io.printf("backdrop: %s\n", tmdb.backdropUrl($cfg, $film.backdropPath, "w1280"));

# an empty path gives "" rather than a URL that would 404
io.printf("missing:  \"%s\"\n", tmdb.posterUrl($cfg, "", "w500"));

# sizes are per kind, and asking for the wrong one says which would work
try {
    tmdb.profileUrl($cfg, "/x.jpg", "w342");
} catch (e) {
    io.printf("\nrefused: %s\n", $e.message);
}

# an images call answers every localized version, ordered by user rating
io.printf("\nposters, best rated first\n");
def images as tmdb.Images init tmdb.movieImages($c, 550);
def shown as int init 0;
for (def poster in $images.posters) {
    if ($shown >= 5) {
        break;
    }
    io.printf(
        "  %-4s %.1f (%3d votes)  %s\n",
        $poster.language,
        $poster.voteAverage,
        $poster.voteCount,
        tmdb.posterUrl($cfg, $poster.filePath, "w185"));
    $shown = $shown + 1;
}

# TMDB hosts no video - a Video is a site and a key
io.printf("\nvideos\n");
for (def v in tmdb.movieVideos($c, 550)) {
    io.printf("  %-10s %-36s %s\n", $v.kind, $v.name, tmdb.videoUrl($v));
}
