# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the entity structs both API generations share, and their folds.
# Spliced into tmdb.j via include - not a standalone module.
#
# TMDB repeats a few shapes across endpoints (a genre, a summary row); each
# is folded once, here.

/**
 * A genre id and its name.
 *
 * Films and series number genres differently: `28` is Action for films,
 * series use `10759` "Action & Adventure". Fetch the right list with
 * `movieGenres` or `showGenres`.
 *
 * @field id {int} the genre id, as used by `withGenres` in discovery
 * @field name {string} the name, in the client's language
 */
export def struct Genre {
    id as int,
    name as string
};

/**
 * A production company, as embedded in a film or series.
 *
 * `company` fetches the full record.
 *
 * @field id {int} the company id
 * @field name {string} the company name
 * @field logoPath {string} an image path for `imageUrl`, "" when there is none
 * @field originCountry {string} a two-letter country code, "" when unknown
 */
export def struct Company {
    id as int,
    name as string,
    logoPath as string,
    originCountry as string
};

/**
 * A television network.
 *
 * Shaped like `Company`, but networks have their own id space: network 49
 * is HBO, company 49 is a different company.
 *
 * @field id {int} the network id
 * @field name {string} the network name
 * @field logoPath {string} an image path for `imageUrl`, "" when there is none
 * @field originCountry {string} a two-letter country code, "" when unknown
 */
export def struct Network {
    id as int,
    name as string,
    logoPath as string,
    originCountry as string
};

/**
 * A country from a production list, the configuration list or a region list.
 *
 * A production country carries a code and a name; the configuration and
 * region lists carry an English and a native name. `name` takes `name`,
 * falling back to `english_name`.
 *
 * @field code {string} the two-letter ISO 3166-1 code
 * @field name {string} the best available name
 * @field englishName {string} the English name, "" when not given
 * @field nativeName {string} the endonym, "" when not given
 */
export def struct Country {
    code as string,
    name as string,
    englishName as string,
    nativeName as string
};

/**
 * A language, in either shape TMDB writes one.
 *
 * @field code {string} the ISO 639-1 code
 * @field name {string} the endonym ("Deutsch"), "" when not given
 * @field englishName {string} the English name ("German"), "" when not given
 */
export def struct Language {
    code as string,
    name as string,
    englishName as string
};

/**
 * The collection a film belongs to, as embedded in its record.
 *
 * `collection` fetches it with its parts.
 *
 * @field id {int} the collection id, 0 when the film is in none
 * @field name {string} the collection name
 * @field posterPath {string} an image path for `imageUrl`
 * @field backdropPath {string} an image path for `imageUrl`
 */
export def struct CollectionRef {
    id as int,
    name as string,
    posterPath as string,
    backdropPath as string
};

/**
 * A film as a row of a paginated movie list.
 *
 * The row of search, discovery, recommendations, the curated lists and an
 * account's collections. It carries `genreIds`, not names: resolve them
 * with `genreIndex` over `movieGenres`, fetched once.
 *
 * @field id {int} the movie id
 * @field title {string} the title, in the client's language
 * @field originalTitle {string} the title in its original language
 * @field overview {string} the synopsis, "" when untranslated
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field releaseDate {string} `YYYY-MM-DD`, "" when unknown
 * @field genreIds {list of int} genre ids, resolvable with `movieGenres`
 * @field originalLanguage {string} an ISO 639-1 code
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} number of ratings behind the mean
 * @field adult {bool} whether the title is adult
 * @field video {bool} TMDB's flag for a direct-to-video release
 */
export def struct MovieSummary {
    id as int,
    title as string,
    originalTitle as string,
    overview as string,
    posterPath as string,
    backdropPath as string,
    releaseDate as string,
    genreIds as list of int,
    originalLanguage as string,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool,
    video as bool
};

/**
 * A series as a row of a paginated series list.
 *
 * TMDB calls a series' title `name` and its date `first_air_date`; the
 * struct keeps those names.
 *
 * @field id {int} the series id
 * @field name {string} the series name, in the client's language
 * @field originalName {string} the name in its original language
 * @field overview {string} the synopsis, "" when untranslated
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field firstAirDate {string} `YYYY-MM-DD`, "" when unknown
 * @field genreIds {list of int} genre ids, resolvable with `showGenres`
 * @field originalLanguage {string} an ISO 639-1 code
 * @field originCountry {list of string} the producing countries
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} number of ratings behind the mean
 * @field adult {bool} whether the series is adult
 */
export def struct ShowSummary {
    id as int,
    name as string,
    originalName as string,
    overview as string,
    posterPath as string,
    backdropPath as string,
    firstAirDate as string,
    genreIds as list of int,
    originalLanguage as string,
    originCountry as list of string,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool
};

/**
 * A person as a row of a paginated people list.
 *
 * `knownFor` holds the two or three titles TMDB picks to identify them;
 * it is filled on search and popularity pages and empty elsewhere.
 *
 * @field id {int} the person id
 * @field name {string} the name TMDB files them under
 * @field originalName {string} the name in its original script
 * @field profilePath {string} an image path for `profileUrl`
 * @field knownForDepartment {string} e.g. "Acting", "Directing"
 * @field gender {int} 0 unknown, 1 female, 2 male, 3 non-binary - see `genderName`
 * @field popularity {float} TMDB's popularity score
 * @field adult {bool} whether the person is filed as adult
 * @field knownFor {list of MediaItem} the titles they are known for
 */
