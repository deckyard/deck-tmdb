# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - v4 custom lists: create, read, edit, and the items in them.
# Spliced into tmdb.j via include - not a standalone module.
#
# The verbs that write (create, update, delete, clear, add, remove) need a
# user access token. `listDetails`, `listItemsAll` and `listItemStatus` read
# a public list with the application token; a private list needs its
# owner's token.
#
# A list holds films and series, whose id spaces overlap (550 is both a
# film and a series), so every item is a `MediaKind` and id pair.

/**
 * List sort: the order items were added, oldest first. The default.
 */
export def const LIST_SORT_ORIGINAL_ASC as string init "original_order.asc";

/**
 * List sort: the order items were added, newest first.
 */
export def const LIST_SORT_ORIGINAL_DESC as string init "original_order.desc";

/**
 * List sort: worst rated first.
 */
export def const LIST_SORT_RATING_ASC as string init "vote_average.asc";

/**
 * List sort: best rated first.
 */
export def const LIST_SORT_RATING_DESC as string init "vote_average.desc";

/**
 * List sort: oldest title first.
 */
export def const LIST_SORT_RELEASE_ASC as string init "primary_release_date.asc";

/**
 * List sort: newest title first.
 */
export def const LIST_SORT_RELEASE_DESC as string init "primary_release_date.desc";

/**
 * List sort: alphabetical.
 */
export def const LIST_SORT_TITLE_ASC as string init "title.asc";

/**
 * List sort: reverse alphabetical.
 */
export def const LIST_SORT_TITLE_DESC as string init "title.desc";

/**
 * A title to add to or remove from a list: a kind and an id.
 *
 * Build one with `listItem`.
 *
 * @field kind {MediaKind} `MediaKind.Movie` or `MediaKind.Show`
 * @field id {int} the title's id in that catalogue
 */
export def struct ListItem {
    kind as MediaKind,
    id as int
};

/**
 * A custom list's metadata and one page of its items.
 *
 * `results` is page `page` only: TMDB answers 20 items at a time.
 *
 * @field id {int} the list id
 * @field name {string} the list's name
 * @field description {string} the list's description, often ""
 * @field public {bool} whether anyone can read it
 * @field sortBy {string} the list's own ordering, a `LIST_SORT_*` value
 * @field region {string} the list's ISO 3166-1 country
 * @field language {string} the list's ISO 639-1 language
 * @field itemCount {int} how many titles the list holds in total
 * @field averageRating {float} the mean rating of its titles
 * @field revenue {int} the combined box office of its films
 * @field runtime {int} the combined runtime of its titles, in minutes
 * @field posterPath {string} an image path for `posterUrl`, "" when unset
 * @field backdropPath {string} an image path for `backdropUrl`, "" when unset
 * @field createdByName {string} the owner's display name
 * @field createdByUsername {string} the owner's TMDB username
 * @field page {int} which page of items this is
 * @field totalPages {int} how many pages of items there are
 * @field totalResults {int} how many items there are
 * @field results {list of MediaItem} this page's items
 */
export def struct ListDetails {
    id as int,
    name as string,
    description as string,
    public as bool,
    sortBy as string,
    region as string,
    language as string,
    itemCount as int,
    averageRating as float,
    revenue as int,
    runtime as int,
    posterPath as string,
    backdropPath as string,
    createdByName as string,
    createdByUsername as string,
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of MediaItem
};

/**
 * What happened to one item in a bulk add or remove.
 *
 * @field kind {MediaKind} the item's kind
 * @field id {int} the item's id
 * @field success {bool} whether that item was added or removed
 */
export def struct ItemOutcome {
    kind as MediaKind,
    id as int,
    success as bool
};

/**
 * TMDB's answer to a bulk add or remove, with one outcome per item.
 *
 * The request can succeed while single items fail, for example a title
 * already in the list.
 *
 * @field success {bool} whether the request as a whole succeeded
 * @field statusCode {int} TMDB's status code
 * @field statusMessage {string} TMDB's status text
 * @field results {list of ItemOutcome} what happened to each item
 */
export def struct ItemsResponse {
    success as bool,
    statusCode as int,
    statusMessage as string,
    results as list of ItemOutcome
};

/**
 * Whether one title is in a list, from `listItemStatus`.
 *
 * @field success {bool} true when the title is in the list
 * @field listId {int} the list that was checked
 * @field mediaId {int} the title that was checked
 * @field kind {MediaKind} that title's kind
 * @field statusCode {int} TMDB's status code
 * @field statusMessage {string} TMDB's status text
 */
export def struct ItemStatus {
    success as bool,
    listId as int,
    mediaId as int,
    kind as MediaKind,
    statusCode as int,
    statusMessage as string
};

