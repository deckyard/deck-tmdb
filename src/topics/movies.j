# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the /movie endpoints: one film, its sub-resources, the curated lists.
# Spliced into tmdb.j via include - not a standalone module.

/**
 * The sub-resources `movieBundle` appends: nine of TMDB's limit of 20.
 *
 * `watch/providers` is addressed in the reply as `watch~1providers`.
 *
 * @internal
 */
def const MOVIE_APPENDICES as list of string init [
    "credits",
    "images",
    "videos",
    "keywords",
    "external_ids",
    "recommendations",
    "similar",
    "reviews",
    "watch/providers"
];

/**
 * Release type: the festival or press premiere.
 */
export def const RELEASE_PREMIERE as int init 1;

/**
 * Release type: a limited theatrical run.
 */
export def const RELEASE_THEATRICAL_LIMITED as int init 2;

/**
 * Release type: the wide theatrical release, the usual "release date".
 */
export def const RELEASE_THEATRICAL as int init 3;

/**
 * Release type: digital (streaming or download).
 */
export def const RELEASE_DIGITAL as int init 4;

/**
 * Release type: physical media.
 */
export def const RELEASE_PHYSICAL as int init 5;

/**
 * Release type: a television broadcast.
 */
export def const RELEASE_TV as int init 6;

/**
 * A film's full record, as `/movie/{id}` answers it.
 *
 * Missing values come back zeroed: an unreleased film has `runtime` 0 and
 * `releaseDate` "", and many films have `budget` and `revenue` 0 because
 * nobody filed the numbers.
 *
 * @field id {int} the movie id
 * @field title {string} the title, in the client's language
 * @field originalTitle {string} the title in its original language
 * @field tagline {string} the marketing line, "" when there is none
 * @field overview {string} the synopsis
 * @field releaseDate {string} the primary release date, `YYYY-MM-DD`
 * @field runtime {int} the runtime in minutes, 0 when unknown
 * @field status {string} e.g. "Released", "Post Production", "Planned"
 * @field homepage {string} the official site, "" when there is none
 * @field imdbId {string} e.g. "tt0076759", "" when not cross-referenced
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field genres {list of Genre} the genres, named
 * @field belongsToCollection {CollectionRef} the franchise, `id` 0 when none
 * @field budget {int} the budget in US dollars, 0 when not filed
 * @field revenue {int} the box office in US dollars, 0 when not filed
 * @field originalLanguage {string} an ISO 639-1 code
 * @field originCountry {list of string} the producing countries
 * @field spokenLanguages {list of Language} the languages spoken in it
 * @field productionCompanies {list of Company} the companies behind it
 * @field productionCountries {list of Country} where it was made
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} how many ratings that mean is over
 * @field adult {bool} whether the film is adult
 * @field video {bool} TMDB's direct-to-video flag
 */
export def struct Movie {
    id as int,
    title as string,
    originalTitle as string,
    tagline as string,
    overview as string,
    releaseDate as string,
    runtime as int,
    status as string,
    homepage as string,
    imdbId as string,
    posterPath as string,
    backdropPath as string,
    genres as list of Genre,
    belongsToCollection as CollectionRef,
    budget as int,
    revenue as int,
    originalLanguage as string,
    originCountry as list of string,
    spokenLanguages as list of Language,
    productionCompanies as list of Company,
    productionCountries as list of Country,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool,
    video as bool
};

/**
 * One dated release of a film in one country.
 *
 * A country usually has several (premiere, cinemas, streaming, disc), and
 * each can carry its own certification.
 *
 * @field date {string} an ISO 8601 timestamp
 * @field kind {int} a `RELEASE_*` constant - see `releaseTypeName`
 * @field certification {string} the age rating, "" when unrated
 * @field language {string} an ISO 639-1 code, "" when not language-specific
 * @field note {string} a free-text qualifier, e.g. "Director's cut"
 */
export def struct ReleaseDate {
    date as string,
    kind as int,
    certification as string,
    language as string,
    note as string
};

/**
 * Every release of a film in one country.
 *
 * @field region {string} the two-letter country code
 * @field releases {list of ReleaseDate} the releases there, in TMDB's order
 */
export def struct ReleaseGroup {
    region as string,
    releases as list of ReleaseDate
};

