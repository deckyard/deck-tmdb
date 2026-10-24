# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the browse topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testTrendingPath() {
    testing.assertEqual(trendingPath("all", TREND_DAY), "/3/trending/all/day");
    testing.assertEqual(trendingPath("movie", TREND_WEEK), "/3/trending/movie/week");
    testing.assertEqual(trendingPath("tv", "WEEK"), "/3/trending/tv/week");
    testing.assertEqual(trendingPath("person", "  day  "), "/3/trending/person/day");
}

func testTrendingRefusesAnUnknownWindow() {
    testing.assertThrows("trendingOverAMonth", "tmdb");
    testing.assertThrows("trendingOverNothing", "tmdb");
    testing.assertThrows("trendingMoviesOverAMonth", "tmdb");
    testing.assertThrows("trendingShowsOverAMonth", "tmdb");
    testing.assertThrows("trendingPeopleOverAMonth", "tmdb");
}

func trendingOverAMonth() {
    trendingAll(client("t"), "month", 1);
}

func trendingOverNothing() {
    trendingAll(client("t"), "", 1);
}

func trendingMoviesOverAMonth() {
    trendingMovies(client("t"), "month", 1);
}

func trendingShowsOverAMonth() {
    trendingShows(client("t"), "month", 1);
}

func trendingPeopleOverAMonth() {
    trendingPeople(client("t"), "month", 1);
}

func testTrendingValidatesThePage() {
    testing.assertThrows("trendingAtPageZero", "tmdb");
}

func trendingAtPageZero() {
    trendingAll(client("t"), TREND_DAY, 0);
}

func testProviderParams() {
    testing.assertEqual(providerParams(client("t"), "de")["watch_region"], "DE");
    testing.assertEqual(providerParams(client("t"), "  ")["language"], DEFAULT_LANGUAGE);
    # "" means "every country", so the parameter is omitted rather than sent empty
    testing.assertFalse(maps.has(providerParams(client("t"), ""), "watch_region"));
    testing.assertThrows("providersInABadRegion", "tmdb");
    testing.assertThrows("movieProvidersInABadRegion", "tmdb");
    testing.assertThrows("showProvidersInABadRegion", "tmdb");
}

func providersInABadRegion() {
    providerParams(client("t"), "GER");
}

func movieProvidersInABadRegion() {
    movieProviders(client("t"), "GER");
}

func showProvidersInABadRegion() {
    showProviders(client("t"), "GER");
}

func testChangeParams() {
    def bounded as map of string to string init changeParams(
        client("t"),
        "2026-08-01",
        "2026-08-08",
        2);
    testing.assertEqual($bounded["start_date"], "2026-08-01");
    testing.assertEqual($bounded["end_date"], "2026-08-08");
    testing.assertEqual($bounded["page"], "2");
    # both ends empty means TMDB's own default window
    def defaulted as map of string to string init changeParams(client("t"), "", "", 1);
    testing.assertFalse(maps.has($defaulted, "start_date"));
    testing.assertFalse(maps.has($defaulted, "end_date"));
    testing.assertEqual($defaulted["page"], "1");
}

func testChangeFeedsValidateTheirArguments() {
    testing.assertThrows("changedMoviesWithABadDate", "tmdb");
    testing.assertThrows("changedShowsAtPageZero", "tmdb");
    testing.assertThrows("changedPeopleWithABadDate", "tmdb");
}

func changedMoviesWithABadDate() {
    changedMovies(client("t"), "2026/08/01", "", 1);
}

func changedShowsAtPageZero() {
    changedShows(client("t"), "", "", 0);
}

func changedPeopleWithABadDate() {
    changedPeople(client("t"), "", "08-2026", 1);
}

func testCertificationsFoldEnumeratesTheCountryKeys() {
    def doc as json.Value init json.decode('{"certifications": {
        "US": [
            {"certification": "G", "meaning": "All ages admitted.", "order": 1},
            {"certification": "PG-13", "meaning": "Some material may be inappropriate.",
             "order": 3}],
        "CA-QC": [{"certification": "G", "meaning": "General.", "order": 1}]
    }}');
    def groups as list of CertificationGroup init certificationsFrom($doc);
    testing.assertEqual(len($groups), 2);
    testing.assertEqual($groups[0].region, "US");
    testing.assertEqual(len($groups[0].certifications), 2);
    testing.assertEqual($groups[0].certifications[1].certification, "PG-13");
    testing.assertEqual($groups[0].certifications[1].order, 3);
    # a hyphenated key is a valid JSON Pointer token and must survive
    testing.assertEqual($groups[1].region, "CA-QC");
    testing.assertEqual($groups[1].certifications[0].meaning, "General.");
    testing.assertEqual(len(certificationsFrom(json.decode('{}'))), 0);
}

func testCertificationsIn() {
    def groups as list of CertificationGroup init certificationsFrom(json.decode('{"certifications": {"DE": [{"certification": "12", "meaning": "x", "order": 3}]}}'));
    testing.assertEqual(len(certificationsIn($groups, "DE")), 1);
    testing.assertEqual(certificationsIn($groups, "de")[0].certification, "12");
    testing.assertEqual(len(certificationsIn($groups, "US")), 0);
    testing.assertEqual(len(certificationsIn([], "DE")), 0);
}

func testChangePageFold() {
    def doc as json.Value init json.decode('{
        "results": [{"id": 550, "adult": false}, {"id": 1, "adult": true}],
        "page": 1, "total_pages": 3, "total_results": 42}');
    def page as ChangePage init changePageFrom($doc);
    testing.assertEqual($page.page, 1);
    testing.assertEqual($page.totalPages, 3);
    testing.assertEqual($page.totalResults, 42);
    testing.assertEqual(len($page.results), 2);
    testing.assertEqual($page.results[0].id, 550);
    testing.assertFalse($page.results[0].adult);
    testing.assertTrue($page.results[1].adult);
}

func testGenreListVerbsValidateNothingElse() {
    # the genre lists take no arguments beyond the client, so the language is
    # the only thing that reaches the wire
    testing.assertEqual(localeParams(withLanguage(client("t"), "de"))["language"], "de");
}

func testListVerbsAskForTheirEndpoints() {
    assertRequested(movieCertificationsRequest, "GET " + API_BASE + "/3/certification/movie/list");
    assertRequested(showCertificationsRequest, "GET " + API_BASE + "/3/certification/tv/list");
    assertRequested(movieGenresRequest, "GET " + API_BASE + "/3/genre/movie/list");
    assertRequested(showGenresRequest, "GET " + API_BASE + "/3/genre/tv/list");
    assertRequested(providerRegionsRequest, "GET " + API_BASE + "/3/watch/providers/regions");
}

func movieCertificationsRequest(c as Client) {
    movieCertifications($c);
}

func showCertificationsRequest(c as Client) {
    showCertifications($c);
}

func movieGenresRequest(c as Client) {
    movieGenres($c);
}

func showGenresRequest(c as Client) {
    showGenres($c);
}

func providerRegionsRequest(c as Client) {
    providerRegions($c);
}
