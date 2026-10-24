# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the catalog topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testCatalogPaths() {
    testing.assertEqual(collectionPath(10, ""), "/3/collection/10");
    testing.assertEqual(collectionPath(10, "/images"), "/3/collection/10/images");
    testing.assertEqual(companyPath(41077, ""), "/3/company/41077");
    testing.assertEqual(networkPath(49, "/images"), "/3/network/49/images");
    testing.assertEqual(keywordPath(818, "/movies"), "/3/keyword/818/movies");
}

func testCatalogPathsValidateTheirIds() {
    testing.assertThrows("collectionPathWithZeroId", "tmdb");
    testing.assertThrows("companyPathWithZeroId", "tmdb");
    testing.assertThrows("networkPathWithZeroId", "tmdb");
    testing.assertThrows("keywordPathWithZeroId", "tmdb");
}

func collectionPathWithZeroId() {
    collectionPath(0, "");
}

func companyPathWithZeroId() {
    companyPath(0, "");
}

func networkPathWithZeroId() {
    networkPath(0, "");
}

func keywordPathWithZeroId() {
    keywordPath(0, "");
}

func testEveryCatalogVerbValidatesItsId() {
    testing.assertThrows("collectionWithZeroId", "tmdb");
    testing.assertThrows("companyWithZeroId", "tmdb");
    testing.assertThrows("networkWithZeroId", "tmdb");
    testing.assertThrows("keywordWithZeroId", "tmdb");
    testing.assertThrows("keywordMoviesAtPageZero", "tmdb");
}

func collectionWithZeroId() {
    collection(client("t"), 0);
}

func companyWithZeroId() {
    company(client("t"), 0);
}

func networkWithZeroId() {
    network(client("t"), 0);
}

func keywordWithZeroId() {
    keyword(client("t"), 0);
}

func keywordMoviesAtPageZero() {
    keywordMovies(client("t"), 818, 0);
}

func testEnsureToken() {
    testing.assertEqual(ensureToken("  tt0076759  ", "external id"), "tt0076759");
    testing.assertEqual(
        ensureToken("52fe4250c3a36847f80149f3", "credit id"),
        "52fe4250c3a36847f80149f3");
    testing.assertThrows("blankToken", "tmdb");
    testing.assertThrows("tokenWithASlash", "tmdb");
    testing.assertThrows("tokenWithTraversal", "tmdb");
    testing.assertThrows("tokenWithAQuery", "tmdb");
}

func blankToken() {
    ensureToken("  ", "review id");
}

func tokenWithASlash() {
    review(client("t"), "abc/def");
}

func tokenWithTraversal() {
    credit(client("t"), "../../4/account");
}

func tokenWithAQuery() {
    review(client("t"), "abc?x=1");
}

func testCollectionFold() {
    def doc as json.Value init json.decode('{
        "id": 10,
        "name": "Star Wars Collection",
        "original_language": "en",
        "original_name": "Star Wars Collection",
        "overview": "An epic space opera...",
        "poster_path": "/pWV.jpg",
        "backdrop_path": "/iY2.jpg",
        "parts": [
            {"adult": false, "backdrop_path": "/2w4.jpg", "id": 11, "title": "Star Wars",
             "original_title": "Star Wars", "overview": "Princess Leia...",
             "poster_path": "/6Ff.jpg", "media_type": "movie", "original_language": "en",
             "genre_ids": [12, 28, 878], "popularity": 20.6, "release_date": "1977-05-25",
             "video": false, "vote_average": 8.2, "vote_count": 22061},
            {"adult": false, "id": 1891, "title": "The Empire Strikes Back",
             "media_type": "movie", "release_date": "1980-05-20", "vote_average": 8.4}]
    }');
    def set as Collection init collectionFrom($doc);
    testing.assertEqual($set.id, 10);
    testing.assertEqual($set.name, "Star Wars Collection");
    testing.assertEqual($set.originalLanguage, "en");
    testing.assertEqual(len($set.parts), 2);
    testing.assertEqual($set.parts[0].title, "Star Wars");
    testing.assertEqual($set.parts[0].releaseDate, "1977-05-25");
    testing.assertTrue($set.parts[1].kind == MediaKind.Movie);
}

