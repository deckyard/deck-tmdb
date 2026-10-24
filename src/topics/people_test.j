# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the people topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testPersonPath() {
    testing.assertEqual(personPath(31, ""), "/3/person/31");
    testing.assertEqual(personPath(31, "/movie_credits"), "/3/person/31/movie_credits");
    testing.assertThrows("personPathWithZeroId", "tmdb");
}

func personPathWithZeroId() {
    personPath(0, "");
}

func testEveryPersonVerbValidatesItsArguments() {
    testing.assertThrows("personWithZeroId", "tmdb");
    testing.assertThrows("personBundleWithZeroId", "tmdb");
    testing.assertThrows("personImagesWithZeroId", "tmdb");
    testing.assertThrows("popularPeopleAtPageZero", "tmdb");
}

func personWithZeroId() {
    person(client("t"), 0);
}

func personBundleWithZeroId() {
    personBundle(client("t"), 0);
}

func personImagesWithZeroId() {
    personImages(client("t"), 0);
}

func popularPeopleAtPageZero() {
    popularPeople(client("t"), 0);
}

func testPersonFold() {
    def doc as json.Value init json.decode('{
        "adult": false,
        "also_known_as": ["Thomas Jeffrey Hanks", "Tom Hanks"],
        "biography": "Thomas Jeffrey Hanks (born July 9, 1956) is an American actor...",
        "birthday": "1956-07-09",
        "deathday": null,
        "gender": 2,
        "homepage": null,
        "id": 31,
        "imdb_id": "nm0000158",
        "known_for_department": "Acting",
        "name": "Tom Hanks",
        "place_of_birth": "Concord, California, USA",
        "popularity": 82.989,
        "profile_path": "/xnd.jpg"
    }');
    def p as Person init personFrom($doc);
    testing.assertEqual($p.id, 31);
    testing.assertEqual($p.name, "Tom Hanks");
    testing.assertEqual($p.birthday, "1956-07-09");
    # null means "alive, or not recorded" - it must read as "", not throw
    testing.assertEqual($p.deathday, "");
    testing.assertEqual($p.homepage, "");
    testing.assertEqual($p.gender, 2);
    testing.assertEqual(genderName($p.gender), "male");
    testing.assertEqual($p.knownForDepartment, "Acting");
    testing.assertEqual($p.imdbId, "nm0000158");
    testing.assertEqual($p.placeOfBirth, "Concord, California, USA");
    testing.assertEqual(len($p.alsoKnownAs), 2);
}

func testPersonCreditsFoldForFilms() {
    def credits as PersonCredits init personCreditsFrom(sampleMovieCredits(), MediaKind.Movie);
    testing.assertEqual($credits.id, 31);
    testing.assertEqual(len($credits.cast), 2);
    testing.assertEqual($credits.cast[0].title, "Forrest Gump");
    testing.assertEqual($credits.cast[0].character, "Forrest Gump");
    testing.assertEqual($credits.cast[0].order, 0);
    testing.assertEqual($credits.cast[0].releaseDate, "1994-06-23");
    testing.assertEqual($credits.cast[0].job, "");
    # the endpoint carries no media_type, so the fallback kind decides
    testing.assertTrue($credits.cast[0].kind == MediaKind.Movie);
    testing.assertEqual($credits.crew[0].job, "Producer");
    testing.assertEqual($credits.crew[0].department, "Production");
    testing.assertEqual($credits.crew[0].character, "");
}

func testCombinedCreditsKeepTheDiscriminator() {
    def doc as json.Value init json.decode('{"id": 31, "crew": [], "cast": [
        {"id": 13, "media_type": "movie", "title": "Forrest Gump",
         "release_date": "1994-06-23", "character": "Forrest Gump"},
        {"id": 1408, "media_type": "tv", "name": "Band of Brothers",
         "first_air_date": "2001-09-09", "character": "Narrator", "episode_count": 10}]}');
    def credits as PersonCredits init personCreditsFrom($doc, MediaKind.Unknown);
    testing.assertTrue($credits.cast[0].kind == MediaKind.Movie);
    testing.assertTrue($credits.cast[1].kind == MediaKind.Show);
    # the series row's `name` and `first_air_date` land in the same fields
    testing.assertEqual($credits.cast[1].title, "Band of Brothers");
    testing.assertEqual($credits.cast[1].releaseDate, "2001-09-09");
    testing.assertEqual($credits.cast[1].episodeCount, 10);
}

