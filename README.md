# @deckyard/tmdb

[![test](https://github.com/deckyard/deck-tmdb/actions/workflows/test.yml/badge.svg)](https://github.com/deckyard/deck-tmdb/actions/workflows/test.yml)
[![Documentation](https://img.shields.io/badge/docs-github%20pages-blue)](https://deckyard.github.io/deck-tmdb/)
[![release](https://img.shields.io/github/v/release/deckyard/deck-tmdb)](https://github.com/deckyard/deck-tmdb/releases/latest)

A typed [Jennifer](https://jennifer-lang.dev) client for
[The Movie Database](https://www.themoviedb.org). One `Client` reaches both
API generations: the v3 catalogue (search, discovery, films, series, people,
images, watch providers) and v4 user authentication, accounts and custom
lists. Replies are folded into structs, arguments are checked before the
request, and every failure is `Error{kind: "tmdb"}`.

## Install

```sh
jvc add @deckyard/tmdb
```

Or unpack `src/` from a release archive (`deckyard-tmdb-<version>.tar.gz`) into
`vendor/deckyard/tmdb/`.

Requires Jennifer 0.25.0 or newer and the default `jennifer` binary: the deck
declares the `net` capability, which `jennifer-tiny` lacks.

## Example

```jennifer
use io;
import "@deckyard/tmdb/" as tmdb;

# TMDB_ACCESS_TOKEN=eyJ... jennifer run app.j
def c as tmdb.Client init tmdb.clientFromEnv();
def hits as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);

for (def m in $hits.results) {
    io.printf("%s (%s)  %.1f\n", $m.title, tmdb.year($m.releaseDate), $m.voteAverage);
}

def film as tmdb.MovieBundle init tmdb.movieBundle($c, $hits.results[0].id);
io.printf("%d min, directed by %s\n", $film.movie.runtime, tmdb.directorOf($film.credits));
```

The token is the long `eyJ...` **API Read Access Token** from
<https://www.themoviedb.org/settings/api>, not the 32-character API key; see
[Getting started](https://deckyard.github.io/deck-tmdb/getting-started.html).

## Documentation

[deckyard.github.io/deck-tmdb](https://deckyard.github.io/deck-tmdb/), with
every export in the
[cheatsheet](https://deckyard.github.io/deck-tmdb/cheatsheet.html). Runnable
programs are in [`examples/`](examples). `tools/check-all.sh` runs the CI gate.

## Licence

LGPL-3.0-only, see [LICENSE](LICENSE). Copyright (C) 2026 mplx &lt;mplx@jennifer-lang.dev&gt;.

This product uses the TMDB API but is **not endorsed or certified by TMDB**.
Using the API means agreeing to its
[terms of use](https://www.themoviedb.org/api-terms-of-use), which require
attribution in any application built on it. The watch-provider data is
JustWatch's and carries its own attribution requirement.
