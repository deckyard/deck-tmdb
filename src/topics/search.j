# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the /search endpoints.
# Spliced into tmdb.j via include - not a standalone module.
#
# Search ranks titles against words a person typed. It does not filter:
# "science fiction from the eighties, rated above 7" is `discover`.

/**
 * Search for films by title.
 *
 * Matches the title, the original title and the alternative titles, so
 * "Die Verurteilten" finds *The Shawshank Redemption*. TMDB's ranking
 * weights popularity heavily.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the matching films
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchMovies(c as Client, query as string, page as int) {
    return moviePageFrom(apiGet($c, "/3/search/movie", searchParams($c, $query, $page)));
}

/**
 * Search for films whose primary release falls in one year.
 *
 * Tells remakes apart ("The Thing", 1982 or 2011). Sends
 * `primary_release_year`: the original theatrical release, not a local
 * re-release.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param year {int} the primary release year, e.g. 1982
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the matching films
 * @throws {Error} kind "tmdb" on a blank query, a year outside 1800..2200, a
 *                 page outside 1..`MAX_PAGE`, or a failed request
 */
export func searchMoviesInYear(c as Client, query as string, year as int, page as int) {
    def params as map of string to string init searchParams($c, $query, $page);
    $params["primary_release_year"] = convert.toString(ensureYear($year));
    return moviePageFrom(apiGet($c, "/3/search/movie", $params));
}

/**
 * Search for series by name.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the matching series
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchShows(c as Client, query as string, page as int) {
    return showPageFrom(apiGet($c, "/3/search/tv", searchParams($c, $query, $page)));
}

/**
 * Search for series that first aired in one year.
 *
 * Tells remakes apart: *The Office* premiered in 2001 in Britain and 2005
 * in America. Sends `first_air_date_year`.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param year {int} the first-air year, e.g. 2005
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the matching series
 * @throws {Error} kind "tmdb" on a blank query, a year outside 1800..2200, a
 *                 page outside 1..`MAX_PAGE`, or a failed request
 */
export func searchShowsInYear(c as Client, query as string, year as int, page as int) {
    def params as map of string to string init searchParams($c, $query, $page);
    $params["first_air_date_year"] = convert.toString(ensureYear($year));
    return showPageFrom(apiGet($c, "/3/search/tv", $params));
}

/**
 * Search for people by name.
 *
 * Matches the name and every alias ("Thomas Jeffrey Hanks" finds Tom
 * Hanks). Each row carries `knownFor`, the two or three titles that tell
 * namesakes apart.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {PersonPage} the matching people
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchPeople(c as Client, query as string, page as int) {
    return personPageFrom(apiGet($c, "/3/search/person", searchParams($c, $query, $page)));
}

/**
 * Search films, series and people at once, in one ranked list.
 *
 * Every row carries its `kind`; `onlyMovies`, `onlyShows` and
 * `onlyPeople` split the list.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {MediaPage} the matching rows, of mixed kind
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchMulti(c as Client, query as string, page as int) {
    return mediaPageFrom(
        apiGet($c, "/3/search/multi", searchParams($c, $query, $page)),
        MediaKind.Unknown);
}

/**
 * Search for collections, TMDB's franchise groupings.
 *
 * E.g. *Star Wars Collection*. `collection` fetches one with its films.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {CollectionPage} the matching collections
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchCollections(c as Client, query as string, page as int) {
    return collectionPageFrom(apiGet($c, "/3/search/collection", searchParams($c, $query, $page)));
}

/**
 * Search for production companies.
 *
 * Sends neither the client's language nor the adult flag. The ids are
 * what `withCompanies` takes.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {CompanyPage} the matching companies
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 */
export func searchCompanies(c as Client, query as string, page as int) {
    def params as map of string to string init {
        "query": ensureText($query, "search query"),
        "page": convert.toString(ensurePage($page))
    };
    return companyPageFrom(apiGet($c, "/3/search/company", $params));
}

