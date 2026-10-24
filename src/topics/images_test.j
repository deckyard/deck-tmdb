# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - white-box tests for the configuration and image topic.
# Spliced into tmdb_test.j via include - run with:
#   jennifer test src/tmdb_test.j

func testConfigurationFold() {
    def doc as json.Value init json.decode('{
        "images": {
            "base_url": "http://image.tmdb.org/t/p/",
            "secure_base_url": "https://image.tmdb.org/t/p/",
            "backdrop_sizes": ["w300", "w780", "w1280", "original"],
            "logo_sizes": ["w45", "w92", "w154", "w185", "w300", "w500", "original"],
            "poster_sizes": ["w92", "w154", "w185", "w342", "w500", "w780", "original"],
            "profile_sizes": ["w45", "w185", "h632", "original"],
            "still_sizes": ["w92", "w185", "w300", "original"]
        },
        "change_keys": ["adult", "air_date", "budget"]
    }');
    def cfg as Configuration init configurationFrom($doc);
    testing.assertEqual($cfg.secureBaseUrl, DEFAULT_IMAGE_BASE);
    testing.assertEqual($cfg.baseUrl, "http://image.tmdb.org/t/p/");
    testing.assertEqual(len($cfg.posterSizes), 7);
    testing.assertEqual($cfg.profileSizes, ["w45", "w185", "h632", SIZE_ORIGINAL]);
    testing.assertEqual($cfg.changeKeys, ["adult", "air_date", "budget"]);
}

func testDefaultConfigurationMatchesTheDocumentedOne() {
    def cfg as Configuration init defaultConfiguration();
    testing.assertEqual($cfg.secureBaseUrl, DEFAULT_IMAGE_BASE);
    testing.assertContains($cfg.posterSizes, "w500");
    testing.assertContains($cfg.backdropSizes, "w1280");
    testing.assertContains($cfg.profileSizes, "h632");
    testing.assertContains($cfg.stillSizes, "w300");
    testing.assertContains($cfg.logoSizes, "w154");
    # every list ends with the size that always exists
    testing.assertContains($cfg.posterSizes, SIZE_ORIGINAL);
}

func testPosterUrl() {
    def cfg as Configuration init defaultConfiguration();
    testing.assertEqual(
        posterUrl($cfg, "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg", "w500"),
        "https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg");
}

func testEveryPerKindBuilder() {
    def cfg as Configuration init defaultConfiguration();
    testing.assertContains(backdropUrl($cfg, "/a.jpg", "w1280"), "/w1280/a.jpg");
    testing.assertContains(profileUrl($cfg, "/a.jpg", "h632"), "/h632/a.jpg");
    testing.assertContains(stillUrl($cfg, "/a.jpg", "w300"), "/w300/a.jpg");
    testing.assertContains(logoUrl($cfg, "/a.jpg", "w154"), "/w154/a.jpg");
    testing.assertContains(imageUrl($cfg, "/a.jpg", SIZE_ORIGINAL), "/original/a.jpg");
}

func testAnEmptyPathGivesAnEmptyUrl() {
    # TMDB writes null for "this object has no poster"; a listing wants a
    # placeholder, not a URL that 404s
    def cfg as Configuration init defaultConfiguration();
    testing.assertEqual(posterUrl($cfg, "", "w500"), "");
    testing.assertEqual(posterUrl($cfg, "   ", "w500"), "");
    testing.assertEqual(imageUrl($cfg, "", SIZE_ORIGINAL), "");
}

func testAPathWithoutALeadingSlashStillWorks() {
    testing.assertEqual(
        posterUrl(defaultConfiguration(), "pB8.jpg", "w500"),
        "https://image.tmdb.org/t/p/w500/pB8.jpg");
}

func testTheSizeIsCheckedAgainstTheRightList() {
    # w342 is a poster size and not a profile size
    testing.assertContains(posterUrl(defaultConfiguration(), "/a.jpg", "w342"), "w342");
    testing.assertThrows("profileAtAPosterSize", "tmdb");
    testing.assertThrows("posterAtAMadeUpSize", "tmdb");
    testing.assertThrows("posterAtABlankSize", "tmdb");
}

func profileAtAPosterSize() {
    profileUrl(defaultConfiguration(), "/a.jpg", "w342");
}

func posterAtAMadeUpSize() {
    posterUrl(defaultConfiguration(), "/a.jpg", "w9999");
}

func posterAtABlankSize() {
    posterUrl(defaultConfiguration(), "/a.jpg", "  ");
}

func testTheErrorNamesTheSizesThatWouldWork() {
    try {
        posterUrl(defaultConfiguration(), "/a.jpg", "w9999");
        testing.assertTrue(false);
    } catch (e) {
        testing.assertContains($e.message, "poster size");
        testing.assertContains($e.message, "w500");
    }
}

func testImageUrlAcceptsAnySizeFromAnyList() {
    def cfg as Configuration init defaultConfiguration();
    # h632 is a profile size, w1280 a backdrop size; the general builder takes both
    testing.assertContains(imageUrl($cfg, "/a.jpg", "h632"), "/h632/");
    testing.assertContains(imageUrl($cfg, "/a.jpg", "w1280"), "/w1280/");
    testing.assertThrows("imageAtAMadeUpSize", "tmdb");
}

