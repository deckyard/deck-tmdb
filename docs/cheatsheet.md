# Cheatsheet

Every export, by topic. Call them through the module alias:
`movie(c as Client, movieId as int)` here is `tmdb.movie($c, 550)` in code.
The docblocks in `src/topics/` and the guides give the details.

- Ids must be positive and pages run from 1 to `MAX_PAGE` (500); both are
  checked before the request.
- A `null` or missing field reads as `""`, `0`, `false` or `[]`.
- Every failure is `Error{kind: "tmdb"}`; see [Errors](errors.md).

## Client and plumbing

Building and configuring a client, and the escape hatches for endpoints without a typed verb. Guide: [Installing and importing](getting-started.md).

| constant | value | meaning |
| --- | --- | --- |
| `API_BASE` | `"https://api.themoviedb.org"` | Host both API generations answer on. |
| `APPROVAL_BASE` | `"https://www.themoviedb.org/auth/access"` | Page where a user approves a v4 request token. |
| `DEFAULT_TIMEOUT_MS` | `15000` | Per-request idle timeout of a fresh client, in milliseconds. |
| `DEFAULT_RETRIES` | `2` | Times a fresh client retries a 429 or 5xx before giving up. |
| `DEFAULT_BACKOFF_MS` | `500` | Base delay of a fresh client before a retry, in milliseconds. |
| `MAX_RESPONSE_BYTES` | `16777216` | Largest response body the client reads, in bytes (16 MiB). |
| `DEFAULT_LANGUAGE` | `"en-US"` | The `language` a fresh client sends. |
| `MAX_PAGE` | `500` | Highest page number TMDB serves. |

| function | returns | what it does |
| --- | --- | --- |
| `client(readAccessToken as string)` | `Client` | Build a client around a TMDB API read access token. |
| `clientFromApiKey(apiKey as string)` | `Client` | Build a v3-only client around the legacy API key. |
| `clientFromEnv()` | `Client` | Build a client from the TMDB_* environment variables. |
| `withLanguage(c as Client, language as string)` | `Client` | A copy of the client that asks for another language. |
| `withRegion(c as Client, region as string)` | `Client` | A copy of the client pinned to a release region. |
| `withUserToken(c as Client, userToken as string)` | `Client` | A copy of the client acting for a signed-in user. |
| `withAdult(c as Client, enabled as bool)` | `Client` | A copy of the client that includes or excludes adult titles. |
| `withTimeout(c as Client, timeoutMs as int)` | `Client` | A copy of the client with another per-request idle timeout. |
| `withRetries(c as Client, retries as int)` | `Client` | A copy of the client with another retry budget for a 429 or 5xx. |
| `withBackoff(c as Client, backoffMs as int)` | `Client` | A copy of the client with another base delay between retries. |
| `setVerbose(c as Client, enabled as bool)` | `Client` | A copy of the client that prints every request it makes. |
| `isVerbose(c as Client)` | `bool` | Whether the client prints its requests. |
| `hasBearer(c as Client)` | `bool` | Whether the client can reach the v4 endpoints. |
| `hasUser(c as Client)` | `bool` | Whether the client acts for a signed-in user. |
| `call(c as Client, path as string, params as map of string to string)` | `json.Value` | GET any TMDB path and return the decoded body. |
| `callPost(c as Client, path as string, body as json.Value)` | `json.Value` | POST a JSON body to any TMDB path and return the decoded reply. |
| `callPut(c as Client, path as string, body as json.Value)` | `json.Value` | PUT a JSON body to any TMDB path and return the decoded reply. |
| `callDelete(c as Client, path as string, body as json.Value)` | `json.Value` | DELETE any TMDB path with a JSON body and return the decoded reply. |
| `mediaKindName(kind as MediaKind)` | `string` | The `media_type` string TMDB writes for a media kind. |
| `parseMediaKind(name as string)` | `MediaKind` | Read a TMDB `media_type` string as a media kind. |
| `year(date as string)` | `string` | The year of a TMDB `YYYY-MM-DD` date, or "" when there is none. |

### `MediaKind`

The kind of a row in a mixed result set.

| variant |
| --- |
| `Movie` |
| `Show` |
| `Person` |
| `Episode` |
| `Season` |
| `Unknown` |

### `Client`

A configured TMDB caller.

| field | meaning |
| --- | --- |
| `token as string` | the API read access token, "" when unset |
| `apiKey as string` | the legacy v3 API key, "" when unset |
| `userToken as string` | a v4 user access token, "" when unset |
| `language as string` | the `language` parameter, e.g. "en-US" |
| `region as string` | two-letter release region, e.g. "US"; "" to omit |
| `includeAdult as bool` | whether search and discovery return adult titles |
| `timeoutMs as int` | per-request idle timeout in milliseconds |
| `retries as int` | retry budget for a 429 / 5xx |
| `backoffMs as int` | base delay between retries, in milliseconds |
| `verbose as bool` | print each request, credentials redacted |

## Shared entities

Structs several topics return, and helpers over them.

| function | returns | what it does |
| --- | --- | --- |
| `genderName(gender as int)` | `string` | The name of a TMDB gender code: 1 female, 2 male, 3 non-binary. |
| `morePages(page as int, totalPages as int)` | `bool` | Whether a paginated result set has a page after this one. |
| `isMovie(item as MediaItem)` | `bool` | Whether a mixed row is a film. |
| `isShow(item as MediaItem)` | `bool` | Whether a mixed row is a series. |
| `isPerson(item as MediaItem)` | `bool` | Whether a mixed row is a person. |
| `onlyMovies(items as list of MediaItem)` | `list of MediaItem` | The films of a mixed page, in order. |
| `onlyShows(items as list of MediaItem)` | `list of MediaItem` | The series of a mixed page, in order. |
| `onlyPeople(items as list of MediaItem)` | `list of MediaItem` | The people of a mixed page, in order. |
| `genreIndex(genres as list of Genre)` | `map of string to string` | Index a genre list by id, for resolving `genreIds`. |
| `genreNames(index as map of string to string, ids as list of int)` | `list of string` | The genre names of a row, looked up in a `genreIndex`. |

### `Genre`

A genre id and its name.

| field | meaning |
| --- | --- |
| `id as int` | the genre id, as used by `withGenres` in discovery |
| `name as string` | the name, in the client's language |

### `Company`

A production company, as embedded in a film or series.

| field | meaning |
| --- | --- |
| `id as int` | the company id |
| `name as string` | the company name |
| `logoPath as string` | an image path for `imageUrl`, "" when there is none |
| `originCountry as string` | a two-letter country code, "" when unknown |

### `Network`

A television network.

| field | meaning |
| --- | --- |
| `id as int` | the network id |
| `name as string` | the network name |
| `logoPath as string` | an image path for `imageUrl`, "" when there is none |
| `originCountry as string` | a two-letter country code, "" when unknown |

### `Country`

A country from a production list, the configuration list or a region list.

| field | meaning |
| --- | --- |
| `code as string` | the two-letter ISO 3166-1 code |
| `name as string` | the best available name |
| `englishName as string` | the English name, "" when not given |
| `nativeName as string` | the endonym, "" when not given |

### `Language`

A language, in either shape TMDB writes one.

| field | meaning |
| --- | --- |
| `code as string` | the ISO 639-1 code |
| `name as string` | the endonym ("Deutsch"), "" when not given |
| `englishName as string` | the English name ("German"), "" when not given |

### `CollectionRef`

The collection a film belongs to, as embedded in its record.

| field | meaning |
| --- | --- |
| `id as int` | the collection id, 0 when the film is in none |
| `name as string` | the collection name |
| `posterPath as string` | an image path for `imageUrl` |
| `backdropPath as string` | an image path for `imageUrl` |

### `MovieSummary`

A film as a row of a paginated movie list.

| field | meaning |
| --- | --- |
| `id as int` | the movie id |
| `title as string` | the title, in the client's language |
| `originalTitle as string` | the title in its original language |
| `overview as string` | the synopsis, "" when untranslated |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `releaseDate as string` | `YYYY-MM-DD`, "" when unknown |
| `genreIds as list of int` | genre ids, resolvable with `movieGenres` |
| `originalLanguage as string` | an ISO 639-1 code |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | number of ratings behind the mean |
| `adult as bool` | whether the title is adult |
| `video as bool` | TMDB's flag for a direct-to-video release |

### `ShowSummary`

A series as a row of a paginated series list.

| field | meaning |
| --- | --- |
| `id as int` | the series id |
| `name as string` | the series name, in the client's language |
| `originalName as string` | the name in its original language |
| `overview as string` | the synopsis, "" when untranslated |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `firstAirDate as string` | `YYYY-MM-DD`, "" when unknown |
| `genreIds as list of int` | genre ids, resolvable with `showGenres` |
| `originalLanguage as string` | an ISO 639-1 code |
| `originCountry as list of string` | the producing countries |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | number of ratings behind the mean |
| `adult as bool` | whether the series is adult |