export def struct PersonSummary {
    id as int,
    name as string,
    originalName as string,
    profilePath as string,
    knownForDepartment as string,
    gender as int,
    popularity as float,
    adult as bool,
    knownFor as list of MediaItem
};

/**
 * One row of a mixed result set: a film, series, person, season or episode.
 *
 * Multi-search, trending, `find`, a collection's parts and custom list
 * items mix kinds in one array, and TMDB names the same idea differently
 * per kind. This struct normalizes: `title` is `title` or else `name`,
 * `releaseDate` is `release_date`, `first_air_date` or `air_date`, and
 * `kind` says which kind the row is. Fields of one kind only
 * (`profilePath`, `video` ...) are zero on the others.
 *
 * @field kind {MediaKind} what this row is
 * @field id {int} the id, in the id space of `kind`
 * @field title {string} `title` for a film, `name` for a series or person
 * @field originalTitle {string} the same, in the original language
 * @field overview {string} the synopsis, "" for a person
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field profilePath {string} an image path for `profileUrl`, people only
 * @field releaseDate {string} the first date given, "" for a person
 * @field genreIds {list of int} genre ids, empty for a person
 * @field originalLanguage {string} an ISO 639-1 code
 * @field originCountry {list of string} the producing countries, series only
 * @field knownForDepartment {string} e.g. "Acting", people only
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} number of ratings behind the mean
 * @field adult {bool} whether the row is adult
 * @field video {bool} the direct-to-video flag, films only
 */
export def struct MediaItem {
    kind as MediaKind,
    id as int,
    title as string,
    originalTitle as string,
    overview as string,
    posterPath as string,
    backdropPath as string,
    profilePath as string,
    releaseDate as string,
    genreIds as list of int,
    originalLanguage as string,
    originCountry as list of string,
    knownForDepartment as string,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool,
    video as bool
};

/**
 * One page of films.
 *
 * @field page {int} the page number, 1-based
 * @field totalPages {int} the page count TMDB reports, which may exceed `MAX_PAGE`
 * @field totalResults {int} the row count over all pages
 * @field results {list of MovieSummary} this page's rows
 */
export def struct MoviePage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of MovieSummary
};

/**
 * One page of series.
 *
 * @field page {int} the page number, 1-based
 * @field totalPages {int} the page count TMDB reports, which may exceed `MAX_PAGE`
 * @field totalResults {int} the row count over all pages
 * @field results {list of ShowSummary} this page's rows
 */
export def struct ShowPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of ShowSummary
};

/**
 * One page of people.
 *
 * @field page {int} the page number, 1-based
 * @field totalPages {int} the page count TMDB reports, which may exceed `MAX_PAGE`
 * @field totalResults {int} the row count over all pages
 * @field results {list of PersonSummary} this page's rows
 */
export def struct PersonPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of PersonSummary
};

/**
 * One page of mixed rows, from multi-search, trending or a custom list.
 *
 * @field page {int} the page number, 1-based
 * @field totalPages {int} the page count TMDB reports, which may exceed `MAX_PAGE`
 * @field totalResults {int} the row count over all pages
 * @field results {list of MediaItem} this page's rows
 */
export def struct MediaPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of MediaItem
};

/**
 * A still, poster, backdrop, logo or profile image.
 *
 * `filePath` is not a URL: pass it to `imageUrl` with a size from
 * `configuration`, or to `posterUrl`, `backdropUrl`, `profileUrl`,
 * `stillUrl` or `logoUrl`.
 *
 * @field filePath {string} the image path, e.g. "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg"
 * @field aspectRatio {float} width divided by height
 * @field width {int} the original width in pixels
 * @field height {int} the original height in pixels
 * @field language {string} the ISO 639-1 code of any text in it, "" for none
 * @field voteAverage {float} the mean user rating of this image
 * @field voteCount {int} number of ratings behind the mean
 */
export def struct Image {
    filePath as string,
    aspectRatio as float,
    width as int,
    height as int,
    language as string,
    voteAverage as float,
    voteCount as int
};

/**
 * Every image attached to one object, by kind.
 *
 * A film has backdrops, posters and logos; an episode has stills; a person
 * has profiles. The other lists come back empty.
 *
 * @field id {int} the object the images belong to
 * @field backdrops {list of Image} wide artwork
 * @field posters {list of Image} tall artwork
 * @field logos {list of Image} title treatments, usually transparent
 * @field stills {list of Image} episode frames
 * @field profiles {list of Image} photographs of a person
 */
export def struct Images {
    id as int,
    backdrops as list of Image,
    posters as list of Image,
    logos as list of Image,
    stills as list of Image,
    profiles as list of Image
};

/**
 * A trailer, teaser, clip or featurette hosted on YouTube or Vimeo.
 *
 * TMDB stores no video: `site` and `key` name where it lives, and
 * `videoUrl` turns the pair into a link.
 *
 * @field id {string} TMDB's id for this video record
 * @field name {string} the video's title
 * @field key {string} the id on `site`, e.g. a YouTube video id
 * @field site {string} the host, "YouTube" or "Vimeo"
 * @field size {int} the vertical resolution, e.g. 1080
 * @field kind {string} TMDB's `type`: "Trailer", "Teaser", "Clip", ...
 * @field language {string} an ISO 639-1 code
 * @field region {string} an ISO 3166-1 code
 * @field official {bool} whether it comes from the rights holder
 * @field publishedAt {string} an ISO 8601 timestamp
 */
