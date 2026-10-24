# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the movies topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testMoviePath() {
    testing.assertEqual(moviePath(550, ""), "/3/movie/550");
    testing.assertEqual(moviePath(550, "/credits"), "/3/movie/550/credits");
    testing.assertEqual(moviePath(550, "/watch/providers"), "/3/movie/550/watch/providers");
    testing.assertThrows("moviePathWithZeroId", "tmdb");
    testing.assertThrows("moviePathWithNegativeId", "tmdb");
}

func moviePathWithZeroId() {
    moviePath(0, "");
}

func moviePathWithNegativeId() {
    moviePath(-1, "/credits");
}

func testEveryMovieVerbValidatesItsId() {
    testing.assertThrows("movieWithZeroId", "tmdb");
    testing.assertThrows("movieCreditsWithZeroId", "tmdb");
    testing.assertThrows("movieImagesWithZeroId", "tmdb");
    testing.assertThrows("movieBundleWithZeroId", "tmdb");
    testing.assertThrows("movieRecommendationsWithZeroId", "tmdb");
}

func movieWithZeroId() {
    movie(client("t"), 0);
}

func movieCreditsWithZeroId() {
    movieCredits(client("t"), 0);
}

func movieImagesWithZeroId() {
    movieImages(client("t"), 0);
}

func movieBundleWithZeroId() {
    movieBundle(client("t"), 0);
}

func movieRecommendationsWithZeroId() {
    movieRecommendations(client("t"), 0, 1);
}

func testPaginatedMovieVerbsValidateThePage() {
    testing.assertThrows("movieSimilarAtPageZero", "tmdb");
    testing.assertThrows("movieReviewsPastTheCeiling", "tmdb");
    testing.assertThrows("nowPlayingAtPageZero", "tmdb");
    testing.assertThrows("popularMoviesAtPageZero", "tmdb");
    testing.assertThrows("topRatedMoviesAtPageZero", "tmdb");
    testing.assertThrows("upcomingMoviesAtPageZero", "tmdb");
}

func movieSimilarAtPageZero() {
    movieSimilar(client("t"), 550, 0);
}

func movieReviewsPastTheCeiling() {
    movieReviews(client("t"), 550, MAX_PAGE + 1);
}

func nowPlayingAtPageZero() {
    nowPlaying(client("t"), 0);
}

func popularMoviesAtPageZero() {
    popularMovies(client("t"), 0);
}

func topRatedMoviesAtPageZero() {
    topRatedMovies(client("t"), 0);
}

func upcomingMoviesAtPageZero() {
    upcomingMovies(client("t"), 0);
}

func testMovieFold() {
    def film as Movie init movieFrom(sampleMovie());
    testing.assertEqual($film.id, 11);
    testing.assertEqual($film.title, "Star Wars");
    testing.assertEqual($film.originalTitle, "Star Wars");
    testing.assertEqual($film.releaseDate, "1977-05-25");
    testing.assertEqual($film.runtime, 121);
    testing.assertEqual($film.status, "Released");
    testing.assertEqual($film.imdbId, "tt0076759");
    testing.assertEqual($film.budget, 11000000);
    testing.assertEqual($film.revenue, 775398007);
    testing.assertEqual($film.originCountry, ["US"]);
    testing.assertContains($film.tagline, "a galaxy far");
    testing.assertEqual(len($film.genres), 3);
    testing.assertEqual($film.genres[0].name, "Adventure");
    testing.assertEqual($film.belongsToCollection.id, 10);
    testing.assertEqual($film.belongsToCollection.name, "Star Wars Collection");
    testing.assertEqual(len($film.productionCompanies), 2);
    testing.assertEqual($film.productionCompanies[1].name, "20th Century Fox");
    testing.assertEqual($film.productionCountries[0].code, "US");
    testing.assertEqual($film.spokenLanguages[0].code, "en");
    testing.assertEqual($film.voteCount, 22061);
    testing.assertFalse($film.adult);
}

func testMovieFoldZeroesWhatTmdbOmits() {
    def sparse as Movie init movieFrom(json.decode('{"id": 1, "title": "Untitled"}'));
    testing.assertEqual($sparse.runtime, 0);
    testing.assertEqual($sparse.releaseDate, "");
    testing.assertEqual($sparse.budget, 0);
    testing.assertEqual(len($sparse.genres), 0);
    testing.assertEqual($sparse.belongsToCollection.id, 0);
}

