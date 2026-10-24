# SPDX-License-Identifier: LGPL-3.0-only
# SPDX-FileCopyrightText: Copyright (C) 2026 mplx <mplx@jennifer-lang.dev>
# pragma-jennifer-version: >=0.25.0

# tmdb - the /configuration endpoints and turning an image path into a URL.
# Spliced into tmdb.j via include - not a standalone module.
#
# TMDB returns an image *path* ("/6FfCtAuVAW.jpg"), never a URL. The caller
# prepends a host and a size, both published under /configuration and
# documented as changeable.

/**
 * The size that asks for the image as uploaded.
 *
 * Every size list ends with it, so it exists for every image kind. On a
 * listing page it can mean a download of several megabytes per row.
 */
export def const SIZE_ORIGINAL as string init "original";

/**
 * The HTTPS image host TMDB has published for years.
 *
 * `defaultConfiguration` uses it so URLs can be built without a request.
 * TMDB documents the host as changeable; long-running programs should use
 * the live `configuration`.
 */
export def const DEFAULT_IMAGE_BASE as string init "https://image.tmdb.org/t/p/";

/**
 * The image hosts, the size lists per image kind, and the change keys.
 *
 * Size lists run smallest to largest and differ per kind: `w342` exists
 * for posters, not for profiles. The per-kind URL builders check against
 * the matching list.
 *
 * @field baseUrl {string} the plain-HTTP image host
 * @field secureBaseUrl {string} the HTTPS image host, preferred
 * @field backdropSizes {list of string} sizes valid for a backdrop
 * @field logoSizes {list of string} sizes valid for a logo
 * @field posterSizes {list of string} sizes valid for a poster
 * @field profileSizes {list of string} sizes valid for a profile photo
 * @field stillSizes {list of string} sizes valid for an episode still
 * @field changeKeys {list of string} the fields the change endpoints report on
 */
export def struct Configuration {
    baseUrl as string,
    secureBaseUrl as string,
    backdropSizes as list of string,
    logoSizes as list of string,
    posterSizes as list of string,
    profileSizes as list of string,
    stillSizes as list of string,
    changeKeys as list of string
};

/**
 * A department and the jobs filed under it.
 *
 * One entry of `/configuration/jobs`: the vocabulary of `CrewMember.job`,
 * grouped by `CrewMember.department`.
 *
 * @field department {string} the department name, e.g. "Camera"
 * @field jobs {list of string} the jobs in it, e.g. "Director of Photography"
 */
export def struct Department {
    department as string,
    jobs as list of string
};

/**
 * A country and the time zones in it.
 *
 * The zone names are what `airingTodayIn` takes as its `timezone` argument.
 *
 * @field code {string} the two-letter ISO 3166-1 code
 * @field zones {list of string} IANA zone names, e.g. "Europe/Berlin"
 */
export def struct TimezoneGroup {
    code as string,
    zones as list of string
};

/**
 * Fetch the image configuration from `/configuration`.
 *
 * It changes rarely and every image URL needs it: fetch it once and keep
 * it rather than asking per image.
 *
 * @param c {Client} an API client
 * @return {Configuration} the image hosts, size lists and change keys
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func configuration(c as Client) {
    return configurationFrom(apiGet($c, "/3/configuration", {}));
}

/**
 * A snapshot of TMDB's published image configuration, built without a request.
 *
 * For a script, a test, or the first paint before the live configuration
 * arrives. Programs that run longer than a session should call
 * `configuration` instead. `changeKeys` is empty.
 *
 * @return {Configuration} the documented defaults
 */
export func defaultConfiguration() {
    return Configuration{
        baseUrl: "http://image.tmdb.org/t/p/",
        secureBaseUrl: DEFAULT_IMAGE_BASE,
        backdropSizes: ["w300", "w780", "w1280", SIZE_ORIGINAL],
        logoSizes: ["w45", "w92", "w154", "w185", "w300", "w500", SIZE_ORIGINAL],
        posterSizes: ["w92", "w154", "w185", "w342", "w500", "w780", SIZE_ORIGINAL],
        profileSizes: ["w45", "w185", "h632", SIZE_ORIGINAL],
        stillSizes: ["w92", "w185", "w300", SIZE_ORIGINAL],
        changeKeys: []
    };
}

/**
 * Build an image URL at any size that appears in any of the configuration's lists.
 *
 * For when the image kind is not known. The per-kind builders
 * (`posterUrl`, `backdropUrl`, ...) check the size against that kind's
 * list only. An empty `path` (TMDB's `null`, "no image") gives "" rather
 * than a URL that would 404. A path is prefixed with `/` if it lacks one.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} an image path from a struct, e.g. `posterPath`
 * @param size {string} a size from the configuration, or `SIZE_ORIGINAL`
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is in no list, or the path holds
 *                 `..`, `//`, `?`, `#`, `:` or a space
 */
export func imageUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, allSizes($cfg), "image");
}

/**
 * Build the URL of a poster.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} a `posterPath` from a struct
 * @param size {string} a size from `cfg.posterSizes`, e.g. "w500"
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is not a poster size or the path is unsafe
 */