/**
 * Build a `ListItem`, checking the kind and id.
 *
 * @param kind {MediaKind} `MediaKind.Movie` or `MediaKind.Show`
 * @param id {int} the title's id in that catalogue
 * @return {ListItem} the pair
 * @throws {Error} kind "tmdb" on a non-positive id or a kind a list cannot hold
 */
export func listItem(kind as MediaKind, id as int) {
    ensureListKind($kind);
    return ListItem{kind: $kind, id: ensureId($id, "media")};
}

/**
 * Create a custom list (writes).
 *
 * The new list's id comes back as `StatusResponse.id`.
 *
 * @param c {Client} an API client carrying a user access token
 * @param name {string} the list's name
 * @param description {string} the list's description, "" for none
 * @param isPublic {bool} whether anyone may read it
 * @return {StatusResponse} TMDB's answer, with the new list's `id`
 * @throws {Error} kind "tmdb" without a user token, on a blank name, or on a
 *                 transport failure
 */
export func createList(c as Client, name as string, description as string, isPublic as bool) {
    return createListIn($c, $name, $description, $isPublic, "", "");
}

/**
 * Create a custom list with its own language and country (writes).
 *
 * The list's language decides which translation of its titles TMDB's
 * website shows, whoever reads it. The language is sent lowercased, the
 * country uppercased.
 *
 * @param c {Client} an API client carrying a user access token
 * @param name {string} the list's name
 * @param description {string} the list's description, "" for none
 * @param isPublic {bool} whether anyone may read it
 * @param language {string} an ISO 639-1 code, "" for the account's default
 * @param region {string} a two-letter ISO 3166-1 code, "" for the default
 * @return {StatusResponse} TMDB's answer, with the new list's `id`
 * @throws {Error} kind "tmdb" without a user token, on a blank name, a bad
 *                 language or region, or on a transport failure
 */
export func createListIn(
    c as Client,
    name as string,
    description as string,
    isPublic as bool,
    language as string,
    region as string) {
    requireUser($c, "createList");
    def body as json.Value init json.set(json.map(), "/name", ensureText($name, "list name"));
    $body = json.set($body, "/description", strings.trim($description));
    $body = json.set($body, "/public", $isPublic);
    def lang as string init strings.trim($language);
    if ($lang != "") {
        if (not isLanguageTag($lang)) {
            raiseError("the list language must look like \"en\", got \"" + $lang + "\"");
        }
        $body = json.set($body, "/iso_639_1", strings.lower($lang));
    }
    def code as string init strings.upper(strings.trim($region));
    if ($code != "") {
        if (not isCountryCode($code)) {
            raiseError("the list country must be two letters, got \"" + $code + "\"");
        }
        $body = json.set($body, "/iso_3166_1", $code);
    }
    return statusFrom(apiPost($c, "/4/list", $body));
}

/**
 * A list's metadata and one page of its items.
 *
 * A public list reads with the application token; a private one needs its
 * owner's user token.
 *
 * @param c {Client} an API client
 * @param listId {int} the list id
 * @param page {int} the page of items to fetch, 1-based
 * @return {ListDetails} the list's metadata and that page of items
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, a list you
 *                 may not read, or a transport failure
 */
export func listDetails(c as Client, listId as int, page as int) {
    def params as map of string to string init pageParams($c, $page);
    return listDetailsFrom(apiGet($c, listPath($listId, ""), $params));
}

/**
 * Fold a list-details reply.
 *
 * @param reply {json.Value} the reply
 * @return {ListDetails} the list's metadata and this page of its items
 * @internal
 */
func listDetailsFrom(reply as json.Value) {
    return ListDetails{
        id: nodeInt($reply, "/id"),
        name: nodeString($reply, "/name"),
        description: nodeString($reply, "/description"),
        public: nodeBool($reply, "/public"),
        sortBy: nodeString($reply, "/sort_by"),
        region: nodeString($reply, "/iso_3166_1"),
        language: nodeString($reply, "/iso_639_1"),
        itemCount: nodeInt($reply, "/item_count"),
        averageRating: nodeFloat($reply, "/average_rating"),
        revenue: nodeInt($reply, "/revenue"),
        runtime: nodeInt($reply, "/runtime"),
        posterPath: nodeString($reply, "/poster_path"),
        backdropPath: nodeString($reply, "/backdrop_path"),
        createdByName: nodeString($reply, "/created_by/name"),
        createdByUsername: nodeString($reply, "/created_by/username"),
        page: nodeInt($reply, "/page"),
        totalPages: nodeInt($reply, "/total_pages"),
        totalResults: nodeInt($reply, "/total_results"),
        results: mediaItemsFrom($reply, "/results", MediaKind.Unknown)
    };
}

