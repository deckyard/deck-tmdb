#!/usr/bin/env -S jennifer run
# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# lists example - the deck's only writing verbs.
#
# WRITES to your TMDB account: it creates a list, fills it, edits it, then
# deletes it again. Needs a user access token - run examples/auth.j.
#
#   TMDB_ACCESS_TOKEN=eyJ... TMDB_USER_TOKEN=eyJ... jennifer run examples/lists.j

use io;

import "../src/tmdb.j" as tmdb;

def c as tmdb.Client init tmdb.clientFromEnv();

if (not tmdb.hasUser($c)) {
    io.printf("set TMDB_USER_TOKEN - see examples/auth.j\n");
    exit 1;
}

def made as tmdb.StatusResponse init tmdb.createList(
    $c,
    "deck-tmdb example",
    "created by examples/lists.j - safe to delete",
    false);
def listId as int init $made.id;
io.printf("created list %d\n", $listId);

# bulk: one request, and the per-item results say what landed
def added as tmdb.ItemsResponse init tmdb.addListItems(
    $c,
    $listId,
    [
        tmdb.listItem(tmdb.MediaKind.Movie, 550),
        tmdb.listItem(tmdb.MediaKind.Movie, 680),
        tmdb.listItem(tmdb.MediaKind.Show, 1399)
    ]);
io.printf("\nadd: %s\n", $added.statusMessage);
for (def outcome in $added.results) {
    io.printf("  %-6s %7d  %t\n", tmdb.mediaKindName($outcome.kind), $outcome.id, $outcome.success);
}

# a list holds films and series and nothing else
try {
    tmdb.listItem(tmdb.MediaKind.Person, 31);
} catch (e) {
    io.printf("\nrefused: %s\n", $e.message);
}

# one reply carries the metadata and one page of the contents
def l as tmdb.ListDetails init tmdb.listDetails($c, $listId, 1);
io.printf("\n%s by %s - %d items\n", $l.name, $l.createdByUsername, $l.itemCount);
for (def item in $l.results) {
    io.printf(
        "  %-6s %-40s %s\n",
        tmdb.mediaKindName($item.kind),
        $item.title,
        tmdb.year($item.releaseDate));
}

# what an "add to list" button should check before offering itself
def present as tmdb.ItemStatus init tmdb.listItemStatus($c, $listId, tmdb.MediaKind.Movie, 550);
io.printf("\nFight Club already in the list: %t\n", $present.success);

tmdb.removeListItems($c, $listId, [tmdb.listItem(tmdb.MediaKind.Movie, 680)]);
io.printf("removed one\n");

# updateList replaces all four editable fields, so read before you write
tmdb.updateList($c, $listId, $l.name, "edited", true, tmdb.LIST_SORT_RELEASE_DESC);
io.printf("renamed and made public\n");

tmdb.clearList($c, $listId);
io.printf("cleared\n");

tmdb.deleteList($c, $listId);
io.printf("deleted list %d\n", $listId);
