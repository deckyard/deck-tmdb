# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the shared model.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j
#
# The JSON in these tests is copied from TMDB's own documented responses,
# trimmed to the fields the folds read.

func testGenderName() {
    testing.assertEqual(genderName(0), "unknown");
    testing.assertEqual(genderName(1), "female");
    testing.assertEqual(genderName(2), "male");
    testing.assertEqual(genderName(3), "non-binary");
    testing.assertEqual(genderName(9), "unknown");
}

func testMorePagesStopsAtTheTmdbCeiling() {
    testing.assertTrue(morePages(1, 5));
    testing.assertFalse(morePages(5, 5));
    testing.assertFalse(morePages(6, 5));
    # TMDB refuses page 501 however many pages it claims to have
    testing.assertFalse(morePages(MAX_PAGE, 900));
    testing.assertTrue(morePages(MAX_PAGE - 1, 900));
}

func testGenreFolds() {
    def doc as json.Value init json.decode('{"genres": [
        {"id": 12, "name": "Adventure"}, {"id": 28, "name": "Action"}]}');
    def genres as list of Genre init genresFrom($doc, "/genres");
    testing.assertEqual(len($genres), 2);
    testing.assertEqual($genres[0].id, 12);
    testing.assertEqual($genres[1].name, "Action");
    testing.assertEqual(len(genresFrom($doc, "/missing")), 0);
}

func testGenreIndexAndNames() {
    def index as map of string to string init genreIndex([
        Genre{id: 12, name: "Adventure"},
        Genre{id: 28, name: "Action"}
    ]);
    testing.assertEqual($index["12"], "Adventure");
    testing.assertEqual(genreNames($index, [28, 12]), ["Action", "Adventure"]);
    # an id the index has never heard of is skipped, not reported as ""
    testing.assertEqual(genreNames($index, [28, 99999]), ["Action"]);
    testing.assertEqual(genreNames($index, []), []);
}

func testCompanyAndNetworkFolds() {
    def doc as json.Value init json.decode('{
        "production_companies": [
            {"id": 1, "logo_path": "/tlV.png", "name": "Lucasfilm Ltd.", "origin_country": "US"}],
        "networks": [
            {"id": 49, "logo_path": "/tuo.png", "name": "HBO", "origin_country": "US"}]
    }');
    def companies as list of Company init companiesFrom($doc, "/production_companies");
    testing.assertEqual($companies[0].name, "Lucasfilm Ltd.");
    testing.assertEqual($companies[0].logoPath, "/tlV.png");
    def networks as list of Network init networksFrom($doc, "/networks");
    testing.assertEqual($networks[0].id, 49);
    testing.assertEqual($networks[0].originCountry, "US");
}

func testCountryFoldFillsNameFromWhicheverShapeArrived() {
    # a production country carries a plain `name`
    def embedded as json.Value init json.decode('{"cs": [{"iso_3166_1": "US", "name": "United States of America"}]}');
    def one as list of Country init countriesFrom($embedded, "/cs");
    testing.assertEqual($one[0].code, "US");
    testing.assertEqual($one[0].name, "United States of America");
    testing.assertEqual($one[0].englishName, "");

    # the configuration endpoint carries english_name / native_name instead
    def configured as json.Value init json.decode('{"cs": [{"iso_3166_1": "DE", "english_name": "Germany", "native_name": "Deutschland"}]}');
    def two as list of Country init countriesFrom($configured, "/cs");
    testing.assertEqual($two[0].name, "Germany");
    testing.assertEqual($two[0].nativeName, "Deutschland");
}

func testLanguageFold() {
    def doc as json.Value init json.decode('{"spoken_languages": [
        {"english_name": "English", "iso_639_1": "en", "name": "English"}]}');
    def langs as list of Language init languagesFrom($doc, "/spoken_languages");
    testing.assertEqual($langs[0].code, "en");
    testing.assertEqual($langs[0].englishName, "English");
}

func testCollectionRefFoldZeroesWhenThereIsNoCollection() {
    def belongs as json.Value init json.decode('{"belongs_to_collection": {
        "id": 10, "name": "Star Wars Collection",
        "poster_path": "/pWV.jpg", "backdrop_path": "/iY2.jpg"}}');
    def ref as CollectionRef init collectionRefFrom($belongs, "/belongs_to_collection");
    testing.assertEqual($ref.id, 10);
    testing.assertEqual($ref.name, "Star Wars Collection");

    def alone as json.Value init json.decode('{"belongs_to_collection": null}');
    testing.assertEqual(collectionRefFrom($alone, "/belongs_to_collection").id, 0);
}