export func posterUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, $cfg.posterSizes, "poster");
}

/**
 * Build the URL of a backdrop.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} a `backdropPath` from a struct
 * @param size {string} a size from `cfg.backdropSizes`, e.g. "w1280"
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is not a backdrop size or the path is unsafe
 */
export func backdropUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, $cfg.backdropSizes, "backdrop");
}

/**
 * Build the URL of a person's profile photograph.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} a `profilePath` from a struct
 * @param size {string} a size from `cfg.profileSizes`, e.g. "w185"
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is not a profile size or the path is unsafe
 */
export func profileUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, $cfg.profileSizes, "profile");
}

/**
 * Build the URL of an episode still.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} a `stillPath` from an episode
 * @param size {string} a size from `cfg.stillSizes`, e.g. "w300"
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is not a still size or the path is unsafe
 */
export func stillUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, $cfg.stillSizes, "still");
}

/**
 * Build the URL of a company, network or title logo.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} a `logoPath` from a struct
 * @param size {string} a size from `cfg.logoSizes`, e.g. "w154"
 * @return {string} the HTTPS URL, or "" when `path` is empty
 * @throws {Error} kind "tmdb" when the size is not a logo size or the path is unsafe
 */
export func logoUrl(cfg as Configuration, path as string, size as string) {
    return buildImageUrl($cfg, $path, $size, $cfg.logoSizes, "logo");
}

/**
 * The watch URL of a video on YouTube or Vimeo.
 *
 * TMDB hosts no video: a `Video` is a `site` and a `key`. YouTube and
 * Vimeo are the only sites TMDB uses; the site name is matched in any case.
 *
 * @param video {Video} the video record
 * @return {string} the watch URL, or "" for another site or an empty key
 */
export func videoUrl(video as Video) {
    if ($video.key == "") {
        return "";
    }
    match (strings.lower(strings.trim($video.site))) {
        when "youtube" { return "https://www.youtube.com/watch?v=" + $video.key; }
        when "vimeo" { return "https://vimeo.com/" + $video.key; }
        else { return ""; }
    }
    return "";
}

/**
 * The thumbnail URL of a YouTube video (`hqdefault.jpg`).
 *
 * Vimeo thumbnails need a second API call, so any site but YouTube
 * gives "".
 *
 * @param video {Video} the video record
 * @return {string} the thumbnail URL, or "" when there is none to build
 */
export func videoThumbnailUrl(video as Video) {
    if ($video.key == "" or strings.lower(strings.trim($video.site)) != "youtube") {
        return "";
    }
    return "https://img.youtube.com/vi/" + $video.key + "/hqdefault.jpg";
}

/**
 * The countries TMDB knows, with their English and native names.
 *
 * The values behind every `iso_3166_1` in the API, and the valid values
 * for `withRegion`. Sends the client's language.
 *
 * @param c {Client} an API client
 * @return {list of Country} the countries, in TMDB's order
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func countries(c as Client) {
    return countriesFrom(apiGet($c, "/3/configuration/countries", localeParams($c)), "");
}

/**
 * The languages TMDB knows, with their English names and endonyms.
 *
 * The valid values for the language half of `withLanguage`.
 *
 * @param c {Client} an API client
 * @return {list of Language} the languages, in TMDB's order
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func languages(c as Client) {
    return languagesFrom(apiGet($c, "/3/configuration/languages", {}), "");
}

/**
 * The language-region tags TMDB has translations for, e.g. "de-DE".
 *
 * Narrower than `languages`: these tags return translated text, so they
 * are the ones to offer in a language picker.
 *
 * @param c {Client} an API client
 * @return {list of string} tags like "de-DE", "pt-BR"
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func primaryTranslations(c as Client) {
    return nodeStringList(apiGet($c, "/3/configuration/primary_translations", {}), "");
}

/**
 * The crew jobs TMDB recognizes, grouped by department.
 *
 * @param c {Client} an API client
 * @return {list of Department} the departments and their jobs
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func jobs(c as Client) {
    return departmentsFrom(apiGet($c, "/3/configuration/jobs", {}));
}

/**
 * The time zones TMDB knows, grouped by country.
 *
 * The zone names are what `airingTodayIn` takes to decide which broadcast
 * day "today" is.
 *
 * @param c {Client} an API client
 * @return {list of TimezoneGroup} the countries and their zones
 * @throws {Error} kind "tmdb" on a transport failure or an unhappy status
 */
export func timezones(c as Client) {
    return timezoneGroupsFrom(apiGet($c, "/3/configuration/timezones", {}));
}

/**
 * Fold a jobs reply, whose root is a bare list.
 *
 * @param v {json.Value} the reply
 * @return {list of Department} the folded departments
 * @internal
 */
func departmentsFrom(v as json.Value) {
    def out as list of Department init [];
    for (def i in 0..nodeLength($v, "")) {
        def ptr as string init itemPointer("", $i);
        $out[] = Department{
            department: nodeString($v, $ptr + "/department"),
            jobs: nodeStringList($v, $ptr + "/jobs")
        };
    }
    return $out;
}

