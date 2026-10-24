# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the whole-catalogue views: trending, genres, certifications,
# watch providers, and the change feeds.
# Spliced into tmdb.j via include - not a standalone module.
#
# Nothing here takes an id.

/**
 * Trending over the last 24 hours.
 */
export def const TREND_DAY as string init "day";

/**
 * Trending over the last 7 days.
 */
export def const TREND_WEEK as string init "week";

/**
 * One rating in one country's certification system.
 *
 * @field certification {string} the rating, e.g. "PG-13"
 * @field meaning {string} TMDB's explanation of it
 * @field order {int} strictness rank, ascending; sort on this
 */
export def struct Certification {
    certification as string,
    meaning as string,
    order as int
};

/**
 * One country's whole certification system.
 *
 * @field region {string} the two-letter country code
 * @field certifications {list of Certification} its ratings, in TMDB's order
 */
export def struct CertificationGroup {
    region as string,
    certifications as list of Certification
};

/**
 * One changed title or person: an id and the adult flag, nothing more.
 *
 * Re-fetch the record to see what changed.
 *
 * @field id {int} the id of the changed title or person
 * @field adult {bool} whether it is adult, so a filtered mirror can skip it
 */
export def struct ChangeEntry {
    id as int,
    adult as bool
};

/**
 * One page of change entries.
 *
 * @field page {int} which page this is, 1-based
 * @field totalPages {int} how many pages the feed has
 * @field totalResults {int} how many entries the feed has
 * @field results {list of ChangeEntry} this page's entries
 */
export def struct ChangePage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of ChangeEntry
};

/**
 * One page of trending films, series and people in one ranked list.
 *
 * TMDB computes trending from views, ratings and list activity, so it
 * moves faster than `popularMovies`. Check each row's `kind`.
 *
 * @param c {Client} an API client
 * @param window {string} `TREND_DAY` or `TREND_WEEK`
 * @param page {int} the page to fetch, 1-based
 * @return {MediaPage} the trending rows, of mixed kind
 * @throws {Error} kind "tmdb" on an unknown window, a bad page, or a
 *                 transport failure
 */
export func trendingAll(c as Client, window as string, page as int) {
    return mediaPageFrom(
        apiGet($c, trendingPath("all", $window), pageParams($c, $page)),
        MediaKind.Unknown);
}

/**
 * One page of trending films.
 *
 * @param c {Client} an API client
 * @param window {string} `TREND_DAY` or `TREND_WEEK`
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the trending films
 * @throws {Error} kind "tmdb" on an unknown window, a bad page, or a
 *                 transport failure
 */
export func trendingMovies(c as Client, window as string, page as int) {
    return moviePageFrom(apiGet($c, trendingPath("movie", $window), pageParams($c, $page)));
}

/**
 * One page of trending series.
 *
 * @param c {Client} an API client
 * @param window {string} `TREND_DAY` or `TREND_WEEK`
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the trending series
 * @throws {Error} kind "tmdb" on an unknown window, a bad page, or a
 *                 transport failure
 */
export func trendingShows(c as Client, window as string, page as int) {
    return showPageFrom(apiGet($c, trendingPath("tv", $window), pageParams($c, $page)));
}

/**
 * One page of trending people.
 *
 * @param c {Client} an API client
 * @param window {string} `TREND_DAY` or `TREND_WEEK`
 * @param page {int} the page to fetch, 1-based
 * @return {PersonPage} the trending people
 * @throws {Error} kind "tmdb" on an unknown window, a bad page, or a
 *                 transport failure
 */
export func trendingPeople(c as Client, window as string, page as int) {
    return personPageFrom(apiGet($c, trendingPath("person", $window), pageParams($c, $page)));
}

/**
 * The film genres, named in the client's language.
 *
 * Fetch once and keep: `withGenres` and every `genreIds` field use these
 * ids. `genreIndex` turns the list into a lookup map.
 *
 * @param c {Client} an API client
 * @return {list of Genre} the film genres, named in the client's language
 * @throws {Error} kind "tmdb" on a transport failure
 * @example
 *   def names as map of string to string init tmdb.genreIndex(tmdb.movieGenres($c));
 */