/**
 * A film and nine sub-resources, fetched in one request by `movieBundle`.
 *
 * Every field is filled; a film with no reviews has an empty `reviews`.
 *
 * @field movie {Movie} the film itself
 * @field credits {Credits} cast and crew
 * @field images {Images} posters, backdrops and logos
 * @field videos {list of Video} trailers, teasers and clips
 * @field keywords {list of Keyword} the subject tags
 * @field externalIds {ExternalIds} the film's ids elsewhere
 * @field recommendations {MoviePage} what TMDB suggests next
 * @field similar {MoviePage} films sharing genres and keywords
 * @field reviews {ReviewPage} the first page of user reviews
 * @field watchOffers {list of WatchOffers} where to watch it, by country
 */
export def struct MovieBundle {
    movie as Movie,
    credits as Credits,
    images as Images,
    videos as list of Video,
    keywords as list of Keyword,
    externalIds as ExternalIds,
    recommendations as MoviePage,
    similar as MoviePage,
    reviews as ReviewPage,
    watchOffers as list of WatchOffers
};

/**
 * Read a film's record.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {Movie} the film
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown film, or a
 *                 transport failure
 * @example
 *   def film as tmdb.Movie init tmdb.movie($c, 550);
 *   io.printf("%s (%s), %d min\n", $film.title, tmdb.year($film.releaseDate), $film.runtime);
 */
export func movie(c as Client, movieId as int) {
    return movieFrom(apiGet($c, moviePath($movieId, ""), localeParams($c)));
}

/**
 * Read a film and nine of its sub-resources in one request.
 *
 * Uses `append_to_response`: one request instead of ten, with a larger
 * reply. The paged members (`recommendations`, `similar`, `reviews`) are
 * always page 1; call the individual verb for a later page.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {MovieBundle} the film and its sub-resources
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown film, or a
 *                 transport failure
 * @example
 *   def b as tmdb.MovieBundle init tmdb.movieBundle($c, 550);
 *   io.printf("%s, directed by %s\n", $b.movie.title, tmdb.directorOf($b.credits));
 *   io.printf("%d in the cast, %d trailers\n", len($b.credits.cast), len($b.videos));
 */
export func movieBundle(c as Client, movieId as int) {
    def params as map of string to string init localeParams($c);
    $params["append_to_response"] = strings.join(MOVIE_APPENDICES, ",");
    def reply as json.Value init apiGet($c, moviePath($movieId, ""), $params);
    return MovieBundle{
        movie: movieFrom($reply),
        credits: creditsFrom(json.get($reply, "/credits")),
        images: imagesFrom(json.get($reply, "/images")),
        videos: videosFrom(json.get($reply, "/videos")),
        keywords: keywordsFrom($reply, "/keywords/keywords"),
        externalIds: externalIdsFrom(json.get($reply, "/external_ids")),
        recommendations: moviePageFrom(json.get($reply, "/recommendations")),
        similar: moviePageFrom(json.get($reply, "/similar")),
        reviews: reviewPageFrom(json.get($reply, "/reviews")),
        watchOffers: watchOffersListFrom(json.get($reply, "/watch~1providers"))
    };
}

/**
 * Read a film's cast and crew.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {Credits} the cast, in billing order, and the crew
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   def credits as tmdb.Credits init tmdb.movieCredits($c, 550);
 *   for (def actor in $credits.cast) {
 *       io.printf("%s as %s\n", $actor.name, $actor.character);
 *   }
 */
export func movieCredits(c as Client, movieId as int) {
    return creditsFrom(apiGet($c, moviePath($movieId, "/credits"), localeParams($c)));
}

/**
 * Read a film's artwork.
 *
 * Sends no `language`, so artwork in every language comes back. Each
 * `Image` carries the language of the text in it.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {Images} the backdrops, posters and logos
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func movieImages(c as Client, movieId as int) {
    return imagesFrom(apiGet($c, moviePath($movieId, "/images"), {}));
}

/**
 * Read a film's trailers, teasers and clips.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of Video} the videos; pair with `videoUrl`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   for (def v in tmdb.movieVideos($c, 550)) {
 *       if ($v.kind == "Trailer" and $v.official) {
 *           io.printf("%s\n", tmdb.videoUrl($v));
 *       }
 *   }
 */
