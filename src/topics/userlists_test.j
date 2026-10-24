# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the custom-list topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testListPath() {
    testing.assertEqual(listPath(8175284, ""), "/4/list/8175284");
    testing.assertEqual(listPath(8175284, "/items"), "/4/list/8175284/items");
    testing.assertEqual(listPath(8175284, "/clear"), "/4/list/8175284/clear");
    testing.assertEqual(listPath(8175284, "/item_status"), "/4/list/8175284/item_status");
    testing.assertThrows("listPathWithZeroId", "tmdb");
}

func listPathWithZeroId() {
    listPath(0, "");
}

func testListItem() {
    def film as ListItem init listItem(MediaKind.Movie, 550);
    testing.assertTrue($film.kind == MediaKind.Movie);
    testing.assertEqual($film.id, 550);
    testing.assertEqual(listItem(MediaKind.Show, 1399).id, 1399);
}

func testEnsureListKind() {
    # a list holds films and series and nothing else
    ensureListKind(MediaKind.Movie);
    ensureListKind(MediaKind.Show);
    testing.assertThrows("listItemForAPerson", "tmdb");
    testing.assertThrows("listItemForAnEpisode", "tmdb");
    testing.assertThrows("listItemForASeason", "tmdb");
    testing.assertThrows("listItemOfUnknownKind", "tmdb");
    testing.assertThrows("listItemWithZeroId", "tmdb");
}

func listItemForAPerson() {
    listItem(MediaKind.Person, 31);
}

func listItemForAnEpisode() {
    listItem(MediaKind.Episode, 63056);
}

func listItemForASeason() {
    listItem(MediaKind.Season, 3624);
}

func listItemOfUnknownKind() {
    listItem(MediaKind.Unknown, 1);
}

func listItemWithZeroId() {
    listItem(MediaKind.Movie, 0);
}

func testEnsureListSort() {
    for (def sort in [
        LIST_SORT_ORIGINAL_ASC,
        LIST_SORT_ORIGINAL_DESC,
        LIST_SORT_RATING_ASC,
        LIST_SORT_RATING_DESC,
        LIST_SORT_RELEASE_ASC,
        LIST_SORT_RELEASE_DESC,
        LIST_SORT_TITLE_ASC,
        LIST_SORT_TITLE_DESC
    ]) {
        testing.assertEqual(ensureListSort($sort), $sort);
    }
    testing.assertThrows("listSortThatIsMadeUp", "tmdb");
}

func listSortThatIsMadeUp() {
    ensureListSort("popularity.desc");
}

func testItemsBody() {
    def body as json.Value init itemsBody([
        listItem(MediaKind.Movie, 550),
        listItem(MediaKind.Show, 1399)
    ]);
    testing.assertEqual(json.length($body, "/items"), 2);
    testing.assertEqual(json.asString($body, "/items/0/media_type"), "movie");
    testing.assertEqual(json.asInt($body, "/items/0/media_id"), 550);
    # the deck says "show" and the wire says "tv"
    testing.assertEqual(json.asString($body, "/items/1/media_type"), "tv");
    testing.assertEqual(json.asInt($body, "/items/1/media_id"), 1399);
}

func testItemsBodyRefusesAnEmptyRequest() {
    testing.assertThrows("itemsBodyWithNothing", "tmdb");
}

func itemsBodyWithNothing() {
    itemsBody([]);
}

func testListWriteVerbsNeedAUserToken() {
    testing.assertThrows("createListWithoutAUser", "tmdb");
    testing.assertThrows("createListInWithoutAUser", "tmdb");
    testing.assertThrows("updateListWithoutAUser", "tmdb");
    testing.assertThrows("deleteListWithoutAUser", "tmdb");
    testing.assertThrows("clearListWithoutAUser", "tmdb");
    testing.assertThrows("addItemsWithoutAUser", "tmdb");
    testing.assertThrows("removeItemsWithoutAUser", "tmdb");
}

func createListWithoutAUser() {
    createList(client("t"), "Rewatch", "", false);
}

func createListInWithoutAUser() {
    createListIn(client("t"), "Rewatch", "", false, "en", "US");
}

func updateListWithoutAUser() {
    updateList(client("t"), 8175284, "Rewatch", "", true, "");
}

func deleteListWithoutAUser() {
    deleteList(client("t"), 8175284);
}

func clearListWithoutAUser() {
    clearList(client("t"), 8175284);
}

func addItemsWithoutAUser() {
    addListItems(client("t"), 8175284, [listItem(MediaKind.Movie, 550)]);
}

func removeItemsWithoutAUser() {
    removeListItems(client("t"), 8175284, [listItem(MediaKind.Movie, 550)]);
}

func testListWriteVerbsValidateTheirArguments() {
    testing.assertThrows("createListWithNoName", "tmdb");
    testing.assertThrows("createListInABadLanguage", "tmdb");
    testing.assertThrows("createListInABadCountry", "tmdb");
    testing.assertThrows("updateListWithNoName", "tmdb");
    testing.assertThrows("updateListWithABadSort", "tmdb");
    testing.assertThrows("deleteListWithZeroId", "tmdb");
    testing.assertThrows("addNoItems", "tmdb");
}

func createListWithNoName() {
    createList(listClient(), "  ", "", false);
}

func createListInABadLanguage() {
    createListIn(listClient(), "Rewatch", "", false, "english", "");
}

func createListInABadCountry() {
    createListIn(listClient(), "Rewatch", "", false, "", "USA");
}

