# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the discovery topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j
#
# The translation table is the whole point of this topic, so it is tested
# key by key on both catalogues rather than by sampling.

func testAnEmptyFilterHasNoCriteria() {
    testing.assertEqual(len(discoverFilter().criteria), 0);
    testing.assertEqual(len(filterParams(discoverFilter(), false)), 0);
}

func testBuildersReturnFreshFilters() {
    def base as DiscoverFilter init discoverFilter();
    def narrowed as DiscoverFilter init withGenres($base, [878]);
    testing.assertEqual(len($base.criteria), 0);
    testing.assertEqual(len($narrowed.criteria), 1);
    # two branches off one base do not see each other
    def a as DiscoverFilter init releasedInYear($base, 1999);
    def b as DiscoverFilter init releasedInYear($base, 2001);
    testing.assertEqual(filterParams($a, false)["primary_release_year"], "1999");
    testing.assertEqual(filterParams($b, false)["primary_release_year"], "2001");
}

func testGenreJoiningIsAndVersusOr() {
    testing.assertEqual(
        filterParams(withGenres(discoverFilter(), [878, 53]), false)["with_genres"],
        "878,53");
    testing.assertEqual(
        filterParams(withAnyGenre(discoverFilter(), [27, 53]), false)["with_genres"],
        "27|53");
    testing.assertEqual(
        filterParams(withoutGenres(discoverFilter(), [99]), false)["without_genres"],
        "99");
}

func testKeywordAndCompanyJoining() {
    testing.assertEqual(
        filterParams(withKeywords(discoverFilter(), [1, 2]), false)["with_keywords"],
        "1,2");
    testing.assertEqual(
        filterParams(withAnyKeyword(discoverFilter(), [1, 2]), false)["with_keywords"],
        "1|2");
    testing.assertEqual(
        filterParams(withoutKeywords(discoverFilter(), [3]), false)["without_keywords"],
        "3");
    testing.assertEqual(
        filterParams(withCompanies(discoverFilter(), [41077, 2]), false)["with_companies"],
        "41077|2");
    testing.assertEqual(
        filterParams(withoutCompanies(discoverFilter(), [4]), false)["without_companies"],
        "4");
}

func testJoinIdsRefusesEmptyAndBadIds() {
    testing.assertEqual(joinIds([1, 2, 3], ",", "genre"), "1,2,3");
    testing.assertEqual(joinIds([7], "|", "genre"), "7");
    testing.assertThrows("joinNoIds", "tmdb");
    testing.assertThrows("joinAZeroId", "tmdb");
}

func joinNoIds() {
    withGenres(discoverFilter(), []);
}

func joinAZeroId() {
    withGenres(discoverFilter(), [878, 0]);
}

func testDateAndYearTranslatePerCatalogue() {
    def f as DiscoverFilter init releasedBetween(discoverFilter(), "1990-01-01", "1999-12-31");
    def films as map of string to string init filterParams($f, false);
    testing.assertEqual($films["primary_release_date.gte"], "1990-01-01");
    testing.assertEqual($films["primary_release_date.lte"], "1999-12-31");
    def series as map of string to string init filterParams($f, true);
    testing.assertEqual($series["first_air_date.gte"], "1990-01-01");
    testing.assertEqual($series["first_air_date.lte"], "1999-12-31");

    def y as DiscoverFilter init releasedInYear(discoverFilter(), 1999);
    testing.assertEqual(filterParams($y, false)["primary_release_year"], "1999");
    testing.assertEqual(filterParams($y, true)["first_air_date_year"], "1999");
}

func testAnOpenEndedWindowSendsOnlyOneBound() {
    def since as map of string to string init filterParams(
        releasedBetween(discoverFilter(), "2020-01-01", ""),
        false);
    testing.assertEqual($since["primary_release_date.gte"], "2020-01-01");
    testing.assertFalse(maps.has($since, "primary_release_date.lte"));

    def ceiling as map of string to string init filterParams(
        releasedBetween(discoverFilter(), "", "1979-12-31"),
        false);
    testing.assertFalse(maps.has($ceiling, "primary_release_date.gte"));
    testing.assertEqual($ceiling["primary_release_date.lte"], "1979-12-31");
}

func testReleaseWindowValidation() {
    testing.assertThrows("windowWithNoEnds", "tmdb");
    testing.assertThrows("windowThatIsInverted", "tmdb");
    testing.assertThrows("windowWithABadDate", "tmdb");
}

func windowWithNoEnds() {
    releasedBetween(discoverFilter(), "", "");
}

