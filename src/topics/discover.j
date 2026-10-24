# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - /discover/movie and /discover/tv, behind a filter builder.
# Spliced into tmdb.j via include - not a standalone module.
#
# The two catalogues name the same concept differently: films filter on
# `primary_release_date.gte` and sort by `title.asc`, series on
# `first_air_date.gte` and `name.asc`. `DiscoverFilter` stores deck key
# names and `wireName` / `wireValue` translate them per catalogue at
# request time. A criterion the catalogue lacks (a network on a film)
# throws instead of being sent and silently ignored by the server.

/**
 * Sort: most popular first. TMDB's default.
 */
export def const SORT_POPULARITY_DESC as string init "popularity.desc";

/**
 * Sort: least popular first.
 */
export def const SORT_POPULARITY_ASC as string init "popularity.asc";

/**
 * Sort: best rated first (`vote_average.desc`).
 *
 * Pair it with `withMinVotes`, or the top of the list is titles with a
 * single ten-star rating.
 */
export def const SORT_RATING_DESC as string init "rating.desc";

/**
 * Sort: worst rated first (`vote_average.asc`). Pair it with `withMinVotes`.
 */
export def const SORT_RATING_ASC as string init "rating.asc";

/**
 * Sort: most ratings first (`vote_count.desc`), a rough proxy for most watched.
 */
export def const SORT_VOTES_DESC as string init "votes.desc";

/**
 * Sort: newest first, by primary release date (films) or first air date (series).
 */
export def const SORT_NEWEST as string init "date.desc";

/**
 * Sort: oldest first, by primary release date (films) or first air date (series).
 */
export def const SORT_OLDEST as string init "date.asc";

/**
 * Sort: alphabetical, `title.asc` for films and `name.asc` for series.
 */
export def const SORT_TITLE_ASC as string init "title.asc";

/**
 * Sort: reverse alphabetical, `title.desc` for films and `name.desc` for series.
 */
export def const SORT_TITLE_DESC as string init "title.desc";

/**
 * Sort: highest box office first. Films only.
 */
export def const SORT_REVENUE_DESC as string init "revenue.desc";

/**
 * `with_status` for a series still being made.
 */
export def const SHOW_STATUS_RETURNING as int init 0;

/**
 * `with_status` for a series that is announced but not shooting.
 */
export def const SHOW_STATUS_PLANNED as int init 1;

/**
 * `with_status` for a series currently in production.
 */
export def const SHOW_STATUS_IN_PRODUCTION as int init 2;

/**
 * `with_status` for a series that finished on its own terms.
 */
export def const SHOW_STATUS_ENDED as int init 3;

/**
 * `with_status` for a series that was cancelled.
 */
export def const SHOW_STATUS_CANCELLED as int init 4;

/**
 * `with_status` for a pilot that never became a series.
 */
export def const SHOW_STATUS_PILOT as int init 5;

/**
 * `with_type` for a documentary series.
 */
export def const SHOW_TYPE_DOCUMENTARY as int init 0;

/**
 * `with_type` for a news programme.
 */
export def const SHOW_TYPE_NEWS as int init 1;

/**
 * `with_type` for a miniseries: a closed run with no second season.
 */
export def const SHOW_TYPE_MINISERIES as int init 2;

/**
 * `with_type` for reality television.
 */
export def const SHOW_TYPE_REALITY as int init 3;

/**
 * `with_type` for scripted drama and comedy.
 */
export def const SHOW_TYPE_SCRIPTED as int init 4;

/**
 * `with_type` for a talk show.
 */
export def const SHOW_TYPE_TALK_SHOW as int init 5;

/**
 * `with_type` for a video release filed as a series.
 */
export def const SHOW_TYPE_VIDEO as int init 6;

/**
 * Monetization: included in a subscription.
 */
export def const MONETIZATION_FLATRATE as string init "flatrate";

/**
 * Monetization: free to watch, no advertising.
 */
export def const MONETIZATION_FREE as string init "free";

/**
 * Monetization: free to watch, advertising-supported.
 */
export def const MONETIZATION_ADS as string init "ads";

/**
 * Monetization: rentable.
 */
export def const MONETIZATION_RENT as string init "rent";

/**
 * Monetization: purchasable.
 */