func testMovieSummaryFold() {
    def doc as json.Value init json.decode('{"results": [{
        "adult": false,
        "backdrop_path": "/hZk.jpg",
        "genre_ids": [18, 53, 35],
        "id": 550,
        "original_language": "en",
        "original_title": "Fight Club",
        "overview": "A ticking-time-bomb insomniac...",
        "popularity": 73.433,
        "poster_path": "/pB8.jpg",
        "release_date": "1999-10-15",
        "title": "Fight Club",
        "video": false,
        "vote_average": 8.433,
        "vote_count": 26279
    }]}');
    def m as MovieSummary init movieSummaryFrom($doc, "/results/0");
    testing.assertEqual($m.id, 550);
    testing.assertEqual($m.title, "Fight Club");
    testing.assertEqual($m.releaseDate, "1999-10-15");
    testing.assertEqual($m.genreIds, [18, 53, 35]);
    testing.assertEqual($m.voteCount, 26279);
    testing.assertEqual($m.voteAverage, 8.433);
    testing.assertFalse($m.adult);
    testing.assertFalse($m.video);
}

func testShowSummaryFold() {
    def doc as json.Value init json.decode('{"results": [{
        "adult": false,
        "backdrop_path": "/6LW.jpg",
        "genre_ids": [10765, 18],
        "id": 1399,
        "origin_country": ["US"],
        "original_language": "en",
        "original_name": "Game of Thrones",
        "overview": "Seven noble families...",
        "popularity": 346.098,
        "poster_path": "/1XS.jpg",
        "first_air_date": "2011-04-17",
        "name": "Game of Thrones",
        "vote_average": 8.4,
        "vote_count": 21000
    }]}');
    def s as ShowSummary init showSummaryFrom($doc, "/results/0");
    testing.assertEqual($s.id, 1399);
    testing.assertEqual($s.name, "Game of Thrones");
    testing.assertEqual($s.firstAirDate, "2011-04-17");
    testing.assertEqual($s.originCountry, ["US"]);
    testing.assertEqual($s.genreIds, [10765, 18]);
}

func testPersonSummaryFoldReadsKnownFor() {
    def doc as json.Value init json.decode('{"results": [{
        "adult": false,
        "gender": 2,
        "id": 31,
        "known_for_department": "Acting",
        "name": "Tom Hanks",
        "original_name": "Tom Hanks",
        "popularity": 82.989,
        "profile_path": "/xnd.jpg",
        "known_for": [
            {"id": 13, "media_type": "movie", "title": "Forrest Gump",
             "release_date": "1994-06-23"},
            {"id": 862, "media_type": "movie", "title": "Toy Story"}]
    }]}');
    def p as PersonSummary init personSummaryFrom($doc, "/results/0");
    testing.assertEqual($p.name, "Tom Hanks");
    testing.assertEqual($p.gender, 2);
    testing.assertEqual($p.knownForDepartment, "Acting");
    testing.assertEqual(len($p.knownFor), 2);
    testing.assertEqual($p.knownFor[0].title, "Forrest Gump");
    testing.assertTrue($p.knownFor[0].kind == MediaKind.Movie);
}

func testMediaItemNormalizesTitleAndDate() {
    def doc as json.Value init json.decode('{"results": [
        {"media_type": "movie", "id": 550, "title": "Fight Club",
         "original_title": "Fight Club", "release_date": "1999-10-15"},
        {"media_type": "tv", "id": 1399, "name": "Game of Thrones",
         "original_name": "Game of Thrones", "first_air_date": "2011-04-17",
         "origin_country": ["US"]},
        {"media_type": "person", "id": 31, "name": "Tom Hanks",
         "known_for_department": "Acting", "profile_path": "/xnd.jpg"}
    ]}');
    def rows as list of MediaItem init mediaItemsFrom($doc, "/results", MediaKind.Unknown);
    testing.assertEqual(len($rows), 3);

    testing.assertTrue($rows[0].kind == MediaKind.Movie);
    testing.assertEqual($rows[0].title, "Fight Club");
    testing.assertEqual($rows[0].releaseDate, "1999-10-15");

    # a series' `name` and `first_air_date` land in the same two fields
    testing.assertTrue($rows[1].kind == MediaKind.Show);
    testing.assertEqual($rows[1].title, "Game of Thrones");
    testing.assertEqual($rows[1].releaseDate, "2011-04-17");
    testing.assertEqual($rows[1].originCountry, ["US"]);

    testing.assertTrue($rows[2].kind == MediaKind.Person);
    testing.assertEqual($rows[2].title, "Tom Hanks");
    testing.assertEqual($rows[2].releaseDate, "");
    testing.assertEqual($rows[2].profilePath, "/xnd.jpg");
}