export func movieVideos(c as Client, movieId as int) {
    return videosFrom(apiGet($c, moviePath($movieId, "/videos"), localeParams($c)));
}

/**
 * Read a film's subject keywords.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of Keyword} the keywords
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func movieKeywords(c as Client, movieId as int) {
    return keywordsFrom(apiGet($c, moviePath($movieId, "/keywords"), {}), "/keywords");
}

/**
 * Read what TMDB recommends after a film.
 *
 * Based on viewing behaviour; `movieSimilar` is the content-based list.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the recommendations
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func movieRecommendations(c as Client, movieId as int, page as int) {
    return moviePageFrom(apiGet($c, moviePath($movieId, "/recommendations"), pageParams($c, $page)));
}

/**
 * Read films that share genres and keywords with a film.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the similar films
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func movieSimilar(c as Client, movieId as int, page as int) {
    return moviePageFrom(apiGet($c, moviePath($movieId, "/similar"), pageParams($c, $page)));
}

/**
 * Read a film's user reviews.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @param page {int} the page to fetch, 1-based
 * @return {ReviewPage} the reviews
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func movieReviews(c as Client, movieId as int, page as int) {
    return reviewPageFrom(apiGet($c, moviePath($movieId, "/reviews"), pageParams($c, $page)));
}

/**
 * Read every dated release of a film, by country, with age ratings.
 *
 * `certificationOf` picks one country's rating out of the result.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of ReleaseGroup} the releases, grouped by country
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   def groups as list of tmdb.ReleaseGroup init tmdb.movieReleaseDates($c, 550);
 *   io.printf("US rating: %s\n", tmdb.certificationOf($groups, "US"));
 */
export func movieReleaseDates(c as Client, movieId as int) {
    return releaseGroupsFrom(apiGet($c, moviePath($movieId, "/release_dates"), {}));
}

/**
 * Read a film's ids on other sites.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {ExternalIds} the ids
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func movieExternalIds(c as Client, movieId as int) {
    return externalIdsFrom(apiGet($c, moviePath($movieId, "/external_ids"), {}));
}

/**
 * Read a film's translated titles and synopses.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of Translation} every translation TMDB holds
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func movieTranslations(c as Client, movieId as int) {
    return translationsFrom(apiGet($c, moviePath($movieId, "/translations"), {}));
}

/**
 * Read the titles a film is released under elsewhere.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of AlternativeTitle} the alternative titles
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func movieAlternativeTitles(c as Client, movieId as int) {
    return alternativeTitlesFrom(apiGet($c, moviePath($movieId, "/alternative_titles"), {}));
}

/**
 * Read where a film can be watched, country by country.
 *
 * The data comes from JustWatch, and TMDB's terms require you to credit
 * JustWatch when you display it. Availability changes weekly; do not cache
 * it for long.
 *
 * @param c {Client} an API client
 * @param movieId {int} the movie id
 * @return {list of WatchOffers} one entry per country TMDB has offers for
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   def here as tmdb.WatchOffers init tmdb.offersIn(tmdb.movieWatchProviders($c, 550), "DE");
 *   for (def p in $here.flatrate) { io.printf("%s\n", $p.providerName); }
 */
export func movieWatchProviders(c as Client, movieId as int) {
    return watchOffersListFrom(apiGet($c, moviePath($movieId, "/watch/providers"), {}));
}

/**
 * Read the films in cinemas now.
 *
 * Sends the client's region; without `withRegion` TMDB answers the US
 * listing.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the films now playing
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 * @example
 *   $c = tmdb.withRegion($c, "DE");
 *   for (def m in tmdb.nowPlaying($c, 1).results) { io.printf("%s\n", $m.title); }
 */
export func nowPlaying(c as Client, page as int) {
    return moviePageFrom(apiGet($c, "/3/movie/now_playing", regionParams($c, $page)));
}