func testCollectionPageFold() {
    def doc as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{"adult": false, "backdrop_path": "/iY2.jpg", "id": 10,
            "name": "Star Wars Collection", "original_language": "en",
            "original_name": "Star Wars Collection", "overview": "An epic...",
            "poster_path": "/pWV.jpg"}]}');
    def page as CollectionPage init collectionPageFrom($doc);
    testing.assertEqual($page.totalResults, 1);
    testing.assertEqual($page.results[0].id, 10);
    testing.assertEqual($page.results[0].name, "Star Wars Collection");
    testing.assertEqual($page.results[0].posterPath, "/pWV.jpg");
}

func testCompanyDetailsFold() {
    def doc as json.Value init json.decode('{
        "description": "",
        "headquarters": "New York City, New York, USA",
        "homepage": "https://a24films.com",
        "id": 41077,
        "logo_path": "/1Qs.png",
        "name": "A24",
        "origin_country": "US",
        "parent_company": null
    }');
    def studio as CompanyDetails init companyDetailsFrom($doc);
    testing.assertEqual($studio.id, 41077);
    testing.assertEqual($studio.name, "A24");
    testing.assertEqual($studio.headquarters, "New York City, New York, USA");
    testing.assertEqual($studio.originCountry, "US");
    # an independent company has no parent, and that reads as 0 / ""
    testing.assertEqual($studio.parentCompanyId, 0);
    testing.assertEqual($studio.parentCompanyName, "");
}

func testCompanyDetailsFoldReadsTheParent() {
    def doc as json.Value init json.decode('{
        "id": 420, "name": "Marvel Studios", "origin_country": "US",
        "parent_company": {"id": 2, "name": "Walt Disney Pictures", "logo_path": "/w.png"}}');
    def studio as CompanyDetails init companyDetailsFrom($doc);
    testing.assertEqual($studio.parentCompanyId, 2);
    testing.assertEqual($studio.parentCompanyName, "Walt Disney Pictures");
}

func testCompanyPageFold() {
    def doc as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{"id": 41077, "logo_path": "/1Qs.png", "name": "A24",
            "origin_country": "US"}]}');
    def page as CompanyPage init companyPageFrom($doc);
    testing.assertEqual($page.results[0].name, "A24");
    testing.assertEqual($page.results[0].originCountry, "US");
}

func testNetworkDetailsFold() {
    def doc as json.Value init json.decode('{
        "headquarters": "New York City, New York",
        "homepage": "http://www.hbo.com",
        "id": 49, "logo_path": "/tuo.png", "name": "HBO", "origin_country": "US"}');
    def n as NetworkDetails init networkDetailsFrom($doc);
    testing.assertEqual($n.id, 49);
    testing.assertEqual($n.name, "HBO");
    testing.assertEqual($n.homepage, "http://www.hbo.com");
}

func testKeywordPageFold() {
    def doc as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 2,
        "results": [{"id": 818, "name": "based on novel or book"},
                    {"id": 4565, "name": "dystopia"}]}');
    def page as KeywordPage init keywordPageFrom($doc);
    testing.assertEqual($page.totalResults, 2);
    testing.assertEqual($page.results[1].name, "dystopia");
}

func testCreditDetailFold() {
    def doc as json.Value init json.decode('{
        "credit_type": "cast",
        "department": "Actors",
        "job": "Actor",
        "media": {"adult": false, "backdrop_path": "/6LW.jpg", "id": 1399,
            "name": "Game of Thrones", "original_language": "en",
            "original_name": "Game of Thrones", "overview": "Seven noble families...",
            "poster_path": "/1XS.jpg", "media_type": "tv", "genre_ids": [10765],
            "popularity": 346.098, "first_air_date": "2011-04-17", "vote_average": 8.4,
            "vote_count": 21000, "origin_country": ["US"], "character": "Jon Snow"},
        "media_type": "tv",
        "id": "5256c8af19c2956ff6046e2b",
        "person": {"adult": false, "id": 239019, "name": "Kit Harington",
            "original_name": "Kit Harington", "media_type": "person", "popularity": 25.0,
            "gender": 2, "known_for_department": "Acting", "profile_path": "/4MT.jpg"}
    }');
    def one as CreditDetail init creditDetailFrom($doc);
    testing.assertEqual($one.id, "5256c8af19c2956ff6046e2b");
    testing.assertEqual($one.creditKind, "cast");
    testing.assertEqual($one.character, "Jon Snow");
    testing.assertEqual($one.person.name, "Kit Harington");
    testing.assertEqual($one.person.gender, 2);
    testing.assertEqual($one.media.title, "Game of Thrones");
    testing.assertTrue($one.media.kind == MediaKind.Show);
    testing.assertEqual($one.media.releaseDate, "2011-04-17");
}

