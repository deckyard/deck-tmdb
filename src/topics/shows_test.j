# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the shows topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testShowSeasonAndEpisodePaths() {
    testing.assertEqual(showPath(1399, ""), "/3/tv/1399");
    testing.assertEqual(showPath(1399, "/credits"), "/3/tv/1399/credits");
    testing.assertEqual(seasonPath(1399, 1, ""), "/3/tv/1399/season/1");
    testing.assertEqual(seasonPath(1399, 1, "/images"), "/3/tv/1399/season/1/images");
    testing.assertEqual(episodePath(1399, 1, 5, ""), "/3/tv/1399/season/1/episode/5");
    testing.assertEqual(
        episodePath(1399, 1, 5, "/credits"),
        "/3/tv/1399/season/1/episode/5/credits");
}

func testSeasonZeroIsLegalBecauseItIsTheSpecials() {
    testing.assertEqual(seasonPath(1399, 0, ""), "/3/tv/1399/season/0");
    testing.assertEqual(episodePath(1399, 0, 1, ""), "/3/tv/1399/season/0/episode/1");
}

func testShowPathsValidateTheirArguments() {
    testing.assertThrows("showPathWithZeroId", "tmdb");
    testing.assertThrows("seasonPathWithNegativeSeason", "tmdb");
    testing.assertThrows("episodePathWithNegativeEpisode", "tmdb");
}

func showPathWithZeroId() {
    showPath(0, "");
}

func seasonPathWithNegativeSeason() {
    seasonPath(1399, -1, "");
}

func episodePathWithNegativeEpisode() {
    episodePath(1399, 1, -1, "");
}

func testEveryShowVerbValidatesItsArguments() {
    testing.assertThrows("showWithZeroId", "tmdb");
    testing.assertThrows("showBundleWithZeroId", "tmdb");
    testing.assertThrows("seasonWithNegativeNumber", "tmdb");
    testing.assertThrows("episodeWithNegativeNumber", "tmdb");
    testing.assertThrows("showRecommendationsAtPageZero", "tmdb");
    testing.assertThrows("popularShowsAtPageZero", "tmdb");
    testing.assertThrows("airingTodayInNowhere", "tmdb");
}

func showWithZeroId() {
    show(client("t"), 0);
}

func showBundleWithZeroId() {
    showBundle(client("t"), 0);
}

func seasonWithNegativeNumber() {
    season(client("t"), 1399, -1);
}

func episodeWithNegativeNumber() {
    episode(client("t"), 1399, 1, -1);
}

func showRecommendationsAtPageZero() {
    showRecommendations(client("t"), 1399, 0);
}

func popularShowsAtPageZero() {
    popularShows(client("t"), 0);
}

func airingTodayInNowhere() {
    airingTodayIn(client("t"), "  ", 1);
}

func testShowFold() {
    def series as Show init showFrom(sampleShow());
    testing.assertEqual($series.id, 1399);
    testing.assertEqual($series.name, "Game of Thrones");
    testing.assertEqual($series.firstAirDate, "2011-04-17");
    testing.assertEqual($series.lastAirDate, "2019-05-19");
    testing.assertEqual($series.numberOfSeasons, 8);
    testing.assertEqual($series.numberOfEpisodes, 73);
    testing.assertEqual($series.episodeRunTime, [60]);
    testing.assertEqual($series.languages, ["en"]);
    testing.assertEqual($series.originCountry, ["US"]);
    testing.assertFalse($series.inProduction);
    testing.assertEqual(len($series.createdBy), 2);
    testing.assertEqual($series.createdBy[0].name, "David Benioff");
    testing.assertEqual($series.networks[0].name, "HBO");
    testing.assertEqual(len($series.seasons), 2);
    testing.assertEqual($series.lastEpisodeToAir.name, "The Iron Throne");
    testing.assertEqual($series.lastEpisodeToAir.episodeNumber, 6);
    # TMDB writes null when nothing is scheduled; the struct zeroes rather than absent
    testing.assertEqual($series.nextEpisodeToAir.id, 0);
    testing.assertEqual($series.nextEpisodeToAir.name, "");
}