func testReleaseDatesFold() {
    def doc as json.Value init json.decode('{"id": 550, "results": [
        {"iso_3166_1": "US", "release_dates": [
            {"certification": "", "iso_639_1": "", "note": "premiere",
             "release_date": "1999-09-10T00:00:00.000Z", "type": 1},
            {"certification": "R", "iso_639_1": "", "note": "",
             "release_date": "1999-10-15T00:00:00.000Z", "type": 3}]},
        {"iso_3166_1": "DE", "release_dates": [
            {"certification": "18", "iso_639_1": "de", "note": "",
             "release_date": "1999-11-11T00:00:00.000Z", "type": 3}]}
    ]}');
    def groups as list of ReleaseGroup init releaseGroupsFrom($doc);
    testing.assertEqual(len($groups), 2);
    testing.assertEqual($groups[0].region, "US");
    testing.assertEqual(len($groups[0].releases), 2);
    testing.assertEqual($groups[0].releases[0].kind, RELEASE_PREMIERE);
    testing.assertEqual($groups[0].releases[0].note, "premiere");
    testing.assertEqual($groups[0].releases[1].certification, "R");
    testing.assertEqual($groups[1].releases[0].language, "de");
}

func testCertificationOfSkipsUnratedReleases() {
    def groups as list of ReleaseGroup init releaseGroupsFrom(json.decode('{"results": [
        {"iso_3166_1": "US", "release_dates": [
            {"certification": "", "type": 1, "release_date": "1999-09-10T00:00:00.000Z"},
            {"certification": "R", "type": 3, "release_date": "1999-10-15T00:00:00.000Z"}]}
    ]}'));
    # the premiere row is unrated; the answer must be the theatrical one
    testing.assertEqual(certificationOf($groups, "US"), "R");
    testing.assertEqual(certificationOf($groups, "us"), "R");
    testing.assertEqual(certificationOf($groups, "DE"), "");
    testing.assertEqual(certificationOf([], "US"), "");
}

func testReleaseTypeName() {
    testing.assertEqual(releaseTypeName(RELEASE_PREMIERE), "premiere");
    testing.assertEqual(releaseTypeName(RELEASE_THEATRICAL_LIMITED), "theatrical (limited)");
    testing.assertEqual(releaseTypeName(RELEASE_THEATRICAL), "theatrical");
    testing.assertEqual(releaseTypeName(RELEASE_DIGITAL), "digital");
    testing.assertEqual(releaseTypeName(RELEASE_PHYSICAL), "physical");
    testing.assertEqual(releaseTypeName(RELEASE_TV), "tv");
    testing.assertEqual(releaseTypeName(0), "unknown");
    testing.assertEqual(releaseTypeName(99), "unknown");
}

func testWatchOffersListFoldEnumeratesTheCountryKeys() {
    def doc as json.Value init json.decode('{"id": 550, "results": {
        "DE": {"link": "https://www.themoviedb.org/movie/550/watch?locale=DE",
               "flatrate": [{"provider_id": 8, "provider_name": "Netflix",
                             "logo_path": "/pbp.jpg", "display_priority": 0}]},
        "US": {"link": "https://www.themoviedb.org/movie/550/watch?locale=US",
               "rent": [{"provider_id": 2, "provider_name": "Apple TV",
                         "logo_path": "/peU.jpg", "display_priority": 1}]}
    }}');
    def offers as list of WatchOffers init watchOffersListFrom($doc);
    testing.assertEqual(len($offers), 2);
    testing.assertEqual($offers[0].region, "DE");
    testing.assertEqual($offers[0].flatrate[0].providerName, "Netflix");
    testing.assertEqual($offers[1].region, "US");
    testing.assertEqual(len($offers[1].rent), 1);
    testing.assertEqual(len(watchOffersListFrom(json.decode('{"id": 1}'))), 0);
}

func testOffersInIsSafeToWalkWhenThereAreNone() {
    def offers as list of WatchOffers init watchOffersListFrom(json.decode('{"results": {
        "DE": {"link": "x", "flatrate": [{"provider_id": 8, "provider_name": "Netflix"}]}}}'));
    testing.assertEqual(offersIn($offers, "de").flatrate[0].providerName, "Netflix");
    def nowhere as WatchOffers init offersIn($offers, "JP");
    testing.assertEqual($nowhere.region, "JP");
    testing.assertEqual($nowhere.link, "");
    testing.assertEqual(len($nowhere.flatrate), 0);
    testing.assertEqual(len($nowhere.rent), 0);
    testing.assertEqual(len($nowhere.buy), 0);
}

func testDirectorHelpers() {
    def credits as Credits init creditsFrom(json.decode('{"id": 550, "cast": [], "crew": [
        {"id": 7467, "name": "David Fincher", "department": "Directing", "job": "Director"},
        {"id": 7469, "name": "Jim Uhls", "department": "Writing", "job": "Screenplay"},
        {"id": 1, "name": "Second Unit Person", "department": "Directing",
         "job": "Second Unit Director"}
    ]}'));
    testing.assertEqual(directorOf($credits), "David Fincher");
    testing.assertEqual(directorsOf($credits), ["David Fincher"]);
    testing.assertEqual(crewNamed($credits, "Screenplay"), ["Jim Uhls"]);
    # the match is exact, so a second-unit director is not the director
    testing.assertEqual(len(crewNamed($credits, "Second Unit Director")), 1);
    testing.assertEqual(crewNamed($credits, "Composer"), []);
}