export def const MONETIZATION_BUY as string init "buy";

/**
 * A set of discovery criteria, independent of the catalogue it runs on.
 *
 * Every builder returns a copy, so one base filter can be specialized in
 * several directions. `criteria` holds the deck's key names, not TMDB's;
 * `filterParams` shows the wire form. Build it with the builders: an
 * unknown key throws at request time.
 *
 * @field criteria {map of string to string} the criteria, by deck key name
 */
export def struct DiscoverFilter {
    criteria as map of string to string
};

/**
 * An empty filter: everything, most popular first.
 *
 * @return {DiscoverFilter} a filter with no criteria
 */
export func discoverFilter() {
    return DiscoverFilter{criteria: {}};
}

/**
 * A copy of the filter with a different ordering.
 *
 * The `SORT_*` constants are catalogue-neutral: `SORT_NEWEST` becomes
 * `primary_release_date.desc` for films and `first_air_date.desc` for
 * series. Any other string is sent verbatim.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param sort {string} a `SORT_*` constant, or a raw TMDB sort string
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the sort is blank
 */
export func sortedBy(f as DiscoverFilter, sort as string) {
    return setCriterion($f, "sort", ensureText($sort, "sort order"));
}

/**
 * A copy of the filter narrowed to titles in **every** listed genre.
 *
 * Genre ids come from `movieGenres` or `showGenres` and differ per
 * catalogue: 28 is Action for films, 10759 "Action & Adventure" for
 * series. Replaces an earlier `withGenres` or `withAnyGenre`.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param genreIds {list of int} the genre ids that must all apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 * @example
 *   $f = tmdb.withGenres($f, [878, 53]);   # science fiction and thriller
 */
export func withGenres(f as DiscoverFilter, genreIds as list of int) {
    return setCriterion($f, "genres", joinIds($genreIds, ",", "genre"));
}

/**
 * A copy of the filter narrowed to titles in **any** listed genre.
 *
 * Replaces an earlier `withGenres` or `withAnyGenre`.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param genreIds {list of int} the genre ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 * @example
 *   $f = tmdb.withAnyGenre($f, [27, 53]);   # horror or thriller
 */
export func withAnyGenre(f as DiscoverFilter, genreIds as list of int) {
    return setCriterion($f, "genres", joinIds($genreIds, "|", "genre"));
}

/**
 * A copy of the filter excluding every listed genre.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param genreIds {list of int} the genre ids to exclude
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withoutGenres(f as DiscoverFilter, genreIds as list of int) {
    return setCriterion($f, "notGenres", joinIds($genreIds, ",", "genre"));
}

/**
 * A copy of the filter narrowed to titles carrying **every** keyword.
 *
 * Keywords are finer than genres ("time loop", "based on novel"); find
 * their ids with `searchKeywords`. Replaces an earlier `withKeywords` or
 * `withAnyKeyword`.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param keywordIds {list of int} the keyword ids that must all apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withKeywords(f as DiscoverFilter, keywordIds as list of int) {
    return setCriterion($f, "keywords", joinIds($keywordIds, ",", "keyword"));
}

/**
 * A copy of the filter narrowed to titles carrying **any** keyword.
 *
 * Replaces an earlier `withKeywords` or `withAnyKeyword`.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param keywordIds {list of int} the keyword ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withAnyKeyword(f as DiscoverFilter, keywordIds as list of int) {
    return setCriterion($f, "keywords", joinIds($keywordIds, "|", "keyword"));
}

/**
 * A copy of the filter excluding every listed keyword.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param keywordIds {list of int} the keyword ids to exclude
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withoutKeywords(f as DiscoverFilter, keywordIds as list of int) {
    return setCriterion($f, "notKeywords", joinIds($keywordIds, ",", "keyword"));
}

/**
 * A copy of the filter narrowed to titles from any listed company.
 *
 * Company ids come from `searchCompanies`. A studio often has several
 * (distributor, production arm, predecessor), so list them all.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param companyIds {list of int} the company ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 * @example
 *   $f = tmdb.withCompanies($f, [41077]);   # A24
 */
export func withCompanies(f as DiscoverFilter, companyIds as list of int) {
    return setCriterion($f, "companies", joinIds($companyIds, "|", "company"));
}