### `PersonSummary`

A person as a row of a paginated people list.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | the name TMDB files them under |
| `originalName as string` | the name in its original script |
| `profilePath as string` | an image path for `profileUrl` |
| `knownForDepartment as string` | e.g. "Acting", "Directing" |
| `gender as int` | 0 unknown, 1 female, 2 male, 3 non-binary - see `genderName` |
| `popularity as float` | TMDB's popularity score |
| `adult as bool` | whether the person is filed as adult |
| `knownFor as list of MediaItem` | the titles they are known for |

### `MediaItem`

One row of a mixed result set: a film, series, person, season or episode.

| field | meaning |
| --- | --- |
| `kind as MediaKind` | what this row is |
| `id as int` | the id, in the id space of `kind` |
| `title as string` | `title` for a film, `name` for a series or person |
| `originalTitle as string` | the same, in the original language |
| `overview as string` | the synopsis, "" for a person |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `profilePath as string` | an image path for `profileUrl`, people only |
| `releaseDate as string` | the first date given, "" for a person |
| `genreIds as list of int` | genre ids, empty for a person |
| `originalLanguage as string` | an ISO 639-1 code |
| `originCountry as list of string` | the producing countries, series only |
| `knownForDepartment as string` | e.g. "Acting", people only |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | number of ratings behind the mean |
| `adult as bool` | whether the row is adult |
| `video as bool` | the direct-to-video flag, films only |

### `MoviePage`

One page of films.

| field | meaning |
| --- | --- |
| `page as int` | the page number, 1-based |
| `totalPages as int` | the page count TMDB reports, which may exceed `MAX_PAGE` |
| `totalResults as int` | the row count over all pages |
| `results as list of MovieSummary` | this page's rows |

### `ShowPage`

One page of series.

| field | meaning |
| --- | --- |
| `page as int` | the page number, 1-based |
| `totalPages as int` | the page count TMDB reports, which may exceed `MAX_PAGE` |
| `totalResults as int` | the row count over all pages |
| `results as list of ShowSummary` | this page's rows |

### `PersonPage`

One page of people.

| field | meaning |
| --- | --- |
| `page as int` | the page number, 1-based |
| `totalPages as int` | the page count TMDB reports, which may exceed `MAX_PAGE` |
| `totalResults as int` | the row count over all pages |
| `results as list of PersonSummary` | this page's rows |

### `MediaPage`

One page of mixed rows, from multi-search, trending or a custom list.

| field | meaning |
| --- | --- |
| `page as int` | the page number, 1-based |
| `totalPages as int` | the page count TMDB reports, which may exceed `MAX_PAGE` |
| `totalResults as int` | the row count over all pages |
| `results as list of MediaItem` | this page's rows |

### `Image`

A still, poster, backdrop, logo or profile image.

| field | meaning |
| --- | --- |
| `filePath as string` | the image path, e.g. "/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg" |
| `aspectRatio as float` | width divided by height |
| `width as int` | the original width in pixels |
| `height as int` | the original height in pixels |
| `language as string` | the ISO 639-1 code of any text in it, "" for none |
| `voteAverage as float` | the mean user rating of this image |
| `voteCount as int` | number of ratings behind the mean |

### `Images`

Every image attached to one object, by kind.

| field | meaning |
| --- | --- |
| `id as int` | the object the images belong to |
| `backdrops as list of Image` | wide artwork |
| `posters as list of Image` | tall artwork |
| `logos as list of Image` | title treatments, usually transparent |
| `stills as list of Image` | episode frames |
| `profiles as list of Image` | photographs of a person |

### `Video`

A trailer, teaser, clip or featurette hosted on YouTube or Vimeo.

| field | meaning |
| --- | --- |
| `id as string` | TMDB's id for this video record |
| `name as string` | the video's title |
| `key as string` | the id on `site`, e.g. a YouTube video id |
| `site as string` | the host, "YouTube" or "Vimeo" |
| `size as int` | the vertical resolution, e.g. 1080 |
| `kind as string` | TMDB's `type`: "Trailer", "Teaser", "Clip", ... |
| `language as string` | an ISO 639-1 code |
| `region as string` | an ISO 3166-1 code |
| `official as bool` | whether it comes from the rights holder |
| `publishedAt as string` | an ISO 8601 timestamp |

### `CastMember`

Someone in front of the camera.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | the performer's name |
| `originalName as string` | the name in its original script |
| `character as string` | who they played |
| `creditId as string` | the credit's own id, for `credit` |
| `order as int` | billing order, 0 first |
| `castId as int` | TMDB's per-film cast row id, 0 when not given |
| `gender as int` | see `genderName` |
| `knownForDepartment as string` | e.g. "Acting" |
| `popularity as float` | TMDB's popularity score |
| `profilePath as string` | an image path for `profileUrl` |
| `adult as bool` | whether the person is filed as adult |

### `CrewMember`

Someone behind the camera.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | their name |
| `originalName as string` | the name in its original script |
| `job as string` | the specific job, e.g. "Director of Photography" |
| `department as string` | the department the job sits in, e.g. "Camera" |
| `creditId as string` | the credit's own id, for `credit` |
| `gender as int` | see `genderName` |
| `knownForDepartment as string` | what they are usually credited for |
| `popularity as float` | TMDB's popularity score |
| `profilePath as string` | an image path for `profileUrl` |
| `adult as bool` | whether the person is filed as adult |

### `Credits`

The cast and crew of one title.

| field | meaning |
| --- | --- |
| `id as int` | the film, series, season or episode the credits belong to |
| `cast as list of CastMember` | performers, in billing order |
| `crew as list of CrewMember` | everyone else |

### `ExternalIds`

The same object's ids on other sites.

| field | meaning |
| --- | --- |
| `imdbId as string` | e.g. "tt0076759" for a title, "nm0000158" for a person |
| `tvdbId as int` | TheTVDB's id, series and episodes only |
| `tvrageId as int` | the retired TVRage id |
| `wikidataId as string` | e.g. "Q17738" |
| `facebookId as string` | a Facebook page or username |
| `instagramId as string` | an Instagram handle |
| `twitterId as string` | an X / Twitter handle |
| `tiktokId as string` | a TikTok handle, people only |
| `youtubeId as string` | a YouTube channel, people only |
| `freebaseId as string` | the retired Freebase id |
| `freebaseMid as string` | the retired Freebase machine id |

### `Keyword`

A keyword: TMDB's free-form subject tag.

| field | meaning |
| --- | --- |
| `id as int` | the keyword id |
| `name as string` | the keyword |

### `Review`

A user review.

| field | meaning |
| --- | --- |
| `id as string` | the review id |
| `author as string` | the display name on the review |
| `username as string` | the reviewer's TMDB username |
| `name as string` | the reviewer's full name, "" when not set |
| `avatarPath as string` | an image path or an absolute Gravatar URL |
| `rating as float` | the reviewer's own score out of 10, 0 when unrated |
| `content as string` | the review body, as Markdown |
| `url as string` | the review's page on TMDB |
| `createdAt as string` | an ISO 8601 timestamp |
| `updatedAt as string` | an ISO 8601 timestamp |
| `language as string` | an ISO 639-1 code |
| `mediaId as int` | the reviewed title, 0 unless fetched by `review` |
| `mediaTitle as string` | the reviewed title's name, "" unless fetched by `review` |
| `mediaKind as MediaKind` | what was reviewed, `Unknown` unless fetched by `review` |

### `ReviewPage`

One page of reviews.

| field | meaning |
| --- | --- |
| `id as int` | the title the reviews belong to, 0 when not given |
| `page as int` | the page number, 1-based |
| `totalPages as int` | the page count |
| `totalResults as int` | the review count over all pages |
| `results as list of Review` | this page's reviews |

### `WatchProvider`

A streaming, rental or purchase service.

| field | meaning |
| --- | --- |
| `providerId as int` | the provider id, as used by `withWatchProviders` |
| `providerName as string` | the service's name, e.g. "Netflix" |
| `logoPath as string` | an image path for `logoUrl` |
| `displayPriority as int` | TMDB's suggested ordering, lower first |

### `WatchOffers`

The ways to watch a title in one country.

| field | meaning |
| --- | --- |
| `region as string` | the two-letter country code |
| `link as string` | a TMDB page listing the offers, "" when not given |
| `flatrate as list of WatchProvider` | included in a subscription |
| `rent as list of WatchProvider` | rentable |
| `buy as list of WatchProvider` | purchasable |
| `ads as list of WatchProvider` | free with advertising |
| `free as list of WatchProvider` | free outright |

### `Translation`

One translation of a title's text.

| field | meaning |
| --- | --- |
| `region as string` | the ISO 3166-1 code the translation is filed under |
| `language as string` | the ISO 639-1 code |
| `name as string` | the endonym of the language |
| `englishName as string` | the English name of the language |
| `title as string` | the translated title or name |
| `overview as string` | the translated synopsis |
| `tagline as string` | the translated tagline, films and series only |
| `homepage as string` | the localized homepage |