/**
 * Read the most popular films; sends the client's region.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the popular films
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func popularMovies(c as Client, page as int) {
    return moviePageFrom(apiGet($c, "/3/movie/popular", regionParams($c, $page)));
}

/**
 * Read the best rated films.
 *
 * TMDB applies its own vote floor, so the list does not match
 * `discoverMovies` sorted by rating. Sends the client's region.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the top rated films
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func topRatedMovies(c as Client, page as int) {
    return moviePageFrom(apiGet($c, "/3/movie/top_rated", regionParams($c, $page)));
}

/**
 * Read the films about to be released; sends the client's region.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the upcoming films
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func upcomingMovies(c as Client, page as int) {
    return moviePageFrom(apiGet($c, "/3/movie/upcoming", regionParams($c, $page)));
}

/**
 * Read the film most recently added to TMDB.
 *
 * One record; its id is the current upper bound of the movie id space.
 *
 * @param c {Client} an API client
 * @return {Movie} the newest film record
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func latestMovie(c as Client) {
    return movieFrom(apiGet($c, "/3/movie/latest", localeParams($c)));
}

/**
 * The first director's name out of a credits record.
 *
 * Answers the first "Director" crew credit; use `directorsOf` for a film
 * with several.
 *
 * @param credits {Credits} the credits to look in
 * @return {string} the director's name, or "" when the crew has none
 * @example
 *   io.printf("directed by %s\n", tmdb.directorOf(tmdb.movieCredits($c, 550)));
 */
export func directorOf(credits as Credits) {
    def names as list of string init directorsOf($credits);
    if (len($names) == 0) {
        return "";
    }
    return $names[0];
}

/**
 * Every director's name out of a credits record.
 *
 * @param credits {Credits} the credits to look in
 * @return {list of string} the names, in crew order
 * @example
 *   strings.join(tmdb.directorsOf($credits), " & ");
 */
export func directorsOf(credits as Credits) {
    return crewNamed($credits, "Director");
}

/**
 * Every crew name credited with one job.
 *
 * The job is matched case-insensitively against TMDB's job names
 * ("Writer", "Original Music Composer"); `jobs` lists them all.
 *
 * @param credits {Credits} the credits to look in
 * @param job {string} the job name, any case
 * @return {list of string} the names, in crew order
 * @throws {Error} kind "tmdb" when the job name is blank
 * @example
 *   tmdb.crewNamed($credits, "Original Music Composer");
 */
export func crewNamed(credits as Credits, job as string) {
    def wanted as string init strings.lower(ensureText($job, "job name"));
    def names as list of string init [];
    for (def member in $credits.crew) {
        if (strings.lower($member.job) == $wanted) {
            $names[] = $member.name;
        }
    }
    return $names;
}

/**
 * The lowercase name of a release type.
 *
 * @param kind {int} a `ReleaseDate.kind`, or a `RELEASE_*` constant
 * @return {string} e.g. "theatrical", "digital"; "unknown" for anything else
 */
export func releaseTypeName(kind as int) {
    match ($kind) {
        when RELEASE_PREMIERE { return "premiere"; }
        when RELEASE_THEATRICAL_LIMITED { return "theatrical (limited)"; }
        when RELEASE_THEATRICAL { return "theatrical"; }
        when RELEASE_DIGITAL { return "digital"; }
        when RELEASE_PHYSICAL { return "physical"; }
        when RELEASE_TV { return "tv"; }
        else { return "unknown"; }
    }
    return "unknown";
}

/**
 * One country's age rating, out of a release-dates result.
 *
 * Answers the first non-empty certification among the country's releases,
 * because the premiere row is often unrated where the theatrical one is not.
 *
 * @param groups {list of ReleaseGroup} the result of `movieReleaseDates`
 * @param region {string} two-letter country code, any case
 * @return {string} the certification, or "" when that country has none
 * @example
 *   tmdb.certificationOf(tmdb.movieReleaseDates($c, 550), "DE");
 */
export func certificationOf(groups as list of ReleaseGroup, region as string) {
    def wanted as string init strings.upper(strings.trim($region));
    for (def group in $groups) {
        if (strings.upper($group.region) != $wanted) {
            continue;
        }
        for (def release in $group.releases) {
            if ($release.certification != "") {
                return $release.certification;
            }
        }
    }
    return "";
}