export func movieGenres(c as Client) {
    return genresFrom(apiGet($c, "/3/genre/movie/list", localeParams($c)), "/genres");
}

/**
 * The series genres, named in the client's language.
 *
 * Not the film set: series have "Action & Adventure" and "Sci-Fi &
 * Fantasy" where films have separate genres.
 *
 * @param c {Client} an API client
 * @return {list of Genre} the series genres, named in the client's language
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func showGenres(c as Client) {
    return genresFrom(apiGet($c, "/3/genre/tv/list", localeParams($c)), "/genres");
}

/**
 * Every country's film certification system.
 *
 * The values `ratedFor` and `ratedUpTo` take and `ReleaseDate.certification`
 * holds.
 *
 * @param c {Client} an API client
 * @return {list of CertificationGroup} one entry per country
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func movieCertifications(c as Client) {
    return certificationsFrom(apiGet($c, "/3/certification/movie/list", {}));
}

/**
 * Every country's series certification system.
 *
 * @param c {Client} an API client
 * @return {list of CertificationGroup} one entry per country
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func showCertifications(c as Client) {
    return certificationsFrom(apiGet($c, "/3/certification/tv/list", {}));
}

/**
 * The countries TMDB has watch-provider data for.
 *
 * The valid watch regions for `availableOn` and the `*WatchProviders`
 * results.
 *
 * @param c {Client} an API client
 * @return {list of Country} the countries, with names
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func providerRegions(c as Client) {
    return countriesFrom(apiGet($c, "/3/watch/providers/regions", localeParams($c)), "/results");
}

/**
 * The streaming and rental services for films, in one country or all.
 *
 * Provider ids are the same in every country; which services exist
 * differs. These are the ids `availableOn` takes.
 *
 * @param c {Client} an API client
 * @param watchRegion {string} a two-letter country code, "" for every country
 * @return {list of WatchProvider} the services, in TMDB's display order
 * @throws {Error} kind "tmdb" on a bad region or a transport failure
 */
export func movieProviders(c as Client, watchRegion as string) {
    return watchProvidersFrom(
        apiGet($c, "/3/watch/providers/movie", providerParams($c, $watchRegion)),
        "/results");
}

/**
 * The streaming and rental services for series, in one country or all.
 *
 * @param c {Client} an API client
 * @param watchRegion {string} a two-letter country code, "" for every country
 * @return {list of WatchProvider} the services, in TMDB's display order
 * @throws {Error} kind "tmdb" on a bad region or a transport failure
 */
export func showProviders(c as Client, watchRegion as string) {
    return watchProvidersFrom(
        apiGet($c, "/3/watch/providers/tv", providerParams($c, $watchRegion)),
        "/results");
}

/**
 * One page of film ids changed in a date range.
 *
 * TMDB keeps 14 days of history and defaults to the last 24 hours when
 * both dates are ""; the server refuses a range wider than 14 days.
 *
 * @param c {Client} an API client
 * @param startDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param endDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param page {int} the page to fetch, 1-based
 * @return {ChangePage} the ids that changed
 * @throws {Error} kind "tmdb" on a malformed date, a bad page, or a
 *                 transport failure
 */
export func changedMovies(c as Client, startDate as string, endDate as string, page as int) {
    return changePageFrom(apiGet(
        $c,
        "/3/movie/changes",
        changeParams($c, $startDate, $endDate, $page)));
}

/**
 * One page of series ids changed in a date range; see `changedMovies`.
 *
 * @param c {Client} an API client
 * @param startDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param endDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param page {int} the page to fetch, 1-based
 * @return {ChangePage} the ids that changed
 * @throws {Error} kind "tmdb" on a malformed date, a bad page, or a
 *                 transport failure
 */
export func changedShows(c as Client, startDate as string, endDate as string, page as int) {
    return changePageFrom(apiGet(
        $c,
        "/3/tv/changes",
        changeParams($c, $startDate, $endDate, $page)));
}

/**
 * One page of person ids changed in a date range; see `changedMovies`.
 *
 * @param c {Client} an API client
 * @param startDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param endDate {string} `YYYY-MM-DD`, or "" for the default window
 * @param page {int} the page to fetch, 1-based
 * @return {ChangePage} the ids that changed
 * @throws {Error} kind "tmdb" on a malformed date, a bad page, or a
 *                 transport failure
 */