### `AlternativeTitle`

A title a work is released under in another country.

| field | meaning |
| --- | --- |
| `region as string` | the two-letter country code |
| `title as string` | the title used there |
| `kind as string` | TMDB's `type` note, e.g. "working title"; often "" |

### `StatusResponse`

TMDB's answer to a write.

| field | meaning |
| --- | --- |
| `success as bool` | whether the write happened |
| `statusCode as int` | TMDB's status code, e.g. 1 success, 13 deleted |
| `statusMessage as string` | TMDB's sentence about the outcome |
| `id as int` | the id of the thing created, 0 when nothing was |

## Configuration, images and videos

Guide: [Images and videos](images.md).

| constant | value | meaning |
| --- | --- | --- |
| `SIZE_ORIGINAL` | `"original"` | The size that asks for the image as uploaded. |
| `DEFAULT_IMAGE_BASE` | `"https://image.tmdb.org/t/p/"` | The HTTPS image host TMDB has published for years. |

| function | returns | what it does |
| --- | --- | --- |
| `configuration(c as Client)` | `Configuration` | Fetch the image configuration from `/configuration`. |
| `defaultConfiguration()` | `Configuration` | A snapshot of TMDB's published image configuration, built without a request. |
| `imageUrl(cfg as Configuration, path as string, size as string)` | `string` | Build an image URL at any size that appears in any of the configuration's lists. |
| `posterUrl(cfg as Configuration, path as string, size as string)` | `string` | Build the URL of a poster. |
| `backdropUrl(cfg as Configuration, path as string, size as string)` | `string` | Build the URL of a backdrop. |
| `profileUrl(cfg as Configuration, path as string, size as string)` | `string` | Build the URL of a person's profile photograph. |
| `stillUrl(cfg as Configuration, path as string, size as string)` | `string` | Build the URL of an episode still. |
| `logoUrl(cfg as Configuration, path as string, size as string)` | `string` | Build the URL of a company, network or title logo. |
| `videoUrl(video as Video)` | `string` | The watch URL of a video on YouTube or Vimeo. |
| `videoThumbnailUrl(video as Video)` | `string` | The thumbnail URL of a YouTube video (`hqdefault.jpg`). |
| `countries(c as Client)` | `list of Country` | The countries TMDB knows, with their English and native names. |
| `languages(c as Client)` | `list of Language` | The languages TMDB knows, with their English names and endonyms. |
| `primaryTranslations(c as Client)` | `list of string` | The language-region tags TMDB has translations for, e.g. "de-DE". |
| `jobs(c as Client)` | `list of Department` | The crew jobs TMDB recognizes, grouped by department. |
| `timezones(c as Client)` | `list of TimezoneGroup` | The time zones TMDB knows, grouped by country. |

### `Configuration`

The image hosts, the size lists per image kind, and the change keys.

| field | meaning |
| --- | --- |
| `baseUrl as string` | the plain-HTTP image host |
| `secureBaseUrl as string` | the HTTPS image host, preferred |
| `backdropSizes as list of string` | sizes valid for a backdrop |
| `logoSizes as list of string` | sizes valid for a logo |
| `posterSizes as list of string` | sizes valid for a poster |
| `profileSizes as list of string` | sizes valid for a profile photo |
| `stillSizes as list of string` | sizes valid for an episode still |
| `changeKeys as list of string` | the fields the change endpoints report on |

### `Department`

A department and the jobs filed under it.

| field | meaning |
| --- | --- |
| `department as string` | the department name, e.g. "Camera" |
| `jobs as list of string` | the jobs in it, e.g. "Director of Photography" |

### `TimezoneGroup`

A country and the time zones in it.

| field | meaning |
| --- | --- |
| `code as string` | the two-letter ISO 3166-1 code |
| `zones as list of string` | IANA zone names, e.g. "Europe/Berlin" |

## Search

Guide: [Searching](searching.md).

| function | returns | what it does |
| --- | --- | --- |
| `searchMovies(c as Client, query as string, page as int)` | `MoviePage` | Search for films by title. |
| `searchMoviesInYear(c as Client, query as string, year as int, page as int)` | `MoviePage` | Search for films whose primary release falls in one year. |
| `searchShows(c as Client, query as string, page as int)` | `ShowPage` | Search for series by name. |
| `searchShowsInYear(c as Client, query as string, year as int, page as int)` | `ShowPage` | Search for series that first aired in one year. |
| `searchPeople(c as Client, query as string, page as int)` | `PersonPage` | Search for people by name. |
| `searchMulti(c as Client, query as string, page as int)` | `MediaPage` | Search films, series and people at once, in one ranked list. |
| `searchCollections(c as Client, query as string, page as int)` | `CollectionPage` | Search for collections, TMDB's franchise groupings. |
| `searchCompanies(c as Client, query as string, page as int)` | `CompanyPage` | Search for production companies. |
| `searchKeywords(c as Client, query as string, page as int)` | `KeywordPage` | Search for keywords, TMDB's subject tags. |
| `searchMoviesAll(c as Client, query as string, maxPages as int)` | `list of MovieSummary` | Every film matching a query, up to a page budget. |
| `searchShowsAll(c as Client, query as string, maxPages as int)` | `list of ShowSummary` | Every series matching a query, up to a page budget. |

## Discovery

Guide: [Discovery](discovery.md).

| constant | value | meaning |
| --- | --- | --- |
| `SORT_POPULARITY_DESC` | `"popularity.desc"` | Sort: most popular first. |
| `SORT_POPULARITY_ASC` | `"popularity.asc"` | Sort: least popular first. |
| `SORT_RATING_DESC` | `"rating.desc"` | Sort: best rated first (`vote_average.desc`). |
| `SORT_RATING_ASC` | `"rating.asc"` | Sort: worst rated first (`vote_average.asc`). |
| `SORT_VOTES_DESC` | `"votes.desc"` | Sort: most ratings first (`vote_count.desc`), a rough proxy for most watched. |
| `SORT_NEWEST` | `"date.desc"` | Sort: newest first, by primary release date (films) or first air date (series). |
| `SORT_OLDEST` | `"date.asc"` | Sort: oldest first, by primary release date (films) or first air date (series). |
| `SORT_TITLE_ASC` | `"title.asc"` | Sort: alphabetical, `title.asc` for films and `name.asc` for series. |
| `SORT_TITLE_DESC` | `"title.desc"` | Sort: reverse alphabetical, `title.desc` for films and `name.desc` for series. |
| `SORT_REVENUE_DESC` | `"revenue.desc"` | Sort: highest box office first. |
| `SHOW_STATUS_RETURNING` | `0` | `with_status` for a series still being made. |
| `SHOW_STATUS_PLANNED` | `1` | `with_status` for a series that is announced but not shooting. |
| `SHOW_STATUS_IN_PRODUCTION` | `2` | `with_status` for a series currently in production. |
| `SHOW_STATUS_ENDED` | `3` | `with_status` for a series that finished on its own terms. |
| `SHOW_STATUS_CANCELLED` | `4` | `with_status` for a series that was cancelled. |
| `SHOW_STATUS_PILOT` | `5` | `with_status` for a pilot that never became a series. |
| `SHOW_TYPE_DOCUMENTARY` | `0` | `with_type` for a documentary series. |
| `SHOW_TYPE_NEWS` | `1` | `with_type` for a news programme. |
| `SHOW_TYPE_MINISERIES` | `2` | `with_type` for a miniseries: a closed run with no second season. |
| `SHOW_TYPE_REALITY` | `3` | `with_type` for reality television. |
| `SHOW_TYPE_SCRIPTED` | `4` | `with_type` for scripted drama and comedy. |
| `SHOW_TYPE_TALK_SHOW` | `5` | `with_type` for a talk show. |
| `SHOW_TYPE_VIDEO` | `6` | `with_type` for a video release filed as a series. |
| `MONETIZATION_FLATRATE` | `"flatrate"` | Monetization: included in a subscription. |
| `MONETIZATION_FREE` | `"free"` | Monetization: free to watch, no advertising. |
| `MONETIZATION_ADS` | `"ads"` | Monetization: free to watch, advertising-supported. |
| `MONETIZATION_RENT` | `"rent"` | Monetization: rentable. |
| `MONETIZATION_BUY` | `"buy"` | Monetization: purchasable. |