/**
 * One country's offers, out of a watch-providers result.
 *
 * A country with no offers gives empty lists and an empty link.
 *
 * @param offers {list of WatchOffers} the result of a watch-providers call
 * @param region {string} two-letter country code, any case
 * @return {WatchOffers} that country's offers, zeroed when there are none
 * @example
 *   def here as tmdb.WatchOffers init tmdb.offersIn($offers, "GB");
 *   io.printf("%d subscription services\n", len($here.flatrate));
 */
export func offersIn(offers as list of WatchOffers, region as string) {
    def wanted as string init strings.upper(strings.trim($region));
    for (def entry in $offers) {
        if (strings.upper($entry.region) == $wanted) {
            return $entry;
        }
    }
    return WatchOffers{
        region: $wanted,
        link: "",
        flatrate: [],
        rent: [],
        buy: [],
        ads: [],
        free: []
    };
}

/**
 * The path of a film's record or one of its sub-resources.
 *
 * @param movieId {int} the movie id
 * @param suffix {string} the sub-resource, e.g. "/credits"; "" for the film
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func moviePath(movieId as int, suffix as string) {
    return "/3/movie/" + convert.toString(ensureId($movieId, "movie")) + $suffix;
}

/**
 * Fold a film record.
 *
 * @param v {json.Value} the reply, or the root of a bundle
 * @return {Movie} the folded film
 * @internal
 */
func movieFrom(v as json.Value) {
    return Movie{
        id: nodeInt($v, "/id"),
        title: nodeString($v, "/title"),
        originalTitle: nodeString($v, "/original_title"),
        tagline: nodeString($v, "/tagline"),
        overview: nodeString($v, "/overview"),
        releaseDate: nodeString($v, "/release_date"),
        runtime: nodeInt($v, "/runtime"),
        status: nodeString($v, "/status"),
        homepage: nodeString($v, "/homepage"),
        imdbId: nodeString($v, "/imdb_id"),
        posterPath: nodeString($v, "/poster_path"),
        backdropPath: nodeString($v, "/backdrop_path"),
        genres: genresFrom($v, "/genres"),
        belongsToCollection: collectionRefFrom($v, "/belongs_to_collection"),
        budget: nodeInt($v, "/budget"),
        revenue: nodeInt($v, "/revenue"),
        originalLanguage: nodeString($v, "/original_language"),
        originCountry: nodeStringList($v, "/origin_country"),
        spokenLanguages: languagesFrom($v, "/spoken_languages"),
        productionCompanies: companiesFrom($v, "/production_companies"),
        productionCountries: countriesFrom($v, "/production_countries"),
        popularity: nodeFloat($v, "/popularity"),
        voteAverage: nodeFloat($v, "/vote_average"),
        voteCount: nodeInt($v, "/vote_count"),
        adult: nodeBool($v, "/adult"),
        video: nodeBool($v, "/video")
    };
}

/**
 * Fold a release-dates reply.
 *
 * @param v {json.Value} the reply
 * @return {list of ReleaseGroup} the folded groups, one per country
 * @internal
 */
func releaseGroupsFrom(v as json.Value) {
    def out as list of ReleaseGroup init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $out[] = ReleaseGroup{
            region: nodeString($v, $ptr + "/iso_3166_1"),
            releases: releaseDatesFrom($v, $ptr + "/release_dates")
        };
    }
    return $out;
}

/**
 * Fold a country's list of releases.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of ReleaseDate} the folded releases
 * @internal
 */
func releaseDatesFrom(v as json.Value, ptr as string) {
    def out as list of ReleaseDate init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        def item as string init itemPointer($ptr, $i);
        $out[] = ReleaseDate{
            date: nodeString($v, $item + "/release_date"),
            kind: nodeInt($v, $item + "/type"),
            certification: nodeString($v, $item + "/certification"),
            language: nodeString($v, $item + "/iso_639_1"),
            note: nodeString($v, $item + "/note")
        };
    }
    return $out;
}

/**
 * Fold a watch-providers reply, whose results are keyed by country.
 *
 * @param v {json.Value} the reply
 * @return {list of WatchOffers} one entry per country, in TMDB's order
 * @internal
 */
func watchOffersListFrom(v as json.Value) {
    def out as list of WatchOffers init [];
    for (def region in nodeKeys($v, "/results")) {
        $out[] = watchOffersFrom($v, "/results/" + pointerToken($region), $region);
    }
    return $out;
}