export func changedPeople(c as Client, startDate as string, endDate as string, page as int) {
    return changePageFrom(apiGet(
        $c,
        "/3/person/changes",
        changeParams($c, $startDate, $endDate, $page)));
}

/**
 * One country's ratings out of a certifications result; no request.
 *
 * The country code is matched case-insensitively.
 *
 * @param groups {list of CertificationGroup} a `*Certifications` result
 * @param region {string} the two-letter country code
 * @return {list of Certification} that country's ratings, empty when absent
 */
export func certificationsIn(groups as list of CertificationGroup, region as string) {
    def wanted as string init strings.upper(strings.trim($region));
    for (def group in $groups) {
        if (strings.upper($group.region) == $wanted) {
            return $group.certifications;
        }
    }
    return [];
}

/**
 * The path of a trending feed.
 *
 * @param kind {string} "all", "movie", "tv" or "person"
 * @param window {string} the trending window
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the window is neither day nor week
 * @internal
 */
func trendingPath(kind as string, window as string) {
    def span as string init strings.lower(strings.trim($window));
    if ($span != TREND_DAY and $span != TREND_WEEK) {
        raiseError("the trending window must be TREND_DAY or TREND_WEEK, got \"" +
            $window + "\"");
    }
    return "/3/trending/" + $kind + "/" + $span;
}

/**
 * The parameters a watch-provider catalogue call takes.
 *
 * @param c {Client} the client
 * @param watchRegion {string} the country code, "" for every country
 * @return {map of string to string} the parameters
 * @throws {Error} kind "tmdb" when the region is neither empty nor two letters
 * @internal
 */
func providerParams(c as Client, watchRegion as string) {
    def params as map of string to string init localeParams($c);
    def region as string init strings.upper(strings.trim($watchRegion));
    if ($region != "") {
        if (not isCountryCode($region)) {
            raiseError("the watch region must be a two-letter country code, got \"" +
                $region + "\"");
        }
        $params["watch_region"] = $region;
    }
    return $params;
}

/**
 * The parameters a change feed takes.
 *
 * @param c {Client} the client
 * @param startDate {string} the start of the window, "" for the default
 * @param endDate {string} the end of the window, "" for the default
 * @param page {int} the requested page
 * @return {map of string to string} the parameters
 * @throws {Error} kind "tmdb" on a malformed date or a bad page
 * @internal
 */
func changeParams(c as Client, startDate as string, endDate as string, page as int) {
    def params as map of string to string init {"page": convert.toString(ensurePage($page))};
    def lo as string init strings.trim($startDate);
    def hi as string init strings.trim($endDate);
    if ($lo != "") {
        $params["start_date"] = ensureDate($lo);
    }
    if ($hi != "") {
        $params["end_date"] = ensureDate($hi);
    }
    return $params;
}

/**
 * Fold a certifications reply, whose entries are keyed by country.
 *
 * @param v {json.Value} the reply
 * @return {list of CertificationGroup} the folded systems
 * @internal
 */
func certificationsFrom(v as json.Value) {
    def out as list of CertificationGroup init [];
    for (def region in nodeKeys($v, "/certifications")) {
        def ptr as string init "/certifications/" + pointerToken($region);
        def ratings as list of Certification init [];
        for (def i in 0..nodeLength($v, $ptr)) {
            def item as string init itemPointer($ptr, $i);
            $ratings[] = Certification{
                certification: nodeString($v, $item + "/certification"),
                meaning: nodeString($v, $item + "/meaning"),
                order: nodeInt($v, $item + "/order")
            };
        }
        $out[] = CertificationGroup{region: $region, certifications: $ratings};
    }
    return $out;
}

/**
 * Fold a change-feed reply.
 *
 * @param v {json.Value} the reply
 * @return {ChangePage} the folded page
 * @internal
 */
func changePageFrom(v as json.Value) {
    def rows as list of ChangeEntry init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $rows[] = ChangeEntry{id: nodeInt($v, $ptr + "/id"), adult: nodeBool($v, $ptr + "/adult")};
    }
    return ChangePage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}