func testMediaItemUsesTheFallbackKindWhenTmdbOmitsOne() {
    def doc as json.Value init json.decode('{"parts": [{"id": 11, "title": "Star Wars"}]}');
    def rows as list of MediaItem init mediaItemsFrom($doc, "/parts", MediaKind.Movie);
    testing.assertTrue($rows[0].kind == MediaKind.Movie);
    def unknown as list of MediaItem init mediaItemsFrom($doc, "/parts", MediaKind.Unknown);
    testing.assertTrue($unknown[0].kind == MediaKind.Unknown);
}

func testFirstText() {
    def doc as json.Value init json.decode('{"a": {"name": "n"}, "b": {"title": "t"}}');
    testing.assertEqual(firstText($doc, "/a", ["/title", "/name"]), "n");
    testing.assertEqual(firstText($doc, "/b", ["/title", "/name"]), "t");
    testing.assertEqual(firstText($doc, "/a", ["/nope"]), "");
}

func testKindPredicatesAndFilters() {
    def rows as list of MediaItem init [
        blankItem(MediaKind.Movie, 1),
        blankItem(MediaKind.Show, 2),
        blankItem(MediaKind.Person, 3),
        blankItem(MediaKind.Movie, 4)
    ];
    testing.assertTrue(isMovie($rows[0]));
    testing.assertTrue(isShow($rows[1]));
    testing.assertTrue(isPerson($rows[2]));
    testing.assertFalse(isMovie($rows[1]));
    testing.assertEqual(len(onlyMovies($rows)), 2);
    testing.assertEqual(onlyMovies($rows)[1].id, 4);
    testing.assertEqual(len(onlyShows($rows)), 1);
    testing.assertEqual(len(onlyPeople($rows)), 1);
    testing.assertEqual(len(onlyMovies([])), 0);
}

func testPageFolds() {
    def movies as json.Value init json.decode('{
        "page": 2, "total_pages": 7, "total_results": 133,
        "results": [{"id": 550, "title": "Fight Club"}]}');
    def mp as MoviePage init moviePageFrom($movies);
    testing.assertEqual($mp.page, 2);
    testing.assertEqual($mp.totalPages, 7);
    testing.assertEqual($mp.totalResults, 133);
    testing.assertEqual($mp.results[0].title, "Fight Club");

    def shows as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{"id": 1399, "name": "Game of Thrones"}]}');
    testing.assertEqual(showPageFrom($shows).results[0].name, "Game of Thrones");

    def people as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{"id": 31, "name": "Tom Hanks"}]}');
    testing.assertEqual(personPageFrom($people).results[0].name, "Tom Hanks");

    def mixed as json.Value init json.decode('{
        "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{"id": 550, "title": "Fight Club", "media_type": "movie"}]}');
    testing.assertTrue(mediaPageFrom($mixed, MediaKind.Unknown).results[0].kind == MediaKind.Movie);
}

func testEmptyPageFoldsToAnEmptyPage() {
    def empty as json.Value init json.decode('{"page": 1, "results": [], "total_pages": 1, "total_results": 0}');
    testing.assertEqual(len(moviePageFrom($empty).results), 0);
    testing.assertEqual(moviePageFrom($empty).totalResults, 0);
}

func testImageFolds() {
    def doc as json.Value init json.decode('{
        "id": 550,
        "backdrops": [{"aspect_ratio": 1.778, "height": 2160, "iso_639_1": null,
            "file_path": "/hZk.jpg", "vote_average": 5.312, "vote_count": 4, "width": 3840}],
        "posters": [{"aspect_ratio": 0.667, "height": 3000, "iso_639_1": "en",
            "file_path": "/pB8.jpg", "vote_average": 5.456, "vote_count": 9, "width": 2000}],
        "logos": []
    }');
    def images as Images init imagesFrom($doc);
    testing.assertEqual($images.id, 550);
    testing.assertEqual(len($images.backdrops), 1);
    testing.assertEqual($images.backdrops[0].filePath, "/hZk.jpg");
    testing.assertEqual($images.backdrops[0].width, 3840);
    # TMDB writes null for "no text in this image"
    testing.assertEqual($images.backdrops[0].language, "");
    testing.assertEqual($images.posters[0].language, "en");
    testing.assertEqual(len($images.logos), 0);
    testing.assertEqual(len($images.stills), 0);
    testing.assertEqual(len($images.profiles), 0);
}

