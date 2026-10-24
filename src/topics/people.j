# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the /person endpoints: one person, their filmography, their photos.
# Spliced into tmdb.j via include - not a standalone module.
#
# A person's credits are rows of *titles*, each carrying the role that
# links it to the person: `PersonCredit` is a film or series summary plus
# a character or a job.

/**
 * The sub-resources `personBundle` appends: three of TMDB's limit of 20.
 *
 * @internal
 */
def const PERSON_APPENDICES as list of string init ["combined_credits", "images", "external_ids"];

/**
 * A person's full record, as `/person/{id}` answers it.
 *
 * @field id {int} the person id
 * @field name {string} the name TMDB files them under
 * @field alsoKnownAs {list of string} every alias and transliteration
 * @field biography {string} the biography, in the client's language
 * @field birthday {string} `YYYY-MM-DD`, "" when unknown
 * @field deathday {string} `YYYY-MM-DD`, "" when they are alive or unknown
 * @field placeOfBirth {string} free text, "" when unknown
 * @field gender {int} see `genderName`
 * @field knownForDepartment {string} e.g. "Acting", "Directing"
 * @field homepage {string} the official site, "" when there is none
 * @field imdbId {string} e.g. "nm0000158", "" when not cross-referenced
 * @field profilePath {string} an image path for `profileUrl`
 * @field popularity {float} TMDB's popularity score
 * @field adult {bool} whether the person is filed as adult
 */
export def struct Person {
    id as int,
    name as string,
    alsoKnownAs as list of string,
    biography as string,
    birthday as string,
    deathday as string,
    placeOfBirth as string,
    gender as int,
    knownForDepartment as string,
    homepage as string,
    imdbId as string,
    profilePath as string,
    popularity as float,
    adult as bool
};

/**
 * One title on a person's filmography, with the person's role in it.
 *
 * A cast row fills `character`; a crew row fills `job` and `department`.
 * `episodeCount` is set on series credits only.
 *
 * @field kind {MediaKind} `Movie` or `Show`
 * @field id {int} the title's id, in the id space of `kind`
 * @field title {string} `title` for a film, `name` for a series
 * @field originalTitle {string} the same, in the original language
 * @field character {string} who they played, "" on a crew credit
 * @field job {string} the job they did, "" on a cast credit
 * @field department {string} the department that job sits in
 * @field creditId {string} the credit's own id, for `credit`
 * @field order {int} billing order on a cast credit, 0 when not billed
 * @field episodeCount {int} episodes they appear in, series credits only
 * @field overview {string} the title's synopsis
 * @field releaseDate {string} `release_date` or `first_air_date`
 * @field posterPath {string} an image path for `posterUrl`
 * @field backdropPath {string} an image path for `backdropUrl`
 * @field genreIds {list of int} the title's genre ids
 * @field originalLanguage {string} an ISO 639-1 code
 * @field popularity {float} TMDB's popularity score
 * @field voteAverage {float} the mean user rating, 0 to 10
 * @field voteCount {int} how many ratings that mean is over
 * @field adult {bool} whether the title is adult
 */
export def struct PersonCredit {
    kind as MediaKind,
    id as int,
    title as string,
    originalTitle as string,
    character as string,
    job as string,
    department as string,
    creditId as string,
    order as int,
    episodeCount as int,
    overview as string,
    releaseDate as string,
    posterPath as string,
    backdropPath as string,
    genreIds as list of int,
    originalLanguage as string,
    popularity as float,
    voteAverage as float,
    voteCount as int,
    adult as bool
};

/**
 * A person's filmography, split into cast and crew credits.
 *
 * A title can appear in both halves, and once per job in `crew` (directed
 * and wrote: two rows), as TMDB sends it.
 *
 * @field id {int} the person the credits belong to
 * @field cast {list of PersonCredit} titles they performed in
 * @field crew {list of PersonCredit} titles they worked on
 */
export def struct PersonCredits {
    id as int,
    cast as list of PersonCredit,
    crew as list of PersonCredit
};

/**
 * A person and three sub-resources, fetched in one request by `personBundle`.
 *
 * @field person {Person} the person themselves
 * @field credits {PersonCredits} their whole filmography, films and series
 * @field images {Images} their profile photographs
 * @field externalIds {ExternalIds} their ids and handles elsewhere
 */
export def struct PersonBundle {
    person as Person,
    credits as PersonCredits,
    images as Images,
    externalIds as ExternalIds
};