/**
 * A copy of the filter excluding every listed company.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param companyIds {list of int} the company ids to exclude
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withoutCompanies(f as DiscoverFilter, companyIds as list of int) {
    return setCriterion($f, "notCompanies", joinIds($companyIds, ",", "company"));
}

/**
 * A copy of the filter narrowed to films involving any listed person.
 *
 * Matches cast or crew. Films only: `discoverShows` throws on a filter
 * carrying it.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param personIds {list of int} the person ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 * @example
 *   $f = tmdb.withPeople($f, [1245]);   # Scarlett Johansson
 */
export func withPeople(f as DiscoverFilter, personIds as list of int) {
    return setCriterion($f, "people", joinIds($personIds, "|", "person"));
}

/**
 * A copy of the filter narrowed to films any listed person appears in.
 *
 * Cast only. Films only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param personIds {list of int} the person ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withCast(f as DiscoverFilter, personIds as list of int) {
    return setCriterion($f, "cast", joinIds($personIds, "|", "person"));
}

/**
 * A copy of the filter narrowed to films any listed person worked on.
 *
 * Crew only (directors, writers, composers). Films only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param personIds {list of int} the person ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func withCrew(f as DiscoverFilter, personIds as list of int) {
    return setCriterion($f, "crew", joinIds($personIds, "|", "person"));
}

/**
 * A copy of the filter narrowed to series on any listed network.
 *
 * Network ids come from a series' `networks` field or `network`. Series
 * only: `discoverMovies` throws on a filter carrying it.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param networkIds {list of int} the network ids, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 * @example
 *   $f = tmdb.withNetworks($f, [49]);   # HBO
 */
export func withNetworks(f as DiscoverFilter, networkIds as list of int) {
    return setCriterion($f, "networks", joinIds($networkIds, "|", "network"));
}

/**
 * A copy of the filter narrowed to one original language.
 *
 * The language the title was made in. The language of the returned
 * metadata is the client's (`withLanguage`). The code is lower-cased.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param code {string} an ISO 639-1 code, e.g. "ja"
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the code is blank
 */
export func inOriginalLanguage(f as DiscoverFilter, code as string) {
    return setCriterion($f, "originalLanguage", strings.lower(ensureText($code, "language code")));
}

/**
 * A copy of the filter narrowed to one country of origin.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param code {string} a two-letter ISO 3166-1 code in any case, e.g. "KR"
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the code is not two letters
 */
export func fromCountry(f as DiscoverFilter, code as string) {
    def value as string init strings.upper(ensureText($code, "country code"));
    if (not isCountryCode($value)) {
        raiseError("the country code must be two letters, got \"" + $value + "\"");
    }
    return setCriterion($f, "originCountry", $value);
}

/**
 * A copy of the filter narrowed to a release window.
 *
 * Filters the primary release date for films, the first air date for
 * series. Either end may be "" for an open interval; both ends are
 * inclusive.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param earliest {string} the earliest date, `YYYY-MM-DD`, or "" for no floor
 * @param latest {string} the latest date, `YYYY-MM-DD`, or "" for no ceiling
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when both ends are empty, a date is malformed,
 *                 or the range is inverted
 * @example
 *   $f = tmdb.releasedBetween($f, "2020-01-01", "");   # since 2020
 */
export func releasedBetween(f as DiscoverFilter, earliest as string, latest as string) {
    def lo as string init strings.trim($earliest);
    def hi as string init strings.trim($latest);
    if ($lo == "" and $hi == "") {
        raiseError("a release window needs at least one end - both were empty");
    }
    if ($lo != "" and $hi != "" and ensureDate($lo) > ensureDate($hi)) {
        raiseError("the release window ends before it starts: " + $lo + " to " + $hi);
    }
    def next as DiscoverFilter init $f;
    if ($lo != "") {
        $next = setCriterion($next, "releasedFrom", ensureDate($lo));
    }
    if ($hi != "") {
        $next = setCriterion($next, "releasedTo", ensureDate($hi));
    }
    return $next;
}

/**
 * A copy of the filter narrowed to one release year.
 *
 * Sends `primary_release_year` for films, `first_air_date_year` for
 * series.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param year {int} the year, e.g. 1999
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the year is outside 1800..2200
 */