/**
 * Replace a list's name, description, visibility and sort order (writes).
 *
 * Name, description and visibility are always sent, so pass the current
 * values for the ones you keep; read the list first. Only the sort order
 * is left alone when "".
 *
 * @param c {Client} an API client carrying a user access token
 * @param listId {int} the list id
 * @param name {string} the list's new name
 * @param description {string} the list's new description, "" for none
 * @param isPublic {bool} whether anyone may read it
 * @param sortBy {string} a `LIST_SORT_*` constant, "" to leave it alone
 * @return {StatusResponse} TMDB's answer
 * @throws {Error} kind "tmdb" without a user token, on a bad id, a blank
 *                 name, an unknown sort, or a transport failure
 */
export func updateList(
    c as Client,
    listId as int,
    name as string,
    description as string,
    isPublic as bool,
    sortBy as string) {
    requireUser($c, "updateList");
    def body as json.Value init json.set(json.map(), "/name", ensureText($name, "list name"));
    $body = json.set($body, "/description", strings.trim($description));
    $body = json.set($body, "/public", $isPublic);
    def sort as string init strings.trim($sortBy);
    if ($sort != "") {
        $body = json.set($body, "/sort_by", ensureListSort($sort));
    }
    return statusFrom(apiPut($c, listPath($listId, ""), $body));
}

/**
 * Delete a list (writes).
 *
 * Irreversible; TMDB asks for no confirmation.
 *
 * @param c {Client} an API client carrying a user access token
 * @param listId {int} the list id
 * @return {StatusResponse} TMDB's answer
 * @throws {Error} kind "tmdb" without a user token, on a non-positive id, or
 *                 on a transport failure
 */
export func deleteList(c as Client, listId as int) {
    requireUser($c, "deleteList");
    return statusFrom(apiDelete($c, listPath($listId, ""), json.map()));
}

/**
 * Remove every item from a list, keeping the list (writes).
 *
 * TMDB defines this as a `GET` on `/4/list/{id}/clear`, so a prefetching
 * or retrying layer can trigger it.
 *
 * @param c {Client} an API client carrying a user access token
 * @param listId {int} the list id
 * @return {StatusResponse} TMDB's answer
 * @throws {Error} kind "tmdb" without a user token, on a non-positive id, or
 *                 on a transport failure
 */
export func clearList(c as Client, listId as int) {
    requireUser($c, "clearList");
    return statusFrom(apiGet($c, listPath($listId, "/clear"), {}));
}

/**
 * Add titles to a list in one request (writes).
 *
 * `results` says which titles landed. A title already in the list is a
 * failed item, not a failed request.
 *
 * @param c {Client} an API client carrying a user access token
 * @param listId {int} the list id
 * @param items {list of ListItem} the titles, from `listItem`
 * @return {ItemsResponse} the overall answer and the per-item outcomes
 * @throws {Error} kind "tmdb" without a user token, on a bad id, an empty
 *                 item list, or a transport failure
 * @example
 *   def added as tmdb.ItemsResponse init tmdb.addListItems($c, $listId, [
 *       tmdb.listItem(tmdb.MediaKind.Movie, 550),
 *       tmdb.listItem(tmdb.MediaKind.Show, 1399)]);
 */
export func addListItems(c as Client, listId as int, items as list of ListItem) {
    requireUser($c, "addListItems");
    return itemsResponseFrom(apiPost($c, listPath($listId, "/items"), itemsBody($items)));
}

/**
 * Remove titles from a list in one request (writes).
 *
 * @param c {Client} an API client carrying a user access token
 * @param listId {int} the list id
 * @param items {list of ListItem} the titles, from `listItem`
 * @return {ItemsResponse} the overall answer and the per-item outcomes
 * @throws {Error} kind "tmdb" without a user token, on a bad id, an empty
 *                 item list, or a transport failure
 */
export func removeListItems(c as Client, listId as int, items as list of ListItem) {
    requireUser($c, "removeListItems");
    return itemsResponseFrom(apiDelete($c, listPath($listId, "/items"), itemsBody($items)));
}

/**
 * Whether one title is in a list, without paging through it.
 *
 * @param c {Client} an API client
 * @param listId {int} the list id
 * @param kind {MediaKind} `MediaKind.Movie` or `MediaKind.Show`
 * @param mediaId {int} the title's id in that catalogue
 * @return {ItemStatus} whether it is in the list
 * @throws {Error} kind "tmdb" on a bad id, a kind a list cannot hold, or a
 *                 transport failure
 */
export func listItemStatus(c as Client, listId as int, kind as MediaKind, mediaId as int) {
    ensureListKind($kind);
    def params as map of string to string init {
        "media_type": mediaKindName($kind),
        "media_id": convert.toString(ensureId($mediaId, "media"))
    };
    return itemStatusFrom(apiGet($c, listPath($listId, "/item_status"), $params));
}

/**
 * Fold an item-status reply.
 *
 * @param v {json.Value} the reply
 * @return {ItemStatus} whether the title is in the list
 * @internal
 */
