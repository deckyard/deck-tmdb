# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the /tv endpoints: series, seasons, episodes, the curated lists.
# Spliced into tmdb.j via include - not a standalone module.
#
# "tv" on the wire, "show" in the deck. Seasons and episodes are addressed
# by number below the series id (season 2, episode 5), not by their own
# ids. Season 0 holds the specials.

/**
 * The sub-resources `showBundle` appends: ten of TMDB's limit of 20.
 *
 * `aggregate_credits` rather than `credits`, because the flat list holds
 * only the regular cast.
 *
 * @internal
 */
def const SHOW_APPENDICES as list of string init [
    "aggregate_credits",
    "images",
    "videos",
    "keywords",
    "external_ids",
    "content_ratings",
    "recommendations",
    "similar",
    "reviews",
    "watch/providers"
];

/**
 * A series' full record, as `/tv/{id}` answers it.
 *
 * Each `seasons` entry carries the `seasonNumber` that `season` takes.
 *
 * @field id {int} the series id
 * @field name {string} the name, in the client's language
 * @field originalName {string} the name in its original language
 * @field tagline {string} the marketing line, "" when there is none
 * @field overview {string} the synopsis
 * @field firstAirDate {string} `YYYY-MM-DD` of the première
 * @field lastAirDate {string} `YYYY-MM-DD` of the most recent episode
 * @field status {string} e.g. "Returning Series", "Ended", "Canceled"
 * @field kind {string} TMDB's `type`: "Scripted", "Miniseries", "Reality", ...
 * @field homepage {string} the official site, "" when there is none
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field genres {list of Genre} the genres, named
 * @field createdBy {list of Creator} the credited creators
 * @field episodeRunTime {list of int} typical episode lengths in minutes
 * @field numberOfSeasons {int} how many seasons, specials excluded
 * @field numberOfEpisodes {int} how many episodes in total
 * @field seasons {list of SeasonSummary} the seasons, season 0 included
 * @field networks {list of Network} who broadcasts or streams it
 * @field productionCompanies {list of Company} the companies behind it
 * @field productionCountries {list of Country} where it was made
 * @field spokenLanguages {list of Language} the languages spoken in it
 * @field languages {list of string} ISO 639-1 codes TMDB files it under
 * @field originCountry {list of string} the producing countries
 * @field originalLanguage {string} an ISO 639-1 code
 * @field lastEpisodeToAir {Episode} the most recent episode, zeroed if none
 * @field nextEpisodeToAir {Episode} the next one, zeroed when nothing is scheduled
 * @field inProduction {bool} whether more is being made
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} how many ratings that mean is over
 * @field adult {bool} whether the series is adult
 */
export def struct Show {
    id as int,
    name as string,
    originalName as string,
    tagline as string,
    overview as string,
    firstAirDate as string,
    lastAirDate as string,
    status as string,
    kind as string,
    homepage as string,
    posterPath as string,
    backdropPath as string,
    genres as list of Genre,
    createdBy as list of Creator,
    episodeRunTime as list of int,
    numberOfSeasons as int,
    numberOfEpisodes as int,
    seasons as list of SeasonSummary,
    networks as list of Network,
    productionCompanies as list of Company,
    productionCountries as list of Country,
    spokenLanguages as list of Language,
    languages as list of string,
    originCountry as list of string,
    originalLanguage as string,
    lastEpisodeToAir as Episode,
    nextEpisodeToAir as Episode,
    inProduction as bool,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool
};

/**
 * Someone credited with creating a series.
 *
 * @field id {int} the person id
 * @field creditId {string} the credit's own id, for `credit`
 * @field name {string} their name
 * @field gender {int} see `genderName`
 * @field profilePath {string} an image path for `profileUrl`
 */
export def struct Creator {
    id as int,
    creditId as string,
    name as string,
    gender as int,
    profilePath as string
};

/**
 * A season as it appears in a series record.
 *
 * Pass `seasonNumber` to `season` for the episodes. Season 0 is the
 * specials.
 *
 * @field id {int} the season's own id
 * @field seasonNumber {int} its number under the series, 0 for specials
 * @field name {string} e.g. "Season 3", "Specials"
 * @field overview {string} the season synopsis, often ""
 * @field airDate {string} `YYYY-MM-DD` of the first episode
 * @field episodeCount {int} how many episodes it holds
 * @field posterPath {string} an image path for `posterUrl`
 * @field voteAverage {float} the mean user rating of the season
 */
export def struct SeasonSummary {
    id as int,
    seasonNumber as int,
    name as string,
    overview as string,
    airDate as string,
    episodeCount as int,
    posterPath as string,
    voteAverage as float
};