func testDirectorOfAnEmptyCrew() {
    def empty as Credits init Credits{id: 0, cast: [], crew: []};
    testing.assertEqual(directorOf($empty), "");
    testing.assertEqual(directorsOf($empty), []);
}

func testCrewNamedIsCaseInsensitiveAndValidates() {
    def credits as Credits init creditsFrom(json.decode('{"id": 1, "cast": [], "crew": [{"name": "A", "job": "Director"}]}'));
    testing.assertEqual(crewNamed($credits, "director"), ["A"]);
    testing.assertThrows("crewNamedNothing", "tmdb");
}

func crewNamedNothing() {
    crewNamed(Credits{id: 0, cast: [], crew: []}, "  ");
}

func testTwoDirectorsAreBothReported() {
    def credits as Credits init creditsFrom(json.decode('{"id": 1, "cast": [], "crew": [
        {"name": "Joel Coen", "job": "Director"},
        {"name": "Ethan Coen", "job": "Director"}]}'));
    testing.assertEqual(directorsOf($credits), ["Joel Coen", "Ethan Coen"]);
    testing.assertEqual(directorOf($credits), "Joel Coen");
}

func testMovieAppendicesFitTmdbsBudget() {
    # TMDB appends at most twenty sub-resources to one request
    testing.assertTrue(len(MOVIE_APPENDICES) <= 20);
    testing.assertContains(MOVIE_APPENDICES, "credits");
    testing.assertContains(MOVIE_APPENDICES, "watch/providers");
}

/**
 * TMDB's documented `/movie/11` response, trimmed to the folded fields.
 *
 * @return {json.Value} the decoded body
 * @internal
 */
func sampleMovie() {
    return json.decode('{
        "adult": false,
        "backdrop_path": "/2w4.jpg",
        "belongs_to_collection": {"id": 10, "name": "Star Wars Collection",
            "poster_path": "/pWV.jpg", "backdrop_path": "/iY2.jpg"},
        "budget": 11000000,
        "genres": [{"id": 12, "name": "Adventure"}, {"id": 28, "name": "Action"},
            {"id": 878, "name": "Science Fiction"}],
        "homepage": "http://www.starwars.com/films/star-wars-episode-iv-a-new-hope",
        "id": 11,
        "imdb_id": "tt0076759",
        "origin_country": ["US"],
        "original_language": "en",
        "original_title": "Star Wars",
        "overview": "Princess Leia is captured...",
        "popularity": 20.6912,
        "poster_path": "/6Ff.jpg",
        "production_companies": [
            {"id": 1, "logo_path": "/tlV.png", "name": "Lucasfilm Ltd.", "origin_country": "US"},
            {"id": 25, "logo_path": "/qZC.png", "name": "20th Century Fox",
             "origin_country": "US"}],
        "production_countries": [{"iso_3166_1": "US", "name": "United States of America"}],
        "release_date": "1977-05-25",
        "revenue": 775398007,
        "runtime": 121,
        "spoken_languages": [{"english_name": "English", "iso_639_1": "en", "name": "English"}],
        "status": "Released",
        "tagline": "A long time ago in a galaxy far, far away...",
        "title": "Star Wars",
        "video": false,
        "vote_average": 8.2,
        "vote_count": 22061
    }');
}

func testLatestMovieAsksForTheLatestEndpoint() {
    assertRequested(latestMovieRequest, "GET " + API_BASE + "/3/movie/latest");
}

func testMovieSubResourceVerbsValidateTheId() {
    testing.assertThrows("movieAlternativeTitlesWithZeroId", "tmdb");
    testing.assertThrows("movieExternalIdsWithZeroId", "tmdb");
    testing.assertThrows("movieKeywordsWithZeroId", "tmdb");
    testing.assertThrows("movieReleaseDatesWithZeroId", "tmdb");
    testing.assertThrows("movieTranslationsWithZeroId", "tmdb");
    testing.assertThrows("movieVideosWithZeroId", "tmdb");
    testing.assertThrows("movieWatchProvidersWithNegativeId", "tmdb");
}

func movieAlternativeTitlesWithZeroId() {
    movieAlternativeTitles(client("t"), 0);
}

func movieExternalIdsWithZeroId() {
    movieExternalIds(client("t"), 0);
}

func movieKeywordsWithZeroId() {
    movieKeywords(client("t"), 0);
}

func movieReleaseDatesWithZeroId() {
    movieReleaseDates(client("t"), 0);
}

func movieTranslationsWithZeroId() {
    movieTranslations(client("t"), 0);
}

func movieVideosWithZeroId() {
    movieVideos(client("t"), 0);
}

func movieWatchProvidersWithNegativeId() {
    movieWatchProviders(client("t"), -550);
}

func latestMovieRequest(c as Client) {
    latestMovie($c);
}