export func releasedInYear(f as DiscoverFilter, year as int) {
    return setCriterion($f, "year", convert.toString(ensureYear($year)));
}

/**
 * A copy of the filter narrowed to titles rated at or above a score.
 *
 * Use it with `withMinVotes`: a title with one ten-star rating averages 10.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param score {float} the lowest acceptable mean rating, 0 to 10
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the score is outside 0..10
 * @example
 *   $f = tmdb.withMinVotes(tmdb.ratedAtLeast($f, 7.5), 1000);
 */
export func ratedAtLeast(f as DiscoverFilter, score as float) {
    return setCriterion($f, "ratingFrom", convert.toString(ensureScore($score)));
}

/**
 * A copy of the filter narrowed to titles rated at or below a score.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param score {float} the highest acceptable mean rating, 0 to 10
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the score is outside 0..10
 */
export func ratedAtMost(f as DiscoverFilter, score as float) {
    return setCriterion($f, "ratingTo", convert.toString(ensureScore($score)));
}

/**
 * A copy of the filter narrowed to titles with at least this many ratings.
 *
 * The companion to any rating filter or `SORT_RATING_DESC`. A few hundred
 * keeps out noise; a few thousand narrows to well-known titles.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param votes {int} the minimum number of ratings
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the count is negative
 */
export func withMinVotes(f as DiscoverFilter, votes as int) {
    if ($votes < 0) {
        raiseError("the vote floor must not be negative, got " + convert.toString($votes));
    }
    return setCriterion($f, "minVotes", convert.toString($votes));
}

/**
 * A copy of the filter narrowed to a runtime window, in minutes.
 *
 * For a series it is the runtime of an episode. Either end may be 0 for
 * an open interval; both are inclusive.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param minMinutes {int} the shortest acceptable runtime, 0 for no floor
 * @param maxMinutes {int} the longest acceptable runtime, 0 for no ceiling
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when a bound is negative or the range is inverted
 * @example
 *   $f = tmdb.runningBetween($f, 0, 100);   # at most 100 minutes
 */
export func runningBetween(f as DiscoverFilter, minMinutes as int, maxMinutes as int) {
    if ($minMinutes < 0 or $maxMinutes < 0) {
        raiseError("a runtime bound must not be negative");
    }
    if ($minMinutes > 0 and $maxMinutes > 0 and $minMinutes > $maxMinutes) {
        raiseError("the runtime window ends before it starts: " +
            convert.toString($minMinutes) + " to " + convert.toString($maxMinutes));
    }
    def next as DiscoverFilter init $f;
    if ($minMinutes > 0) {
        $next = setCriterion($next, "runtimeFrom", convert.toString($minMinutes));
    }
    if ($maxMinutes > 0) {
        $next = setCriterion($next, "runtimeTo", convert.toString($maxMinutes));
    }
    return $next;
}

/**
 * A copy of the filter narrowed to titles offered by a service, in a country.
 *
 * A service's catalogue differs per country, and TMDB refuses a provider
 * filter without a region, so the region is required here too. Provider
 * ids come from `movieProviders` or `showProviders`.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param providerIds {list of int} the provider ids, any of which may apply
 * @param watchRegion {string} the two-letter country, any case
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" on an empty list, a non-positive id, or a bad region
 * @example
 *   $f = tmdb.availableOn($f, [8], "DE");   # on Netflix in Germany
 */
export func availableOn(f as DiscoverFilter, providerIds as list of int, watchRegion as string) {
    def region as string init strings.upper(ensureText($watchRegion, "watch region"));
    if (not isCountryCode($region)) {
        raiseError("the watch region must be a two-letter country code, got \"" +
            $region + "\"");
    }
    def next as DiscoverFilter init setCriterion(
        $f,
        "watchProviders",
        joinIds($providerIds, "|", "provider"));
    return setCriterion($next, "watchRegion", $region);
}

/**
 * A copy of the filter excluding titles offered by listed services.
 *
 * Only takes effect alongside `availableOn`, which sets the region.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param providerIds {list of int} the provider ids to exclude
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the list is empty or holds a non-positive id
 */
export func notAvailableOn(f as DiscoverFilter, providerIds as list of int) {
    return setCriterion($f, "notWatchProviders", joinIds($providerIds, ",", "provider"));
}