/**
 * A season and its episodes.
 *
 * @field id {int} the season's own id
 * @field seasonNumber {int} its number under the series
 * @field name {string} e.g. "Season 3"
 * @field overview {string} the season synopsis
 * @field airDate {string} `YYYY-MM-DD` of the first episode
 * @field posterPath {string} an image path for `posterUrl`
 * @field voteAverage {float} the mean user rating of the season
 * @field episodes {list of Episode} the episodes, in broadcast order
 */
export def struct Season {
    id as int,
    seasonNumber as int,
    name as string,
    overview as string,
    airDate as string,
    posterPath as string,
    voteAverage as float,
    episodes as list of Episode
};

/**
 * One episode of a series.
 *
 * @field id {int} the episode's own id
 * @field seasonNumber {int} which season it belongs to
 * @field episodeNumber {int} its number within that season
 * @field name {string} the episode title
 * @field overview {string} the synopsis
 * @field airDate {string} `YYYY-MM-DD`, "" when unscheduled
 * @field runtime {int} the runtime in minutes, 0 when unknown
 * @field kind {string} TMDB's `episode_type`: "standard", "finale", "mid_season"
 * @field productionCode {string} the production code, often ""
 * @field showId {int} the series it belongs to
 * @field stillPath {string} an image path for `stillUrl`
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} how many ratings that mean is over
 */
export def struct Episode {
    id as int,
    seasonNumber as int,
    episodeNumber as int,
    name as string,
    overview as string,
    airDate as string,
    runtime as int,
    kind as string,
    productionCode as string,
    showId as int,
    stillPath as string,
    voteAverage as float,
    voteCount as int
};

/**
 * One role a performer played across a series.
 *
 * @field creditId {string} the credit's own id, for `credit`
 * @field character {string} who they played
 * @field episodeCount {int} in how many episodes
 */
export def struct CreditRole {
    creditId as string,
    character as string,
    episodeCount as int
};

/**
 * One job a crew member did across a series.
 *
 * @field creditId {string} the credit's own id, for `credit`
 * @field job {string} the job title
 * @field episodeCount {int} in how many episodes
 */
export def struct CreditJob {
    creditId as string,
    job as string,
    episodeCount as int
};

/**
 * A performer's whole run on a series or season.
 *
 * `roles` holds every part the performer played.
 *
 * @field id {int} the person id
 * @field name {string} the performer's name
 * @field originalName {string} the name in its original script
 * @field roles {list of CreditRole} the parts they played
 * @field totalEpisodeCount {int} episodes across all their roles
 * @field order {int} billing order, 0 first
 * @field gender {int} see `genderName`
 * @field knownForDepartment {string} e.g. "Acting"
 * @field popularity {float} TMDB's popularity score
 * @field profilePath {string} an image path for `profileUrl`
 * @field adult {bool} whether the person is filed as adult
 */
export def struct AggregateCastMember {
    id as int,
    name as string,
    originalName as string,
    roles as list of CreditRole,
    totalEpisodeCount as int,
    order as int,
    gender as int,
    knownForDepartment as string,
    popularity as float,
    profilePath as string,
    adult as bool
};

/**
 * A crew member's whole run on a series or season.
 *
 * @field id {int} the person id
 * @field name {string} their name
 * @field originalName {string} the name in its original script
 * @field jobs {list of CreditJob} the jobs they did
 * @field department {string} the department those jobs sit in
 * @field totalEpisodeCount {int} episodes across all their jobs
 * @field gender {int} see `genderName`
 * @field knownForDepartment {string} what they are usually credited for
 * @field popularity {float} TMDB's popularity score
 * @field profilePath {string} an image path for `profileUrl`
 * @field adult {bool} whether the person is filed as adult
 */
export def struct AggregateCrewMember {
    id as int,
    name as string,
    originalName as string,
    jobs as list of CreditJob,
    department as string,
    totalEpisodeCount as int,
    gender as int,
    knownForDepartment as string,
    popularity as float,
    profilePath as string,
    adult as bool
};

/**
 * Cast and crew rolled up over a whole series or season.
 *
 * One row per person, with every part or job and its episode count. The
 * flat `Credits` from `showCredits` holds only the regular cast.
 *
 * @field id {int} the series or season the credits belong to
 * @field cast {list of AggregateCastMember} performers, in billing order
 * @field crew {list of AggregateCrewMember} everyone else
 */
export def struct AggregateCredits {
    id as int,
    cast as list of AggregateCastMember,
    crew as list of AggregateCrewMember
};