/**
 * Read a person's record.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {Person} the person
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown person, or a
 *                 transport failure
 * @example
 *   def p as tmdb.Person init tmdb.person($c, 31);
 *   io.printf("%s, born %s in %s\n", $p.name, $p.birthday, $p.placeOfBirth);
 */
export func person(c as Client, personId as int) {
    return personFrom(apiGet($c, personPath($personId, ""), localeParams($c)));
}

/**
 * Read a person and three of their sub-resources in one request.
 *
 * Appends combined credits, images and external ids via
 * `append_to_response`.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {PersonBundle} the person and their sub-resources
 * @throws {Error} kind "tmdb" on a non-positive id, an unknown person, or a
 *                 transport failure
 * @example
 *   def b as tmdb.PersonBundle init tmdb.personBundle($c, 31);
 *   io.printf("%s: %d acting credits\n", $b.person.name, len($b.credits.cast));
 */
export func personBundle(c as Client, personId as int) {
    def params as map of string to string init localeParams($c);
    $params["append_to_response"] = strings.join(PERSON_APPENDICES, ",");
    def reply as json.Value init apiGet($c, personPath($personId, ""), $params);
    return PersonBundle{
        person: personFrom($reply),
        credits: personCreditsFrom(json.get($reply, "/combined_credits"), MediaKind.Unknown),
        images: imagesFrom(json.get($reply, "/images")),
        externalIds: externalIdsFrom(json.get($reply, "/external_ids"))
    };
}

/**
 * Read a person's film credits.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {PersonCredits} their film filmography
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 * @example
 *   for (def role in tmdb.personMovieCredits($c, 31).cast) {
 *       io.printf("%s (%s) - %s\n", $role.title, tmdb.year($role.releaseDate), $role.character);
 *   }
 */
export func personMovieCredits(c as Client, personId as int) {
    return personCreditsFrom(
        apiGet($c, personPath($personId, "/movie_credits"), localeParams($c)),
        MediaKind.Movie);
}

/**
 * Read a person's series credits.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {PersonCredits} their series filmography
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func personShowCredits(c as Client, personId as int) {
    return personCreditsFrom(
        apiGet($c, personPath($personId, "/tv_credits"), localeParams($c)),
        MediaKind.Show);
}

/**
 * Read a person's whole filmography, films and series together.
 *
 * Each row's `kind` says which catalogue it belongs to.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {PersonCredits} every credit TMDB holds for them
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func personCombinedCredits(c as Client, personId as int) {
    return personCreditsFrom(
        apiGet($c, personPath($personId, "/combined_credits"), localeParams($c)),
        MediaKind.Unknown);
}

/**
 * Read a person's profile photographs.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {Images} the profiles, in `Images.profiles`
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func personImages(c as Client, personId as int) {
    return imagesFrom(apiGet($c, personPath($personId, "/images"), {}));
}

/**
 * Read a person's ids and social media handles elsewhere.
 *
 * The social fields (Instagram, TikTok, YouTube) are usually filled only
 * for people.
 *
 * @param c {Client} an API client
 * @param personId {int} the person id
 * @return {ExternalIds} the ids
 * @throws {Error} kind "tmdb" on a non-positive id or a transport failure
 */
export func personExternalIds(c as Client, personId as int) {
    return externalIdsFrom(apiGet($c, personPath($personId, "/external_ids"), {}));
}

/**
 * Read the most popular people.
 *
 * @param c {Client} an API client
 * @param page {int} the page to fetch, 1-based
 * @return {PersonPage} the popular people
 * @throws {Error} kind "tmdb" on a bad page or a transport failure
 */
export func popularPeople(c as Client, page as int) {
    return personPageFrom(apiGet($c, "/3/person/popular", pageParams($c, $page)));
}

/**
 * Read the person most recently added to TMDB.
 *
 * @param c {Client} an API client
 * @return {Person} the newest person record
 * @throws {Error} kind "tmdb" on a transport failure
 */
export func latestPerson(c as Client) {
    return personFrom(apiGet($c, "/3/person/latest", localeParams($c)));
}

/**
 * The crew credits a person has in one department.
 *
 * Matches `department` case-insensitively; cast credits are never
 * returned. `Person.knownForDepartment` names the person's main one.
 *
 * @param credits {PersonCredits} the filmography
 * @param department {string} the department name, e.g. "Directing"
 * @return {list of PersonCredit} the matching crew credits
 * @throws {Error} kind "tmdb" when the department name is blank
 * @example
 *   def directed as list of tmdb.PersonCredit init tmdb.creditsInDepartment(
 *       tmdb.personCombinedCredits($c, 525), "Directing");
 */
