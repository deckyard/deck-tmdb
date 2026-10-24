# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the account topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testAccountPath() {
    testing.assertEqual(
        accountPath("4bc8892a017a3c0f92000002", "/lists"),
        "/4/account/4bc8892a017a3c0f92000002/lists");
    testing.assertEqual(
        accountPath("  4bc8892a017a3c0f92000002  ", "/movie/favorites"),
        "/4/account/4bc8892a017a3c0f92000002/movie/favorites");
}

func testEnsureAccountIdCatchesTheV3IdMistake() {
    # the v3 account id is a plain number and the v4 one is a hex string;
    # reaching for the wrong one is a 404 with nothing to explain it
    testing.assertThrows("accountIdThatIsNumeric", "tmdb");
    try {
        ensureAccountId("548");
        testing.assertTrue(false);
    } catch (e) {
        testing.assertContains($e.message, "v3 account id");
        testing.assertContains($e.message, "object");
    }
}

func accountIdThatIsNumeric() {
    ensureAccountId("548");
}

func testEnsureAccountIdRefusesPathCharacters() {
    testing.assertThrows("accountIdWithASlash", "tmdb");
    testing.assertThrows("accountIdWithTraversal", "tmdb");
    testing.assertThrows("accountIdThatIsBlank", "tmdb");
}

func accountIdWithASlash() {
    ensureAccountId("abc/def");
}

func accountIdWithTraversal() {
    ensureAccountId("..");
}

func accountIdThatIsBlank() {
    ensureAccountId("  ");
}

func testEnsureAccountSort() {
    for (def sort in [
        ACCOUNT_SORT_ADDED_ASC,
        ACCOUNT_SORT_ADDED_DESC,
        ACCOUNT_SORT_RELEASE_ASC,
        ACCOUNT_SORT_RELEASE_DESC,
        ACCOUNT_SORT_TITLE_ASC,
        ACCOUNT_SORT_TITLE_DESC,
        ACCOUNT_SORT_RATING_ASC,
        ACCOUNT_SORT_RATING_DESC
    ]) {
        testing.assertEqual(ensureAccountSort($sort), $sort);
    }
    testing.assertThrows("accountSortThatIsMadeUp", "tmdb");
}

func accountSortThatIsMadeUp() {
    ensureAccountSort("popularity.desc");
}

func testAccountVerbsNeedAUserToken() {
    testing.assertThrows("accountListsWithoutAUser", "tmdb");
    testing.assertThrows("favoriteMoviesWithoutAUser", "tmdb");
    testing.assertThrows("favoriteShowsWithoutAUser", "tmdb");
    testing.assertThrows("ratedMoviesWithoutAUser", "tmdb");
    testing.assertThrows("ratedShowsWithoutAUser", "tmdb");
    testing.assertThrows("watchlistMoviesWithoutAUser", "tmdb");
    testing.assertThrows("watchlistShowsWithoutAUser", "tmdb");
    testing.assertThrows("recommendedMoviesWithoutAUser", "tmdb");
    testing.assertThrows("recommendedShowsWithoutAUser", "tmdb");
}

func accountListsWithoutAUser() {
    accountLists(client("t"), "4bc8892a017a3c0f92000002", 1);
}

func favoriteMoviesWithoutAUser() {
    favoriteMovies(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func favoriteShowsWithoutAUser() {
    favoriteShows(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func ratedMoviesWithoutAUser() {
    ratedMovies(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func ratedShowsWithoutAUser() {
    ratedShows(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func watchlistMoviesWithoutAUser() {
    watchlistMovies(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func watchlistShowsWithoutAUser() {
    watchlistShows(client("t"), "4bc8892a017a3c0f92000002", 1, "");
}

func recommendedMoviesWithoutAUser() {
    recommendedMovies(client("t"), "4bc8892a017a3c0f92000002", 1);
}

func recommendedShowsWithoutAUser() {
    recommendedShows(client("t"), "4bc8892a017a3c0f92000002", 1);
}

func testTheMissingUserErrorPointsAtTheApprovalFlow() {
    try {
        accountLists(client("t"), "4bc8892a017a3c0f92000002", 1);
        testing.assertTrue(false);
    } catch (e) {
        testing.assertContains($e.message, "user access token");
        testing.assertContains($e.message, "withUserToken");
    }
}

func testAccountVerbsValidateTheirArgumentsToo() {
    testing.assertThrows("accountListsAtPageZero", "tmdb");
    testing.assertThrows("favoriteMoviesWithABadSort", "tmdb");
    testing.assertThrows("favoriteMoviesWithAV3AccountId", "tmdb");
}

func accountListsAtPageZero() {
    accountLists(signedInClient(), "4bc8892a017a3c0f92000002", 0);
}

func favoriteMoviesWithABadSort() {
    favoriteMovies(signedInClient(), "4bc8892a017a3c0f92000002", 1, "popularity.desc");
}

func favoriteMoviesWithAV3AccountId() {
    favoriteMovies(signedInClient(), "548", 1, "");
}

func testListSummaryFoldNormalizesTheV4Spellings() {
    def doc as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{
            "account_object_id": "4bc8892a017a3c0f92000002",
            "adult": 0,
            "average_rating": 7.8,
            "created_at": "2021-03-15T10:00:00Z",
            "description": "films worth a second look",
            "featured": 0,
            "id": 8175284,
            "iso_3166_1": "US",
            "iso_639_1": "en",
            "name": "Rewatch",
            "number_of_items": 42,
            "public": 1,
            "revenue": "1234567",
            "runtime": 5040,
            "sort_by": 1,
            "updated_at": "2026-01-02T09:30:00Z"
        }]}');
    def page as ListPage init listPageFrom($doc);
    testing.assertEqual($page.page, 1);
    testing.assertEqual($page.totalResults, 1);
    def one as ListSummary init $page.results[0];
    testing.assertEqual($one.id, 8175284);
    testing.assertEqual($one.name, "Rewatch");
    testing.assertEqual($one.numberOfItems, 42);
    # v4 writes its booleans as 1 / 0 where v3 writes true / false
    testing.assertTrue($one.public);
    testing.assertFalse($one.adult);
    testing.assertFalse($one.featured);
    # ... and its revenue as a string
    testing.assertEqual($one.revenue, 1234567);
    testing.assertEqual($one.runtime, 5040);
    testing.assertEqual($one.region, "US");
    testing.assertEqual($one.language, "en");
    testing.assertEqual($one.averageRating, 7.8);
    testing.assertEqual($one.accountObjectId, "4bc8892a017a3c0f92000002");
}

/**
 * A client that is acting for a signed-in person.
 *
 * @return {Client} a client with both an application and a user token
 * @internal
 */
func signedInClient() {
    return withUserToken(client("app"), "user");
}