func testFindResultsFold() {
    def doc as json.Value init json.decode('{
        "movie_results": [{"id": 11, "title": "Star Wars", "release_date": "1977-05-25"}],
        "person_results": [],
        "tv_results": [],
        "tv_episode_results": [],
        "tv_season_results": []
    }');
    def hits as FindResults init findResultsFrom($doc);
    testing.assertEqual(len($hits.movies), 1);
    testing.assertEqual($hits.movies[0].title, "Star Wars");
    # the fallback kind is applied because `find` rows carry no media_type
    testing.assertTrue($hits.movies[0].kind == MediaKind.Movie);
    testing.assertEqual(len($hits.shows), 0);
    testing.assertEqual(len($hits.people), 0);
    testing.assertEqual(len($hits.episodes), 0);
    testing.assertEqual(len($hits.seasons), 0);
}

func testFindResultsFoldStampsThePerKindFallback() {
    def doc as json.Value init json.decode('{
        "movie_results": [], "person_results": [{"id": 31, "name": "Tom Hanks"}],
        "tv_results": [{"id": 1399, "name": "Game of Thrones"}],
        "tv_episode_results": [{"id": 63056, "name": "Winter Is Coming"}],
        "tv_season_results": [{"id": 3624, "name": "Season 1"}]}');
    def hits as FindResults init findResultsFrom($doc);
    testing.assertTrue($hits.people[0].kind == MediaKind.Person);
    testing.assertTrue($hits.shows[0].kind == MediaKind.Show);
    testing.assertTrue($hits.episodes[0].kind == MediaKind.Episode);
    testing.assertTrue($hits.seasons[0].kind == MediaKind.Season);
}

func testFindValidatesItsSource() {
    testing.assertContains(FIND_SOURCES, SOURCE_IMDB);
    testing.assertContains(FIND_SOURCES, SOURCE_TVDB);
    testing.assertContains(FIND_SOURCES, SOURCE_WIKIDATA);
    testing.assertContains(FIND_SOURCES, SOURCE_FACEBOOK);
    testing.assertContains(FIND_SOURCES, SOURCE_INSTAGRAM);
    testing.assertContains(FIND_SOURCES, SOURCE_TWITTER);
    testing.assertContains(FIND_SOURCES, SOURCE_TIKTOK);
    testing.assertContains(FIND_SOURCES, SOURCE_YOUTUBE);
    testing.assertThrows("findWithAnUnknownSource", "tmdb");
    testing.assertThrows("findWithNoSource", "tmdb");
    testing.assertThrows("findWithNoId", "tmdb");
}

func findWithAnUnknownSource() {
    find(client("t"), "tt0076759", "letterboxd_id");
}

func findWithNoSource() {
    find(client("t"), "tt0076759", "  ");
}

func findWithNoId() {
    findByImdb(client("t"), "");
}

func testCatalogSubResourceVerbsValidateTheId() {
    testing.assertThrows("collectionImagesWithZeroId", "tmdb");
    testing.assertThrows("collectionTranslationsWithZeroId", "tmdb");
    testing.assertThrows("companyAlternativeNamesWithZeroId", "tmdb");
    testing.assertThrows("companyImagesWithZeroId", "tmdb");
    testing.assertThrows("networkAlternativeNamesWithZeroId", "tmdb");
    testing.assertThrows("networkImagesWithNegativeId", "tmdb");
}

func collectionImagesWithZeroId() {
    collectionImages(client("t"), 0);
}

func collectionTranslationsWithZeroId() {
    collectionTranslations(client("t"), 0);
}

func companyAlternativeNamesWithZeroId() {
    companyAlternativeNames(client("t"), 0);
}

func companyImagesWithZeroId() {
    companyImages(client("t"), 0);
}

func networkAlternativeNamesWithZeroId() {
    networkAlternativeNames(client("t"), 0);
}

func networkImagesWithNegativeId() {
    networkImages(client("t"), -213);
}