export def struct Video {
    id as string,
    name as string,
    key as string,
    site as string,
    size as int,
    kind as string,
    language as string,
    region as string,
    official as bool,
    publishedAt as string
};

/**
 * Someone in front of the camera.
 *
 * @field id {int} the person id
 * @field name {string} the performer's name
 * @field originalName {string} the name in its original script
 * @field character {string} who they played
 * @field creditId {string} the credit's own id, for `credit`
 * @field order {int} billing order, 0 first
 * @field castId {int} TMDB's per-film cast row id, 0 when not given
 * @field gender {int} see `genderName`
 * @field knownForDepartment {string} e.g. "Acting"
 * @field popularity {float} TMDB's popularity score
 * @field profilePath {string} an image path for `profileUrl`
 * @field adult {bool} whether the person is filed as adult
 */
export def struct CastMember {
    id as int,
    name as string,
    originalName as string,
    character as string,
    creditId as string,
    order as int,
    castId as int,
    gender as int,
    knownForDepartment as string,
    popularity as float,
    profilePath as string,
    adult as bool
};

/**
 * Someone behind the camera.
 *
 * @field id {int} the person id
 * @field name {string} their name
 * @field originalName {string} the name in its original script
 * @field job {string} the specific job, e.g. "Director of Photography"
 * @field department {string} the department the job sits in, e.g. "Camera"
 * @field creditId {string} the credit's own id, for `credit`
 * @field gender {int} see `genderName`
 * @field knownForDepartment {string} what they are usually credited for
 * @field popularity {float} TMDB's popularity score
 * @field profilePath {string} an image path for `profileUrl`
 * @field adult {bool} whether the person is filed as adult
 */
export def struct CrewMember {
    id as int,
    name as string,
    originalName as string,
    job as string,
    department as string,
    creditId as string,
    gender as int,
    knownForDepartment as string,
    popularity as float,
    profilePath as string,
    adult as bool
};

/**
 * The cast and crew of one title.
 *
 * @field id {int} the film, series, season or episode the credits belong to
 * @field cast {list of CastMember} performers, in billing order
 * @field crew {list of CrewMember} everyone else
 */
export def struct Credits {
    id as int,
    cast as list of CastMember,
    crew as list of CrewMember
};

/**
 * The same object's ids on other sites.
 *
 * A field is "" (or 0) when TMDB has no id of that kind, the common case
 * for all but `imdbId`. `find` goes the other way.
 *
 * @field imdbId {string} e.g. "tt0076759" for a title, "nm0000158" for a person
 * @field tvdbId {int} TheTVDB's id, series and episodes only
 * @field tvrageId {int} the retired TVRage id
 * @field wikidataId {string} e.g. "Q17738"
 * @field facebookId {string} a Facebook page or username
 * @field instagramId {string} an Instagram handle
 * @field twitterId {string} an X / Twitter handle
 * @field tiktokId {string} a TikTok handle, people only
 * @field youtubeId {string} a YouTube channel, people only
 * @field freebaseId {string} the retired Freebase id
 * @field freebaseMid {string} the retired Freebase machine id
 */
export def struct ExternalIds {
    imdbId as string,
    tvdbId as int,
    tvrageId as int,
    wikidataId as string,
    facebookId as string,
    instagramId as string,
    twitterId as string,
    tiktokId as string,
    youtubeId as string,
    freebaseId as string,
    freebaseMid as string
};

/**
 * A keyword: TMDB's free-form subject tag.
 *
 * Discovery's `withKeywords` filters on them. They are finer than genres:
 * "dystopia", "based on novel", "one-shot".
 *
 * @field id {int} the keyword id
 * @field name {string} the keyword
 */
export def struct Keyword {
    id as int,
    name as string
};

/**
 * A user review.
 *
 * The `media*` fields are filled only by `review`, which fetches one
 * review by id; a review on a title's reviews page leaves them zero.
 *
 * @field id {string} the review id
 * @field author {string} the display name on the review
 * @field username {string} the reviewer's TMDB username
 * @field name {string} the reviewer's full name, "" when not set
 * @field avatarPath {string} an image path or an absolute Gravatar URL
 * @field rating {float} the reviewer's own score out of 10, 0 when unrated
 * @field content {string} the review body, as Markdown
 * @field url {string} the review's page on TMDB
 * @field createdAt {string} an ISO 8601 timestamp
 * @field updatedAt {string} an ISO 8601 timestamp
 * @field language {string} an ISO 639-1 code
 * @field mediaId {int} the reviewed title, 0 unless fetched by `review`
 * @field mediaTitle {string} the reviewed title's name, "" unless fetched by `review`
 * @field mediaKind {MediaKind} what was reviewed, `Unknown` unless fetched by `review`
 */
export def struct Review {
    id as string,
    author as string,
    username as string,
    name as string,
    avatarPath as string,
    rating as float,
    content as string,
    url as string,
    createdAt as string,
    updatedAt as string,
    language as string,
    mediaId as int,
    mediaTitle as string,
    mediaKind as MediaKind
};

/**
 * One page of reviews.
 *
 * @field id {int} the title the reviews belong to, 0 when not given
 * @field page {int} the page number, 1-based
 * @field totalPages {int} the page count
 * @field totalResults {int} the review count over all pages
 * @field results {list of Review} this page's reviews
 */
export def struct ReviewPage {
    id as int,
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of Review
};