func itemStatusFrom(v as json.Value) {
    return ItemStatus{
        success: nodeBool($v, "/success"),
        listId: nodeInt($v, "/id"),
        mediaId: nodeInt($v, "/media_id"),
        kind: parseMediaKind(nodeString($v, "/media_type")),
        statusCode: nodeInt($v, "/status_code"),
        statusMessage: nodeString($v, "/status_message")
    };
}

/**
 * Every item in a list, fetched page by page up to a budget.
 *
 * Stops at the last page, at `maxPages`, or at `MAX_PAGE`. One request
 * per page of 20.
 *
 * @param c {Client} an API client
 * @param listId {int} the list id
 * @param maxPages {int} how many pages to fetch at most
 * @return {list of MediaItem} the items, in the list's own order
 * @throws {Error} kind "tmdb" on a bad id, a non-positive budget, or a
 *                 transport failure
 */
export func listItemsAll(c as Client, listId as int, maxPages as int) {
    ensureBudget($maxPages);
    def out as list of MediaItem init [];
    def page as int init 1;
    while (true) {
        def batch as ListDetails init listDetails($c, $listId, $page);
        for (def item in $batch.results) {
            $out[] = $item;
        }
        if ($page >= $maxPages or not morePages($batch.page, $batch.totalPages)) {
            return $out;
        }
        $page = $page + 1;
    }
    return $out;
}

/**
 * The path of a list or one of its sub-resources.
 *
 * @param listId {int} the list id
 * @param suffix {string} the sub-resource, e.g. "/items"; "" for the list
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func listPath(listId as int, suffix as string) {
    return "/4/list/" + convert.toString(ensureId($listId, "list")) + $suffix;
}

/**
 * Build the `{items: [...]}` body the add and remove verbs take.
 *
 * @param items {list of ListItem} the titles
 * @return {json.Value} the request body
 * @throws {Error} kind "tmdb" when the list is empty
 * @internal
 */
func itemsBody(items as list of ListItem) {
    if (len($items) == 0) {
        raiseError("at least one item is required - build them with listItem()");
    }
    def rows as json.Value init json.list();
    for (def item in $items) {
        ensureListKind($item.kind);
        def row as json.Value init json.set(json.map(), "/media_type", mediaKindName($item.kind));
        $row = json.set($row, "/media_id", ensureId($item.id, "media"));
        $rows = json.append($rows, "", $row);
    }
    return json.set(json.map(), "/items", $rows);
}

/**
 * Refuse a media kind a list cannot hold.
 *
 * TMDB answers a person, season or episode with an unexplained 422.
 *
 * @param kind {MediaKind} the candidate kind
 * @throws {Error} kind "tmdb" for anything but `Movie` and `Show`
 * @internal
 */
func ensureListKind(kind as MediaKind) {
    if ($kind == MediaKind.Movie or $kind == MediaKind.Show) {
        return;
    }
    raiseError("a list holds films and series - MediaKind.Movie or MediaKind.Show, not " +
        "\"" + mediaKindName($kind) + "\"");
}

/**
 * Refuse a sort order a list does not accept.
 *
 * @param sortBy {string} the candidate sort
 * @return {string} the same sort
 * @throws {Error} kind "tmdb" when it is not a `LIST_SORT_*` value
 * @internal
 */
func ensureListSort(sortBy as string) {
    def known as list of string init [
        LIST_SORT_ORIGINAL_ASC,
        LIST_SORT_ORIGINAL_DESC,
        LIST_SORT_RATING_ASC,
        LIST_SORT_RATING_DESC,
        LIST_SORT_RELEASE_ASC,
        LIST_SORT_RELEASE_DESC,
        LIST_SORT_TITLE_ASC,
        LIST_SORT_TITLE_DESC
    ];
    if (not lists.contains($known, $sortBy)) {
        raiseError("\"" + $sortBy + "\" is not a list sort order - use a LIST_SORT_* " +
            "constant, or \"\" to leave the list's ordering alone");
    }
    return $sortBy;
}

/**
 * Fold a bulk add or remove reply.
 *
 * @param v {json.Value} the reply
 * @return {ItemsResponse} the folded answer
 * @internal
 */
func itemsResponseFrom(v as json.Value) {
    def rows as list of ItemOutcome init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $rows[] = ItemOutcome{
            kind: parseMediaKind(nodeString($v, $ptr + "/media_type")),
            id: nodeInt($v, $ptr + "/media_id"),
            success: nodeBool($v, $ptr + "/success")
        };
    }
    return ItemsResponse{
        success: nodeBool($v, "/success"),
        statusCode: nodeInt($v, "/status_code"),
        statusMessage: nodeString($v, "/status_message"),
        results: $rows
    };
}
