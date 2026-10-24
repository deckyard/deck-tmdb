# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the smaller catalogues: collections, companies, networks,
# keywords, reviews, single credits, and the external-id lookup.
# Spliced into tmdb.j via include - not a standalone module.
#
# Each of these has its own id space: network 49 and company 49 are
# different records.

/**
 * `find` source: an IMDb id, `tt0076759` for a title, `nm0000158` for a person.
 */
export def const SOURCE_IMDB as string init "imdb_id";

/**
 * `find` source: a TheTVDB id. Series and episodes only.
 */
export def const SOURCE_TVDB as string init "tvdb_id";

/**
 * `find` source: a Wikidata entity id, e.g. `Q17738`.
 */
export def const SOURCE_WIKIDATA as string init "wikidata_id";

/**
 * `find` source: a Facebook page or username.
 */
export def const SOURCE_FACEBOOK as string init "facebook_id";

/**
 * `find` source: an Instagram handle, without the `@`.
 */
export def const SOURCE_INSTAGRAM as string init "instagram_id";

/**
 * `find` source: an X / Twitter handle, without the `@`.
 */
export def const SOURCE_TWITTER as string init "twitter_id";

/**
 * `find` source: a TikTok handle. People only.
 */
export def const SOURCE_TIKTOK as string init "tiktok_id";

/**
 * `find` source: a YouTube channel id. People only.
 */
export def const SOURCE_YOUTUBE as string init "youtube_id";

/**
 * Every external source `find` accepts.
 *
 * The retired Freebase and TVRage sources are still in TMDB's list, so
 * they are accepted too.
 *
 * @internal
 */
def const FIND_SOURCES as list of string init [
    SOURCE_IMDB,
    SOURCE_TVDB,
    SOURCE_WIKIDATA,
    SOURCE_FACEBOOK,
    SOURCE_INSTAGRAM,
    SOURCE_TWITTER,
    SOURCE_TIKTOK,
    SOURCE_YOUTUBE,
    "freebase_mid",
    "freebase_id",
    "tvrage_id"
];

/**
 * A collection's row in a search result, without its films.
 *
 * @field id {int} the collection id
 * @field name {string} the collection name, e.g. "Star Wars Collection"
 * @field originalName {string} the name in its original language
 * @field overview {string} a description, often ""
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field originalLanguage {string} an ISO 639-1 code
 * @field adult {bool} whether the collection is adult
 */
export def struct CollectionSummary {
    id as int,
    name as string,
    originalName as string,
    overview as string,
    posterPath as string,
    backdropPath as string,
    originalLanguage as string,
    adult as bool
};

/**
 * A collection and the films in it.
 *
 * `parts` is in TMDB's order, which is release order, not story order:
 * the Star Wars collection starts at Episode IV.
 *
 * @field id {int} the collection id
 * @field name {string} the collection name
 * @field originalName {string} the name in its original language
 * @field overview {string} a description, often ""
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field originalLanguage {string} an ISO 639-1 code
 * @field parts {list of MediaItem} the films, in release order
 */
export def struct Collection {
    id as int,
    name as string,
    originalName as string,
    overview as string,
    posterPath as string,
    backdropPath as string,
    originalLanguage as string,
    parts as list of MediaItem
};

/**
 * One page of collections.
 *
 * @field page {int} which page this is, 1-based
 * @field totalPages {int} how many pages the query has
 * @field totalResults {int} how many collections the query has
 * @field results {list of CollectionSummary} this page's rows
 */
export def struct CollectionPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of CollectionSummary
};

/**
 * One page of companies.
 *
 * @field page {int} which page this is, 1-based
 * @field totalPages {int} how many pages the query has
 * @field totalResults {int} how many companies the query has
 * @field results {list of Company} this page's rows
 */
export def struct CompanyPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of Company
};

/**
 * One page of keywords.
 *
 * @field page {int} which page this is, 1-based
 * @field totalPages {int} how many pages the query has
 * @field totalResults {int} how many keywords the query has
 * @field results {list of Keyword} this page's rows
 */
export def struct KeywordPage {
    page as int,
    totalPages as int,
    totalResults as int,
    results as list of Keyword
};