/**
 * Search for keywords, TMDB's subject tags.
 *
 * Sends neither the client's language nor the adult flag. The ids are
 * what `withKeywords` takes.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param page {int} the page to fetch, 1-based
 * @return {KeywordPage} the matching keywords
 * @throws {Error} kind "tmdb" on a blank query, a page outside 1..`MAX_PAGE`,
 *                 or a failed request
 * @example
 *   def tags as tmdb.KeywordPage init tmdb.searchKeywords($c, "time loop", 1);
 *   def f as tmdb.DiscoverFilter init tmdb.withKeywords(
 *       tmdb.discoverFilter(), [$tags.results[0].id]);
 */
export func searchKeywords(c as Client, query as string, page as int) {
    def params as map of string to string init {
        "query": ensureText($query, "search query"),
        "page": convert.toString(ensurePage($page))
    };
    return keywordPageFrom(apiGet($c, "/3/search/keyword", $params));
}

/**
 * Every film matching a query, up to a page budget.
 *
 * Stops at the last page, at `maxPages`, or at `MAX_PAGE`, whichever
 * comes first. One request per page of 20 rows: 5 pages is at most 100
 * films.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param maxPages {int} how many pages to fetch at most
 * @return {list of MovieSummary} the rows, in TMDB's relevance order
 * @throws {Error} kind "tmdb" on a blank query, a non-positive budget, or a
 *                 failed request
 */
export func searchMoviesAll(c as Client, query as string, maxPages as int) {
    ensureBudget($maxPages);
    def out as list of MovieSummary init [];
    def page as int init 1;
    while (true) {
        def batch as MoviePage init searchMovies($c, $query, $page);
        for (def row in $batch.results) {
            $out[] = $row;
        }
        if ($page >= $maxPages or not morePages($batch.page, $batch.totalPages)) {
            return $out;
        }
        $page = $page + 1;
    }
    return $out;
}

/**
 * Every series matching a query, up to a page budget.
 *
 * Same stopping rules as `searchMoviesAll`.
 *
 * @param c {Client} an API client
 * @param query {string} what the user typed
 * @param maxPages {int} how many pages to fetch at most
 * @return {list of ShowSummary} the rows, in TMDB's relevance order
 * @throws {Error} kind "tmdb" on a blank query, a non-positive budget, or a
 *                 failed request
 */
export func searchShowsAll(c as Client, query as string, maxPages as int) {
    ensureBudget($maxPages);
    def out as list of ShowSummary init [];
    def page as int init 1;
    while (true) {
        def batch as ShowPage init searchShows($c, $query, $page);
        for (def row in $batch.results) {
            $out[] = $row;
        }
        if ($page >= $maxPages or not morePages($batch.page, $batch.totalPages)) {
            return $out;
        }
        $page = $page + 1;
    }
    return $out;
}

/**
 * The query, page, language and adult parameters every search takes.
 *
 * @param c {Client} the client
 * @param query {string} the caller's query
 * @param page {int} the requested page
 * @return {map of string to string} the parameters
 * @throws {Error} kind "tmdb" on a blank query or a page outside 1..MAX_PAGE
 * @internal
 */
func searchParams(c as Client, query as string, page as int) {
    def params as map of string to string init pageParams($c, $page);
    $params["query"] = ensureText($query, "search query");
    $params["include_adult"] = boolParam($c.includeAdult);
    return $params;
}

/**
 * Refuse a year no film or series could carry.
 *
 * @param year {int} the candidate year
 * @return {int} the same year
 * @throws {Error} kind "tmdb" when the year is outside 1800..2200
 * @internal
 */
func ensureYear(year as int) {
    if ($year < 1800 or $year > 2200) {
        raiseError("the year must be between 1800 and 2200, got " + convert.toString($year));
    }
    return $year;
}

/**
 * Refuse a page budget that would fetch nothing.
 *
 * @param maxPages {int} the budget
 * @return {int} the same budget
 * @throws {Error} kind "tmdb" when the budget is not positive
 * @internal
 */
func ensureBudget(maxPages as int) {
    if ($maxPages < 1) {
        raiseError("the page budget must be 1 or more, got " + convert.toString($maxPages));
    }
    return $maxPages;
}