func windowThatIsInverted() {
    releasedBetween(discoverFilter(), "1999-12-31", "1990-01-01");
}

func windowWithABadDate() {
    releasedBetween(discoverFilter(), "1990", "");
}

func testEnsureDate() {
    testing.assertEqual(ensureDate("1999-10-15"), "1999-10-15");
    testing.assertEqual(ensureDate("  1999-10-15  "), "1999-10-15");
    testing.assertThrows("dateWithoutDays", "tmdb");
    testing.assertThrows("dateWithSlashes", "tmdb");
    testing.assertThrows("dateWithLetters", "tmdb");
    testing.assertThrows("dateWithShortYear", "tmdb");
}

func dateWithoutDays() {
    ensureDate("1999-10");
}

func dateWithSlashes() {
    ensureDate("1999/10/15");
}

func dateWithLetters() {
    ensureDate("1999-oct-15");
}

func dateWithShortYear() {
    ensureDate("99-10-15");
}

func testIsCalendarDate() {
    testing.assertTrue(isCalendarDate(["1999", "10", "15"]));
    testing.assertFalse(isCalendarDate(["1999", "10"]));
    testing.assertFalse(isCalendarDate(["1999", "1", "15"]));
    testing.assertFalse(isCalendarDate(["199a", "10", "15"]));
}

func testSortTranslation() {
    # the same constant, two different fields
    testing.assertEqual(sortValueFor(SORT_NEWEST, false), "primary_release_date.desc");
    testing.assertEqual(sortValueFor(SORT_NEWEST, true), "first_air_date.desc");
    testing.assertEqual(sortValueFor(SORT_OLDEST, false), "primary_release_date.asc");
    testing.assertEqual(sortValueFor(SORT_TITLE_ASC, false), "title.asc");
    testing.assertEqual(sortValueFor(SORT_TITLE_ASC, true), "name.asc");
    testing.assertEqual(sortValueFor(SORT_TITLE_DESC, true), "name.desc");
    testing.assertEqual(sortValueFor(SORT_RATING_DESC, false), "vote_average.desc");
    testing.assertEqual(sortValueFor(SORT_RATING_ASC, false), "vote_average.asc");
    testing.assertEqual(sortValueFor(SORT_VOTES_DESC, false), "vote_count.desc");
    # these two are already wire values on both catalogues
    testing.assertEqual(sortValueFor(SORT_POPULARITY_DESC, false), "popularity.desc");
    testing.assertEqual(sortValueFor(SORT_POPULARITY_ASC, true), "popularity.asc");
    testing.assertEqual(sortValueFor(SORT_REVENUE_DESC, false), "revenue.desc");
}

func testAnUnknownSortIsPassedThroughVerbatim() {
    # so a sort this deck has no constant for still works
    testing.assertEqual(sortValueFor("something.new", false), "something.new");
}

func testSortedByRefusesABlankSort() {
    testing.assertThrows("sortedByNothing", "tmdb");
}

func sortedByNothing() {
    sortedBy(discoverFilter(), "  ");
}

func testRatingAndVoteFilters() {
    def f as DiscoverFilter init withMinVotes(
        ratedAtMost(ratedAtLeast(discoverFilter(), 7.5), 9.5),
        1000);
    def params as map of string to string init filterParams($f, false);
    testing.assertEqual($params["vote_average.gte"], "7.5");
    testing.assertEqual($params["vote_average.lte"], "9.5");
    testing.assertEqual($params["vote_count.gte"], "1000");
    testing.assertEqual(
        filterParams(withMinVotes(discoverFilter(), 0), false)["vote_count.gte"],
        "0");
}

func testRatingBounds() {
    testing.assertEqual(ensureScore(0.0), 0.0);
    testing.assertEqual(ensureScore(10.0), 10.0);
    testing.assertThrows("ratingBelowZero", "tmdb");
    testing.assertThrows("ratingAboveTen", "tmdb");
    testing.assertThrows("negativeVoteFloor", "tmdb");
}

func ratingBelowZero() {
    ratedAtLeast(discoverFilter(), -0.5);
}

func ratingAboveTen() {
    ratedAtMost(discoverFilter(), 11.0);
}

func negativeVoteFloor() {
    withMinVotes(discoverFilter(), -1);
}

