# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0
# pragma-jennifer-capability: net

/**
 * `tmdb` - a typed client for The Movie Database's HTTP API, v3 and v4.
 *
 * v4 has bearer authentication, the user approval flow, accounts and
 * custom lists, but no search or film details; v3 has the catalogue
 * (films, series, seasons, episodes, people, credits, images, videos,
 * genres, watch providers, discovery). The v4 read access token is a
 * bearer credential both accept, so one `Client` reaches both. Replies are
 * folded into value-semantic structs, and every failure is
 * `Error{kind: "tmdb"}`. `call`, `callPost`, `callPut` and `callDelete`
 * reach endpoints without a typed verb.
 *
 * The implementation is split into topic files spliced in with `include`;
 * this file is the module boundary. The white-box tests are in
 * `tmdb_test.j`.
 *
 * | topic | covers |
 * | --- | --- |
 * | `core` | the client, request plumbing, validation, JSON readers |
 * | `model` | the entity structs both generations share, and their folds |
 * | `images` | the `/configuration` endpoints, and image and video URLs |
 * | `search` | the seven `/search` endpoints |
 * | `discover` | `/discover/movie` and `/discover/tv` with a filter builder |
 * | `movies` | movie details, sub-resources and the curated lists |
 * | `shows` | series, seasons, episodes and the curated lists |
 * | `people` | person details and credits |
 * | `catalog` | collections, companies, networks, keywords, reviews, credits, find |
 * | `browse` | trending, genres, certifications, watch providers, changes |
 * | `auth` | the v4 request-token / access-token approval flow |
 * | `account` | the v4 per-account collections |
 * | `userlists` | v4 custom lists and their items |
 *
 * @module tmdb
 * @version 0.1.0
 * @license LGPL-3.0-only
 * @see https://developer.themoviedb.org/v4/reference/getting-started
 * @see https://developer.themoviedb.org/docs/getting-started
 * @example
 *   import "@deckyard/tmdb/" as tmdb;
 *
 *   def c as tmdb.Client init tmdb.clientFromEnv();
 *   def hits as tmdb.MoviePage init tmdb.searchMovies($c, "blade runner", 1);
 *   for (def m in $hits.results) {
 *       io.printf("%s (%s)\n", $m.title, tmdb.year($m.releaseDate));
 *   }
 *
 *   def film as tmdb.Movie init tmdb.movie($c, $hits.results[0].id);
 *   io.printf("%d min, %s\n", $film.runtime, $film.tagline);
 */

use strings;
use lists;
use maps;
use convert;
use json;
use io;
use os;

import "rest.j" as rest;
import "http.j" as http;
import "uri.j" as uri;

include "topics/core.j";
include "topics/model.j";
include "topics/images.j";
include "topics/search.j";
include "topics/discover.j";
include "topics/movies.j";
include "topics/shows.j";
include "topics/people.j";
include "topics/catalog.j";
include "topics/browse.j";
include "topics/auth.j";
include "topics/account.j";
include "topics/userlists.j";