/**
 * A production company's full record, including its parent company.
 *
 * Follow `parentCompanyId` to walk a corporate tree (Marvel Studios'
 * parent is Disney).
 *
 * @field id {int} the company id
 * @field name {string} the company name
 * @field description {string} a description, usually ""
 * @field headquarters {string} the head office, free text
 * @field homepage {string} the official site, "" when there is none
 * @field logoPath {string} an image path for `logoUrl`
 * @field originCountry {string} a two-letter country code
 * @field parentCompanyId {int} the owning company, 0 when independent
 * @field parentCompanyName {string} that company's name, "" when independent
 */
export def struct CompanyDetails {
    id as int,
    name as string,
    description as string,
    headquarters as string,
    homepage as string,
    logoPath as string,
    originCountry as string,
    parentCompanyId as int,
    parentCompanyName as string
};

/**
 * A television network's full record.
 *
 * @field id {int} the network id
 * @field name {string} the network name
 * @field headquarters {string} the head office, free text
 * @field homepage {string} the official site, "" when there is none
 * @field logoPath {string} an image path for `logoUrl`
 * @field originCountry {string} a two-letter country code
 */
export def struct NetworkDetails {
    id as int,
    name as string,
    headquarters as string,
    homepage as string,
    logoPath as string,
    originCountry as string
};

/**
 * One credit by id: the person, the title and the role connecting them.
 *
 * Every cast and crew row carries the `creditId` this resolves.
 *
 * @field id {string} the credit id
 * @field creditKind {string} "cast" or "crew"
 * @field department {string} the department, on a crew credit
 * @field job {string} the job, on a crew credit
 * @field character {string} the part, on a cast credit
 * @field media {MediaItem} the title the credit is on
 * @field person {PersonSummary} the person credited
 */
export def struct CreditDetail {
    id as string,
    creditKind as string,
    department as string,
    job as string,
    character as string,
    media as MediaItem,
    person as PersonSummary
};

/**
 * What an external id resolved to, one list per kind.
 *
 * Normally one list is non-empty: an IMDb `tt` id finds a film or a
 * series, an `nm` id a person.
 *
 * @field movies {list of MediaItem} films that matched
 * @field shows {list of MediaItem} series that matched
 * @field people {list of MediaItem} people that matched
 * @field episodes {list of MediaItem} episodes that matched
 * @field seasons {list of MediaItem} seasons that matched
 */
export def struct FindResults {
    movies as list of MediaItem,
    shows as list of MediaItem,
    people as list of MediaItem,
    episodes as list of MediaItem,
    seasons as list of MediaItem
};

/**
 * A collection and the films in it.
 *
 * @param c {Client} an API client
 * @param collectionId {int} the collection id
 * @return {Collection} the collection and its parts
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown collection, or
 *                 a transport failure
 */
export func collection(c as Client, collectionId as int) {
    return collectionFrom(apiGet($c, collectionPath($collectionId, ""), localeParams($c)));
}

/**
 * A collection's posters and backdrops, in every language.
 *
 * @param c {Client} an API client
 * @param collectionId {int} the collection id
 * @return {Images} the posters and backdrops
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func collectionImages(c as Client, collectionId as int) {
    return imagesFrom(apiGet($c, collectionPath($collectionId, "/images"), {}));
}

/**
 * Every translation of a collection's name and overview.
 *
 * @param c {Client} an API client
 * @param collectionId {int} the collection id
 * @return {list of Translation} every translation TMDB holds
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func collectionTranslations(c as Client, collectionId as int) {
    return translationsFrom(apiGet($c, collectionPath($collectionId, "/translations"), {}));
}

/**
 * A production company's full record.
 *
 * @param c {Client} an API client
 * @param companyId {int} the company id
 * @return {CompanyDetails} the company
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown company, or a
 *                 transport failure
 */
export func company(c as Client, companyId as int) {
    return companyDetailsFrom(apiGet($c, companyPath($companyId, ""), {}));
}