func testVideoFold() {
    def doc as json.Value init json.decode('{"id": 550, "results": [{
        "iso_639_1": "en", "iso_3166_1": "US", "name": "Fight Club | #TBT Trailer",
        "key": "BdJKm16Co6M", "site": "YouTube", "size": 1080, "type": "Trailer",
        "official": true, "published_at": "2014-10-02T19:20:22.000Z", "id": "5c9294240e0a267cd5"
    }]}');
    def videos as list of Video init videosFrom($doc);
    testing.assertEqual(len($videos), 1);
    testing.assertEqual($videos[0].key, "BdJKm16Co6M");
    testing.assertEqual($videos[0].site, "YouTube");
    testing.assertEqual($videos[0].kind, "Trailer");
    testing.assertEqual($videos[0].size, 1080);
    testing.assertEqual($videos[0].region, "US");
    testing.assertTrue($videos[0].official);
}

func testCreditsFold() {
    def doc as json.Value init json.decode('{
        "id": 550,
        "cast": [{"adult": false, "gender": 2, "id": 819, "known_for_department": "Acting",
            "name": "Edward Norton", "original_name": "Edward Norton", "popularity": 26.99,
            "profile_path": "/8nY.jpg", "cast_id": 4, "character": "The Narrator",
            "credit_id": "52fe4250c3a36847f80149f3", "order": 0}],
        "crew": [{"adult": false, "gender": 2, "id": 7467, "known_for_department": "Directing",
            "name": "David Fincher", "original_name": "David Fincher", "popularity": 11.6,
            "profile_path": "/tpE.jpg", "credit_id": "52fe4250c3a36847f8014a47",
            "department": "Directing", "job": "Director"}]
    }');
    def credits as Credits init creditsFrom($doc);
    testing.assertEqual($credits.id, 550);
    testing.assertEqual($credits.cast[0].name, "Edward Norton");
    testing.assertEqual($credits.cast[0].character, "The Narrator");
    testing.assertEqual($credits.cast[0].castId, 4);
    testing.assertEqual($credits.cast[0].order, 0);
    testing.assertEqual($credits.crew[0].job, "Director");
    testing.assertEqual($credits.crew[0].department, "Directing");
}

func testExternalIdsFold() {
    def doc as json.Value init json.decode('{
        "id": 550, "imdb_id": "tt0137523", "wikidata_id": "Q190050",
        "facebook_id": "fightclub", "instagram_id": null, "twitter_id": null,
        "tvdb_id": 121361
    }');
    def ids as ExternalIds init externalIdsFrom($doc);
    testing.assertEqual($ids.imdbId, "tt0137523");
    testing.assertEqual($ids.wikidataId, "Q190050");
    testing.assertEqual($ids.facebookId, "fightclub");
    # TMDB writes null far more often than it omits the key
    testing.assertEqual($ids.instagramId, "");
    testing.assertEqual($ids.tvdbId, 121361);
    testing.assertEqual($ids.tiktokId, "");
}

func testKeywordFold() {
    def doc as json.Value init json.decode('{"id": 550, "keywords": [{"id": 818, "name": "based on novel or book"}]}');
    def keywords as list of Keyword init keywordsFrom($doc, "/keywords");
    testing.assertEqual(len($keywords), 1);
    testing.assertEqual($keywords[0].id, 818);
    testing.assertEqual($keywords[0].name, "based on novel or book");
}

func testReviewFolds() {
    def doc as json.Value init json.decode('{
        "id": 550, "page": 1, "total_pages": 1, "total_results": 1,
        "results": [{
            "author": "Goddard",
            "author_details": {"name": "Christopher", "username": "Goddard",
                "avatar_path": "/uec.jpg", "rating": 9.0},
            "content": "A masterpiece.",
            "created_at": "2021-06-23T15:58:07.921Z",
            "id": "60d3672d3cc0e0007e6b1c0d",
            "updated_at": "2021-06-23T16:00:00.000Z",
            "url": "https://www.themoviedb.org/review/60d3672d3cc0e0007e6b1c0d"
        }]}');
    def page as ReviewPage init reviewPageFrom($doc);
    testing.assertEqual($page.id, 550);
    testing.assertEqual($page.totalResults, 1);
    def one as Review init $page.results[0];
    testing.assertEqual($one.author, "Goddard");
    testing.assertEqual($one.username, "Goddard");
    testing.assertEqual($one.name, "Christopher");
    testing.assertEqual($one.rating, 9.0);
    testing.assertEqual($one.content, "A masterpiece.");
    # a review read off a title's page does not know what it is about
    testing.assertEqual($one.mediaId, 0);
    testing.assertTrue($one.mediaKind == MediaKind.Unknown);
}

