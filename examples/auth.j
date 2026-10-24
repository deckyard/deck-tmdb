#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# auth example - the three-step v4 approval flow.
#
# Interactive: it prints a URL, waits for you to approve it in a browser,
# then trades the approved request token for a lasting access token.
# Nothing is written to your account.
#
#   TMDB_ACCESS_TOKEN=eyJ... jennifer run examples/auth.j

use io;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

# step 1 - a token waiting to be approved. Not a credential, and it
# expires after fifteen minutes, so mint it when the person is ready.
def pending as tmdb.RequestToken init tmdb.requestToken($c);
if (not $pending.success) {
    io.printf("TMDB refused: %s\n", $pending.statusMessage);
    exit 1;
}

# step 2 - the person approves it on themoviedb.org. approvalUrl sends
# nothing; it is a string builder.
io.printf(
    "open this, approve the request, then press return:\n\n  %s\n\n",
    tmdb.approvalUrl($pending.requestToken));
io.readLine();

# step 3 - trade it in. Still authenticated as the application: the
# approved request token is the evidence.
def granted as tmdb.AccessToken init tmdb.accessToken($c, $pending.requestToken);
if (not $granted.success) {
    io.printf("not approved yet: %s\n", $granted.statusMessage);
    exit 1;
}

io.printf("signed in\n");
io.printf("  account object id: %s\n", $granted.accountId);
io.printf("  access token:      %s...\n", $granted.accessToken);
io.printf("\nkeep both. The token does not expire - treat it like a password.\n");
io.printf("Later runs can skip this flow:\n");
io.printf("  TMDB_USER_TOKEN=<the token> jennifer run app.j\n");

# from here the client acts for that person
$c = tmdb.withUserToken($c, $granted.accessToken);
io.printf("\nacting for a user: %t\n", tmdb.hasUser($c));

def mine as tmdb.ListPage init tmdb.accountLists($c, $granted.accountId, 1);
io.printf("%d custom lists\n", $mine.totalResults);
for (def l in $mine.results) {
    io.printf("  %7d  %-28s %3d items\n", $l.id, $l.name, $l.numberOfItems);
}

# dropping the token locally leaves a working credential behind; end it
# at TMDB instead
tmdb.logout($c, $granted.accessToken);
io.printf("\nsigned out\n");
