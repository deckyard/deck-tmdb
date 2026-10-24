# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the v4 per-account collections.
# Spliced into tmdb.j via include - not a standalone module.
#
# Every verb needs a user access token on the client (see `auth`) and the
# v4 account object id that came with it - the hex string, not the numeric
# v3 account id. `ensureAccountId` refuses an all-digit id.

/**
 * Account sort: oldest addition first.
 */
export def const ACCOUNT_SORT_ADDED_ASC as string init "created_at.asc";

/**
 * Account sort: most recent addition first.
 */
export def const ACCOUNT_SORT_ADDED_DESC as string init "created_at.desc";

/**
 * Account sort: oldest title first.
 */
export def const ACCOUNT_SORT_RELEASE_ASC as string init "release_date.asc";

/**
 * Account sort: newest title first.
 */
export def const ACCOUNT_SORT_RELEASE_DESC as string init "release_date.desc";

/**
 * Account sort: alphabetical.
 */
export def const ACCOUNT_SORT_TITLE_ASC as string init "title.asc";

/**
 * Account sort: reverse alphabetical.
 */
export def const ACCOUNT_SORT_TITLE_DESC as string init "title.desc";

/**
 * Account sort: worst rated first.
 */
export def const ACCOUNT_SORT_RATING_ASC as string init "vote_average.asc";

/**
 * Account sort: best rated first.
 */
export def const ACCOUNT_SORT_RATING_DESC as string init "vote_average.desc";

/**
 * A custom list's row in an account's list index, without its items.
 *
 * `listDetails` fetches the items.
 *
 * @field id {int} the list id the `userlists` verbs take
 * @field name {string} the list's name
 * @field description {string} the list's description, often ""
 * @field accountObjectId {string} the owner's v4 account object id
 * @field public {bool} whether anyone can read it
 * @field adult {bool} whether it is flagged adult
 * @field featured {bool} whether TMDB features it
 * @field numberOfItems {int} how many titles are in it
 * @field averageRating {float} the mean rating of its titles
 * @field revenue {int} the combined box office of its films
 * @field runtime {int} the combined runtime of its titles, in minutes
 * @field region {string} the list's ISO 3166-1 country
 * @field language {string} the list's ISO 639-1 language
 * @field sortBy {int} TMDB's numeric code for the list's own ordering
 * @field createdAt {string} an ISO 8601 timestamp
 * @field updatedAt {string} an ISO 8601 timestamp
 */
export def struct ListSummary {
    id as int,
    name as string,
    description as string,
    accountObjectId as string,
    public as bool,
    adult as bool,
    featured as bool,
    numberOfItems as int,
    averageRating as float,
    revenue as int,
    runtime as int,
    region as string,
    language as string,
    sortBy as int,
    createdAt as string,
    updatedAt as string
};

/**
 * One page of an account's custom lists.
 *
 * @field page {int} which page this is, 1-based
 * @field totalPages {int} how many pages of lists there are
 * @field totalResults {int} how many lists the account has
 * @field results {list of ListSummary} this page's lists
 */
export def struct ListPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of ListSummary
};

/**
 * One page of the custom lists an account has created.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @return {ListPage} the account's lists
 * @throws {Error} kind "tmdb" without a user token, on a bad account id or
 *                 page, or on a transport failure
 */
export func accountLists(c as Client, accountId as string, page as int) {
    requireUser($c, "accountLists");
    def params as map of string to string init {"page": convert.toString(ensurePage($page))};
    return listPageFrom(apiGet($c, accountPath($accountId, "/lists"), $params));
}

/**
 * Fold a paginated envelope of list rows.
 *
 * @param v {json.Value} the reply
 * @return {ListPage} the folded page
 * @internal
 */
func listPageFrom(v as json.Value) {
    def rows as list of ListSummary init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = listSummaryFrom($v, itemPointer("/results", $i));
    }
    return ListPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * One page of an account's favourite films.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {MoviePage} the favourites
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func favoriteMovies(c as Client, accountId as string, page as int, sortBy as string) {
    return moviePageFrom(accountGet($c, $accountId, "/movie/favorites", $page, $sortBy));
}

/**
 * One page of an account's favourite series.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {ShowPage} the favourites
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func favoriteShows(c as Client, accountId as string, page as int, sortBy as string) {
    return showPageFrom(accountGet($c, $accountId, "/tv/favorites", $page, $sortBy));
}

/**
 * One page of the films an account has rated.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {MoviePage} the rated films
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func ratedMovies(c as Client, accountId as string, page as int, sortBy as string) {
    return moviePageFrom(accountGet($c, $accountId, "/movie/rated", $page, $sortBy));
}

/**
 * One page of the series an account has rated.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {ShowPage} the rated series
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func ratedShows(c as Client, accountId as string, page as int, sortBy as string) {
    return showPageFrom(accountGet($c, $accountId, "/tv/rated", $page, $sortBy));
}

/**
 * One page of an account's film watchlist.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {MoviePage} the watchlist
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func watchlistMovies(c as Client, accountId as string, page as int, sortBy as string) {
    return moviePageFrom(accountGet($c, $accountId, "/movie/watchlist", $page, $sortBy));
}

/**
 * One page of an account's series watchlist.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @param sortBy {string} an `ACCOUNT_SORT_*` constant, "" for TMDB's default
 * @return {ShowPage} the watchlist
 * @throws {Error} kind "tmdb" without a user token, on a bad account id,
 *                 page or sort, or on a transport failure
 */