func testSeasonSummariesFold() {
    def series as Show init showFrom(sampleShow());
    testing.assertEqual($series.seasons[0].seasonNumber, 0);
    testing.assertEqual($series.seasons[0].name, "Specials");
    testing.assertEqual($series.seasons[1].seasonNumber, 1);
    testing.assertEqual($series.seasons[1].episodeCount, 10);
}

func testSeasonOfFindsBySeasonNumberNotByIndex() {
    def series as Show init showFrom(sampleShow());
    testing.assertEqual(seasonOf($series, 1).episodeCount, 10);
    testing.assertEqual(seasonOf($series, 0).name, "Specials");
    # a season the series does not have is zeroed, and echoes the number asked for
    def missing as SeasonSummary init seasonOf($series, 9);
    testing.assertEqual($missing.id, 0);
    testing.assertEqual($missing.seasonNumber, 9);
    testing.assertEqual($missing.episodeCount, 0);
}

func testSeasonFold() {
    def doc as json.Value init json.decode('{
        "_id": "5256c89f19c2956ff6046d47",
        "air_date": "2011-04-17",
        "name": "Season 1",
        "overview": "Trouble is brewing in the Seven Kingdoms.",
        "id": 3624,
        "poster_path": "/olJ.jpg",
        "season_number": 1,
        "vote_average": 8.3,
        "episodes": [
            {"air_date": "2011-04-17", "episode_number": 1, "episode_type": "standard",
             "id": 63056, "name": "Winter Is Coming", "overview": "Jon Arryn is dead.",
             "production_code": "101", "runtime": 62, "season_number": 1, "show_id": 1399,
             "still_path": "/9fs.jpg", "vote_average": 8.1, "vote_count": 345},
            {"air_date": "2011-04-24", "episode_number": 2, "episode_type": "standard",
             "id": 63057, "name": "The Kingsroad", "overview": "", "runtime": 56,
             "season_number": 1, "show_id": 1399, "vote_average": 7.9, "vote_count": 253}]
    }');
    def s as Season init seasonFrom($doc);
    testing.assertEqual($s.id, 3624);
    testing.assertEqual($s.seasonNumber, 1);
    testing.assertEqual($s.name, "Season 1");
    testing.assertEqual($s.airDate, "2011-04-17");
    testing.assertEqual(len($s.episodes), 2);
    testing.assertEqual($s.episodes[0].name, "Winter Is Coming");
    testing.assertEqual($s.episodes[0].runtime, 62);
    testing.assertEqual($s.episodes[0].kind, "standard");
    testing.assertEqual($s.episodes[0].showId, 1399);
    testing.assertEqual($s.episodes[1].episodeNumber, 2);
}

func testEpisodeFoldFromAReplyRoot() {
    def doc as json.Value init json.decode('{
        "air_date": "2019-05-19", "episode_number": 6, "episode_type": "finale",
        "id": 1551830, "name": "The Iron Throne", "overview": "In the aftermath...",
        "production_code": "806", "runtime": 80, "season_number": 8, "show_id": 1399,
        "still_path": "/zBi.jpg", "vote_average": 4.809, "vote_count": 241
    }');
    def e as Episode init episodeFrom($doc, "");
    testing.assertEqual($e.id, 1551830);
    testing.assertEqual($e.name, "The Iron Throne");
    testing.assertEqual($e.kind, "finale");
    testing.assertEqual($e.seasonNumber, 8);
    testing.assertEqual($e.episodeNumber, 6);
    testing.assertEqual($e.voteCount, 241);
}

func testCreatorsFold() {
    def series as Show init showFrom(sampleShow());
    testing.assertEqual($series.createdBy[1].name, "D.B. Weiss");
    testing.assertEqual($series.createdBy[1].id, 228068);
    testing.assertEqual($series.createdBy[0].creditId, "5256c8c219c2956ff604858a");
    testing.assertEqual($series.createdBy[0].gender, 2);
}