/**
 * A copy of the filter narrowed to how a title is paid for.
 *
 * Takes `MONETIZATION_*` values, in any case. `MONETIZATION_FLATRATE`
 * (included in a subscription) with `availableOn` finds what a viewer can
 * stream now.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param kinds {list of string} `MONETIZATION_*` values, any of which may apply
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" on an empty list or an unknown monetization kind
 * @example
 *   $f = tmdb.withMonetization($f, [tmdb.MONETIZATION_FLATRATE, tmdb.MONETIZATION_FREE]);
 */
export func withMonetization(f as DiscoverFilter, kinds as list of string) {
    if (len($kinds) == 0) {
        raiseError("at least one monetization kind is required");
    }
    def known as list of string init [
        MONETIZATION_FLATRATE,
        MONETIZATION_FREE,
        MONETIZATION_ADS,
        MONETIZATION_RENT,
        MONETIZATION_BUY
    ];
    def cleaned as list of string init [];
    for (def kind in $kinds) {
        def value as string init strings.lower(strings.trim($kind));
        if (not lists.contains($known, $value)) {
            raiseError("\"" + $kind + "\" is not a monetization kind - use one of " +
                strings.join($known, ", "));
        }
        $cleaned[] = $value;
    }
    return setCriterion($f, "monetization", strings.join($cleaned, "|"));
}

/**
 * A copy of the filter narrowed to one age rating, in one country.
 *
 * Certifications are national systems ("PG-13" is a United States
 * rating), so the country is required. Films only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param country {string} the two-letter country whose system to use
 * @param certification {string} the exact rating, e.g. "PG-13"
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the country is not two letters or the
 *                 certification is blank
 */
export func ratedFor(f as DiscoverFilter, country as string, certification as string) {
    def next as DiscoverFilter init certificationCountry($f, $country);
    return setCriterion($next, "certification", ensureText($certification, "certification"));
}

/**
 * A copy of the filter narrowed to an age rating or a gentler one, in one country.
 *
 * `ratedUpTo($f, "US", "PG-13")` also returns G and PG. Films only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param country {string} the two-letter country whose system to use
 * @param certification {string} the strictest acceptable rating
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the country is not two letters or the
 *                 certification is blank
 */
export func ratedUpTo(f as DiscoverFilter, country as string, certification as string) {
    def next as DiscoverFilter init certificationCountry($f, $country);
    return setCriterion($next, "certificationTo", ensureText($certification, "certification"));
}

/**
 * A copy of the filter narrowed to series in one production state.
 *
 * Series only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param status {int} a `SHOW_STATUS_*` value
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the status is outside 0..5
 */
export func withShowStatus(f as DiscoverFilter, status as int) {
    if ($status < SHOW_STATUS_RETURNING or $status > SHOW_STATUS_PILOT) {
        raiseError("the series status must be one of the SHOW_STATUS_* constants (0..5), got " +
            convert.toString($status));
    }
    return setCriterion($f, "showStatus", convert.toString($status));
}

/**
 * A copy of the filter narrowed to one kind of series.
 *
 * Separates scripted series from reality television, talk shows and so
 * on. Series only.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param kind {int} a `SHOW_TYPE_*` value
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the type is outside 0..6
 */
export func withShowType(f as DiscoverFilter, kind as int) {
    if ($kind < SHOW_TYPE_DOCUMENTARY or $kind > SHOW_TYPE_VIDEO) {
        raiseError("the series type must be one of the SHOW_TYPE_* constants (0..6), got " +
            convert.toString($kind));
    }
    return setCriterion($f, "showType", convert.toString($kind));
}

/**
 * The TMDB query parameters a filter becomes on one catalogue, without a request.
 *
 * The client's language, region, adult flag and the page are not
 * included; they are added at request time.
 *
 * @param f {DiscoverFilter} the filter
 * @param forShows {bool} true to translate for `/discover/tv`, false for movies
 * @return {map of string to string} the TMDB query parameters
 * @throws {Error} kind "tmdb" when a criterion has no equivalent on that catalogue
 * @example
 *   def wire as map of string to string init tmdb.filterParams($f, false);
 *   for (def name in $wire) {
 *       io.printf("%s=%s\n", $name, $wire[$name]);
 *   }
 */