func testCreditsInDepartment() {
    def credits as PersonCredits init personCreditsFrom(
        json.decode('{"id": 525, "cast": [],
        "crew": [
            {"id": 27205, "title": "Inception", "job": "Director", "department": "Directing"},
            {"id": 27205, "title": "Inception", "job": "Writer", "department": "Writing"},
            {"id": 155, "title": "The Dark Knight", "job": "Director",
             "department": "Directing"}]}'),
        MediaKind.Movie);
    def directed as list of PersonCredit init creditsInDepartment($credits, "Directing");
    testing.assertEqual(len($directed), 2);
    testing.assertEqual($directed[0].title, "Inception");
    testing.assertEqual($directed[1].title, "The Dark Knight");
    # the match is case-insensitive
    testing.assertEqual(len(creditsInDepartment($credits, "writing")), 1);
    testing.assertEqual(len(creditsInDepartment($credits, "Camera")), 0);
    testing.assertThrows("creditsInNoDepartment", "tmdb");
}

func creditsInNoDepartment() {
    creditsInDepartment(PersonCredits{id: 0, cast: [], crew: []}, "  ");
}

func testPersonAppendicesFitTmdbsBudget() {
    testing.assertTrue(len(PERSON_APPENDICES) <= 20);
    testing.assertContains(PERSON_APPENDICES, "combined_credits");
}

/**
 * TMDB's documented `/person/31/movie_credits` response, trimmed.
 *
 * @return {json.Value} the decoded body
 * @internal
 */
func sampleMovieCredits() {
    return json.decode('{
        "id": 31,
        "cast": [
            {"adult": false, "backdrop_path": "/7c9.jpg", "genre_ids": [35, 18, 10749],
             "id": 13, "original_language": "en", "original_title": "Forrest Gump",
             "overview": "A man with a low IQ...", "popularity": 55.0,
             "poster_path": "/arw.jpg", "release_date": "1994-06-23",
             "title": "Forrest Gump", "video": false, "vote_average": 8.5,
             "vote_count": 24000, "character": "Forrest Gump",
             "credit_id": "52fe420dc3a36847f800638d", "order": 0},
            {"adult": false, "genre_ids": [16, 35, 10751], "id": 862,
             "original_language": "en", "original_title": "Toy Story",
             "overview": "Led by Woody...", "popularity": 90.0, "poster_path": "/uXD.jpg",
             "release_date": "1995-10-30", "title": "Toy Story", "video": false,
             "vote_average": 8.0, "vote_count": 17000, "character": "Woody (voice)",
             "credit_id": "52fe4271c3a36847f8020fb1", "order": 0}],
        "crew": [
            {"adult": false, "genre_ids": [18, 36], "id": 24238,
             "original_language": "en", "original_title": "The Great Buck Howard",
             "overview": "A young man...", "popularity": 8.0, "poster_path": "/8lZ.jpg",
             "release_date": "2008-01-18", "title": "The Great Buck Howard",
             "video": false, "vote_average": 6.1, "vote_count": 200,
             "credit_id": "52fe44d19251416c7504407f", "department": "Production",
             "job": "Producer"}]
    }');
}

func testLatestPersonAsksForTheLatestEndpoint() {
    assertRequested(latestPersonRequest, "GET " + API_BASE + "/3/person/latest");
}

func testPersonSubResourceVerbsValidateTheId() {
    testing.assertThrows("personCombinedCreditsWithZeroId", "tmdb");
    testing.assertThrows("personExternalIdsWithZeroId", "tmdb");
    testing.assertThrows("personMovieCreditsWithZeroId", "tmdb");
    testing.assertThrows("personShowCreditsWithNegativeId", "tmdb");
}

func personCombinedCreditsWithZeroId() {
    personCombinedCredits(client("t"), 0);
}

func personExternalIdsWithZeroId() {
    personExternalIds(client("t"), 0);
}

func personMovieCreditsWithZeroId() {
    personMovieCredits(client("t"), 0);
}

func personShowCreditsWithNegativeId() {
    personShowCredits(client("t"), -287);
}

func latestPersonRequest(c as Client) {
    latestPerson($c);
}