/**
 * A series' age rating in one country.
 *
 * @field region {string} the two-letter country code
 * @field rating {string} the rating in that country's system, e.g. "TV-MA"
 * @field descriptors {list of string} the content warnings behind it
 */
export def struct ContentRating {
    region as string,
    rating as string,
    descriptors as list of string
};

/**
 * An alternative ordering of a series' episodes (DVD, production, story arc).
 *
 * This is the catalogue entry only; fetch the contents with `call` on
 * `/3/tv/episode_group/{id}`.
 *
 * @field id {string} the group id
 * @field name {string} e.g. "Aired Order", "Story Arc"
 * @field description {string} what the ordering is, often ""
 * @field episodeCount {int} how many episodes it covers
 * @field groupCount {int} how many groups (seasons, arcs) it splits into
 * @field kind {int} TMDB's `type` code for the ordering
 * @field network {Network} the network it belongs to, zeroed when none
 */
export def struct EpisodeGroup {
    id as string,
    name as string,
    description as string,
    episodeCount as int,
    groupCount as int,
    kind as int,
    network as Network
};

/**
 * A series and ten sub-resources, fetched in one request by `showBundle`.
 *
 * Carries `AggregateCredits` rather than flat credits.
 *
 * @field show {Show} the series itself
 * @field credits {AggregateCredits} cast and crew, rolled up over the run
 * @field images {Images} posters, backdrops and logos
 * @field videos {list of Video} trailers, teasers and clips
 * @field keywords {list of Keyword} the subject tags
 * @field externalIds {ExternalIds} the series' ids elsewhere
 * @field contentRatings {list of ContentRating} age ratings, by country
 * @field recommendations {ShowPage} what TMDB suggests next
 * @field similar {ShowPage} series sharing genres and keywords
 * @field reviews {ReviewPage} the first page of user reviews
 * @field watchOffers {list of WatchOffers} where to watch it, by country
 */
export def struct ShowBundle {
    show as Show,
    credits as AggregateCredits,
    images as Images,
    videos as list of Video,
    keywords as list of Keyword,
    externalIds as ExternalIds,
    contentRatings as list of ContentRating,
    recommendations as ShowPage,
    similar as ShowPage,
    reviews as ReviewPage,
    watchOffers as list of WatchOffers
};

/**
 * Read a series' record.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {Show} the series
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown series, or a
 *                 transport failure
 * @example
 *   def s as tmdb.Show init tmdb.show($c, 1399);
 *   io.printf("%s: %d seasons, %d episodes\n",
 *       $s.name, $s.numberOfSeasons, $s.numberOfEpisodes);
 */
export func show(c as Client, seriesId as int) {
    return showFrom(apiGet($c, showPath($seriesId, ""), localeParams($c)));
}

/**
 * Read a series and ten of its sub-resources in one request.
 *
 * Uses `append_to_response`, like `movieBundle`. The paged members
 * (`recommendations`, `similar`, `reviews`) are always page 1.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {ShowBundle} the series and its sub-resources
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown series, or a
 *                 transport failure
 * @example
 *   def b as tmdb.ShowBundle init tmdb.showBundle($c, 1399);
 *   io.printf("%s, %s\n", $b.show.name, tmdb.contentRatingOf($b.contentRatings, "US"));
 */
export func showBundle(c as Client, seriesId as int) {
    def params as map of string to string init localeParams($c);
    $params["append_to_response"] = strings.join(SHOW_APPENDICES, ",");
    def reply as json.Value init apiGet($c, showPath($seriesId, ""), $params);
    return ShowBundle{
        show: showFrom($reply),
        credits: aggregateCreditsFrom(json.get($reply, "/aggregate_credits")),
        images: imagesFrom(json.get($reply, "/images")),
        videos: videosFrom(json.get($reply, "/videos")),
        keywords: keywordsFrom($reply, "/keywords/results"),
        externalIds: externalIdsFrom(json.get($reply, "/external_ids")),
        contentRatings: contentRatingsFrom(json.get($reply, "/content_ratings")),
        recommendations: showPageFrom(json.get($reply, "/recommendations")),
        similar: showPageFrom(json.get($reply, "/similar")),
        reviews: reviewPageFrom(json.get($reply, "/reviews")),
        watchOffers: watchOffersListFrom(json.get($reply, "/watch~1providers"))
    };
}