/**
 * The other names a company trades under.
 *
 * @param c {Client} an API client
 * @param companyId {int} the company id
 * @return {list of string} the alternative names
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func companyAlternativeNames(c as Client, companyId as int) {
    return nodeFieldList(
        apiGet($c, companyPath($companyId, "/alternative_names"), {}),
        "/results",
        "name");
}

/**
 * A company's logos.
 *
 * @param c {Client} an API client
 * @param companyId {int} the company id
 * @return {Images} the logos, in `Images.logos`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func companyImages(c as Client, companyId as int) {
    return imagesFrom(apiGet($c, companyPath($companyId, "/images"), {}));
}

/**
 * A television network's full record.
 *
 * @param c {Client} an API client
 * @param networkId {int} the network id
 * @return {NetworkDetails} the network
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown network, or a
 *                 transport failure
 */
export func network(c as Client, networkId as int) {
    return networkDetailsFrom(apiGet($c, networkPath($networkId, ""), {}));
}

/**
 * The other names a network broadcasts under.
 *
 * @param c {Client} an API client
 * @param networkId {int} the network id
 * @return {list of string} the alternative names
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func networkAlternativeNames(c as Client, networkId as int) {
    return nodeFieldList(
        apiGet($c, networkPath($networkId, "/alternative_names"), {}),
        "/results",
        "name");
}

/**
 * A network's logos.
 *
 * @param c {Client} an API client
 * @param networkId {int} the network id
 * @return {Images} the logos, in `Images.logos`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func networkImages(c as Client, networkId as int) {
    return imagesFrom(apiGet($c, networkPath($networkId, "/images"), {}));
}

/**
 * A keyword by id.
 *
 * @param c {Client} an API client
 * @param keywordId {int} the keyword id
 * @return {Keyword} the keyword
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown keyword, or a
 *                 transport failure
 */
export func keyword(c as Client, keywordId as int) {
    return keywordFrom(apiGet($c, keywordPath($keywordId, ""), {}), "");
}

/**
 * One page of films tagged with a keyword.
 *
 * `discoverMovies` with `withKeywords` does the same and combines with
 * other filters. Honours the client's adult setting.
 *
 * @param c {Client} an API client
 * @param keywordId {int} the keyword id
 * @param page {int} the page to fetch, 1-based
 * @return {MoviePage} the films carrying that keyword
 * @throws {Error} kind "tmdb" on a non-positive id, a bad page, or a
 *                 transport failure
 */
export func keywordMovies(c as Client, keywordId as int, page as int) {
    def params as map of string to string init pageParams($c, $page);
    $params["include_adult"] = boolParam($c.includeAdult);
    return moviePageFrom(apiGet($c, keywordPath($keywordId, "/movies"), $params));
}

/**
 * One review by id.
 *
 * Unlike a row from a `*Reviews` page, it has `mediaId`, `mediaTitle` and
 * `mediaKind` filled in.
 *
 * @param c {Client} an API client
 * @param reviewId {string} the review id
 * @return {Review} the review
 * @throws {Error} kind "tmdb" on a blank or unknown id, or a transport failure
 */
export func review(c as Client, reviewId as string) {
    def id as string init ensureToken($reviewId, "review id");
    return reviewFrom(apiGet($c, "/3/review/" + $id, {}), "");
}

/**
 * One credit by id, from a cast or crew row's `creditId`.
 *
 * @param c {Client} an API client
 * @param creditId {string} the credit id, from a cast or crew row
 * @return {CreditDetail} the person, the title, and the connection
 * @throws {Error} kind "tmdb" on a blank or unknown id, or a transport failure
 */
export func credit(c as Client, creditId as string) {
    def id as string init ensureToken($creditId, "credit id");
    return creditDetailFrom(apiGet($c, "/3/credit/" + $id, localeParams($c)));
}

/**
 * Look up TMDB records by an id on another site (IMDb, TheTVDB, Wikidata ...).
 *
 * The source is a `SOURCE_*` constant, matched case-insensitively.
 *
 * @param c {Client} an API client
 * @param externalId {string} the id on the other site
 * @param source {string} a `SOURCE_*` constant naming which site
 * @return {FindResults} what matched, split by kind
 * @throws {Error} kind "tmdb" on a blank id, an unknown source, or a
 *                 transport failure
 */