export func filterParams(f as DiscoverFilter, forShows as bool) {
    def params as map of string to string init {};
    for (def key in $f.criteria) {
        $params[wireName($key, $forShows)] = wireValue($key, $f.criteria[$key], $forShows);
    }
    return $params;
}

/**
 * Find films matching a filter, from `/discover/movie`.
 *
 * The order is `sortedBy`'s, `SORT_POPULARITY_DESC` by default. Sends the
 * client's language, adult flag and region.
 *
 * @param c {Client} an API client
 * @param f {DiscoverFilter} the criteria
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the matching films
 * @throws {Error} kind "tmdb" when the filter carries a series-only criterion,
 *                 the page is outside 1..`MAX_PAGE`, or the request fails
 */
export func discoverMovies(c as Client, f as DiscoverFilter, page as int) {
    return moviePageFrom(apiGet($c, "/3/discover/movie", discoverParams($c, $f, $page, false)));
}

/**
 * Find series matching a filter, from `/discover/tv`.
 *
 * Sends the client's language and adult flag; the region is not sent.
 *
 * @param c {Client} an API client
 * @param f {DiscoverFilter} the criteria
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the matching series
 * @throws {Error} kind "tmdb" when the filter carries a film-only criterion,
 *                 the page is outside 1..`MAX_PAGE`, or the request fails
 */
export func discoverShows(c as Client, f as DiscoverFilter, page as int) {
    return showPageFrom(apiGet($c, "/3/discover/tv", discoverParams($c, $f, $page, true)));
}

/**
 * Every film matching a filter, up to a page budget.
 *
 * Stops at the last page, at `maxPages`, or at `MAX_PAGE`, whichever
 * comes first. One request per page of 20 rows.
 *
 * @param c {Client} an API client
 * @param f {DiscoverFilter} the criteria
 * @param maxPages {int} how many pages to fetch at most
 * @return {list of MovieSummary} the rows, in the filter's sort order
 * @throws {Error} kind "tmdb" on a bad filter, a non-positive budget, or a
 *                 failed request
 */