func testAggregateCreditsFold() {
    def doc as json.Value init json.decode('{
        "id": 1399,
        "cast": [{
            "adult": false, "gender": 1, "id": 17419, "known_for_department": "Acting",
            "name": "Emilia Clarke", "original_name": "Emilia Clarke", "popularity": 30.0,
            "profile_path": "/r6.jpg", "order": 0, "total_episode_count": 73,
            "roles": [
                {"credit_id": "5256c8af19c2956ff6046e2b", "character": "Daenerys Targaryen",
                 "episode_count": 73},
                {"credit_id": "aaa", "character": "Herself", "episode_count": 1}]}],
        "crew": [{
            "adult": false, "gender": 2, "id": 9813, "known_for_department": "Writing",
            "name": "David Benioff", "original_name": "David Benioff", "popularity": 8.0,
            "profile_path": "/xv.jpg", "department": "Writing", "total_episode_count": 32,
            "jobs": [{"credit_id": "bbb", "job": "Writer", "episode_count": 32}]}]
    }');
    def credits as AggregateCredits init aggregateCreditsFrom($doc);
    testing.assertEqual($credits.id, 1399);
    testing.assertEqual($credits.cast[0].name, "Emilia Clarke");
    testing.assertEqual($credits.cast[0].totalEpisodeCount, 73);
    # a performer can play more than one part, so roles is a list
    testing.assertEqual(len($credits.cast[0].roles), 2);
    testing.assertEqual($credits.cast[0].roles[0].character, "Daenerys Targaryen");
    testing.assertEqual($credits.cast[0].roles[0].episodeCount, 73);
    testing.assertEqual($credits.crew[0].department, "Writing");
    testing.assertEqual($credits.crew[0].jobs[0].job, "Writer");
    testing.assertEqual($credits.crew[0].jobs[0].episodeCount, 32);
}

func testContentRatingsFoldAndLookup() {
    def doc as json.Value init json.decode('{"id": 1399, "results": [
        {"descriptors": [], "iso_3166_1": "US", "rating": "TV-MA"},
        {"descriptors": ["violence"], "iso_3166_1": "DE", "rating": "16"}]}');
    def ratings as list of ContentRating init contentRatingsFrom($doc);
    testing.assertEqual(len($ratings), 2);
    testing.assertEqual($ratings[0].region, "US");
    testing.assertEqual($ratings[1].descriptors, ["violence"]);
    testing.assertEqual(contentRatingOf($ratings, "US"), "TV-MA");
    testing.assertEqual(contentRatingOf($ratings, "de"), "16");
    testing.assertEqual(contentRatingOf($ratings, "JP"), "");
    testing.assertEqual(contentRatingOf([], "US"), "");
}

func testEpisodeGroupsFold() {
    def doc as json.Value init json.decode('{"id": 1399, "results": [{
        "description": "", "episode_count": 102, "group_count": 9,
        "id": "5e9077d2e640d600151f32bd", "name": "Aired Order", "type": 1,
        "network": {"id": 49, "logo_path": "/tuo.png", "name": "HBO",
                    "origin_country": "US"}}]}');
    def groups as list of EpisodeGroup init episodeGroupsFrom($doc);
    testing.assertEqual(len($groups), 1);
    testing.assertEqual($groups[0].id, "5e9077d2e640d600151f32bd");
    testing.assertEqual($groups[0].name, "Aired Order");
    testing.assertEqual($groups[0].episodeCount, 102);
    testing.assertEqual($groups[0].groupCount, 9);
    testing.assertEqual($groups[0].kind, 1);
    testing.assertEqual($groups[0].network.name, "HBO");
}

func testShowAppendicesFitTmdbsBudget() {
    testing.assertTrue(len(SHOW_APPENDICES) <= 20);
    # a long-running series wants rolled-up credits, not the regular cast
    testing.assertContains(SHOW_APPENDICES, "aggregate_credits");
    testing.assertContains(SHOW_APPENDICES, "content_ratings");
}

/**
 * TMDB's documented `/tv/1399` response, trimmed to the folded fields.
 *
 * @return {json.Value} the decoded body
 * @internal
 */