func imageAtAMadeUpSize() {
    imageUrl(defaultConfiguration(), "/a.jpg", "w9999");
}

func testEnsureImagePathRefusesAnythingButAPath() {
    testing.assertEqual(ensureImagePath("/a.jpg"), "/a.jpg");
    testing.assertEqual(ensureImagePath("a.jpg"), "/a.jpg");
    testing.assertThrows("imagePathThatIsAUrl", "tmdb");
    testing.assertThrows("imagePathWithTraversal", "tmdb");
    testing.assertThrows("imagePathWithAQuery", "tmdb");
    testing.assertThrows("imagePathWithASpace", "tmdb");
}

func imagePathThatIsAUrl() {
    posterUrl(defaultConfiguration(), "https://evil.example/a.jpg", "w500");
}

func imagePathWithTraversal() {
    posterUrl(defaultConfiguration(), "/../../a.jpg", "w500");
}

func imagePathWithAQuery() {
    posterUrl(defaultConfiguration(), "/a.jpg?x=1", "w500");
}

func imagePathWithASpace() {
    posterUrl(defaultConfiguration(), "/a b.jpg", "w500");
}

func testImageHostPrefersHttpsAndAlwaysEndsInASlash() {
    def cfg as Configuration init defaultConfiguration();
    testing.assertEqual(imageHost($cfg), DEFAULT_IMAGE_BASE);

    def insecure as Configuration init $cfg;
    $insecure.secureBaseUrl = "";
    testing.assertEqual(imageHost($insecure), "http://image.tmdb.org/t/p/");

    def bare as Configuration init $cfg;
    $bare.secureBaseUrl = "";
    $bare.baseUrl = "";
    testing.assertEqual(imageHost($bare), DEFAULT_IMAGE_BASE);

    def unslashed as Configuration init $cfg;
    $unslashed.secureBaseUrl = "https://cdn.example/t/p";
    testing.assertEqual(imageHost($unslashed), "https://cdn.example/t/p/");
}

func testAllSizesIsTheDeduplicatedUnion() {
    def sizes as list of string init allSizes(defaultConfiguration());
    testing.assertContains($sizes, "w92");
    testing.assertContains($sizes, "h632");
    testing.assertContains($sizes, "w1280");
    # "original" is in all five lists and must appear once
    def originals as int init 0;
    for (def size in $sizes) {
        if ($size == SIZE_ORIGINAL) {
            $originals = $originals + 1;
        }
    }
    testing.assertEqual($originals, 1);
}

func testSizeList() {
    testing.assertEqual(sizeList(["w92", "w500"]), "w92, w500");
    testing.assertContains(sizeList([]), "fetch the configuration first");
}

func testVideoUrl() {
    testing.assertEqual(
        videoUrl(sampleVideo("YouTube", "BdJKm16Co6M")),
        "https://www.youtube.com/watch?v=BdJKm16Co6M");
    testing.assertEqual(videoUrl(sampleVideo("Vimeo", "12345")), "https://vimeo.com/12345");
    # case does not matter; an unknown host answers "" rather than a bad link
    testing.assertContains(videoUrl(sampleVideo("youtube", "abc")), "youtube.com/watch?v=abc");
    testing.assertEqual(videoUrl(sampleVideo("Dailymotion", "abc")), "");
    testing.assertEqual(videoUrl(sampleVideo("YouTube", "")), "");
}

func testVideoThumbnailUrl() {
    testing.assertEqual(
        videoThumbnailUrl(sampleVideo("YouTube", "BdJKm16Co6M")),
        "https://img.youtube.com/vi/BdJKm16Co6M/hqdefault.jpg");
    # Vimeo thumbnails are not addressable without a second API call
    testing.assertEqual(videoThumbnailUrl(sampleVideo("Vimeo", "12345")), "");
    testing.assertEqual(videoThumbnailUrl(sampleVideo("YouTube", "")), "");
}

/**
 * A video record with only the two fields the URL builders read.
 *
 * @param site {string} the hosting site
 * @param key {string} the id on that site
 * @return {Video} the record
 * @internal
 */
func sampleVideo(site as string, key as string) {
    return Video{
        id: "x",
        name: "Trailer",
        key: $key,
        site: $site,
        size: 1080,
        kind: "Trailer",
        language: "en",
        region: "US",
        official: true,
        publishedAt: ""
    };
}

func testConfigurationVerbsAskForTheirEndpoints() {
    assertRequested(configurationRequest, "GET " + API_BASE + "/3/configuration");
    assertRequested(countriesRequest, "GET " + API_BASE + "/3/configuration/countries");
    assertRequested(jobsRequest, "GET " + API_BASE + "/3/configuration/jobs");
    assertRequested(languagesRequest, "GET " + API_BASE + "/3/configuration/languages");
    assertRequested(
        primaryTranslationsRequest,
        "GET " + API_BASE + "/3/configuration/primary_translations");
    assertRequested(timezonesRequest, "GET " + API_BASE + "/3/configuration/timezones");
}

func configurationRequest(c as Client) {
    configuration($c);
}

func countriesRequest(c as Client) {
    countries($c);
}

func jobsRequest(c as Client) {
    jobs($c);
}

func languagesRequest(c as Client) {
    languages($c);
}

func primaryTranslationsRequest(c as Client) {
    primaryTranslations($c);
}

func timezonesRequest(c as Client) {
    timezones($c);
}