export func find(c as Client, externalId as string, source as string) {
    def id as string init ensureToken($externalId, "external id");
    def named as string init strings.lower(ensureText($source, "external source"));
    if (not lists.contains(FIND_SOURCES, $named)) {
        raiseError("\"" + $source + "\" is not an external source - use one of the " +
            "SOURCE_* constants");
    }
    def params as map of string to string init localeParams($c);
    $params["external_source"] = $named;
    return findResultsFrom(apiGet($c, "/3/find/" + $id, $params));
}

/**
 * `find` with `SOURCE_IMDB`.
 *
 * @param c {Client} an API client
 * @param imdbId {string} an IMDb id, e.g. "tt0076759" or "nm0000158"
 * @return {FindResults} what matched, split by kind
 * @throws {Error} kind "tmdb" on a blank id or a transport failure
 * @example
 *   def hits as tmdb.FindResults init tmdb.findByImdb($c, "tt0903747");
 *   io.printf("%s\n", $hits.shows[0].title);   # Breaking Bad
 */
export func findByImdb(c as Client, imdbId as string) {
    return find($c, $imdbId, SOURCE_IMDB);
}

/**
 * The path of a collection's record or one of its sub-resources.
 *
 * @param collectionId {int} the collection id
 * @param suffix {string} the sub-resource; "" for the collection
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func collectionPath(collectionId as int, suffix as string) {
    return "/3/collection/" + convert.toString(ensureId($collectionId, "collection")) + $suffix;
}

/**
 * The path of a company's record or one of its sub-resources.
 *
 * @param companyId {int} the company id
 * @param suffix {string} the sub-resource; "" for the company
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func companyPath(companyId as int, suffix as string) {
    return "/3/company/" + convert.toString(ensureId($companyId, "company")) + $suffix;
}

/**
 * The path of a network's record or one of its sub-resources.
 *
 * @param networkId {int} the network id
 * @param suffix {string} the sub-resource; "" for the network
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func networkPath(networkId as int, suffix as string) {
    return "/3/network/" + convert.toString(ensureId($networkId, "network")) + $suffix;
}

/**
 * The path of a keyword's record or one of its sub-resources.
 *
 * @param keywordId {int} the keyword id
 * @param suffix {string} the sub-resource; "" for the keyword
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func keywordPath(keywordId as int, suffix as string) {
    return "/3/keyword/" + convert.toString(ensureId($keywordId, "keyword")) + $suffix;
}

/**
 * Refuse a string id that is unsafe to splice into a path.
 *
 * Review, credit and external ids go into the URL verbatim, so no
 * slashes, `..`, `?`, `#` or whitespace.
 *
 * @param value {string} the candidate id
 * @param what {string} what it identifies, for the message
 * @return {string} the trimmed id
 * @throws {Error} kind "tmdb" when the id is blank or carries a path character
 * @internal
 */
func ensureToken(value as string, what as string) {
    def id as string init ensureText($value, $what);
    for (def bad in ["/", "..", "?", "#", " ", "\t", "\n", "\r"]) {
        if (strings.contains($id, $bad)) {
            raiseError("the " + $what + " must not contain \"" + $bad + "\", got \"" +
                $id + "\"");
        }
    }
    return $id;
}

/**
 * Fold a collection record.
 *
 * @param v {json.Value} the reply
 * @return {Collection} the folded collection
 * @internal
 */
func collectionFrom(v as json.Value) {
    return Collection{
        id: nodeInt($v, "/id"),
        name: nodeString($v, "/name"),
        originalName: nodeString($v, "/original_name"),
        overview: nodeString($v, "/overview"),
        posterPath: nodeString($v, "/poster_path"),
        backdropPath: nodeString($v, "/backdrop_path"),
        originalLanguage: nodeString($v, "/original_language"),
        parts: mediaItemsFrom($v, "/parts", MediaKind.Movie)
    };
}

/**
 * Fold a company record.
 *
 * @param v {json.Value} the reply
 * @return {CompanyDetails} the folded company
 * @internal
 */