func sampleShow() {
    return json.decode('{
        "adult": false,
        "backdrop_path": "/6LW.jpg",
        "created_by": [
            {"id": 9813, "credit_id": "5256c8c219c2956ff604858a", "name": "David Benioff",
             "gender": 2, "profile_path": "/xvN.jpg"},
            {"id": 228068, "credit_id": "552e611e9251413fea000901", "name": "D.B. Weiss",
             "gender": 2, "profile_path": "/2RM.jpg"}],
        "episode_run_time": [60],
        "first_air_date": "2011-04-17",
        "genres": [{"id": 10765, "name": "Sci-Fi & Fantasy"}, {"id": 18, "name": "Drama"}],
        "homepage": "http://www.hbo.com/game-of-thrones",
        "id": 1399,
        "in_production": false,
        "languages": ["en"],
        "last_air_date": "2019-05-19",
        "last_episode_to_air": {"id": 1551830, "name": "The Iron Throne",
            "overview": "In the aftermath...", "vote_average": 4.809, "vote_count": 241,
            "air_date": "2019-05-19", "episode_number": 6, "production_code": "806",
            "runtime": 80, "season_number": 8, "show_id": 1399, "still_path": "/zBi.jpg"},
        "name": "Game of Thrones",
        "next_episode_to_air": null,
        "networks": [{"id": 49, "logo_path": "/tuo.png", "name": "HBO",
                      "origin_country": "US"}],
        "number_of_episodes": 73,
        "number_of_seasons": 8,
        "origin_country": ["US"],
        "original_language": "en",
        "original_name": "Game of Thrones",
        "overview": "Seven noble families fight for control...",
        "popularity": 346.098,
        "poster_path": "/1XS.jpg",
        "production_companies": [{"id": 76043, "logo_path": "/9RO.png",
            "name": "Revolution Sun Studios", "origin_country": "US"}],
        "production_countries": [{"iso_3166_1": "GB", "name": "United Kingdom"}],
        "seasons": [
            {"air_date": "2010-12-05", "episode_count": 272, "id": 3627, "name": "Specials",
             "overview": "", "poster_path": "/kMT.jpg", "season_number": 0,
             "vote_average": 0},
            {"air_date": "2011-04-17", "episode_count": 10, "id": 3624, "name": "Season 1",
             "overview": "", "poster_path": "/olJ.jpg", "season_number": 1,
             "vote_average": 8.3}],
        "spoken_languages": [{"english_name": "English", "iso_639_1": "en",
                              "name": "English"}],
        "status": "Ended",
        "tagline": "Winter Is Coming",
        "type": "Scripted",
        "vote_average": 8.4,
        "vote_count": 21000
    }');
}

func testLatestShowAsksForTheLatestEndpoint() {
    assertRequested(latestShowRequest, "GET " + API_BASE + "/3/tv/latest");
}

func testShowListVerbsValidateThePage() {
    testing.assertThrows("airingTodayAtPageZero", "tmdb");
    testing.assertThrows("onTheAirAtPageZero", "tmdb");
    testing.assertThrows("topRatedShowsPastTheCeiling", "tmdb");
    testing.assertThrows("showReviewsAtPageZero", "tmdb");
    testing.assertThrows("showSimilarAtPageZero", "tmdb");
    testing.assertThrows("showSimilarWithZeroId", "tmdb");
}

func airingTodayAtPageZero() {
    airingToday(client("t"), 0);
}

func onTheAirAtPageZero() {
    onTheAir(client("t"), 0);
}

func topRatedShowsPastTheCeiling() {
    topRatedShows(client("t"), MAX_PAGE + 1);
}

func showReviewsAtPageZero() {
    showReviews(client("t"), 1399, 0);
}

func showSimilarAtPageZero() {
    showSimilar(client("t"), 1399, 0);
}

func showSimilarWithZeroId() {
    showSimilar(client("t"), 0, 1);
}