func updateListWithNoName() {
    updateList(listClient(), 8175284, "", "", true, "");
}

func updateListWithABadSort() {
    updateList(listClient(), 8175284, "Rewatch", "", true, "popularity.desc");
}

func deleteListWithZeroId() {
    deleteList(listClient(), 0);
}

func addNoItems() {
    addListItems(listClient(), 8175284, []);
}

func testListDetailsAndItemStatusValidateWithoutAUserToken() {
    # reading a public list needs only the application credential, so these
    # fail on the id and the page rather than on the credential
    testing.assertThrows("listDetailsWithZeroId", "tmdb");
    testing.assertThrows("listDetailsAtPageZero", "tmdb");
    testing.assertThrows("itemStatusForAPerson", "tmdb");
    testing.assertThrows("itemStatusWithZeroMediaId", "tmdb");
    testing.assertThrows("listWalkWithNoBudget", "tmdb");
}

func listDetailsWithZeroId() {
    listDetails(client("t"), 0, 1);
}

func listDetailsAtPageZero() {
    listDetails(client("t"), 8175284, 0);
}

func itemStatusForAPerson() {
    listItemStatus(client("t"), 8175284, MediaKind.Person, 31);
}

func itemStatusWithZeroMediaId() {
    listItemStatus(client("t"), 8175284, MediaKind.Movie, 0);
}

func listWalkWithNoBudget() {
    listItemsAll(client("t"), 8175284, 0);
}

func testListDetailsFold() {
    def doc as json.Value init json.decode('{
        "average_rating": 7.8,
        "backdrop_path": null,
        "comments": {},
        "created_by": {"avatar_path": null, "gravatar_hash": "abc", "id": "4bc889",
            "name": "Ada", "username": "ada"},
        "description": "films worth a second look",
        "id": 8175284,
        "iso_3166_1": "US",
        "iso_639_1": "en",
        "item_count": 42,
        "name": "Rewatch",
        "object_ids": {},
        "page": 1,
        "poster_path": null,
        "public": true,
        "revenue": 1234567,
        "runtime": 5040,
        "sort_by": "original_order.asc",
        "total_pages": 3,
        "total_results": 42,
        "results": [
            {"adult": false, "id": 550, "title": "Fight Club", "media_type": "movie",
             "release_date": "1999-10-15", "vote_average": 8.4},
            {"adult": false, "id": 1399, "name": "Game of Thrones", "media_type": "tv",
             "first_air_date": "2011-04-17", "vote_average": 8.4}]
    }');
    def l as ListDetails init listDetailsFrom($doc);
    testing.assertEqual($l.id, 8175284);
    testing.assertEqual($l.name, "Rewatch");
    testing.assertEqual($l.description, "films worth a second look");
    testing.assertTrue($l.public);
    testing.assertEqual($l.sortBy, LIST_SORT_ORIGINAL_ASC);
    testing.assertEqual($l.itemCount, 42);
    testing.assertEqual($l.region, "US");
    testing.assertEqual($l.language, "en");
    testing.assertEqual($l.revenue, 1234567);
    testing.assertEqual($l.runtime, 5040);
    testing.assertEqual($l.createdByName, "Ada");
    testing.assertEqual($l.createdByUsername, "ada");
    # the metadata and one page of items arrive in the same reply
    testing.assertEqual($l.page, 1);
    testing.assertEqual($l.totalPages, 3);
    testing.assertEqual($l.totalResults, 42);
    testing.assertEqual(len($l.results), 2);
    testing.assertTrue($l.results[0].kind == MediaKind.Movie);
    testing.assertTrue($l.results[1].kind == MediaKind.Show);
    testing.assertEqual($l.results[1].title, "Game of Thrones");
    # a list with no artwork writes null, which reads as ""
    testing.assertEqual($l.posterPath, "");
}

func testItemsResponseFold() {
    def doc as json.Value init json.decode('{
        "status_message": "Success.",
        "success": true,
        "status_code": 1,
        "results": [
            {"media_type": "movie", "media_id": 550, "success": true},
            {"media_type": "movie", "media_id": 244786, "success": false},
            {"media_type": "tv", "media_id": 1396, "success": true}]
    }');
    def answer as ItemsResponse init itemsResponseFrom($doc);
    testing.assertTrue($answer.success);
    testing.assertEqual($answer.statusCode, 1);
    testing.assertEqual($answer.statusMessage, "Success.");
    testing.assertEqual(len($answer.results), 3);
    # a request can succeed overall while individual items fail
    testing.assertTrue($answer.results[0].success);
    testing.assertFalse($answer.results[1].success);
    testing.assertEqual($answer.results[1].id, 244786);
    testing.assertTrue($answer.results[2].kind == MediaKind.Show);
}

func testItemStatusFold() {
    def doc as json.Value init json.decode('{
        "media_type": "movie", "success": true, "status_message": "Success.",
        "id": 8175284, "media_id": 550, "status_code": 1}');
    def status as ItemStatus init itemStatusFrom($doc);
    testing.assertTrue($status.success);
    testing.assertEqual($status.listId, 8175284);
    testing.assertEqual($status.mediaId, 550);
    testing.assertTrue($status.kind == MediaKind.Movie);
    testing.assertEqual($status.statusCode, 1);
}

/**
 * A client that may write lists.
 *
 * @return {Client} a client with both an application and a user token
 * @internal
 */
func listClient() {
    return withUserToken(client("app"), "user");
}