func companyDetailsFrom(v as json.Value) {
    return CompanyDetails{
        id: nodeInt($v, "/id"),
        name: nodeString($v, "/name"),
        description: nodeString($v, "/description"),
        headquarters: nodeString($v, "/headquarters"),
        homepage: nodeString($v, "/homepage"),
        logoPath: nodeString($v, "/logo_path"),
        originCountry: nodeString($v, "/origin_country"),
        parentCompanyId: nodeInt($v, "/parent_company/id"),
        parentCompanyName: nodeString($v, "/parent_company/name")
    };
}

/**
 * Fold a network record.
 *
 * @param v {json.Value} the reply
 * @return {NetworkDetails} the folded network
 * @internal
 */
func networkDetailsFrom(v as json.Value) {
    return NetworkDetails{
        id: nodeInt($v, "/id"),
        name: nodeString($v, "/name"),
        headquarters: nodeString($v, "/headquarters"),
        homepage: nodeString($v, "/homepage"),
        logoPath: nodeString($v, "/logo_path"),
        originCountry: nodeString($v, "/origin_country")
    };
}

/**
 * Fold a single-credit record.
 *
 * @param v {json.Value} the reply
 * @return {CreditDetail} the folded credit
 * @internal
 */
func creditDetailFrom(v as json.Value) {
    return CreditDetail{
        id: nodeString($v, "/id"),
        creditKind: nodeString($v, "/credit_type"),
        department: nodeString($v, "/department"),
        job: nodeString($v, "/job"),
        character: nodeString($v, "/media/character"),
        media: mediaItemFrom($v, "/media", parseMediaKind(nodeString($v, "/media_type"))),
        person: personSummaryFrom($v, "/person")
    };
}

/**
 * Fold a find reply.
 *
 * @param v {json.Value} the reply
 * @return {FindResults} the folded results, split by kind
 * @internal
 */
func findResultsFrom(v as json.Value) {
    return FindResults{
        movies: mediaItemsFrom($v, "/movie_results", MediaKind.Movie),
        shows: mediaItemsFrom($v, "/tv_results", MediaKind.Show),
        people: mediaItemsFrom($v, "/person_results", MediaKind.Person),
        episodes: mediaItemsFrom($v, "/tv_episode_results", MediaKind.Episode),
        seasons: mediaItemsFrom($v, "/tv_season_results", MediaKind.Season)
    };
}

/**
 * Fold a paginated envelope of collection rows.
 *
 * @param v {json.Value} the reply
 * @return {CollectionPage} the folded page
 * @internal
 */
func collectionPageFrom(v as json.Value) {
    def rows as list of CollectionSummary init [];
    for (def i in 0..nodeLength($v, "/results")) {
        def ptr as string init itemPointer("/results", $i);
        $rows[] = CollectionSummary{
            id: nodeInt($v, $ptr + "/id"),
            name: nodeString($v, $ptr + "/name"),
            originalName: nodeString($v, $ptr + "/original_name"),
            overview: nodeString($v, $ptr + "/overview"),
            posterPath: nodeString($v, $ptr + "/poster_path"),
            backdropPath: nodeString($v, $ptr + "/backdrop_path"),
            originalLanguage: nodeString($v, $ptr + "/original_language"),
            adult: nodeBool($v, $ptr + "/adult")
        };
    }
    return CollectionPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold a paginated envelope of company rows.
 *
 * @param v {json.Value} the reply
 * @return {CompanyPage} the folded page
 * @internal
 */
func companyPageFrom(v as json.Value) {
    def rows as list of Company init [];
    for (def i in 0..nodeLength($v, "/results")) {
        $rows[] = companyFrom($v, itemPointer("/results", $i));
    }
    return CompanyPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: $rows
    };
}

/**
 * Fold a paginated envelope of keyword rows.
 *
 * @param v {json.Value} the reply
 * @return {KeywordPage} the folded page
 * @internal
 */
func keywordPageFrom(v as json.Value) {
    return KeywordPage{
        page: nodeInt($v, "/page"),
        totalPages: nodeInt($v, "/total_pages"),
        totalResults: nodeInt($v, "/total_results"),
        results: keywordsFrom($v, "/results")
    };
}