export func discoverMoviesAll(c as Client, f as DiscoverFilter, maxPages as int) {
    ensureBudget($maxPages);
    def out as list of MovieSummary init [];
    def page as int init 1;
    while (true) {
        def batch as MoviePage init discoverMovies($c, $f, $page);
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
 * Every series matching a filter, up to a page budget.
 *
 * Same stopping rules as `discoverMoviesAll`.
 *
 * @param c {Client} an API client
 * @param f {DiscoverFilter} the criteria
 * @param maxPages {int} how many pages to fetch at most
 * @return {list of ShowSummary} the rows, in the filter's sort order
 * @throws {Error} kind "tmdb" on a bad filter, a non-positive budget, or a
 *                 failed request
 */
export func discoverShowsAll(c as Client, f as DiscoverFilter, maxPages as int) {
    ensureBudget($maxPages);
    def out as list of ShowSummary init [];
    def page as int init 1;
    while (true) {
        def batch as ShowPage init discoverShows($c, $f, $page);
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
 * A copy of the filter with one criterion set.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param key {string} the deck's key name
 * @param value {string} the value to store
 * @return {DiscoverFilter} the copy
 * @internal
 */
func setCriterion(f as DiscoverFilter, key as string, value as string) {
    def next as DiscoverFilter init $f;
    $next.criteria[$key] = $value;
    return $next;
}

/**
 * The full parameter map for one discovery request.
 *
 * @param c {Client} the client
 * @param f {DiscoverFilter} the criteria
 * @param page {int} the requested page
 * @param forShows {bool} which catalogue is being queried
 * @return {map of string to string} the query parameters
 * @throws {Error} kind "tmdb" on an inapplicable criterion or a bad page
 * @internal
 */
func discoverParams(c as Client, f as DiscoverFilter, page as int, forShows as bool) {
    def params as map of string to string init pageParams($c, $page);
    $params["include_adult"] = boolParam($c.includeAdult);
    if (not $forShows and $c.region != "") {
        $params["region"] = $c.region;
    }
    for (def key in $f.criteria) {
        $params[wireName($key, $forShows)] = wireValue($key, $f.criteria[$key], $forShows);
    }
    return $params;
}

/**
 * The TMDB parameter name a deck key maps to.
 *
 * A key with no equivalent on the asked-for catalogue throws rather than
 * being dropped.
 *
 * @param key {string} the deck's key name
 * @param forShows {bool} which catalogue is being queried
 * @return {string} the TMDB query parameter name
 * @throws {Error} kind "tmdb" when the criterion does not apply
 * @internal
 */
func wireName(key as string, forShows as bool) {
    match ($key) {
        when "sort" { return "sort_by"; }
        when "genres" { return "with_genres"; }
        when "notGenres" { return "without_genres"; }
        when "keywords" { return "with_keywords"; }
        when "notKeywords" { return "without_keywords"; }
        when "companies" { return "with_companies"; }
        when "notCompanies" { return "without_companies"; }
        when "originalLanguage" { return "with_original_language"; }
        when "originCountry" { return "with_origin_country"; }
        when "ratingFrom" { return "vote_average.gte"; }
        when "ratingTo" { return "vote_average.lte"; }
        when "minVotes" { return "vote_count.gte"; }
        when "runtimeFrom" { return "with_runtime.gte"; }
        when "runtimeTo" { return "with_runtime.lte"; }
        when "watchProviders" { return "with_watch_providers"; }
        when "notWatchProviders" { return "without_watch_providers"; }
        when "watchRegion" { return "watch_region"; }
        when "monetization" { return "with_watch_monetization_types"; }
        when "releasedFrom" { return dateParam($forShows, ".gte"); }
        when "releasedTo" { return dateParam($forShows, ".lte"); }
        when "year" { return yearParam($forShows); }
        when "people" { return moviesOnly("with_people", $forShows, "withPeople"); }
        when "cast" { return moviesOnly("with_cast", $forShows, "withCast"); }
        when "crew" { return moviesOnly("with_crew", $forShows, "withCrew"); }
        when "certification" { return moviesOnly("certification", $forShows, "ratedFor"); }
        when "certificationTo" { return moviesOnly("certification.lte", $forShows, "ratedUpTo"); }
        when "certificationCountry" {
            return moviesOnly("certification_country", $forShows, "ratedFor");
        }
        when "networks" { return showsOnly("with_networks", $forShows, "withNetworks"); }
        when "showStatus" { return showsOnly("with_status", $forShows, "withShowStatus"); }
        when "showType" { return showsOnly("with_type", $forShows, "withShowType"); }
        else {
            raiseError("unknown discovery criterion \"" + $key + "\" - build filters with " +
                "the builder functions, not by editing `criteria`");
        }
    }
    return "";
}

/**
 * The value a deck key sends, once the catalogue is known.
 *
 * Only the sort order is translated; other values are already wire values.
 *
 * @param key {string} the deck's key name
 * @param value {string} the stored value
 * @param forShows {bool} which catalogue is being queried
 * @return {string} the value to send
 * @internal
 */
func wireValue(key as string, value as string, forShows as bool) {
    if ($key != "sort") {
        return $value;
    }
    match ($value) {
        when SORT_RATING_DESC { return "vote_average.desc"; }
        when SORT_RATING_ASC { return "vote_average.asc"; }
        when SORT_VOTES_DESC { return "vote_count.desc"; }
        when SORT_NEWEST { return dateParam($forShows, ".desc"); }
        when SORT_OLDEST { return dateParam($forShows, ".asc"); }
        when SORT_TITLE_ASC { return titleSort($forShows, ".asc"); }
        when SORT_TITLE_DESC { return titleSort($forShows, ".desc"); }
        else { return $value; }
    }
    return $value;
}

/**
 * The date field of a catalogue, with a suffix.
 *
 * @param forShows {bool} which catalogue is being queried
 * @param suffix {string} the comparator or direction, e.g. ".gte"
 * @return {string} the parameter or sort field
 * @internal
 */
func dateParam(forShows as bool, suffix as string) {
    if ($forShows) {
        return "first_air_date" + $suffix;
    }
    return "primary_release_date" + $suffix;
}

/**
 * The year field of a catalogue.
 *
 * @param forShows {bool} which catalogue is being queried
 * @return {string} the parameter name
 * @internal
 */
func yearParam(forShows as bool) {
    if ($forShows) {
        return "first_air_date_year";
    }
    return "primary_release_year";
}

/**
 * The title-sort field of a catalogue, with a direction.
 *
 * @param forShows {bool} which catalogue is being queried
 * @param suffix {string} ".asc" or ".desc"
 * @return {string} the sort field
 * @internal
 */
func titleSort(forShows as bool, suffix as string) {
    if ($forShows) {
        return "name" + $suffix;
    }
    return "title" + $suffix;
}

/**
 * Pass a film-only parameter through, or refuse it on the series side.
 *
 * @param name {string} the TMDB parameter name
 * @param forShows {bool} which catalogue is being queried
 * @param builder {string} the builder that set it, for the message
 * @return {string} the parameter name
 * @throws {Error} kind "tmdb" when querying series
 * @internal
 */
func moviesOnly(name as string, forShows as bool, builder as string) {
    if ($forShows) {
        raiseError($builder + " filters films, and this filter is being run against the " +
            "series catalogue - build a separate filter for discoverShows");
    }
    return $name;
}

/**
 * Pass a series-only parameter through, or refuse it on the film side.
 *
 * @param name {string} the TMDB parameter name
 * @param forShows {bool} which catalogue is being queried
 * @param builder {string} the builder that set it, for the message
 * @return {string} the parameter name
 * @throws {Error} kind "tmdb" when querying films
 * @internal
 */
func showsOnly(name as string, forShows as bool, builder as string) {
    if (not $forShows) {
        raiseError($builder + " filters series, and this filter is being run against the " +
            "film catalogue - build a separate filter for discoverMovies");
    }
    return $name;
}

/**
 * A copy of the filter with the certification country set.
 *
 * @param f {DiscoverFilter} the filter to copy
 * @param country {string} the two-letter country code
 * @return {DiscoverFilter} the copy
 * @throws {Error} kind "tmdb" when the code is not two letters
 * @internal
 */
func certificationCountry(f as DiscoverFilter, country as string) {
    def code as string init strings.upper(ensureText($country, "certification country"));
    if (not isCountryCode($code)) {
        raiseError("the certification country must be two letters, got \"" + $code + "\"");
    }
    return setCriterion($f, "certificationCountry", $code);
}

/**
 * Join ids into the list TMDB expects, checking each one.
 *
 * @param ids {list of int} the ids
 * @param separator {string} "," for "and", "|" for "or"
 * @param what {string} what the ids identify, for the message
 * @return {string} the joined list
 * @throws {Error} kind "tmdb" on an empty list or a non-positive id
 * @internal
 */
func joinIds(ids as list of int, separator as string, what as string) {
    if (len($ids) == 0) {
        raiseError("at least one " + $what + " id is required");
    }
    def parts as list of string init [];
    for (def id in $ids) {
        $parts[] = convert.toString(ensureId($id, $what));
    }
    return strings.join($parts, $separator);
}

/**
 * Refuse a rating outside the scale TMDB uses.
 *
 * @param score {float} the candidate score
 * @return {float} the same score
 * @throws {Error} kind "tmdb" when the score is outside 0..10
 * @internal
 */
func ensureScore(score as float) {
    if ($score < 0.0 or $score > 10.0) {
        raiseError("a rating must be between 0 and 10, got " + convert.toString($score));
    }
    return $score;
}

/**
 * Refuse anything that is not a `YYYY-MM-DD` date.
 *
 * @param date {string} the candidate date
 * @return {string} the same date
 * @throws {Error} kind "tmdb" when the shape is wrong
 * @internal
 */
func ensureDate(date as string) {
    def text as string init strings.trim($date);
    def parts as list of string init strings.split($text, "-");
    if (not isCalendarDate($parts)) {
        raiseError("a date must look like YYYY-MM-DD, got \"" + $text + "\"");
    }
    return $text;
}

/**
 * Whether a dash-split date has the three all-digit parts of `YYYY-MM-DD`.
 *
 * @param parts {list of string} the date split on "-"
 * @return {bool} true when the shape is right
 * @internal
 */
func isCalendarDate(parts as list of string) {
    if (len($parts) != 3) {
        return false;
    }
    def widths as list of int init [4, 2, 2];
    for (def i in 0..3) {
        if (len($parts[$i]) != $widths[$i] or not isDigits($parts[$i])) {
            return false;
        }
    }
    return true;
}