/**
 * A streaming, rental or purchase service.
 *
 * @field providerId {int} the provider id, as used by `withWatchProviders`
 * @field providerName {string} the service's name, e.g. "Netflix"
 * @field logoPath {string} an image path for `logoUrl`
 * @field displayPriority {int} TMDB's suggested ordering, lower first
 */
export def struct WatchProvider {
    providerId as int,
    providerName as string,
    logoPath as string,
    displayPriority as int
};

/**
 * The ways to watch a title in one country.
 *
 * The lists are TMDB's monetization buckets and are often empty: a film
 * may be rentable and buyable but on no subscription service.
 *
 * @field region {string} the two-letter country code
 * @field link {string} a TMDB page listing the offers, "" when not given
 * @field flatrate {list of WatchProvider} included in a subscription
 * @field rent {list of WatchProvider} rentable
 * @field buy {list of WatchProvider} purchasable
 * @field ads {list of WatchProvider} free with advertising
 * @field free {list of WatchProvider} free outright
 */
export def struct WatchOffers {
    region as string,
    link as string,
    flatrate as list of WatchProvider,
    rent as list of WatchProvider,
    buy as list of WatchProvider,
    ads as list of WatchProvider,
    free as list of WatchProvider
};

/**
 * One translation of a title's text.
 *
 * TMDB nests the strings under `data`, keyed `title` for films and `name`
 * for series; both read into `title`.
 *
 * @field region {string} the ISO 3166-1 code the translation is filed under
 * @field language {string} the ISO 639-1 code
 * @field name {string} the endonym of the language
 * @field englishName {string} the English name of the language
 * @field title {string} the translated title or name
 * @field overview {string} the translated synopsis
 * @field tagline {string} the translated tagline, films and series only
 * @field homepage {string} the localized homepage
 */
export def struct Translation {
    region as string,
    language as string,
    name as string,
    englishName as string,
    title as string,
    overview as string,
    tagline as string,
    homepage as string
};

/**
 * A title a work is released under in another country.
 *
 * @field region {string} the two-letter country code
 * @field title {string} the title used there
 * @field kind {string} TMDB's `type` note, e.g. "working title"; often ""
 */
export def struct AlternativeTitle {
    region as string,
    title as string,
    kind as string
};

/**
 * TMDB's answer to a write.
 *
 * Every v4 mutation (creating a list, adding items, logging out) answers
 * in this shape. Check `success`; `statusCode` is TMDB's own outcome
 * code, finer than the HTTP status.
 *
 * @field success {bool} whether the write happened
 * @field statusCode {int} TMDB's status code, e.g. 1 success, 13 deleted
 * @field statusMessage {string} TMDB's sentence about the outcome
 * @field id {int} the id of the thing created, 0 when nothing was
 */
export def struct StatusResponse {
    success as bool,
    statusCode as int,
    statusMessage as string,
    id as int
};

/**
 * The name of a TMDB gender code: 1 female, 2 male, 3 non-binary.
 *
 * @param gender {int} the code from a person record
 * @return {string} "female", "male", "non-binary", or "unknown" for 0 and
 *                  any other code
 */
export func genderName(gender as int) {
    match ($gender) {
        when 1 { return "female"; }
        when 2 { return "male"; }
        when 3 { return "non-binary"; }
        else { return "unknown"; }
    }
    return "unknown";
}

/**
 * Whether a paginated result set has a page after this one.
 *
 * Unlike `page < totalPages`, it stops at `MAX_PAGE`: a query with 900
 * pages of results still refuses page 501.
 *
 * @param page {int} the page just read
 * @param totalPages {int} the `totalPages` from that page
 * @return {bool} true when another page can be fetched
 * @example
 *   def p as int init 1;
 *   def hits as tmdb.MoviePage init tmdb.searchMovies($c, "alien", $p);
 *   while (tmdb.morePages($hits.page, $hits.totalPages)) {
 *       $p = $p + 1;
 *       $hits = tmdb.searchMovies($c, "alien", $p);
 *   }
 */
export func morePages(page as int, totalPages as int) {
    if ($page >= MAX_PAGE) {
        return false;
    }
    return $page < $totalPages;
}

/**
 * Whether a mixed row is a film.
 *
 * @param item {MediaItem} the row
 * @return {bool} true when `kind` is `MediaKind.Movie`
 */
export func isMovie(item as MediaItem) {
    return $item.kind == MediaKind.Movie;
}

/**
 * Whether a mixed row is a series.
 *
 * @param item {MediaItem} the row
 * @return {bool} true when `kind` is `MediaKind.Show`
 */
export func isShow(item as MediaItem) {
    return $item.kind == MediaKind.Show;
}

/**
 * Whether a mixed row is a person.
 *
 * @param item {MediaItem} the row
 * @return {bool} true when `kind` is `MediaKind.Person`
 */
export func isPerson(item as MediaItem) {
    return $item.kind == MediaKind.Person;
}

/**
 * The films of a mixed page, in order.
 *
 * @param items {list of MediaItem} the mixed rows
 * @return {list of MediaItem} the rows whose `kind` is `Movie`
 */
export func onlyMovies(items as list of MediaItem) {
    return ofKind($items, MediaKind.Movie);
}

/**
 * The series of a mixed page, in order.
 *
 * @param items {list of MediaItem} the mixed rows
 * @return {list of MediaItem} the rows whose `kind` is `Show`
 */