/**
 * Fold a timezones reply, whose root is a bare list.
 *
 * @param v {json.Value} the reply
 * @return {list of TimezoneGroup} the folded countries and their zones
 * @internal
 */
func timezoneGroupsFrom(v as json.Value) {
    def out as list of TimezoneGroup init [];
    for (def i in 0..nodeLength($v, "")) {
        def ptr as string init itemPointer("", $i);
        $out[] = TimezoneGroup{
            code: nodeString($v, $ptr + "/iso_3166_1"),
            zones: nodeStringList($v, $ptr + "/zones")
        };
    }
    return $out;
}

/**
 * Fold the configuration reply.
 *
 * @param v {json.Value} the reply
 * @return {Configuration} the folded configuration
 * @internal
 */
func configurationFrom(v as json.Value) {
    return Configuration{
        baseUrl: nodeString($v, "/images/base_url"),
        secureBaseUrl: nodeString($v, "/images/secure_base_url"),
        backdropSizes: nodeStringList($v, "/images/backdrop_sizes"),
        logoSizes: nodeStringList($v, "/images/logo_sizes"),
        posterSizes: nodeStringList($v, "/images/poster_sizes"),
        profileSizes: nodeStringList($v, "/images/profile_sizes"),
        stillSizes: nodeStringList($v, "/images/still_sizes"),
        changeKeys: nodeStringList($v, "/change_keys")
    };
}

/**
 * Build an image URL after checking the size against a list.
 *
 * @param cfg {Configuration} the image configuration
 * @param path {string} the image path
 * @param size {string} the requested size
 * @param allowed {list of string} the sizes valid for this kind
 * @param kind {string} what is being addressed, for the message
 * @return {string} the URL, or "" when the path is empty
 * @throws {Error} kind "tmdb" when the size is not allowed or the path is unsafe
 * @internal
 */
func buildImageUrl(
    cfg as Configuration,
    path as string,
    size as string,
    allowed as list of string,
    kind as string) {
    def file as string init strings.trim($path);
    if ($file == "") {
        return "";
    }
    def wanted as string init ensureText($size, "image size");
    if (not lists.contains($allowed, $wanted)) {
        raiseError("\"" + $wanted + "\" is not a " + $kind + " size - the configuration " +
            "offers " + sizeList($allowed));
    }
    return imageHost($cfg) + $wanted + ensureImagePath($file);
}

/**
 * The image host to build on: `secureBaseUrl`, else `baseUrl`, else
 * `DEFAULT_IMAGE_BASE`.
 *
 * Only a hand-built `Configuration` can lack the secure host.
 *
 * @param cfg {Configuration} the image configuration
 * @return {string} the base URL, always ending in a slash
 * @internal
 */
func imageHost(cfg as Configuration) {
    def base as string init $cfg.secureBaseUrl;
    if ($base == "") {
        $base = $cfg.baseUrl;
    }
    if ($base == "") {
        $base = DEFAULT_IMAGE_BASE;
    }
    if (not strings.endsWith($base, "/")) {
        $base = $base + "/";
    }
    return $base;
}

/**
 * Refuse an image path that would not address an image.
 *
 * The path may come from the caller; one carrying `..` or a scheme would
 * build a URL pointing elsewhere.
 *
 * @param path {string} the trimmed path
 * @return {string} the path, with a leading slash
 * @throws {Error} kind "tmdb" when the path is not a plain file path
 * @internal
 */
func ensureImagePath(path as string) {
    def file as string init $path;
    if (not strings.startsWith($file, "/")) {
        $file = "/" + $file;
    }
    for (def bad in ["..", "//", "?", "#", " ", ":"]) {
        if (strings.contains($file, $bad)) {
            raiseError("\"" + $path + "\" is not an image path - pass the `posterPath` " +
                "(or `backdropPath`, `profilePath`, ...) field of a struct, not a URL");
        }
    }
    return $file;
}

/**
 * Every size the configuration knows, for the general `imageUrl`.
 *
 * @param cfg {Configuration} the image configuration
 * @return {list of string} the union of the five size lists
 * @internal
 */
func allSizes(cfg as Configuration) {
    def out as list of string init [];
    def groups as list of list of string init [
        $cfg.backdropSizes,
        $cfg.logoSizes,
        $cfg.posterSizes,
        $cfg.profileSizes,
        $cfg.stillSizes
    ];
    for (def group in $groups) {
        for (def size in $group) {
            if (not lists.contains($out, $size)) {
                $out[] = $size;
            }
        }
    }
    return $out;
}

/**
 * Render a size list for an error message.
 *
 * @param sizes {list of string} the valid sizes
 * @return {string} the sizes, comma-separated, or a note that there are none
 * @internal
 */
func sizeList(sizes as list of string) {
    if (len($sizes) == 0) {
        return "none for this kind - fetch the configuration first";
    }
    return strings.join($sizes, ", ");
}