/**
 * Read a series' regular cast and crew.
 *
 * Only the people billed for the series as a whole; `showAggregateCredits`
 * covers everyone who appeared.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {Credits} the regular cast and crew
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showCredits(c as Client, seriesId as int) {
    return creditsFrom(apiGet($c, showPath($seriesId, "/credits"), localeParams($c)));
}

/**
 * Read a series' credits rolled up over its whole run.
 *
 * One row per person, with every part they played and its episode count.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {AggregateCredits} the rolled-up credits
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   for (def actor in tmdb.showAggregateCredits($c, 1399).cast) {
 *       io.printf("%s - %s (%d episodes)\n",
 *           $actor.name, $actor.roles[0].character, $actor.totalEpisodeCount);
 *   }
 */
export func showAggregateCredits(c as Client, seriesId as int) {
    return aggregateCreditsFrom(apiGet(
        $c,
        showPath($seriesId, "/aggregate_credits"),
        localeParams($c)));
}

/**
 * Read a series' artwork, in every language (no `language` is sent).
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {Images} the backdrops, posters and logos
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showImages(c as Client, seriesId as int) {
    return imagesFrom(apiGet($c, showPath($seriesId, "/images"), {}));
}

/**
 * Read a series' trailers, teasers and clips.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of Video} the videos; pair with `videoUrl`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showVideos(c as Client, seriesId as int) {
    return videosFrom(apiGet($c, showPath($seriesId, "/videos"), localeParams($c)));
}

/**
 * Read a series' subject keywords.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of Keyword} the keywords
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showKeywords(c as Client, seriesId as int) {
    return keywordsFrom(apiGet($c, showPath($seriesId, "/keywords"), {}), "/results");
}

/**
 * Read a series' age ratings, country by country.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of ContentRating} the ratings; see `contentRatingOf`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showContentRatings(c as Client, seriesId as int) {
    return contentRatingsFrom(apiGet($c, showPath($seriesId, "/content_ratings"), {}));
}

/**
 * Read the alternative episode orderings a series has.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of EpisodeGroup} the orderings
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showEpisodeGroups(c as Client, seriesId as int) {
    return episodeGroupsFrom(apiGet($c, showPath($seriesId, "/episode_groups"), {}));
}

/**
 * Read what TMDB recommends after a series.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the recommendations
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func showRecommendations(c as Client, seriesId as int, page as int) {
    return showPageFrom(apiGet($c, showPath($seriesId, "/recommendations"), pageParams($c, $page)));
}

/**
 * Read series that share genres and keywords with a series.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the similar series
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func showSimilar(c as Client, seriesId as int, page as int) {
    return showPageFrom(apiGet($c, showPath($seriesId, "/similar"), pageParams($c, $page)));
}

/**
 * Read a series' user reviews.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param page {int} the page to fetch, 1-based
 * @return {ReviewPage} the reviews
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func showReviews(c as Client, seriesId as int, page as int) {
    return reviewPageFrom(apiGet($c, showPath($seriesId, "/reviews"), pageParams($c, $page)));
}

/**
 * Read a series' ids on other sites, TheTVDB's included.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {ExternalIds} the ids
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showExternalIds(c as Client, seriesId as int) {
    return externalIdsFrom(apiGet($c, showPath($seriesId, "/external_ids"), {}));
}

/**
 * Read a series' translated names and synopses.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of Translation} every translation TMDB holds
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showTranslations(c as Client, seriesId as int) {
    return translationsFrom(apiGet($c, showPath($seriesId, "/translations"), {}));
}

/**
 * Read the names a series is broadcast under elsewhere.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of AlternativeTitle} the alternative names
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showAlternativeTitles(c as Client, seriesId as int) {
    return alternativeTitlesFrom(apiGet($c, showPath($seriesId, "/alternative_titles"), {}));
}

/**
 * Read where a series can be watched, country by country.
 *
 * JustWatch data: TMDB's terms require crediting JustWatch when you
 * display it.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @return {list of WatchOffers} one entry per country; see `offersIn`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func showWatchProviders(c as Client, seriesId as int) {
    return watchOffersListFrom(apiGet($c, showPath($seriesId, "/watch/providers"), {}));
}

/**
 * Read one season, episodes included.
 *
 * Season 0 (the specials) is legal; a negative number is refused.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number, 0 for specials
 * @return {Season} the season and its episodes
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 * @example
 *   def s as tmdb.Season init tmdb.season($c, 1399, 1);
 *   for (def e in $s.episodes) {
 *       io.printf("%dx%02d %s\n", $e.seasonNumber, $e.episodeNumber, $e.name);
 *   }
 */
export func season(c as Client, seriesId as int, seasonNumber as int) {
    return seasonFrom(apiGet($c, seasonPath($seriesId, $seasonNumber, ""), localeParams($c)));
}