export func onlyShows(items as list of MediaItem) {
    return ofKind($items, MediaKind.Show);
}

/**
 * The people of a mixed page, in order.
 *
 * @param items {list of MediaItem} the mixed rows
 * @return {list of MediaItem} the rows whose `kind` is `Person`
 */
export func onlyPeople(items as list of MediaItem) {
    return ofKind($items, MediaKind.Person);
}

/**
 * Index a genre list by id, for resolving `genreIds`.
 *
 * Rows carry only `genreIds`; fetch the genre list once, index it, and
 * look ids up with `genreNames`.
 *
 * @param genres {list of Genre} the genres, from `movieGenres` or `showGenres`
 * @return {map of string to string} id (as text) to name
 * @example
 *   def names as map of string to string init tmdb.genreIndex(tmdb.movieGenres($c));
 *   io.printf("%s\n", $names[convert.toString($m.genreIds[0])]);
 */
export func genreIndex(genres as list of Genre) {
    def index as map of string to string init {};
    for (def g in $genres) {
        $index[convert.toString($g.id)] = $g.name;
    }
    return $index;
}

/**
 * The genre names of a row, looked up in a `genreIndex`.
 *
 * @param index {map of string to string} the index from `genreIndex`
 * @param ids {list of int} the row's `genreIds`
 * @return {list of string} the names, skipping ids the index does not know
 */
export func genreNames(index as map of string to string, ids as list of int) {
    def names as list of string init [];
    for (def id in $ids) {
        def key as string init convert.toString($id);
        if (maps.has($index, $key)) {
            $names[] = $index[$key];
        }
    }
    return $names;
}

/**
 * The rows of a mixed list that are of one kind.
 *
 * @param items {list of MediaItem} the mixed rows
 * @param kind {MediaKind} the kind to keep
 * @return {list of MediaItem} the matching rows, in order
 * @internal
 */
func ofKind(items as list of MediaItem, kind as MediaKind) {
    def out as list of MediaItem init [];
    for (def item in $items) {
        if ($item.kind == $kind) {
            $out[] = $item;
        }
    }
    return $out;
}

/**
 * Fold one genre object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Genre} the folded genre
 * @internal
 */
func genreFrom(v as json.Value, ptr as string) {
    return Genre{id: nodeInt($v, $ptr + "/id"), name: nodeString($v, $ptr + "/name")};
}

/**
 * Fold a list of genre objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Genre} the folded genres
 * @internal
 */
func genresFrom(v as json.Value, ptr as string) {
    def out as list of Genre init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = genreFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one company object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Company} the folded company
 * @internal
 */
func companyFrom(v as json.Value, ptr as string) {
    return Company{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        logoPath: nodeString($v, $ptr + "/logo_path"),
        originCountry: nodeString($v, $ptr + "/origin_country")
    };
}

/**
 * Fold a list of company objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Company} the folded companies
 * @internal
 */
func companiesFrom(v as json.Value, ptr as string) {
    def out as list of Company init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = companyFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one network object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Network} the folded network
 * @internal
 */
func networkFrom(v as json.Value, ptr as string) {
    return Network{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        logoPath: nodeString($v, $ptr + "/logo_path"),
        originCountry: nodeString($v, $ptr + "/origin_country")
    };
}

/**
 * Fold a list of network objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Network} the folded networks
 * @internal
 */
func networksFrom(v as json.Value, ptr as string) {
    def out as list of Network init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = networkFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one country object, filling `name` from whatever was given.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Country} the folded country
 * @internal
 */
func countryFrom(v as json.Value, ptr as string) {
    def english as string init nodeString($v, $ptr + "/english_name");
    def name as string init nodeString($v, $ptr + "/name");
    if ($name == "") {
        $name = $english;
    }
    return Country{
        code: nodeString($v, $ptr + "/iso_3166_1"),
        name: $name,
        englishName: $english,
        nativeName: nodeString($v, $ptr + "/native_name")
    };
}

/**
 * Fold a list of country objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Country} the folded countries
 * @internal
 */
func countriesFrom(v as json.Value, ptr as string) {
    def out as list of Country init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = countryFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one language object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Language} the folded language
 * @internal
 */
func languageFrom(v as json.Value, ptr as string) {
    return Language{
        code: nodeString($v, $ptr + "/iso_639_1"),
        name: nodeString($v, $ptr + "/name"),
        englishName: nodeString($v, $ptr + "/english_name")
    };
}

/**
 * Fold a list of language objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Language} the folded languages
 * @internal
 */
