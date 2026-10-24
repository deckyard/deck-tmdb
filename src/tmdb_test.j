# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# White-box unit tests for the tmdb module.
#
# Runs as the co-located test overlay: `jennifer test src/tmdb_test.j`.
# The tests are split into topic files under `topics/`, spliced together
# here with `include` - one test file per implementation topic file.
#
# Everything network-free is covered: the client builders, every argument
# check, the request plumbing that can be exercised without a socket
# (headers, query strings, the verbose transcript, error interpretation),
# the discovery filter's whole translation table, image and video URL
# building, and every routine that folds a TMDB reply into a struct - fed
# from response bodies copied out of TMDB's own documentation.
#
# The verbs themselves are thin compositions of these tested helpers over
# `apiGet` / `apiPost` / `apiPut` / `apiDelete`; what they add is one HTTP
# request, which is exercised against the live service rather than here.

use testing;
use maps;
use strings;

include "topics/core_test.j";
include "topics/model_test.j";
include "topics/images_test.j";
include "topics/search_test.j";
include "topics/discover_test.j";
include "topics/movies_test.j";
include "topics/shows_test.j";
include "topics/people_test.j";
include "topics/catalog_test.j";
include "topics/browse_test.j";
include "topics/auth_test.j";
include "topics/account_test.j";
include "topics/userlists_test.j";