func testRuntimeWindow() {
    def both as map of string to string init filterParams(
        runningBetween(discoverFilter(), 80, 100),
        false);
    testing.assertEqual($both["with_runtime.gte"], "80");
    testing.assertEqual($both["with_runtime.lte"], "100");
    # 0 means "no bound on this end"
    def capped as map of string to string init filterParams(
        runningBetween(discoverFilter(), 0, 100),
        false);
    testing.assertFalse(maps.has($capped, "with_runtime.gte"));
    testing.assertEqual($capped["with_runtime.lte"], "100");
    testing.assertThrows("negativeRuntime", "tmdb");
    testing.assertThrows("invertedRuntime", "tmdb");
}

func negativeRuntime() {
    runningBetween(discoverFilter(), -1, 100);
}

func invertedRuntime() {
    runningBetween(discoverFilter(), 120, 90);
}

func testLanguageAndCountryFilters() {
    testing.assertEqual(
        filterParams(inOriginalLanguage(discoverFilter(), "JA"), false)["with_original_language"],
        "ja");
    testing.assertEqual(
        filterParams(fromCountry(discoverFilter(), "kr"), false)["with_origin_country"],
        "KR");
    testing.assertThrows("countryWithThreeLetters", "tmdb");
    testing.assertThrows("blankOriginalLanguage", "tmdb");
}

func countryWithThreeLetters() {
    fromCountry(discoverFilter(), "KOR");
}

func blankOriginalLanguage() {
    inOriginalLanguage(discoverFilter(), "  ");
}

func testWatchProviderFilters() {
    def f as DiscoverFilter init notAvailableOn(availableOn(discoverFilter(), [8, 337], "de"), [9]);
    def params as map of string to string init filterParams($f, false);
    testing.assertEqual($params["with_watch_providers"], "8|337");
    testing.assertEqual($params["watch_region"], "DE");
    testing.assertEqual($params["without_watch_providers"], "9");
    # the same criteria are legal on the series catalogue
    testing.assertEqual(filterParams($f, true)["watch_region"], "DE");
    testing.assertThrows("availableWithNoRegion", "tmdb");
    testing.assertThrows("availableInABadRegion", "tmdb");
}

func availableWithNoRegion() {
    availableOn(discoverFilter(), [8], "");
}

func availableInABadRegion() {
    availableOn(discoverFilter(), [8], "GER");
}

func testMonetizationFilter() {
    def f as DiscoverFilter init withMonetization(
        discoverFilter(),
        [MONETIZATION_FLATRATE, MONETIZATION_FREE]);
    testing.assertEqual(filterParams($f, false)["with_watch_monetization_types"], "flatrate|free");
    testing.assertEqual(
        filterParams(withMonetization(discoverFilter(), ["  RENT  "]), false)["with_watch_monetization_types"],
        "rent");
    testing.assertThrows("monetizationWithNothing", "tmdb");
    testing.assertThrows("monetizationThatIsMadeUp", "tmdb");
}

func monetizationWithNothing() {
    withMonetization(discoverFilter(), []);
}

func monetizationThatIsMadeUp() {
    withMonetization(discoverFilter(), ["subscription"]);
}

func testCertificationFilters() {
    def exact as map of string to string init filterParams(
        ratedFor(discoverFilter(), "us", "PG-13"),
        false);
    testing.assertEqual($exact["certification_country"], "US");
    testing.assertEqual($exact["certification"], "PG-13");

    def upTo as map of string to string init filterParams(
        ratedUpTo(discoverFilter(), "DE", "12"),
        false);
    testing.assertEqual($upTo["certification_country"], "DE");
    testing.assertEqual($upTo["certification.lte"], "12");

    testing.assertThrows("certificationInABadCountry", "tmdb");
    testing.assertThrows("blankCertification", "tmdb");
}

func certificationInABadCountry() {
    ratedFor(discoverFilter(), "USA", "PG-13");
}

func blankCertification() {
    ratedFor(discoverFilter(), "US", "  ");
}

func testSeriesOnlyFilters() {
    def f as DiscoverFilter init withShowType(
        withShowStatus(withNetworks(discoverFilter(), [49]), SHOW_STATUS_RETURNING),
        SHOW_TYPE_SCRIPTED);
    def params as map of string to string init filterParams($f, true);
    testing.assertEqual($params["with_networks"], "49");
    testing.assertEqual($params["with_status"], "0");
    testing.assertEqual($params["with_type"], "4");
    testing.assertThrows("statusOutOfRange", "tmdb");
    testing.assertThrows("typeOutOfRange", "tmdb");
}

func statusOutOfRange() {
    withShowStatus(discoverFilter(), 6);
}

func typeOutOfRange() {
    withShowType(discoverFilter(), 7);
}