func languagesFrom(v as json.Value, ptr as string) {
    def out as list of Language init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = languageFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold the collection a film belongs to.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object, which may be null
 * @return {CollectionRef} the reference, zeroed when the film is in none
 * @internal
 */
func collectionRefFrom(v as json.Value, ptr as string) {
    return CollectionRef{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        posterPath: nodeString($v, $ptr + "/poster_path"),
        backdropPath: nodeString($v, $ptr + "/backdrop_path")
    };
}

/**
 * Fold one movie row.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {MovieSummary} the folded row
 * @internal
 */
func movieSummaryFrom(v as json.Value, ptr as string) {
    return MovieSummary{
        id: nodeInt($v, $ptr + "/id"),
        title: nodeString($v, $ptr + "/title"),
        originalTitle: nodeString($v, $ptr + "/original_title"),
        overview: nodeString($v, $ptr + "/overview"),
        posterPath: nodeString($v, $ptr + "/poster_path"),
        backdropPath: nodeString($v, $ptr + "/backdrop_path"),
        releaseDate: nodeString($v, $ptr + "/release_date"),
        genreIds: nodeIntList($v, $ptr + "/genre_ids"),
        originalLanguage: nodeString($v, $ptr + "/original_language"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count"),
        adult: nodeBool($v, $ptr + "/adult"),
        video: nodeBool($v, $ptr + "/video")
    };
}

/**
 * Fold one series row.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {ShowSummary} the folded row
 * @internal
 */
func showSummaryFrom(v as json.Value, ptr as string) {
    return ShowSummary{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        originalName: nodeString($v, $ptr + "/original_name"),
        overview: nodeString($v, $ptr + "/overview"),
        posterPath: nodeString($v, $ptr + "/poster_path"),
        backdropPath: nodeString($v, $ptr + "/backdrop_path"),
        firstAirDate: nodeString($v, $ptr + "/first_air_date"),
        genreIds: nodeIntList($v, $ptr + "/genre_ids"),
        originalLanguage: nodeString($v, $ptr + "/original_language"),
        originCountry: nodeStringList($v, $ptr + "/origin_country"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count"),
        adult: nodeBool($v, $ptr + "/adult")
    };
}

/**
 * Fold one person row, `known_for` included.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {PersonSummary} the folded row
 * @internal
 */
func personSummaryFrom(v as json.Value, ptr as string) {
    return PersonSummary{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        originalName: nodeString($v, $ptr + "/original_name"),
        profilePath: nodeString($v, $ptr + "/profile_path"),
        knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
        gender: nodeInt($v, $ptr + "/gender"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        adult: nodeBool($v, $ptr + "/adult"),
        knownFor: mediaItemsFrom($v, $ptr + "/known_for", MediaKind.Unknown)
    };
}

/**
 * Fold one mixed row, normalizing the title and date pairs.
 *
 * `fallback` names the row when it has no `media_type`: single-kind
 * endpoints (a collection's parts, a favourites page) omit it.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {MediaItem} the folded row
 * @internal
 */
func mediaItemFrom(v as json.Value, ptr as string, fallback as MediaKind) {
    def kind as MediaKind init $fallback;
    def named as string init nodeString($v, $ptr + "/media_type");
    if ($named != "") {
        $kind = parseMediaKind($named);
    }
    return MediaItem{
        kind: $kind,
        id: nodeInt($v, $ptr + "/id"),
        title: firstText($v, $ptr, ["/title", "/name"]),
        originalTitle: firstText($v, $ptr, ["/original_title", "/original_name"]),
        overview: nodeString($v, $ptr + "/overview"),
        posterPath: nodeString($v, $ptr + "/poster_path"),
        backdropPath: nodeString($v, $ptr + "/backdrop_path"),
        profilePath: nodeString($v, $ptr + "/profile_path"),
        releaseDate: firstText($v, $ptr, ["/release_date", "/first_air_date", "/air_date"]),
        genreIds: nodeIntList($v, $ptr + "/genre_ids"),
        originalLanguage: nodeString($v, $ptr + "/original_language"),
        originCountry: nodeStringList($v, $ptr + "/origin_country"),
        knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count"),
        adult: nodeBool($v, $ptr + "/adult"),
        video: nodeBool($v, $ptr + "/video")
    };
}

/**
 * Fold a list of mixed rows.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {list of MediaItem} the folded rows
 * @internal
 */
func mediaItemsFrom(v as json.Value, ptr as string, fallback as MediaKind) {
    def out as list of MediaItem init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = mediaItemFrom($v, itemPointer($ptr, $i), $fallback);
    }
    return $out;
}

/**
 * The first of several fields that is not empty.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @param fields {list of string} pointer suffixes to try, in order
 * @return {string} the first non-empty value, or ""
 * @internal
 */
func firstText(v as json.Value, ptr as string, fields as list of string) {
    for (def field in $fields) {
        def value as string init nodeString($v, $ptr + $field);
        if ($value != "") {
            return $value;
        }
    }
    return "";
}

/**
 * Fold a paginated envelope of movie rows.
 *
 * @param v {json.Value} the reply
 * @return {MoviePage} the folded page
 * @internal
 */
func moviePageFrom(v as json.Value) {
    def rows as list of MovieSummary init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = movieSummaryFrom($v, itemPointer("/results", $i));
    }
    return MoviePage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold a paginated envelope of series rows.
 *
 * @param v {json.Value} the reply
 * @return {ShowPage} the folded page
 * @internal
 */
func showPageFrom(v as json.Value) {
    def rows as list of ShowSummary init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = showSummaryFrom($v, itemPointer("/results", $i));
    }
    return ShowPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold a paginated envelope of person rows.
 *
 * @param v {json.Value} the reply
 * @return {PersonPage} the folded page
 * @internal
 */
func personPageFrom(v as json.Value) {
    def rows as list of PersonSummary init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = personSummaryFrom($v, itemPointer("/results", $i));
    }
    return PersonPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold a paginated envelope of mixed rows.
 *
 * @param v {json.Value} the reply
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {MediaPage} the folded page
 * @internal
 */
func mediaPageFrom(v as json.Value, fallback as MediaKind) {
    return MediaPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: mediaItemsFrom($v, "/results", $fallback)
    };
}

/**
 * Fold one image object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Image} the folded image
 * @internal
 */
func imageFrom(v as json.Value, ptr as string) {
    return Image{
        filePath: nodeString($v, $ptr + "/file_path"),
        aspectRatio: nodeFloat($v, $ptr + "/aspect_ratio"),
        width: nodeInt($v, $ptr + "/width"),
        height: nodeInt($v, $ptr + "/height"),
        language: nodeString($v, $ptr + "/iso_639_1"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count")
    };
}

/**
 * Fold a list of image objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Image} the folded images
 * @internal
 */
func imageListFrom(v as json.Value, ptr as string) {
    def out as list of Image init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = imageFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold an images reply, whichever buckets it carried.
 *
 * @param v {json.Value} the reply
 * @return {Images} the folded images
 * @internal
 */
func imagesFrom(v as json.Value) {
    return Images{
        id: nodeInt($v, "/id"),
        backdrops: imageListFrom($v, "/backdrops"),
        posters: imageListFrom($v, "/posters"),
        logos: imageListFrom($v, "/logos"),
        stills: imageListFrom($v, "/stills"),
        profiles: imageListFrom($v, "/profiles")
    };
}

/**
 * Fold one video object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Video} the folded video
 * @internal
 */
func videoFrom(v as json.Value, ptr as string) {
    return Video{
        id: nodeString($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        key: nodeString($v, $ptr + "/key"),
        site: nodeString($v, $ptr + "/site"),
        size: nodeInt($v, $ptr + "/size"),
        kind: nodeString($v, $ptr + "/type"),
        language: nodeString($v, $ptr + "/iso_639_1"),
        region: nodeString($v, $ptr + "/iso_3166_1"),
        official: nodeBool($v, $ptr + "/official"),
        publishedAt: nodeString($v, $ptr + "/published_at")
    };
}

/**
 * Fold a videos reply.
 *
 * @param v {json.Value} the reply
 * @return {list of Video} the folded videos
 * @internal
 */
func videosFrom(v as json.Value) {
    def out as list of Video init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $out[] = videoFrom($v, itemPointer("/results", $i));
    }
    return $out;
}

/**
 * Fold one cast row.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {CastMember} the folded row
 * @internal
 */
func castMemberFrom(v as json.Value, ptr as string) {
    return CastMember{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        originalName: nodeString($v, $ptr + "/original_name"),
        character: nodeString($v, $ptr + "/character"),
        creditId: nodeString($v, $ptr + "/credit_id"),
        order: nodeInt($v, $ptr + "/order"),
        castId: nodeInt($v, $ptr + "/cast_id"),
        gender: nodeInt($v, $ptr + "/gender"),
        knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        profilePath: nodeString($v, $ptr + "/profile_path"),
        adult: nodeBool($v, $ptr + "/adult")
    };
}

/**
 * Fold a list of cast rows.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of CastMember} the folded rows
 * @internal
 */
func castFrom(v as json.Value, ptr as string) {
    def out as list of CastMember init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = castMemberFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one crew row.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @return {CrewMember} the folded row
 * @internal
 */
func crewMemberFrom(v as json.Value, ptr as string) {
    return CrewMember{
        id: nodeInt($v, $ptr + "/id"),
        name: nodeString($v, $ptr + "/name"),
        originalName: nodeString($v, $ptr + "/original_name"),
        job: nodeString($v, $ptr + "/job"),
        department: nodeString($v, $ptr + "/department"),
        creditId: nodeString($v, $ptr + "/credit_id"),
        gender: nodeInt($v, $ptr + "/gender"),
        knownForDepartment: nodeString($v, $ptr + "/known_for_department"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        profilePath: nodeString($v, $ptr + "/profile_path"),
        adult: nodeBool($v, $ptr + "/adult")
    };
}

/**
 * Fold a list of crew rows.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of CrewMember} the folded rows
 * @internal
 */
func crewFrom(v as json.Value, ptr as string) {
    def out as list of CrewMember init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = crewMemberFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold a credits reply.
 *
 * @param v {json.Value} the reply
 * @return {Credits} the folded credits
 * @internal
 */
func creditsFrom(v as json.Value) {
    return Credits{
        id: nodeInt($v, "/id"),
        cast: castFrom($v, "/cast"),
        crew: crewFrom($v, "/crew")
    };
}

/**
 * Fold an external-ids reply.
 *
 * @param v {json.Value} the reply
 * @return {ExternalIds} the folded ids
 * @internal
 */
func externalIdsFrom(v as json.Value) {
    return ExternalIds{
        imdbId: nodeString($v, "/imdb_id"),
        tvdbId: nodeInt($v, "/tvdb_id"),
        tvrageId: nodeInt($v, "/tvrage_id"),
        wikidataId: nodeString($v, "/wikidata_id"),
        facebookId: nodeString($v, "/facebook_id"),
        instagramId: nodeString($v, "/instagram_id"),
        twitterId: nodeString($v, "/twitter_id"),
        tiktokId: nodeString($v, "/tiktok_id"),
        youtubeId: nodeString($v, "/youtube_id"),
        freebaseId: nodeString($v, "/freebase_id"),
        freebaseMid: nodeString($v, "/freebase_mid")
    };
}

/**
 * Fold one keyword object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Keyword} the folded keyword
 * @internal
 */
func keywordFrom(v as json.Value, ptr as string) {
    return Keyword{id: nodeInt($v, $ptr + "/id"), name: nodeString($v, $ptr + "/name")};
}

/**
 * Fold a list of keyword objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of Keyword} the folded keywords
 * @internal
 */
func keywordsFrom(v as json.Value, ptr as string) {
    def out as list of Keyword init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = keywordFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one review object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Review} the folded review
 * @internal
 */
func reviewFrom(v as json.Value, ptr as string) {
    return Review{
        id: nodeString($v, $ptr + "/id"),
        author: nodeString($v, $ptr + "/author"),
        username: nodeString($v, $ptr + "/author_details/username"),
        name: nodeString($v, $ptr + "/author_details/name"),
        avatarPath: nodeString($v, $ptr + "/author_details/avatar_path"),
        rating: nodeFloat($v, $ptr + "/author_details/rating"),
        content: nodeString($v, $ptr + "/content"),
        url: nodeString($v, $ptr + "/url"),
        createdAt: nodeString($v, $ptr + "/created_at"),
        updatedAt: nodeString($v, $ptr + "/updated_at"),
        language: nodeString($v, $ptr + "/iso_639_1"),
        mediaId: nodeInt($v, $ptr + "/media_id"),
        mediaTitle: nodeString($v, $ptr + "/media_title"),
        mediaKind: parseMediaKind(nodeString($v, $ptr + "/media_type"))
    };
}

/**
 * Fold a paginated envelope of reviews.
 *
 * @param v {json.Value} the reply
 * @return {ReviewPage} the folded page
 * @internal
 */
func reviewPageFrom(v as json.Value) {
    def rows as list of Review init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = reviewFrom($v, itemPointer("/results", $i));
    }
    return ReviewPage{
        id: nodeInt($v, "/id"),
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold one watch-provider object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {WatchProvider} the folded provider
 * @internal
 */
func watchProviderFrom(v as json.Value, ptr as string) {
    return WatchProvider{
        providerId: nodeInt($v, $ptr + "/provider_id"),
        providerName: nodeString($v, $ptr + "/provider_name"),
        logoPath: nodeString($v, $ptr + "/logo_path"),
        displayPriority: nodeInt($v, $ptr + "/display_priority")
    };
}

/**
 * Fold a list of watch-provider objects.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @return {list of WatchProvider} the folded providers
 * @internal
 */
func watchProvidersFrom(v as json.Value, ptr as string) {
    def out as list of WatchProvider init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = watchProviderFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold one country's block of watch offers.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the country's object
 * @param region {string} the country code the block was filed under
 * @return {WatchOffers} the folded offers
 * @internal
 */
func watchOffersFrom(v as json.Value, ptr as string, region as string) {
    return WatchOffers{
        region: $region,
        link: nodeString($v, $ptr + "/link"),
        flatrate: watchProvidersFrom($v, $ptr + "/flatrate"),
        rent: watchProvidersFrom($v, $ptr + "/rent"),
        buy: watchProvidersFrom($v, $ptr + "/buy"),
        ads: watchProvidersFrom($v, $ptr + "/ads"),
        free: watchProvidersFrom($v, $ptr + "/free")
    };
}

/**
 * Fold one translation object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {Translation} the folded translation
 * @internal
 */
func translationFrom(v as json.Value, ptr as string) {
    return Translation{
        region: nodeString($v, $ptr + "/iso_3166_1"),
        language: nodeString($v, $ptr + "/iso_639_1"),
        name: nodeString($v, $ptr + "/name"),
        englishName: nodeString($v, $ptr + "/english_name"),
        title: firstText($v, $ptr + "/data", ["/title", "/name"]),
        overview: nodeString($v, $ptr + "/data/overview"),
        tagline: nodeString($v, $ptr + "/data/tagline"),
        homepage: nodeString($v, $ptr + "/data/homepage")
    };
}

/**
 * Fold a translations reply.
 *
 * @param v {json.Value} the reply
 * @return {list of Translation} the folded translations
 * @internal
 */
func translationsFrom(v as json.Value) {
    def out as list of Translation init [];
    for (def i in 0..nodeLength($v, "/translations")) {
        $out[] = translationFrom($v, itemPointer("/translations", $i));
    }
    return $out;
}

/**
 * Fold one alternative-title object.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the object
 * @return {AlternativeTitle} the folded title
 * @internal
 */
func alternativeTitleFrom(v as json.Value, ptr as string) {
    return AlternativeTitle{
        region: nodeString($v, $ptr + "/iso_3166_1"),
        title: firstText($v, $ptr, ["/title", "/name"]),
        kind: nodeString($v, $ptr + "/type")
    };
}

/**
 * Fold an alternative-titles reply.
 *
 * Films file the titles under `titles`, series under `results`.
 *
 * @param v {json.Value} the reply
 * @return {list of AlternativeTitle} the folded titles
 * @internal
 */
func alternativeTitlesFrom(v as json.Value) {
    def ptr as string init "/titles";
    if (nodeLength($v, $ptr) == 0) {
        $ptr = "/results";
    }
    def out as list of AlternativeTitle init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = alternativeTitleFrom($v, itemPointer($ptr, $i));
    }
    return $out;
}

/**
 * Fold a write reply.
 *
 * @param v {json.Value} the reply
 * @return {StatusResponse} the folded status
 * @internal
 */
func statusFrom(v as json.Value) {
    return StatusResponse{
        success: nodeBool($v, "/success"),
        statusCode: nodeInt($v, "/status_code"),
        statusMessage: nodeString($v, "/status_message"),
        id: nodeInt($v, "/id")
    };
}