func testShowSubResourceVerbsValidateTheId() {
    testing.assertThrows("showAggregateCreditsWithZeroId", "tmdb");
    testing.assertThrows("showAlternativeTitlesWithZeroId", "tmdb");
    testing.assertThrows("showContentRatingsWithZeroId", "tmdb");
    testing.assertThrows("showCreditsWithZeroId", "tmdb");
    testing.assertThrows("showEpisodeGroupsWithZeroId", "tmdb");
    testing.assertThrows("showExternalIdsWithZeroId", "tmdb");
    testing.assertThrows("showImagesWithZeroId", "tmdb");
    testing.assertThrows("showKeywordsWithZeroId", "tmdb");
    testing.assertThrows("showTranslationsWithZeroId", "tmdb");
    testing.assertThrows("showVideosWithZeroId", "tmdb");
    testing.assertThrows("showWatchProvidersWithNegativeId", "tmdb");
}

func showAggregateCreditsWithZeroId() {
    showAggregateCredits(client("t"), 0);
}

func showAlternativeTitlesWithZeroId() {
    showAlternativeTitles(client("t"), 0);
}

func showContentRatingsWithZeroId() {
    showContentRatings(client("t"), 0);
}

func showCreditsWithZeroId() {
    showCredits(client("t"), 0);
}

func showEpisodeGroupsWithZeroId() {
    showEpisodeGroups(client("t"), 0);
}

func showExternalIdsWithZeroId() {
    showExternalIds(client("t"), 0);
}

func showImagesWithZeroId() {
    showImages(client("t"), 0);
}

func showKeywordsWithZeroId() {
    showKeywords(client("t"), 0);
}

func showTranslationsWithZeroId() {
    showTranslations(client("t"), 0);
}

func showVideosWithZeroId() {
    showVideos(client("t"), 0);
}

func showWatchProvidersWithNegativeId() {
    showWatchProviders(client("t"), -1399);
}

func testSeasonSubResourceVerbsValidateTheirNumbers() {
    testing.assertThrows("seasonAggregateCreditsWithNegativeSeason", "tmdb");
    testing.assertThrows("seasonCreditsWithNegativeSeason", "tmdb");
    testing.assertThrows("seasonExternalIdsWithZeroSeries", "tmdb");
    testing.assertThrows("seasonImagesWithNegativeSeason", "tmdb");
    testing.assertThrows("seasonVideosWithNegativeSeason", "tmdb");
}

func seasonAggregateCreditsWithNegativeSeason() {
    seasonAggregateCredits(client("t"), 1399, -1);
}

func seasonCreditsWithNegativeSeason() {
    seasonCredits(client("t"), 1399, -1);
}

func seasonExternalIdsWithZeroSeries() {
    seasonExternalIds(client("t"), 0, 1);
}

func seasonImagesWithNegativeSeason() {
    seasonImages(client("t"), 1399, -1);
}

func seasonVideosWithNegativeSeason() {
    seasonVideos(client("t"), 1399, -1);
}

func testEpisodeSubResourceVerbsValidateTheirNumbers() {
    testing.assertThrows("episodeCreditsWithNegativeEpisode", "tmdb");
    testing.assertThrows("episodeExternalIdsWithNegativeSeason", "tmdb");
    testing.assertThrows("episodeImagesWithZeroSeries", "tmdb");
    testing.assertThrows("episodeVideosWithNegativeEpisode", "tmdb");
}

func episodeCreditsWithNegativeEpisode() {
    episodeCredits(client("t"), 1399, 1, -1);
}

func episodeExternalIdsWithNegativeSeason() {
    episodeExternalIds(client("t"), 1399, -1, 1);
}

func episodeImagesWithZeroSeries() {
    episodeImages(client("t"), 0, 1, 1);
}

func episodeVideosWithNegativeEpisode() {
    episodeVideos(client("t"), 1399, 1, -1);
}

func testSeasonZeroReachesTheWire() {
    # specials live in season 0, so the sub-resource verbs must send it
    assertRequested(seasonZeroVideos, "GET " + API_BASE + "/3/tv/1399/season/0/videos");
    assertRequested(
        specialEpisodeCredits,
        "GET " + API_BASE + "/3/tv/1399/season/0/episode/1/credits");
}

func seasonZeroVideos(c as Client) {
    seasonVideos($c, 1399, 0);
}

func specialEpisodeCredits(c as Client) {
    episodeCredits($c, 1399, 0, 1);
}

func latestShowRequest(c as Client) {
    latestShow($c);
}