func testWatchProviderFolds() {
    def doc as json.Value init json.decode('{"results": {"DE": {
        "link": "https://www.themoviedb.org/movie/550/watch?locale=DE",
        "flatrate": [{"logo_path": "/pbp.jpg", "provider_id": 8,
            "provider_name": "Netflix", "display_priority": 0}],
        "rent": [{"logo_path": "/peU.jpg", "provider_id": 2,
            "provider_name": "Apple TV", "display_priority": 1}]
    }}}');
    def offers as WatchOffers init watchOffersFrom($doc, "/results/DE", "DE");
    testing.assertEqual($offers.region, "DE");
    testing.assertContains($offers.link, "locale=DE");
    testing.assertEqual(len($offers.flatrate), 1);
    testing.assertEqual($offers.flatrate[0].providerName, "Netflix");
    testing.assertEqual($offers.flatrate[0].providerId, 8);
    testing.assertEqual(len($offers.rent), 1);
    # the buckets TMDB left out fold to empty lists, not to a missing field
    testing.assertEqual(len($offers.buy), 0);
    testing.assertEqual(len($offers.ads), 0);
    testing.assertEqual(len($offers.free), 0);
}

func testTranslationFoldReadsBothTitleAndName() {
    def films as json.Value init json.decode('{"translations": [{
        "iso_3166_1": "DE", "iso_639_1": "de", "name": "Deutsch", "english_name": "German",
        "data": {"homepage": "", "overview": "Ein Mann...", "runtime": 139,
            "tagline": "Alles ist erlaubt.", "title": "Fight Club"}}]}');
    def one as list of Translation init translationsFrom($films);
    testing.assertEqual($one[0].region, "DE");
    testing.assertEqual($one[0].language, "de");
    testing.assertEqual($one[0].name, "Deutsch");
    testing.assertEqual($one[0].englishName, "German");
    testing.assertEqual($one[0].title, "Fight Club");
    testing.assertEqual($one[0].tagline, "Alles ist erlaubt.");

    # a series files its title under `name` instead
    def series as json.Value init json.decode('{"translations": [{
        "iso_3166_1": "DE", "iso_639_1": "de",
        "data": {"name": "Das Lied von Eis und Feuer", "overview": "x"}}]}');
    testing.assertEqual(translationsFrom($series)[0].title, "Das Lied von Eis und Feuer");
}

func testAlternativeTitleFoldReadsBothEnvelopes() {
    # a film files them under `titles`
    def films as json.Value init json.decode('{"id": 550, "titles": [
        {"iso_3166_1": "BR", "title": "Clube da Luta", "type": ""}]}');
    def one as list of AlternativeTitle init alternativeTitlesFrom($films);
    testing.assertEqual(len($one), 1);
    testing.assertEqual($one[0].region, "BR");
    testing.assertEqual($one[0].title, "Clube da Luta");

    # a series files them under `results`
    def series as json.Value init json.decode('{"id": 1399, "results": [
        {"iso_3166_1": "DE", "title": "GoT", "type": "abbreviation"}]}');
    def two as list of AlternativeTitle init alternativeTitlesFrom($series);
    testing.assertEqual($two[0].title, "GoT");
    testing.assertEqual($two[0].kind, "abbreviation");

    testing.assertEqual(len(alternativeTitlesFrom(json.decode('{"id": 1}'))), 0);
}

func testStatusFold() {
    def doc as json.Value init json.decode('{"status_message": "The item/record was created successfully.", "id": 8175284, ' +
        '"success": true, "status_code": 1}');
    def status as StatusResponse init statusFrom($doc);
    testing.assertTrue($status.success);
    testing.assertEqual($status.statusCode, 1);
    testing.assertEqual($status.id, 8175284);
    testing.assertContains($status.statusMessage, "created successfully");
}

/**
 * A zeroed mixed row of one kind, for the filter tests.
 *
 * @param kind {MediaKind} the kind to stamp on it
 * @param id {int} the id to stamp on it
 * @return {MediaItem} the row
 * @internal
 */
func blankItem(kind as MediaKind, id as int) {
    return MediaItem{
        kind: $kind,
        id: $id,
        title: "",
        originalTitle: "",
        overview: "",
        posterPath: "",
        backdropPath: "",
        profilePath: "",
        releaseDate: "",
        genreIds: [],
        originalLanguage: "",
        originCountry: [],
        knownForDepartment: "",
        popularity: 0.0,
        voteAverage: 0.0,
        voteCount: 0,
        adult: false,
        video: false
    };
}