func testFilmOnlyFilters() {
    def f as DiscoverFilter init withCrew(
        withCast(withPeople(discoverFilter(), [1245]), [819]),
        [7467]);
    def params as map of string to string init filterParams($f, false);
    testing.assertEqual($params["with_people"], "1245");
    testing.assertEqual($params["with_cast"], "819");
    testing.assertEqual($params["with_crew"], "7467");
}

func testACatalogueMismatchIsRefusedRatherThanIgnored() {
    # a network on the film catalogue, and a person filter on the series one
    testing.assertThrows("networksAgainstFilms", "tmdb");
    testing.assertThrows("statusAgainstFilms", "tmdb");
    testing.assertThrows("typeAgainstFilms", "tmdb");
    testing.assertThrows("peopleAgainstSeries", "tmdb");
    testing.assertThrows("castAgainstSeries", "tmdb");
    testing.assertThrows("crewAgainstSeries", "tmdb");
    testing.assertThrows("certificationAgainstSeries", "tmdb");
    testing.assertThrows("certificationCeilingAgainstSeries", "tmdb");
}

func networksAgainstFilms() {
    filterParams(withNetworks(discoverFilter(), [49]), false);
}

func statusAgainstFilms() {
    filterParams(withShowStatus(discoverFilter(), SHOW_STATUS_ENDED), false);
}

func typeAgainstFilms() {
    filterParams(withShowType(discoverFilter(), SHOW_TYPE_REALITY), false);
}

func peopleAgainstSeries() {
    filterParams(withPeople(discoverFilter(), [1245]), true);
}

func castAgainstSeries() {
    filterParams(withCast(discoverFilter(), [1245]), true);
}

func crewAgainstSeries() {
    filterParams(withCrew(discoverFilter(), [525]), true);
}

func certificationAgainstSeries() {
    filterParams(ratedFor(discoverFilter(), "US", "PG-13"), true);
}

func certificationCeilingAgainstSeries() {
    filterParams(ratedUpTo(discoverFilter(), "US", "PG-13"), true);
}

func testTheMismatchErrorNamesTheBuilder() {
    try {
        filterParams(withNetworks(discoverFilter(), [49]), false);
        testing.assertTrue(false);
    } catch (e) {
        testing.assertContains($e.message, "withNetworks");
        testing.assertContains($e.message, "discoverMovies");
    }
}

func testAHandEditedCriterionIsRefused() {
    def f as DiscoverFilter init discoverFilter();
    $f.criteria["madeUp"] = "x";
    testing.assertThrows("filterWithAnUnknownCriterion", "tmdb");
}

func filterWithAnUnknownCriterion() {
    def f as DiscoverFilter init discoverFilter();
    $f.criteria["madeUp"] = "x";
    filterParams($f, false);
}

func testDiscoverParamsAddsThePageAndClientSettings() {
    def c as Client init withRegion(withAdult(client("t"), true), "DE");
    def params as map of string to string init discoverParams(
        $c,
        withGenres(discoverFilter(), [878]),
        3,
        false);
    testing.assertEqual($params["page"], "3");
    testing.assertEqual($params["language"], DEFAULT_LANGUAGE);
    testing.assertEqual($params["include_adult"], "true");
    testing.assertEqual($params["region"], "DE");
    testing.assertEqual($params["with_genres"], "878");
    # `region` is a film-only parameter
    testing.assertFalse(maps.has(discoverParams($c, discoverFilter(), 1, true), "region"));
}

func testDiscoverValidatesThePage() {
    testing.assertThrows("discoverAtPageZero", "tmdb");
    testing.assertThrows("discoverShowsPastTheCeiling", "tmdb");
    testing.assertThrows("discoverWalkWithNoBudget", "tmdb");
    testing.assertThrows("discoverShowWalkWithNoBudget", "tmdb");
}

func discoverAtPageZero() {
    discoverMovies(client("t"), discoverFilter(), 0);
}

func discoverShowsPastTheCeiling() {
    discoverShows(client("t"), discoverFilter(), MAX_PAGE + 1);
}

func discoverWalkWithNoBudget() {
    discoverMoviesAll(client("t"), discoverFilter(), 0);
}

func discoverShowWalkWithNoBudget() {
    discoverShowsAll(client("t"), discoverFilter(), 0);
}

/**
 * What one sort constant becomes on one catalogue.
 *
 * @param sort {string} the `SORT_*` constant, or a raw sort string
 * @param forShows {bool} which catalogue is being queried
 * @return {string} the value that would be sent
 * @internal
 */
func sortValueFor(sort as string, forShows as bool) {
    return filterParams(sortedBy(discoverFilter(), $sort), $forShows)["sort_by"];
}