/**
 * Read a season's cast and crew.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @return {Credits} the season's credits
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func seasonCredits(c as Client, seriesId as int, seasonNumber as int) {
    return creditsFrom(apiGet(
        $c,
        seasonPath($seriesId, $seasonNumber, "/credits"),
        localeParams($c)));
}

/**
 * Read a season's credits rolled up over its episodes.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @return {AggregateCredits} the rolled-up credits
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func seasonAggregateCredits(c as Client, seriesId as int, seasonNumber as int) {
    return aggregateCreditsFrom(apiGet(
        $c,
        seasonPath($seriesId, $seasonNumber, "/aggregate_credits"),
        localeParams($c)));
}

/**
 * Read a season's posters, in every language (no `language` is sent).
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @return {Images} the season posters
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func seasonImages(c as Client, seriesId as int, seasonNumber as int) {
    return imagesFrom(apiGet($c, seasonPath($seriesId, $seasonNumber, "/images"), {}));
}

/**
 * Read a season's videos.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @return {list of Video} the videos; pair with `videoUrl`
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func seasonVideos(c as Client, seriesId as int, seasonNumber as int) {
    return videosFrom(apiGet($c, seasonPath($seriesId, $seasonNumber, "/videos"), localeParams($c)));
}

/**
 * Read a season's ids on other sites.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @return {ExternalIds} the ids
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func seasonExternalIds(c as Client, seriesId as int, seasonNumber as int) {
    return externalIdsFrom(apiGet($c, seasonPath($seriesId, $seasonNumber, "/external_ids"), {}));
}

/**
 * Read one episode's record.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number within that season
 * @return {Episode} the episode
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 * @example
 *   def e as tmdb.Episode init tmdb.episode($c, 1399, 1, 1);
 *   io.printf("%s (%s), %d min\n", $e.name, $e.airDate, $e.runtime);
 */
export func episode(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int) {
    return episodeFrom(
        apiGet($c, episodePath($seriesId, $seasonNumber, $episodeNumber, ""), localeParams($c)),
        "");
}

/**
 * Read an episode's cast, crew and guest stars.
 *
 * The deck appends TMDB's `guest_stars` to `cast`, after the regulars.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number
 * @return {Credits} the episode's credits
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func episodeCredits(
    c as Client,
    seriesId as int,
    seasonNumber as int,
    episodeNumber as int) {
    def reply as json.Value init apiGet(
        $c,
        episodePath($seriesId, $seasonNumber, $episodeNumber, "/credits"),
        localeParams($c));
    def merged as list of CastMember init castFrom($reply, "/cast");
    for (def guest in castFrom($reply, "/guest_stars")) {
        $merged[] = $guest;
    }
    return Credits{id: nodeInt($reply, "/id"), cast: $merged, crew: crewFrom($reply, "/crew")};
}

/**
 * Read an episode's stills, in every language (no `language` is sent).
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number
 * @return {Images} the stills
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func episodeImages(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int) {
    return imagesFrom(apiGet(
        $c,
        episodePath($seriesId, $seasonNumber, $episodeNumber, "/images"),
        {}));
}

/**
 * Read an episode's videos.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number
 * @return {list of Video} the videos; pair with `videoUrl`
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func episodeVideos(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int) {
    return videosFrom(apiGet(
        $c,
        episodePath($seriesId, $seasonNumber, $episodeNumber, "/videos"),
        localeParams($c)));
}

/**
 * Read an episode's ids on other sites.
 *
 * @param c {Client} an API client
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number
 * @return {ExternalIds} the ids
 * @throws {Error} kind "tmdb" on a bad id or number, or a transport failure
 */
export func episodeExternalIds(
    c as Client,
    seriesId as int,
    seasonNumber as int,
    episodeNumber as int) {
    return externalIdsFrom(apiGet(
        $c,
        episodePath($seriesId, $seasonNumber, $episodeNumber, "/external_ids"),
        {}));
}

/**
 * Read the series with an episode airing today, in TMDB's own time zone.
 *
 * `airingTodayIn` takes the time zone.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the series airing today
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func airingToday(c as Client, page as int) {
    return showPageFrom(apiGet($c, "/3/tv/airing_today", pageParams($c, $page)));
}

/**
 * Read the series with an episode airing today, in one time zone.
 *
 * @param c {Client} an API client
 * @param timezone {string} an IANA zone name, e.g. "Europe/Berlin"; see `timezones`
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the series airing today there
 * @throws {Error} kind "tmdb" on a blank zone, a bad page, or a transport failure
 * @example
 *   tmdb.airingTodayIn($c, "Europe/Berlin", 1);
 */