export func watchlistShows(c as Client, accountId as string, page as int, sortBy as string) {
    return showPageFrom(accountGet($c, $accountId, "/tv/watchlist", $page, $sortBy));
}

/**
 * One page of films TMDB recommends to an account, from its activity.
 *
 * Unlike `movieRecommendations`, computed from what the account has rated,
 * favourited and listed.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the recommendations
 * @throws {Error} kind "tmdb" without a user token, on a bad account id or
 *                 page, or on a transport failure
 */
export func recommendedMovies(c as Client, accountId as string, page as int) {
    return moviePageFrom(accountGet($c, $accountId, "/movie/recommendations", $page, ""));
}

/**
 * One page of series TMDB recommends to an account, from its activity.
 *
 * @param c {Client} an API client carrying a user access token
 * @param accountId {string} the v4 account object id
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the recommendations
 * @throws {Error} kind "tmdb" without a user token, on a bad account id or
 *                 page, or on a transport failure
 */
export func recommendedShows(c as Client, accountId as string, page as int) {
    return showPageFrom(accountGet($c, $accountId, "/tv/recommendations", $page, ""));
}

/**
 * GET one of an account's collections.
 *
 * @param c {Client} the client
 * @param accountId {string} the account object id
 * @param suffix {string} the collection path, e.g. "/movie/favorites"
 * @param page {int} the requested page
 * @param sortBy {string} the sort order, "" to omit
 * @return {json.Value} the decoded reply
 * @throws {Error} kind "tmdb" without a user token or on a bad argument
 * @internal
 */
func accountGet(c as Client, accountId as string, suffix as string, page as int, sortBy as string) {
    requireUser($c, "the account collections");
    def params as map of string to string init pageParams($c, $page);
    def sort as string init strings.trim($sortBy);
    if ($sort != "") {
        $params["sort_by"] = ensureAccountSort($sort);
    }
    return apiGet($c, accountPath($accountId, $suffix), $params);
}

/**
 * The path of one of an account's collections.
 *
 * @param accountId {string} the account object id
 * @param suffix {string} the collection path
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the account id is blank or looks like a v3 id
 * @internal
 */
func accountPath(accountId as string, suffix as string) {
    return "/4/account/" + ensureAccountId($accountId) + $suffix;
}

/**
 * Refuse anything that is not a v4 account object id.
 *
 * The numeric v3 id names the same account but gets an unexplained 404
 * from v4, so an all-digit id is refused here with a message.
 *
 * @param accountId {string} the candidate id
 * @return {string} the trimmed id
 * @throws {Error} kind "tmdb" when the id is blank, numeric, or unsafe in a path
 * @internal
 */
func ensureAccountId(accountId as string) {
    def id as string init ensureText($accountId, "account object id");
    for (def bad in ["/", "..", "?", "#", " ", "\t", "\n", "\r"]) {
        if (strings.contains($id, $bad)) {
            raiseError("the account object id must not contain \"" + $bad + "\", got \"" +
                $id + "\"");
        }
    }
    if (isDigits($id)) {
        raiseError("\"" + $id + "\" is the numeric v3 account id; v4 wants the account " +
            "*object* id, the hex string that came back with the access token " +
            "(AccessToken.accountId)");
    }
    return $id;
}

/**
 * Refuse a sort order the account endpoints do not accept.
 *
 * @param sortBy {string} the candidate sort
 * @return {string} the same sort
 * @throws {Error} kind "tmdb" when it is not an `ACCOUNT_SORT_*` value
 * @internal
 */
func ensureAccountSort(sortBy as string) {
    def known as list of string init [
        ACCOUNT_SORT_ADDED_ASC,
        ACCOUNT_SORT_ADDED_DESC,
        ACCOUNT_SORT_RELEASE_ASC,
        ACCOUNT_SORT_RELEASE_DESC,
        ACCOUNT_SORT_TITLE_ASC,
        ACCOUNT_SORT_TITLE_DESC,
        ACCOUNT_SORT_RATING_ASC,
        ACCOUNT_SORT_RATING_DESC
    ];
    if (not lists.contains($known, $sortBy)) {
        raiseError("\"" + $sortBy + "\" is not an account sort order - use an " +
            "ACCOUNT_SORT_* constant, or \"\" for TMDB's default");
    }
    return $sortBy;
}

/**
 * Fold one row of an account's list index.
 *
 * v4 writes the booleans as `1` / `0` and revenue as a string;
 * `nodeBool` and `nodeInt` read both.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {ListSummary} the folded row
 * @internal
 */
func listSummaryFrom(v as json.Value, ptr as string) {
    return ListSummary{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        description: nodeString($v, $ptr + "/description"),
        accountObjectId: nodeString($v, $ptr + "/account_object_id"),
        public: nodeBool($v, $ptr + "/public"),
        adult: nodeBool($v, $ptr + "/adult"),
        featured: nodeBool($v, $ptr + "/featured"),
        numberOfItems: nodeInt($v, $ptr + "/number_of_items"),
        averageRating: nodeFloat($v, $ptr + "/average_rating"),
        revenue: nodeInt($v, $ptr + "/revenue"),
        runtime: nodeInt($v, $ptr + "/runtime"),
        region: nodeString($v, $ptr + "/iso_3166_1"),
        language: nodeString($v, $ptr + "/iso_639_1"),
        sortBy: nodeInt($v, $ptr + "/sort_by"),
        createdAt: nodeString($v, $ptr + "/created_at"),
        updatedAt: nodeString($v, $ptr + "/updated_at")
    };
}
