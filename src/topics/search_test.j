# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the search topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testSearchParams() {
    def params as map of string to string init searchParams(client("t"), "  blade runner  ", 2);
    testing.assertEqual($params["query"], "blade runner");
    testing.assertEqual($params["page"], "2");
    testing.assertEqual($params["language"], DEFAULT_LANGUAGE);
    testing.assertEqual($params["include_adult"], "false");
}

func testSearchParamsCarriesTheAdultFlag() {
    testing.assertEqual(
        searchParams(withAdult(client("t"), true), "q", 1)["include_adult"],
        "true");
}

func testSearchRefusesABlankQuery() {
    testing.assertThrows("searchWithBlankQuery", "tmdb");
    testing.assertThrows("searchMultiWithBlankQuery", "tmdb");
    testing.assertThrows("searchCompaniesWithBlankQuery", "tmdb");
    testing.assertThrows("searchKeywordsWithBlankQuery", "tmdb");
}

func searchWithBlankQuery() {
    searchMovies(client("t"), "   ", 1);
}

func searchMultiWithBlankQuery() {
    searchMulti(client("t"), "", 1);
}

func searchCompaniesWithBlankQuery() {
    searchCompanies(client("t"), "", 1);
}

func searchKeywordsWithBlankQuery() {
    searchKeywords(client("t"), "", 1);
}

func testSearchRefusesABadPage() {
    testing.assertThrows("searchAtPageZero", "tmdb");
    testing.assertThrows("searchPastTheCeiling", "tmdb");
}

func searchAtPageZero() {
    searchShows(client("t"), "the office", 0);
}

func searchPastTheCeiling() {
    searchPeople(client("t"), "hanks", MAX_PAGE + 1);
}

func testEnsureYear() {
    testing.assertEqual(ensureYear(1982), 1982);
    testing.assertEqual(ensureYear(1800), 1800);
    testing.assertEqual(ensureYear(2200), 2200);
    testing.assertThrows("yearBeforeCinema", "tmdb");
    testing.assertThrows("yearFarInTheFuture", "tmdb");
}

func yearBeforeCinema() {
    ensureYear(1799);
}

func yearFarInTheFuture() {
    ensureYear(2201);
}

func testYearNarrowedSearchesValidateTheYear() {
    testing.assertThrows("searchMoviesInABadYear", "tmdb");
    testing.assertThrows("searchShowsInABadYear", "tmdb");
}

func searchMoviesInABadYear() {
    searchMoviesInYear(client("t"), "the thing", 82, 1);
}

func searchShowsInABadYear() {
    searchShowsInYear(client("t"), "the office", 0, 1);
}

func testEnsureBudget() {
    testing.assertEqual(ensureBudget(1), 1);
    testing.assertEqual(ensureBudget(25), 25);
    testing.assertThrows("budgetOfZero", "tmdb");
    testing.assertThrows("negativeBudget", "tmdb");
}

func budgetOfZero() {
    ensureBudget(0);
}

func negativeBudget() {
    ensureBudget(-3);
}

func testPageWalkersValidateTheirBudget() {
    testing.assertThrows("walkMoviesWithNoBudget", "tmdb");
    testing.assertThrows("walkShowsWithNoBudget", "tmdb");
}

func walkMoviesWithNoBudget() {
    searchMoviesAll(client("t"), "alien", 0);
}

func walkShowsWithNoBudget() {
    searchShowsAll(client("t"), "alien", 0);
}

func testSearchCollectionsValidatesQueryAndPage() {
    testing.assertThrows("searchCollectionsWithBlankQuery", "tmdb");
    testing.assertThrows("searchCollectionsAtPageZero", "tmdb");
    testing.assertThrows("searchCollectionsPastTheCeiling", "tmdb");
}

func searchCollectionsWithBlankQuery() {
    searchCollections(client("t"), " ", 1);
}

func searchCollectionsAtPageZero() {
    searchCollections(client("t"), "star wars", 0);
}

func searchCollectionsPastTheCeiling() {
    searchCollections(client("t"), "star wars", MAX_PAGE + 1);
}