export func airingTodayIn(c as Client, timezone as string, page as int) {
    def params as map of string to string init pageParams($c, $page);
    $params["timezone"] = ensureText($timezone, "time zone");
    return showPageFrom(apiGet($c, "/3/tv/airing_today", $params));
}

/**
 * Read the series with an episode airing in the next seven days.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the series on the air
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func onTheAir(c as Client, page as int) {
    return showPageFrom(apiGet($c, "/3/tv/on_the_air", pageParams($c, $page)));
}

/**
 * Read the most popular series.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the popular series
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func popularShows(c as Client, page as int) {
    return showPageFrom(apiGet($c, "/3/tv/popular", pageParams($c, $page)));
}

/**
 * Read the best rated series.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {ShowPage} the top rated series
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func topRatedShows(c as Client, page as int) {
    return showPageFrom(apiGet($c, "/3/tv/top_rated", pageParams($c, $page)));
}

/**
 * Read the series most recently added to TMDB.
 *
 * @param c {Client} an API client
 * @return {Show} the newest series record
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func latestShow(c as Client) {
    return showFrom(apiGet($c, "/3/tv/latest", localeParams($c)));
}

/**
 * One country's rating, out of a content-ratings result.
 *
 * @param ratings {list of ContentRating} the result of `showContentRatings`
 * @param region {string} two-letter country code, any case
 * @return {string} the rating, or "" when that country has none
 * @example
 *   tmdb.contentRatingOf(tmdb.showContentRatings($c, 1399), "US");   # "TV-MA"
 */
export func contentRatingOf(ratings as list of ContentRating, region as string) {
    def wanted as string init strings.upper(strings.trim($region));
    for (def entry in $ratings) {
        if (strings.upper($entry.region) == $wanted) {
            return $entry.rating;
        }
    }
    return "";
}

/**
 * A season out of a series' season list, by number rather than index.
 *
 * TMDB lists season 0 only when a series has specials, so `seasons[0]` is
 * not always season 0 or season 1.
 *
 * @param s {Show} the series
 * @param seasonNumber {int} the season number to find
 * @return {SeasonSummary} that season, zeroed when the series has no such season
 * @example
 *   def third as tmdb.SeasonSummary init tmdb.seasonOf($show, 3);
 *   io.printf("%d episodes\n", $third.episodeCount);
 */
export func seasonOf(s as Show, seasonNumber as int) {
    for (def entry in $s.seasons) {
        if ($entry.seasonNumber == $seasonNumber) {
            return $entry;
        }
    }
    return SeasonSummary{
        id: 0,
        seasonNumber: $seasonNumber,
        name: "",
        overview: "",
        airDate: "",
        episodeCount: 0,
        posterPath: "",
        voteAverage: 0.0
    };
}

/**
 * The path of a series' record or one of its sub-resources.
 *
 * @param seriesId {int} the series id
 * @param suffix {string} the sub-resource, e.g. "/credits"; "" for the series
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func showPath(seriesId as int, suffix as string) {
    return "/3/tv/" + convert.toString(ensureId($seriesId, "series")) + $suffix;
}

/**
 * The path of a season's record or one of its sub-resources.
 *
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param suffix {string} the sub-resource; "" for the season
 * @return {string} the request path
 * @throws {Error} kind "tmdb" on a non-positive id or a negative season
 * @internal
 */
func seasonPath(seriesId as int, seasonNumber as int, suffix as string) {
    return showPath(
        $seriesId,
        "/season/" +
            convert.toString(ensureNumber($seasonNumber, "season")) + $suffix);
}

/**
 * The path of an episode's record or one of its sub-resources.
 *
 * @param seriesId {int} the series id
 * @param seasonNumber {int} the season number
 * @param episodeNumber {int} the episode number
 * @param suffix {string} the sub-resource; "" for the episode
 * @return {string} the request path
 * @throws {Error} kind "tmdb" on a non-positive id or a negative number
 * @internal
 */
func episodePath(seriesId as int, seasonNumber as int, episodeNumber as int, suffix as string) {
    return seasonPath(
        $seriesId,
        $seasonNumber,
        "/episode/" +
            convert.toString(ensureNumber($episodeNumber, "episode")) + $suffix);
}

/**
 * Fold a series record.
 *
 * @param v {json.Value} the reply, or the root of a bundle
 * @return {Show} the folded series
 * @internal
 */