export func creditsInDepartment(credits as PersonCredits, department as string) {
    def wanted as string init strings.lower(ensureText($department, "department"));
    def out as list of PersonCredit init [];
    for (def entry in $credits.crew) {
        if (strings.lower($entry.department) == $wanted) {
            $out[] = $entry;
        }
    }
    return $out;
}

/**
 * The path of a person's record or one of their sub-resources.
 *
 * @param personId {int} the person id
 * @param suffix {string} the sub-resource, e.g. "/images"; "" for the person
 * @return {string} the request path
 * @throws {Error} kind "tmdb" when the id is not positive
 * @internal
 */
func personPath(personId as int, suffix as string) {
    return "/3/person/" + convert.toString(ensureId($personId, "person")) + $suffix;
}

/**
 * Fold a person record.
 *
 * @param v {json.Value} the reply, or the root of a bundle
 * @return {Person} the folded person
 * @internal
 */
func personFrom(v as json.Value) {
    return Person{
        id: nodeInt($v, "/id"),
        name: nodeString($v, "/name"),
        alsoKnownAs: nodeStringList($v, "/also_known_as"),
        biography: nodeString($v, "/biography"),
        birthday: nodeString($v, "/birthday"),
        deathday: nodeString($v, "/deathday"),
        placeOfBirth: nodeString($v, "/place_of_birth"),
        gender: nodeInt($v, "/gender"),
        knownForDepartment: nodeString($v, "/known_for_department"),
        homepage: nodeString($v, "/homepage"),
        imdbId: nodeString($v, "/imdb_id"),
        profilePath: nodeString($v, "/profile_path"),
        popularity: nodeFloat($v, "/popularity"),
        adult: nodeBool($v, "/adult")
    };
}

/**
 * Fold a person-credits reply.
 *
 * @param v {json.Value} the reply
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {PersonCredits} the folded filmography
 * @internal
 */
func personCreditsFrom(v as json.Value, fallback as MediaKind) {
    return PersonCredits{
        id: nodeInt($v, "/id"),
        cast: personCreditListFrom($v, "/cast", $fallback),
        crew: personCreditListFrom($v, "/crew", $fallback)
    };
}

/**
 * Fold one half of a person-credits reply.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the list
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {list of PersonCredit} the folded credits
 * @internal
 */
func personCreditListFrom(v as json.Value, ptr as string, fallback as MediaKind) {
    def out as list of PersonCredit init [];
    for (def i in 0..nodeLength($v, $ptr)) {
        $out[] = personCreditFrom($v, itemPointer($ptr, $i), $fallback);
    }
    return $out;
}

/**
 * Fold one filmography row.
 *
 * @param v {json.Value} the document
 * @param ptr {string} a JSON Pointer to the row
 * @param fallback {MediaKind} the kind to assume when `media_type` is absent
 * @return {PersonCredit} the folded row
 * @internal
 */
func personCreditFrom(v as json.Value, ptr as string, fallback as MediaKind) {
    def kind as MediaKind init $fallback;
    def named as string init nodeString($v, $ptr + "/media_type");
    if ($named != "") {
        $kind = parseMediaKind($named);
    }
    return PersonCredit{
        kind: $kind,
        id: nodeInt($v, $ptr + "/id"),
        title: firstText($v, $ptr, ["/title", "/name"]),
        originalTitle: firstText($v, $ptr, ["/original_title", "/original_name"]),
        character: nodeString($v, $ptr + "/character"),
        job: nodeString($v, $ptr + "/job"),
        department: nodeString($v, $ptr + "/department"),
        creditId: nodeString($v, $ptr + "/credit_id"),
        order: nodeInt($v, $ptr + "/order"),
        episodeCount: nodeInt($v, $ptr + "/episode_count"),
        overview: nodeString($v, $ptr + "/overview"),
        releaseDate: firstText($v, $ptr, ["/release_date", "/first_air_date"]),
        posterPath: nodeString($v, $ptr + "/poster_path"),
        backdropPath: nodeString($v, $ptr + "/backdrop_path"),
        genreIds: nodeIntList($v, $ptr + "/genre_ids"),
        originalLanguage: nodeString($v, $ptr + "/original_language"),
        popularity: nodeFloat($v, $ptr + "/popularity"),
        voteAverage: nodeFloat($v, $ptr + "/vote_average"),
        voteCount: nodeInt($v, $ptr + "/vote_count"),
        adult: nodeBool($v, $ptr + "/adult")
    };
}