| function | returns | what it does |
| --- | --- | --- |
| `discoverFilter()` | `DiscoverFilter` | An empty filter: everything, most popular first. |
| `sortedBy(f as DiscoverFilter, sort as string)` | `DiscoverFilter` | A copy of the filter with a different ordering. |
| `withGenres(f as DiscoverFilter, genreIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to titles in **every** listed genre. |
| `withAnyGenre(f as DiscoverFilter, genreIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to titles in **any** listed genre. |
| `withoutGenres(f as DiscoverFilter, genreIds as list of int)` | `DiscoverFilter` | A copy of the filter excluding every listed genre. |
| `withKeywords(f as DiscoverFilter, keywordIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to titles carrying **every** keyword. |
| `withAnyKeyword(f as DiscoverFilter, keywordIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to titles carrying **any** keyword. |
| `withoutKeywords(f as DiscoverFilter, keywordIds as list of int)` | `DiscoverFilter` | A copy of the filter excluding every listed keyword. |
| `withCompanies(f as DiscoverFilter, companyIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to titles from any listed company. |
| `withoutCompanies(f as DiscoverFilter, companyIds as list of int)` | `DiscoverFilter` | A copy of the filter excluding every listed company. |
| `withPeople(f as DiscoverFilter, personIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to films involving any listed person. |
| `withCast(f as DiscoverFilter, personIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to films any listed person appears in. |
| `withCrew(f as DiscoverFilter, personIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to films any listed person worked on. |
| `withNetworks(f as DiscoverFilter, networkIds as list of int)` | `DiscoverFilter` | A copy of the filter narrowed to series on any listed network. |
| `inOriginalLanguage(f as DiscoverFilter, code as string)` | `DiscoverFilter` | A copy of the filter narrowed to one original language. |
| `fromCountry(f as DiscoverFilter, code as string)` | `DiscoverFilter` | A copy of the filter narrowed to one country of origin. |
| `releasedBetween(f as DiscoverFilter, earliest as string, latest as string)` | `DiscoverFilter` | A copy of the filter narrowed to a release window. |
| `releasedInYear(f as DiscoverFilter, year as int)` | `DiscoverFilter` | A copy of the filter narrowed to one release year. |
| `ratedAtLeast(f as DiscoverFilter, score as float)` | `DiscoverFilter` | A copy of the filter narrowed to titles rated at or above a score. |
| `ratedAtMost(f as DiscoverFilter, score as float)` | `DiscoverFilter` | A copy of the filter narrowed to titles rated at or below a score. |
| `withMinVotes(f as DiscoverFilter, votes as int)` | `DiscoverFilter` | A copy of the filter narrowed to titles with at least this many ratings. |
| `runningBetween(f as DiscoverFilter, minMinutes as int, maxMinutes as int)` | `DiscoverFilter` | A copy of the filter narrowed to a runtime window, in minutes. |
| `availableOn(f as DiscoverFilter, providerIds as list of int, watchRegion as string)` | `DiscoverFilter` | A copy of the filter narrowed to titles offered by a service, in a country. |
| `notAvailableOn(f as DiscoverFilter, providerIds as list of int)` | `DiscoverFilter` | A copy of the filter excluding titles offered by listed services. |
| `withMonetization(f as DiscoverFilter, kinds as list of string)` | `DiscoverFilter` | A copy of the filter narrowed to how a title is paid for. |
| `ratedFor(f as DiscoverFilter, country as string, certification as string)` | `DiscoverFilter` | A copy of the filter narrowed to one age rating, in one country. |
| `ratedUpTo(f as DiscoverFilter, country as string, certification as string)` | `DiscoverFilter` | A copy of the filter narrowed to an age rating or a gentler one, in one country. |
| `withShowStatus(f as DiscoverFilter, status as int)` | `DiscoverFilter` | A copy of the filter narrowed to series in one production state. |
| `withShowType(f as DiscoverFilter, kind as int)` | `DiscoverFilter` | A copy of the filter narrowed to one kind of series. |
| `filterParams(f as DiscoverFilter, forShows as bool)` | `map of string to string` | The TMDB query parameters a filter becomes on one catalogue, without a request. |
| `discoverMovies(c as Client, f as DiscoverFilter, page as int)` | `MoviePage` | Find films matching a filter, from `/discover/movie`. |
| `discoverShows(c as Client, f as DiscoverFilter, page as int)` | `ShowPage` | Find series matching a filter, from `/discover/tv`. |
| `discoverMoviesAll(c as Client, f as DiscoverFilter, maxPages as int)` | `list of MovieSummary` | Every film matching a filter, up to a page budget. |
| `discoverShowsAll(c as Client, f as DiscoverFilter, maxPages as int)` | `list of ShowSummary` | Every series matching a filter, up to a page budget. |

### `DiscoverFilter`

A set of discovery criteria, independent of the catalogue it runs on.

| field | meaning |
| --- | --- |
| `criteria as map of string to string` | the criteria, by deck key name |

## Movies

Guide: [Movies](movies.md).

| constant | value | meaning |
| --- | --- | --- |
| `RELEASE_PREMIERE` | `1` | Release type: the festival or press premiere. |
| `RELEASE_THEATRICAL_LIMITED` | `2` | Release type: a limited theatrical run. |
| `RELEASE_THEATRICAL` | `3` | Release type: the wide theatrical release, the usual "release date". |
| `RELEASE_DIGITAL` | `4` | Release type: digital (streaming or download). |
| `RELEASE_PHYSICAL` | `5` | Release type: physical media. |
| `RELEASE_TV` | `6` | Release type: a television broadcast. |

| function | returns | what it does |
| --- | --- | --- |
| `movie(c as Client, movieId as int)` | `Movie` | Read a film's record. |
| `movieBundle(c as Client, movieId as int)` | `MovieBundle` | Read a film and nine of its sub-resources in one request. |
| `movieCredits(c as Client, movieId as int)` | `Credits` | Read a film's cast and crew. |
| `movieImages(c as Client, movieId as int)` | `Images` | Read a film's artwork. |
| `movieVideos(c as Client, movieId as int)` | `list of Video` | Read a film's trailers, teasers and clips. |
| `movieKeywords(c as Client, movieId as int)` | `list of Keyword` | Read a film's subject keywords. |
| `movieRecommendations(c as Client, movieId as int, page as int)` | `MoviePage` | Read what TMDB recommends after a film. |
| `movieSimilar(c as Client, movieId as int, page as int)` | `MoviePage` | Read films that share genres and keywords with a film. |
| `movieReviews(c as Client, movieId as int, page as int)` | `ReviewPage` | Read a film's user reviews. |
| `movieReleaseDates(c as Client, movieId as int)` | `list of ReleaseGroup` | Read every dated release of a film, by country, with age ratings. |
| `movieExternalIds(c as Client, movieId as int)` | `ExternalIds` | Read a film's ids on other sites. |
| `movieTranslations(c as Client, movieId as int)` | `list of Translation` | Read a film's translated titles and synopses. |
| `movieAlternativeTitles(c as Client, movieId as int)` | `list of AlternativeTitle` | Read the titles a film is released under elsewhere. |
| `movieWatchProviders(c as Client, movieId as int)` | `list of WatchOffers` | Read where a film can be watched, country by country. |
| `nowPlaying(c as Client, page as int)` | `MoviePage` | Read the films in cinemas now. |
| `popularMovies(c as Client, page as int)` | `MoviePage` | Read the most popular films; sends the client's region. |
| `topRatedMovies(c as Client, page as int)` | `MoviePage` | Read the best rated films. |
| `upcomingMovies(c as Client, page as int)` | `MoviePage` | Read the films about to be released; sends the client's region. |
| `latestMovie(c as Client)` | `Movie` | Read the film most recently added to TMDB. |
| `directorOf(credits as Credits)` | `string` | The first director's name out of a credits record. |
| `directorsOf(credits as Credits)` | `list of string` | Every director's name out of a credits record. |
| `crewNamed(credits as Credits, job as string)` | `list of string` | Every crew name credited with one job. |
| `releaseTypeName(kind as int)` | `string` | The lowercase name of a release type. |
| `certificationOf(groups as list of ReleaseGroup, region as string)` | `string` | One country's age rating, out of a release-dates result. |
| `offersIn(offers as list of WatchOffers, region as string)` | `WatchOffers` | One country's offers, out of a watch-providers result. |

### `Movie`

A film's full record, as `/movie/{id}` answers it.

| field | meaning |
| --- | --- |
| `id as int` | the movie id |
| `title as string` | the title, in the client's language |
| `originalTitle as string` | the title in its original language |
| `tagline as string` | the marketing line, "" when there is none |
| `overview as string` | the synopsis |
| `releaseDate as string` | the primary release date, `YYYY-MM-DD` |
| `runtime as int` | the runtime in minutes, 0 when unknown |
| `status as string` | e.g. "Released", "Post Production", "Planned" |
| `homepage as string` | the official site, "" when there is none |
| `imdbId as string` | e.g. "tt0076759", "" when not cross-referenced |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `genres as list of Genre` | the genres, named |
| `belongsToCollection as CollectionRef` | the franchise, `id` 0 when none |
| `budget as int` | the budget in US dollars, 0 when not filed |
| `revenue as int` | the box office in US dollars, 0 when not filed |
| `originalLanguage as string` | an ISO 639-1 code |
| `originCountry as list of string` | the producing countries |
| `spokenLanguages as list of Language` | the languages spoken in it |
| `productionCompanies as list of Company` | the companies behind it |
| `productionCountries as list of Country` | where it was made |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | how many ratings that mean is over |
| `adult as bool` | whether the film is adult |
| `video as bool` | TMDB's direct-to-video flag |

### `ReleaseDate`

One dated release of a film in one country.

| field | meaning |
| --- | --- |
| `date as string` | an ISO 8601 timestamp |
| `kind as int` | a `RELEASE_*` constant - see `releaseTypeName` |
| `certification as string` | the age rating, "" when unrated |
| `language as string` | an ISO 639-1 code, "" when not language-specific |
| `note as string` | a free-text qualifier, e.g. "Director's cut" |

### `ReleaseGroup`

Every release of a film in one country.

| field | meaning |
| --- | --- |
| `region as string` | the two-letter country code |
| `releases as list of ReleaseDate` | the releases there, in TMDB's order |

### `MovieBundle`

A film and nine sub-resources, fetched in one request by `movieBundle`.

| field | meaning |
| --- | --- |
| `movie as Movie` | the film itself |
| `credits as Credits` | cast and crew |
| `images as Images` | posters, backdrops and logos |
| `videos as list of Video` | trailers, teasers and clips |
| `keywords as list of Keyword` | the subject tags |
| `externalIds as ExternalIds` | the film's ids elsewhere |
| `recommendations as MoviePage` | what TMDB suggests next |
| `similar as MoviePage` | films sharing genres and keywords |
| `reviews as ReviewPage` | the first page of user reviews |
| `watchOffers as list of WatchOffers` | where to watch it, by country |

## Series, seasons and episodes

Guide: [Series, seasons and episodes](shows.md).

| function | returns | what it does |
| --- | --- | --- |
| `show(c as Client, seriesId as int)` | `Show` | Read a series' record. |
| `showBundle(c as Client, seriesId as int)` | `ShowBundle` | Read a series and ten of its sub-resources in one request. |
| `showCredits(c as Client, seriesId as int)` | `Credits` | Read a series' regular cast and crew. |
| `showAggregateCredits(c as Client, seriesId as int)` | `AggregateCredits` | Read a series' credits rolled up over its whole run. |
| `showImages(c as Client, seriesId as int)` | `Images` | Read a series' artwork, in every language (no `language` is sent). |
| `showVideos(c as Client, seriesId as int)` | `list of Video` | Read a series' trailers, teasers and clips. |
| `showKeywords(c as Client, seriesId as int)` | `list of Keyword` | Read a series' subject keywords. |
| `showContentRatings(c as Client, seriesId as int)` | `list of ContentRating` | Read a series' age ratings, country by country. |
| `showEpisodeGroups(c as Client, seriesId as int)` | `list of EpisodeGroup` | Read the alternative episode orderings a series has. |
| `showRecommendations(c as Client, seriesId as int, page as int)` | `ShowPage` | Read what TMDB recommends after a series. |
| `showSimilar(c as Client, seriesId as int, page as int)` | `ShowPage` | Read series that share genres and keywords with a series. |
| `showReviews(c as Client, seriesId as int, page as int)` | `ReviewPage` | Read a series' user reviews. |
| `showExternalIds(c as Client, seriesId as int)` | `ExternalIds` | Read a series' ids on other sites, TheTVDB's included. |
| `showTranslations(c as Client, seriesId as int)` | `list of Translation` | Read a series' translated names and synopses. |
| `showAlternativeTitles(c as Client, seriesId as int)` | `list of AlternativeTitle` | Read the names a series is broadcast under elsewhere. |
| `showWatchProviders(c as Client, seriesId as int)` | `list of WatchOffers` | Read where a series can be watched, country by country. |
| `season(c as Client, seriesId as int, seasonNumber as int)` | `Season` | Read one season, episodes included. |
| `seasonCredits(c as Client, seriesId as int, seasonNumber as int)` | `Credits` | Read a season's cast and crew. |
| `seasonAggregateCredits(c as Client, seriesId as int, seasonNumber as int)` | `AggregateCredits` | Read a season's credits rolled up over its episodes. |
| `seasonImages(c as Client, seriesId as int, seasonNumber as int)` | `Images` | Read a season's posters, in every language (no `language` is sent). |
| `seasonVideos(c as Client, seriesId as int, seasonNumber as int)` | `list of Video` | Read a season's videos. |
| `seasonExternalIds(c as Client, seriesId as int, seasonNumber as int)` | `ExternalIds` | Read a season's ids on other sites. |
| `episode(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int)` | `Episode` | Read one episode's record. |
| `episodeCredits(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int)` | `Credits` | Read an episode's cast, crew and guest stars. |
| `episodeImages(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int)` | `Images` | Read an episode's stills, in every language (no `language` is sent). |
| `episodeVideos(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int)` | `list of Video` | Read an episode's videos. |
| `episodeExternalIds(c as Client, seriesId as int, seasonNumber as int, episodeNumber as int)` | `ExternalIds` | Read an episode's ids on other sites. |
| `airingToday(c as Client, page as int)` | `ShowPage` | Read the series with an episode airing today, in TMDB's own time zone. |
| `airingTodayIn(c as Client, timezone as string, page as int)` | `ShowPage` | Read the series with an episode airing today, in one time zone. |
| `onTheAir(c as Client, page as int)` | `ShowPage` | Read the series with an episode airing in the next seven days. |
| `popularShows(c as Client, page as int)` | `ShowPage` | Read the most popular series. |
| `topRatedShows(c as Client, page as int)` | `ShowPage` | Read the best rated series. |
| `latestShow(c as Client)` | `Show` | Read the series most recently added to TMDB. |
| `contentRatingOf(ratings as list of ContentRating, region as string)` | `string` | One country's rating, out of a content-ratings result. |
| `seasonOf(s as Show, seasonNumber as int)` | `SeasonSummary` | A season out of a series' season list, by number rather than index. |

### `Show`

A series' full record, as `/tv/{id}` answers it.

| field | meaning |
| --- | --- |
| `id as int` | the series id |
| `name as string` | the name, in the client's language |
| `originalName as string` | the name in its original language |
| `tagline as string` | the marketing line, "" when there is none |
| `overview as string` | the synopsis |
| `firstAirDate as string` | `YYYY-MM-DD` of the première |
| `lastAirDate as string` | `YYYY-MM-DD` of the most recent episode |
| `status as string` | e.g. "Returning Series", "Ended", "Canceled" |
| `kind as string` | TMDB's `type`: "Scripted", "Miniseries", "Reality", ... |
| `homepage as string` | the official site, "" when there is none |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `genres as list of Genre` | the genres, named |
| `createdBy as list of Creator` | the credited creators |
| `episodeRunTime as list of int` | typical episode lengths in minutes |
| `numberOfSeasons as int` | how many seasons, specials excluded |
| `numberOfEpisodes as int` | how many episodes in total |
| `seasons as list of SeasonSummary` | the seasons, season 0 included |
| `networks as list of Network` | who broadcasts or streams it |
| `productionCompanies as list of Company` | the companies behind it |
| `productionCountries as list of Country` | where it was made |
| `spokenLanguages as list of Language` | the languages spoken in it |
| `languages as list of string` | ISO 639-1 codes TMDB files it under |
| `originCountry as list of string` | the producing countries |
| `originalLanguage as string` | an ISO 639-1 code |
| `lastEpisodeToAir as Episode` | the most recent episode, zeroed if none |
| `nextEpisodeToAir as Episode` | the next one, zeroed when nothing is scheduled |
| `inProduction as bool` | whether more is being made |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | how many ratings that mean is over |
| `adult as bool` | whether the series is adult |

### `Creator`

Someone credited with creating a series.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `creditId as string` | the credit's own id, for `credit` |
| `name as string` | their name |
| `gender as int` | see `genderName` |
| `profilePath as string` | an image path for `profileUrl` |

### `SeasonSummary`

A season as it appears in a series record.

| field | meaning |
| --- | --- |
| `id as int` | the season's own id |
| `seasonNumber as int` | its number under the series, 0 for specials |
| `name as string` | e.g. "Season 3", "Specials" |
| `overview as string` | the season synopsis, often "" |
| `airDate as string` | `YYYY-MM-DD` of the first episode |
| `episodeCount as int` | how many episodes it holds |
| `posterPath as string` | an image path for `posterUrl` |
| `voteAverage as float` | the mean user rating of the season |

### `Season`

A season and its episodes.

| field | meaning |
| --- | --- |
| `id as int` | the season's own id |
| `seasonNumber as int` | its number under the series |
| `name as string` | e.g. "Season 3" |
| `overview as string` | the season synopsis |
| `airDate as string` | `YYYY-MM-DD` of the first episode |
| `posterPath as string` | an image path for `posterUrl` |
| `voteAverage as float` | the mean user rating of the season |
| `episodes as list of Episode` | the episodes, in broadcast order |

### `Episode`

One episode of a series.

| field | meaning |
| --- | --- |
| `id as int` | the episode's own id |
| `seasonNumber as int` | which season it belongs to |
| `episodeNumber as int` | its number within that season |
| `name as string` | the episode title |
| `overview as string` | the synopsis |
| `airDate as string` | `YYYY-MM-DD`, "" when unscheduled |
| `runtime as int` | the runtime in minutes, 0 when unknown |
| `kind as string` | TMDB's `episode_type`: "standard", "finale", "mid_season" |
| `productionCode as string` | the production code, often "" |
| `showId as int` | the series it belongs to |
| `stillPath as string` | an image path for `stillUrl` |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | how many ratings that mean is over |

### `CreditRole`

One role a performer played across a series.

| field | meaning |
| --- | --- |
| `creditId as string` | the credit's own id, for `credit` |
| `character as string` | who they played |
| `episodeCount as int` | in how many episodes |

### `CreditJob`

One job a crew member did across a series.

| field | meaning |
| --- | --- |
| `creditId as string` | the credit's own id, for `credit` |
| `job as string` | the job title |
| `episodeCount as int` | in how many episodes |

### `AggregateCastMember`

A performer's whole run on a series or season.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | the performer's name |
| `originalName as string` | the name in its original script |
| `roles as list of CreditRole` | the parts they played |
| `totalEpisodeCount as int` | episodes across all their roles |
| `order as int` | billing order, 0 first |
| `gender as int` | see `genderName` |
| `knownForDepartment as string` | e.g. "Acting" |
| `popularity as float` | TMDB's popularity score |
| `profilePath as string` | an image path for `profileUrl` |
| `adult as bool` | whether the person is filed as adult |

### `AggregateCrewMember`

A crew member's whole run on a series or season.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | their name |
| `originalName as string` | the name in its original script |
| `jobs as list of CreditJob` | the jobs they did |
| `department as string` | the department those jobs sit in |
| `totalEpisodeCount as int` | episodes across all their jobs |
| `gender as int` | see `genderName` |
| `knownForDepartment as string` | what they are usually credited for |
| `popularity as float` | TMDB's popularity score |
| `profilePath as string` | an image path for `profileUrl` |
| `adult as bool` | whether the person is filed as adult |

### `AggregateCredits`

Cast and crew rolled up over a whole series or season.

| field | meaning |
| --- | --- |
| `id as int` | the series or season the credits belong to |
| `cast as list of AggregateCastMember` | performers, in billing order |
| `crew as list of AggregateCrewMember` | everyone else |

### `ContentRating`

A series' age rating in one country.

| field | meaning |
| --- | --- |
| `region as string` | the two-letter country code |
| `rating as string` | the rating in that country's system, e.g. "TV-MA" |
| `descriptors as list of string` | the content warnings behind it |

### `EpisodeGroup`

An alternative ordering of a series' episodes (DVD, production, story arc).

| field | meaning |
| --- | --- |
| `id as string` | the group id |
| `name as string` | e.g. "Aired Order", "Story Arc" |
| `description as string` | what the ordering is, often "" |
| `episodeCount as int` | how many episodes it covers |
| `groupCount as int` | how many groups (seasons, arcs) it splits into |
| `kind as int` | TMDB's `type` code for the ordering |
| `network as Network` | the network it belongs to, zeroed when none |

### `ShowBundle`

A series and ten sub-resources, fetched in one request by `showBundle`.

| field | meaning |
| --- | --- |
| `show as Show` | the series itself |
| `credits as AggregateCredits` | cast and crew, rolled up over the run |
| `images as Images` | posters, backdrops and logos |
| `videos as list of Video` | trailers, teasers and clips |
| `keywords as list of Keyword` | the subject tags |
| `externalIds as ExternalIds` | the series' ids elsewhere |
| `contentRatings as list of ContentRating` | age ratings, by country |
| `recommendations as ShowPage` | what TMDB suggests next |
| `similar as ShowPage` | series sharing genres and keywords |
| `reviews as ReviewPage` | the first page of user reviews |
| `watchOffers as list of WatchOffers` | where to watch it, by country |

## People

Guide: [People](people.md).

| function | returns | what it does |
| --- | --- | --- |
| `person(c as Client, personId as int)` | `Person` | Read a person's record. |
| `personBundle(c as Client, personId as int)` | `PersonBundle` | Read a person and three of their sub-resources in one request. |
| `personMovieCredits(c as Client, personId as int)` | `PersonCredits` | Read a person's film credits. |
| `personShowCredits(c as Client, personId as int)` | `PersonCredits` | Read a person's series credits. |
| `personCombinedCredits(c as Client, personId as int)` | `PersonCredits` | Read a person's whole filmography, films and series together. |
| `personImages(c as Client, personId as int)` | `Images` | Read a person's profile photographs. |
| `personExternalIds(c as Client, personId as int)` | `ExternalIds` | Read a person's ids and social media handles elsewhere. |
| `popularPeople(c as Client, page as int)` | `PersonPage` | Read the most popular people. |
| `latestPerson(c as Client)` | `Person` | Read the person most recently added to TMDB. |
| `creditsInDepartment(credits as PersonCredits, department as string)` | `list of PersonCredit` | The crew credits a person has in one department. |

### `Person`

A person's full record, as `/person/{id}` answers it.

| field | meaning |
| --- | --- |
| `id as int` | the person id |
| `name as string` | the name TMDB files them under |
| `alsoKnownAs as list of string` | every alias and transliteration |
| `biography as string` | the biography, in the client's language |
| `birthday as string` | `YYYY-MM-DD`, "" when unknown |
| `deathday as string` | `YYYY-MM-DD`, "" when they are alive or unknown |
| `placeOfBirth as string` | free text, "" when unknown |
| `gender as int` | see `genderName` |
| `knownForDepartment as string` | e.g. "Acting", "Directing" |
| `homepage as string` | the official site, "" when there is none |
| `imdbId as string` | e.g. "nm0000158", "" when not cross-referenced |
| `profilePath as string` | an image path for `profileUrl` |
| `popularity as float` | TMDB's popularity score |
| `adult as bool` | whether the person is filed as adult |

### `PersonCredit`

One title on a person's filmography, with the person's role in it.

| field | meaning |
| --- | --- |
| `kind as MediaKind` | `Movie` or `Show` |
| `id as int` | the title's id, in the id space of `kind` |
| `title as string` | `title` for a film, `name` for a series |
| `originalTitle as string` | the same, in the original language |
| `character as string` | who they played, "" on a crew credit |
| `job as string` | the job they did, "" on a cast credit |
| `department as string` | the department that job sits in |
| `creditId as string` | the credit's own id, for `credit` |
| `order as int` | billing order on a cast credit, 0 when not billed |
| `episodeCount as int` | episodes they appear in, series credits only |
| `overview as string` | the title's synopsis |
| `releaseDate as string` | `release_date` or `first_air_date` |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `genreIds as list of int` | the title's genre ids |
| `originalLanguage as string` | an ISO 639-1 code |
| `popularity as float` | TMDB's popularity score |
| `voteAverage as float` | the mean user rating, 0 to 10 |
| `voteCount as int` | how many ratings that mean is over |
| `adult as bool` | whether the title is adult |

### `PersonCredits`

A person's filmography, split into cast and crew credits.

| field | meaning |
| --- | --- |
| `id as int` | the person the credits belong to |
| `cast as list of PersonCredit` | titles they performed in |
| `crew as list of PersonCredit` | titles they worked on |

### `PersonBundle`

A person and three sub-resources, fetched in one request by `personBundle`.

| field | meaning |
| --- | --- |
| `person as Person` | the person themselves |
| `credits as PersonCredits` | their whole filmography, films and series |
| `images as Images` | their profile photographs |
| `externalIds as ExternalIds` | their ids and handles elsewhere |

## Collections, companies, networks and lookups

Guide: [Collections, companies and lookups](catalog.md).

| constant | value | meaning |
| --- | --- | --- |
| `SOURCE_IMDB` | `"imdb_id"` | `find` source: an IMDb id, `tt0076759` for a title, `nm0000158` for a person. |
| `SOURCE_TVDB` | `"tvdb_id"` | `find` source: a TheTVDB id. |
| `SOURCE_WIKIDATA` | `"wikidata_id"` | `find` source: a Wikidata entity id, e.g. `Q17738`. |
| `SOURCE_FACEBOOK` | `"facebook_id"` | `find` source: a Facebook page or username. |
| `SOURCE_INSTAGRAM` | `"instagram_id"` | `find` source: an Instagram handle, without the `@`. |
| `SOURCE_TWITTER` | `"twitter_id"` | `find` source: an X / Twitter handle, without the `@`. |
| `SOURCE_TIKTOK` | `"tiktok_id"` | `find` source: a TikTok handle. |
| `SOURCE_YOUTUBE` | `"youtube_id"` | `find` source: a YouTube channel id. |

| function | returns | what it does |
| --- | --- | --- |
| `collection(c as Client, collectionId as int)` | `Collection` | A collection and the films in it. |
| `collectionImages(c as Client, collectionId as int)` | `Images` | A collection's posters and backdrops, in every language. |
| `collectionTranslations(c as Client, collectionId as int)` | `list of Translation` | Every translation of a collection's name and overview. |
| `company(c as Client, companyId as int)` | `CompanyDetails` | A production company's full record. |
| `companyAlternativeNames(c as Client, companyId as int)` | `list of string` | The other names a company trades under. |
| `companyImages(c as Client, companyId as int)` | `Images` | A company's logos. |
| `network(c as Client, networkId as int)` | `NetworkDetails` | A television network's full record. |
| `networkAlternativeNames(c as Client, networkId as int)` | `list of string` | The other names a network broadcasts under. |
| `networkImages(c as Client, networkId as int)` | `Images` | A network's logos. |
| `keyword(c as Client, keywordId as int)` | `Keyword` | A keyword by id. |
| `keywordMovies(c as Client, keywordId as int, page as int)` | `MoviePage` | One page of films tagged with a keyword. |
| `review(c as Client, reviewId as string)` | `Review` | One review by id. |
| `credit(c as Client, creditId as string)` | `CreditDetail` | One credit by id, from a cast or crew row's `creditId`. |
| `find(c as Client, externalId as string, source as string)` | `FindResults` | Look up TMDB records by an id on another site (IMDb, TheTVDB, Wikidata ...). |
| `findByImdb(c as Client, imdbId as string)` | `FindResults` | `find` with `SOURCE_IMDB`. |

### `CollectionSummary`

A collection's row in a search result, without its films.

| field | meaning |
| --- | --- |
| `id as int` | the collection id |
| `name as string` | the collection name, e.g. "Star Wars Collection" |
| `originalName as string` | the name in its original language |
| `overview as string` | a description, often "" |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `originalLanguage as string` | an ISO 639-1 code |
| `adult as bool` | whether the collection is adult |

### `Collection`

A collection and the films in it.

| field | meaning |
| --- | --- |
| `id as int` | the collection id |
| `name as string` | the collection name |
| `originalName as string` | the name in its original language |
| `overview as string` | a description, often "" |
| `posterPath as string` | an image path for `posterUrl` |
| `backdropPath as string` | an image path for `backdropUrl` |
| `originalLanguage as string` | an ISO 639-1 code |
| `parts as list of MediaItem` | the films, in release order |

### `CollectionPage`

One page of collections.

| field | meaning |
| --- | --- |
| `page as int` | which page this is, 1-based |
| `totalPages as int` | how many pages the query has |
| `totalResults as int` | how many collections the query has |
| `results as list of CollectionSummary` | this page's rows |

### `CompanyPage`

One page of companies.

| field | meaning |
| --- | --- |
| `page as int` | which page this is, 1-based |
| `totalPages as int` | how many pages the query has |
| `totalResults as int` | how many companies the query has |
| `results as list of Company` | this page's rows |

### `KeywordPage`

One page of keywords.

| field | meaning |
| --- | --- |
| `page as int` | which page this is, 1-based |
| `totalPages as int` | how many pages the query has |
| `totalResults as int` | how many keywords the query has |
| `results as list of Keyword` | this page's rows |

### `CompanyDetails`

A production company's full record, including its parent company.

| field | meaning |
| --- | --- |
| `id as int` | the company id |
| `name as string` | the company name |
| `description as string` | a description, usually "" |
| `headquarters as string` | the head office, free text |
| `homepage as string` | the official site, "" when there is none |
| `logoPath as string` | an image path for `logoUrl` |
| `originCountry as string` | a two-letter country code |
| `parentCompanyId as int` | the owning company, 0 when independent |
| `parentCompanyName as string` | that company's name, "" when independent |

### `NetworkDetails`

A television network's full record.

| field | meaning |
| --- | --- |
| `id as int` | the network id |
| `name as string` | the network name |
| `headquarters as string` | the head office, free text |
| `homepage as string` | the official site, "" when there is none |
| `logoPath as string` | an image path for `logoUrl` |
| `originCountry as string` | a two-letter country code |

### `CreditDetail`

One credit by id: the person, the title and the role connecting them.

| field | meaning |
| --- | --- |
| `id as string` | the credit id |
| `creditKind as string` | "cast" or "crew" |
| `department as string` | the department, on a crew credit |
| `job as string` | the job, on a crew credit |
| `character as string` | the part, on a cast credit |
| `media as MediaItem` | the title the credit is on |
| `person as PersonSummary` | the person credited |

### `FindResults`

What an external id resolved to, one list per kind.

| field | meaning |
| --- | --- |
| `movies as list of MediaItem` | films that matched |
| `shows as list of MediaItem` | series that matched |
| `people as list of MediaItem` | people that matched |
| `episodes as list of MediaItem` | episodes that matched |
| `seasons as list of MediaItem` | seasons that matched |

## Trending, genres, certifications and changes

Guide: [Trending, vocabularies and changes](browsing.md).

| constant | value | meaning |
| --- | --- | --- |
| `TREND_DAY` | `"day"` | Trending over the last 24 hours. |
| `TREND_WEEK` | `"week"` | Trending over the last 7 days. |

| function | returns | what it does |
| --- | --- | --- |
| `trendingAll(c as Client, window as string, page as int)` | `MediaPage` | One page of trending films, series and people in one ranked list. |
| `trendingMovies(c as Client, window as string, page as int)` | `MoviePage` | One page of trending films. |
| `trendingShows(c as Client, window as string, page as int)` | `ShowPage` | One page of trending series. |
| `trendingPeople(c as Client, window as string, page as int)` | `PersonPage` | One page of trending people. |
| `movieGenres(c as Client)` | `list of Genre` | The film genres, named in the client's language. |
| `showGenres(c as Client)` | `list of Genre` | The series genres, named in the client's language. |
| `movieCertifications(c as Client)` | `list of CertificationGroup` | Every country's film certification system. |
| `showCertifications(c as Client)` | `list of CertificationGroup` | Every country's series certification system. |
| `providerRegions(c as Client)` | `list of Country` | The countries TMDB has watch-provider data for. |
| `movieProviders(c as Client, watchRegion as string)` | `list of WatchProvider` | The streaming and rental services for films, in one country or all. |
| `showProviders(c as Client, watchRegion as string)` | `list of WatchProvider` | The streaming and rental services for series, in one country or all. |
| `changedMovies(c as Client, startDate as string, endDate as string, page as int)` | `ChangePage` | One page of film ids changed in a date range. |
| `changedShows(c as Client, startDate as string, endDate as string, page as int)` | `ChangePage` | One page of series ids changed in a date range; see `changedMovies`. |
| `changedPeople(c as Client, startDate as string, endDate as string, page as int)` | `ChangePage` | One page of person ids changed in a date range; see `changedMovies`. |
| `certificationsIn(groups as list of CertificationGroup, region as string)` | `list of Certification` | One country's ratings out of a certifications result; no request. |

### `Certification`

One rating in one country's certification system.

| field | meaning |
| --- | --- |
| `certification as string` | the rating, e.g. "PG-13" |
| `meaning as string` | TMDB's explanation of it |
| `order as int` | strictness rank, ascending; sort on this |

### `CertificationGroup`

One country's whole certification system.

| field | meaning |
| --- | --- |
| `region as string` | the two-letter country code |
| `certifications as list of Certification` | its ratings, in TMDB's order |

### `ChangeEntry`

One changed title or person: an id and the adult flag, nothing more.

| field | meaning |
| --- | --- |
| `id as int` | the id of the changed title or person |
| `adult as bool` | whether it is adult, so a filtered mirror can skip it |

### `ChangePage`

One page of change entries.

| field | meaning |
| --- | --- |
| `page as int` | which page this is, 1-based |
| `totalPages as int` | how many pages the feed has |
| `totalResults as int` | how many entries the feed has |
| `results as list of ChangeEntry` | this page's entries |

## User authentication (v4)

Guide: [Authenticating a user](authentication.md).

| function | returns | what it does |
| --- | --- | --- |
| `requestToken(c as Client)` | `RequestToken` | Step 1: mint a request token for a person to approve. |
| `requestTokenWithRedirect(c as Client, redirectTo as string)` | `RequestToken` | Step 1, with a URL TMDB redirects to after approval. |
| `approvalUrl(token as string)` | `string` | Step 2: the TMDB URL where a person approves a request token. |
| `accessToken(c as Client, approvedToken as string)` | `AccessToken` | Step 3: trade an approved request token for a user access token. |
| `logout(c as Client, userToken as string)` | `StatusResponse` | Invalidate a user access token at TMDB. |

### `RequestToken`

A request token waiting for a person to approve it.

| field | meaning |
| --- | --- |
| `requestToken as string` | the token to have approved |
| `success as bool` | whether TMDB issued it |
| `statusCode as int` | TMDB's status code |
| `statusMessage as string` | TMDB's status text |

### `AccessToken`

A person's user access token and v4 account id.

| field | meaning |
| --- | --- |
| `accessToken as string` | the token to pass to `withUserToken` |
| `accountId as string` | the v4 account object id the `account` verbs take, not the numeric v3 account id |
| `success as bool` | whether the trade succeeded |
| `statusCode as int` | TMDB's status code |
| `statusMessage as string` | TMDB's status text |

## Account collections (v4)

Guide: [Account collections](account.md).

| constant | value | meaning |
| --- | --- | --- |
| `ACCOUNT_SORT_ADDED_ASC` | `"created_at.asc"` | Account sort: oldest addition first. |
| `ACCOUNT_SORT_ADDED_DESC` | `"created_at.desc"` | Account sort: most recent addition first. |
| `ACCOUNT_SORT_RELEASE_ASC` | `"release_date.asc"` | Account sort: oldest title first. |
| `ACCOUNT_SORT_RELEASE_DESC` | `"release_date.desc"` | Account sort: newest title first. |
| `ACCOUNT_SORT_TITLE_ASC` | `"title.asc"` | Account sort: alphabetical. |
| `ACCOUNT_SORT_TITLE_DESC` | `"title.desc"` | Account sort: reverse alphabetical. |
| `ACCOUNT_SORT_RATING_ASC` | `"vote_average.asc"` | Account sort: worst rated first. |
| `ACCOUNT_SORT_RATING_DESC` | `"vote_average.desc"` | Account sort: best rated first. |

| function | returns | what it does |
| --- | --- | --- |
| `accountLists(c as Client, accountId as string, page as int)` | `ListPage` | One page of the custom lists an account has created. |
| `favoriteMovies(c as Client, accountId as string, page as int, sortBy as string)` | `MoviePage` | One page of an account's favourite films. |
| `favoriteShows(c as Client, accountId as string, page as int, sortBy as string)` | `ShowPage` | One page of an account's favourite series. |
| `ratedMovies(c as Client, accountId as string, page as int, sortBy as string)` | `MoviePage` | One page of the films an account has rated. |
| `ratedShows(c as Client, accountId as string, page as int, sortBy as string)` | `ShowPage` | One page of the series an account has rated. |
| `watchlistMovies(c as Client, accountId as string, page as int, sortBy as string)` | `MoviePage` | One page of an account's film watchlist. |
| `watchlistShows(c as Client, accountId as string, page as int, sortBy as string)` | `ShowPage` | One page of an account's series watchlist. |
| `recommendedMovies(c as Client, accountId as string, page as int)` | `MoviePage` | One page of films TMDB recommends to an account, from its activity. |
| `recommendedShows(c as Client, accountId as string, page as int)` | `ShowPage` | One page of series TMDB recommends to an account, from its activity. |

### `ListSummary`

A custom list's row in an account's list index, without its items.

| field | meaning |
| --- | --- |
| `id as int` | the list id the `userlists` verbs take |
| `name as string` | the list's name |
| `description as string` | the list's description, often "" |
| `accountObjectId as string` | the owner's v4 account object id |
| `public as bool` | whether anyone can read it |
| `adult as bool` | whether it is flagged adult |
| `featured as bool` | whether TMDB features it |
| `numberOfItems as int` | how many titles are in it |
| `averageRating as float` | the mean rating of its titles |
| `revenue as int` | the combined box office of its films |
| `runtime as int` | the combined runtime of its titles, in minutes |
| `region as string` | the list's ISO 3166-1 country |
| `language as string` | the list's ISO 639-1 language |
| `sortBy as int` | TMDB's numeric code for the list's own ordering |
| `createdAt as string` | an ISO 8601 timestamp |
| `updatedAt as string` | an ISO 8601 timestamp |

### `ListPage`

One page of an account's custom lists.

| field | meaning |
| --- | --- |
| `page as int` | which page this is, 1-based |
| `totalPages as int` | how many pages of lists there are |
| `totalResults as int` | how many lists the account has |
| `results as list of ListSummary` | this page's lists |

## Custom lists (v4)

Guide: [Custom lists](lists.md).

| constant | value | meaning |
| --- | --- | --- |
| `LIST_SORT_ORIGINAL_ASC` | `"original_order.asc"` | List sort: the order items were added, oldest first. |
| `LIST_SORT_ORIGINAL_DESC` | `"original_order.desc"` | List sort: the order items were added, newest first. |
| `LIST_SORT_RATING_ASC` | `"vote_average.asc"` | List sort: worst rated first. |
| `LIST_SORT_RATING_DESC` | `"vote_average.desc"` | List sort: best rated first. |
| `LIST_SORT_RELEASE_ASC` | `"primary_release_date.asc"` | List sort: oldest title first. |
| `LIST_SORT_RELEASE_DESC` | `"primary_release_date.desc"` | List sort: newest title first. |
| `LIST_SORT_TITLE_ASC` | `"title.asc"` | List sort: alphabetical. |
| `LIST_SORT_TITLE_DESC` | `"title.desc"` | List sort: reverse alphabetical. |

| function | returns | what it does |
| --- | --- | --- |
| `listItem(kind as MediaKind, id as int)` | `ListItem` | Build a `ListItem`, checking the kind and id. |
| `createList(c as Client, name as string, description as string, isPublic as bool)` | `StatusResponse` | Create a custom list (writes). |
| `createListIn(c as Client, name as string, description as string, isPublic as bool, language as string, region as string)` | `StatusResponse` | Create a custom list with its own language and country (writes). |
| `listDetails(c as Client, listId as int, page as int)` | `ListDetails` | A list's metadata and one page of its items. |
| `updateList(c as Client, listId as int, name as string, description as string, isPublic as bool, sortBy as string)` | `StatusResponse` | Replace a list's name, description, visibility and sort order (writes). |
| `deleteList(c as Client, listId as int)` | `StatusResponse` | Delete a list (writes). |
| `clearList(c as Client, listId as int)` | `StatusResponse` | Remove every item from a list, keeping the list (writes). |
| `addListItems(c as Client, listId as int, items as list of ListItem)` | `ItemsResponse` | Add titles to a list in one request (writes). |
| `removeListItems(c as Client, listId as int, items as list of ListItem)` | `ItemsResponse` | Remove titles from a list in one request (writes). |
| `listItemStatus(c as Client, listId as int, kind as MediaKind, mediaId as int)` | `ItemStatus` | Whether one title is in a list, without paging through it. |
| `listItemsAll(c as Client, listId as int, maxPages as int)` | `list of MediaItem` | Every item in a list, fetched page by page up to a budget. |

### `ListItem`

A title to add to or remove from a list: a kind and an id.

| field | meaning |
| --- | --- |
| `kind as MediaKind` | `MediaKind.Movie` or `MediaKind.Show` |
| `id as int` | the title's id in that catalogue |

### `ListDetails`

A custom list's metadata and one page of its items.

| field | meaning |
| --- | --- |
| `id as int` | the list id |
| `name as string` | the list's name |
| `description as string` | the list's description, often "" |
| `public as bool` | whether anyone can read it |
| `sortBy as string` | the list's own ordering, a `LIST_SORT_*` value |
| `region as string` | the list's ISO 3166-1 country |
| `language as string` | the list's ISO 639-1 language |
| `itemCount as int` | how many titles the list holds in total |
| `averageRating as float` | the mean rating of its titles |
| `revenue as int` | the combined box office of its films |
| `runtime as int` | the combined runtime of its titles, in minutes |
| `posterPath as string` | an image path for `posterUrl`, "" when unset |
| `backdropPath as string` | an image path for `backdropUrl`, "" when unset |
| `createdByName as string` | the owner's display name |
| `createdByUsername as string` | the owner's TMDB username |
| `page as int` | which page of items this is |
| `totalPages as int` | how many pages of items there are |
| `totalResults as int` | how many items there are |
| `results as list of MediaItem` | this page's items |

### `ItemOutcome`

What happened to one item in a bulk add or remove.

| field | meaning |
| --- | --- |
| `kind as MediaKind` | the item's kind |
| `id as int` | the item's id |
| `success as bool` | whether that item was added or removed |

### `ItemsResponse`

TMDB's answer to a bulk add or remove, with one outcome per item.

| field | meaning |
| --- | --- |
| `success as bool` | whether the request as a whole succeeded |
| `statusCode as int` | TMDB's status code |
| `statusMessage as string` | TMDB's status text |
| `results as list of ItemOutcome` | what happened to each item |

### `ItemStatus`

Whether one title is in a list, from `listItemStatus`.

| field | meaning |
| --- | --- |
| `success as bool` | true when the title is in the list |
| `listId as int` | the list that was checked |
| `mediaId as int` | the title that was checked |
| `kind as MediaKind` | that title's kind |
| `statusCode as int` | TMDB's status code |
| `statusMessage as string` | TMDB's status text |