func showFrom(v as json.Value) {
    return Show{
        id: nodeInt($v, "/id"),
        name: nodeString($v, "/name"),
        originalName: nodeString($v, "/original_name"),
        tagline: nodeString($v, "/tagline"),
        overview: nodeString($v, "/overview"),
        firstAirDate: nodeString($v, "/first_air_date"),
        lastAirDate: nodeString($v, "/last_air_date"),
        status: nodeString($v, "/status"),
        kind: nodeString($v, "/type"),
        homepage: nodeString($v, "/homepage"),
        posterPath: nodeString($v, "/poster_path"),
        backdropPath: nodeString($v, "/backdrop_path"),
        genres: genresFrom($v, "/genres"),
        createdBy: creatorsFrom($v, "/created_by"),
        episodeRunTime: nodeIntList($v, "/episode_run_time"),
        numberOfSeasons: nodeInt($v, "/number_of_seasons"),
        numberOfEpisodes: nodeInt($v, "/number_of_episodes"),
        seasons: seasonSummariesFrom($v, "/seasons"),
        networks: networksFrom($v, "/networks"),
        productionCompanies: companiesFrom($v, "/production_companies"),
        productionCountries: countriesFrom($v, "/production_countries"),
        spokenLanguages: languagesFrom($v, "/spoken_languages"),
        languages: nodeStringList($v, "/languages"),
        originCountry: nodeStringList($v, "/origin_country"),
        originalLanguage: nodeString($v, "/original_language"),
        lastEpisodeToAir: episodeFrom($v, "/last_episode_to_air"),
        nextEpisodeToAir: episodeFrom($v, "/next_episode_to_air"),
        inProduction: nodeBool($v, "/in_production"),
        popularity: nodeFloat($v, "/popularity"),
        voteAverage: nodeFloat($v, "/vote_average"),
        voteCount: nodeInt($v, "/vote_count"),
        adult: nodeBool($v, "/adult")
    };
}

/**
 * Fold a list of creator objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Creator} the folded creators
 * @internal
 */
func creatorsFrom(v as json.Value, ptr as string) {
    def out as list of Creator init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        def item as string init itemPointer($ptr, $i);
        $out[] = Creator{
            id: nodeInt($v, $item + "/id"),
            creditId: nodeString($v, $item + "/credit_id"),
            name: nodeString($v, $item + "/name"),
            gender: nodeInt($v, $item + "/gender"),
            profilePath: nodeString($v, $item + "/profile_path")
        };
    }
    return $out;
}

/**
 * Fold a list of season summaries.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of SeasonSummary} the folded seasons
 * @internal
 */
func seasonSummariesFrom(v as json.Value, ptr as string) {
    def out as list of SeasonSummary init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        def item as string init itemPointer($ptr, $i);
        $out[] = SeasonSummary{
            id: nodeInt($v, $item + "/id"),
            seasonNumber: nodeInt($v, $item + "/season_number"),
            name: nodeString($v, $item + "/name"),
            overview: nodeString($v, $item + "/overview"),
            airDate: nodeString($v, $item + "/air_date"),
            episodeCount: nodeInt($v, $item + "/episode_count"),
            posterPath: nodeString($v, $item + "/poster_path"),
            voteAverage: nodeFloat($v, $item + "/vote_average")
        };
    }
    return $out;
}

/**
 * Fold a season record.
 *
 * @param v {json.Value} the reply
 * @return {Season} the folded season
 * @internal
 */
func seasonFrom(v as json.Value) {
    def episodes as list of Episode init [];
    for (def i in 0..nodeLength($v, "/episodes")) {
        $episodes[] = episodeFrom($v, itemPointer("/episodes", $i));
    }
    return Season{
        id: nodeInt($v, "/id"),
        seasonNumber: nodeInt($v, "/season_number"),
        name: nodeString($v, "/name"),
        overview: nodeString($v, "/overview"),
        airDate: nodeString($v, "/air_date"),
        posterPath: nodeString($v, "/poster_path"),
        voteAverage: nodeFloat($v, "/vote_average"),
        episodes: $episodes
    };
}

/**
 * Fold an episode object: a reply root, a season's `episodes` element, or
 * a series' `last_episode_to_air` / `next_episode_to_air`.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object, "" for the root
 * @return {Episode} the folded episode
 * @internal
 */
func episodeFrom(v as json.Value, ptr as string) {
    return Episode{
        id: nodeInt($v, $ptr + "/id"),
        seasonNumber: nodeInt($v, $ptr + "/season_number"),
        episodeNumber: nodeInt($v, $ptr + "/episode_number"),
        name: nodeString($v, $ptr + "/name"),
        overview: nodeString($v, $ptr + "/overview"),
        airDate: nodeString($v, $ptr + "/air_date"),
        runtime: nodeInt($v, $ptr + "/runtime"),
        kind: nodeString($v, $ptr + "/episode_type"),
        productionCode: nodeString($v, $ptr + "/production_code"),
        showId: nodeInt($v, $ptr + "/show_id"),
        stillPath: nodeString($v, $ptr + "/still_path"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count")
    };
}

/**
 * Fold an aggregate-credits reply.
 *
 * @param v {json.Value} the reply
 * @return {AggregateCredits} the folded credits
 * @internal
 */
func aggregateCreditsFrom(v as json.Value) {
    def cast as list of AggregateCastMember init [];
    for (def i in 0..nodeLength($v, "/cast")) {
        def ptr as string init itemPointer("/cast", $i);
        $cast[] = AggregateCastMember{
            id: nodeInt($v, $ptr + "/id"),
            name: nodeString($v, $ptr + "/name"),
            originalName: nodeString($v, $ptr + "/original_name"),
            roles: rolesFrom($v, $ptr + "/roles"),
            totalEpisodeCount: nodeInt($v, $ptr + "/total_episode_count"),
            order: nodeInt($v, $ptr + "/order"),
            gender: nodeInt($v, $ptr + "/gender"),
            knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
            popularity: nodeFloat($v, $ptr + "/popularity"),
            profilePath: nodeString($v, $ptr + "/profile_path"),
            adult: nodeBool($v, $ptr + "/adult")
        };
    }
    def crew as list of AggregateCrewMember init [];
    for (def i in 0..nodeLength($v, "/crew")) {
        def ptr as string init itemPointer("/crew", $i);
        $crew[] = AggregateCrewMember{
            id: nodeInt($v, $ptr + "/id"),
            name: nodeString($v, $ptr + "/name"),
            originalName: nodeString($v, $ptr + "/original_name"),
            jobs: creditJobsFrom($v, $ptr + "/jobs"),
            department: nodeString($v, $ptr + "/department"),
            totalEpisodeCount: nodeInt($v, $ptr + "/total_episode_count"),
            gender: nodeInt($v, $ptr + "/gender"),
            knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
            popularity: nodeFloat($v, $ptr + "/popularity"),
            profilePath: nodeString($v, $ptr + "/profile_path"),
            adult: nodeBool($v, $ptr + "/adult")
        };
    }
    return AggregateCredits{id: nodeInt($v, "/id"), cast: $cast, crew: $crew};
}

/**
 * Fold a performer's list of roles.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of CreditRole} the folded roles
 * @internal
 */
func rolesFrom(v as json.Value, ptr as string) {
    def out as list of CreditRole init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        def item as string init itemPointer($ptr, $i);
        $out[] = CreditRole{
            creditId: nodeString($v, $item + "/credit_id"),
            character: nodeString($v, $item + "/character"),
            episodeCount: nodeInt($v, $item + "/episode_count")
        };
    }
    return $out;
}

/**
 * Fold a crew member's list of jobs.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of CreditJob} the folded jobs
 * @internal
 */
func creditJobsFrom(v as json.Value, ptr as string) {
    def out as list of CreditJob init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        def item as string init itemPointer($ptr, $i);
        $out[] = CreditJob{
            creditId: nodeString($v, $item + "/credit_id"),
            job: nodeString($v, $item + "/job"),
            episodeCount: nodeInt($v, $item + "/episode_count")
        };
    }
    return $out;
}

/**
 * Fold an episode-groups reply.
 *
 * @param v {json.Value} the reply
 * @return {list of EpisodeGroup} the folded orderings
 * @internal
 */
func episodeGroupsFrom(v as json.Value) {
    def out as list of EpisodeGroup init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $out[] = EpisodeGroup{
            id: nodeString($v, $ptr + "/id"),
            name: nodeString($v, $ptr + "/name"),
            description: nodeString($v, $ptr + "/description"),
            episodeCount: nodeInt($v, $ptr + "/episode_count"),
            groupCount: nodeInt($v, $ptr + "/group_count"),
            kind: nodeInt($v, $ptr + "/type"),
            network: networkFrom($v, $ptr + "/network")
        };
    }
    return $out;
}

/**
 * Fold a content-ratings reply.
 *
 * @param v {json.Value} the reply
 * @return {list of ContentRating} the folded ratings
 * @internal
 */
func contentRatingsFrom(v as json.Value) {
    def out as list of ContentRating init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $out[] = ContentRating{
            region: nodeString($v, $ptr + "/iso_3166_1"),
            rating: nodeString($v, $ptr + "/rating"),
            descriptors: nodeStringList($v, $ptr + "/descriptors")
        };
    }
    return $out;
}
