# Images and videos

TMDB returns image *paths* (`/6FfCtAuVAW8XJjZ7eWeLibRLWTw.jpg`), not URLs. A
URL is a CDN host, a size and the path; the host and the valid sizes come from
`/configuration` and can change.

```jennifer
def cfg as tmdb.Configuration init tmdb.configuration($c);
def film as tmdb.Movie init tmdb.movie($c, 550);

io.printf("%s\n", tmdb.posterUrl($cfg, $film.posterPath, "w500"));
# https://image.tmdb.org/t/p/w500/pB8BM7pdSp6B6Ih7QZ4DrQ3PmJK.jpg
```

## The configuration

Fetch it once at start-up and keep it; it rarely changes.
`tmdb.defaultConfiguration()` is a built-in snapshot of the documented
configuration, needing no request, for scripts, tests or a first paint. A
long-running program should use the live one.

```jennifer
def cfg as tmdb.Configuration init tmdb.defaultConfiguration();
```

## Sizes per kind

Each kind has its own size list, and each builder checks against it:

| builder | takes | sizes in the snapshot |
| --- | --- | --- |
| `tmdb.posterUrl` | `posterPath` | `w92 w154 w185 w342 w500 w780 original` |
| `tmdb.backdropUrl` | `backdropPath` | `w300 w780 w1280 original` |
| `tmdb.profileUrl` | `profilePath` | `w45 w185 h632 original` |
| `tmdb.stillUrl` | `stillPath` | `w92 w185 w300 original` |
| `tmdb.logoUrl` | `logoPath` | `w45 w92 w154 w185 w300 w500 original` |

`tmdb.SIZE_ORIGINAL` is in every list, but in a listing it can mean several
megabytes per row. A size missing from the kind's list throws, naming the
valid ones:

```jennifer
tmdb.profileUrl($cfg, "/x.jpg", "w342");
# Error{kind: "tmdb"}: "w342" is not a profile size - the configuration
# offers w45, w185, h632, original
```

`tmdb.imageUrl` accepts a size from any of the five lists, for when the kind
is not known.

## Empty and unsafe paths

Every builder returns `""` for an empty path (TMDB's `null` for "no image"):

```jennifer
def url as string init tmdb.posterUrl($cfg, $m.posterPath, "w342");
if ($url == "") {
    $url = "/static/no-poster.svg";
}
```

A path carrying a scheme, a `..` segment, a query string or whitespace throws,
so a caller-supplied string cannot point the URL at another host.

## Choosing among images

An images verb returns every version TMDB holds, ordered by user rating. Each
`Image.language` is the language of the text in the image, `""` for none:

```jennifer
def images as tmdb.Images init tmdb.movieImages($c, 550);

for (def poster in $images.posters) {
    io.printf("%-4s %.1f (%d votes)  %dx%d  %s\n",
        $poster.language,
        $poster.voteAverage,
        $poster.voteCount,
        $poster.width,
        $poster.height,
        tmdb.posterUrl($cfg, $poster.filePath, "w185"));
}
```

The images verbs send no `language`, so every localized version comes back.
`Images.logos` holds the transparent title treatments. Which lists are filled
depends on the record: a film has backdrops, posters and logos, an episode
stills, a person profiles; the rest are empty.

## Videos

A `Video` is a `site` and a `key`. `tmdb.videoUrl` builds the link for YouTube
and Vimeo and returns `""` for any other site or an empty key.
`tmdb.videoThumbnailUrl` works for YouTube only (`hqdefault.jpg`); a Vimeo
thumbnail needs a call to Vimeo's API.

```jennifer
for (def v in tmdb.movieVideos($c, 550)) {
    if ($v.kind == "Trailer" and $v.official) {
        io.printf("%-40s %s\n", $v.name, tmdb.videoUrl($v));
        io.printf("  %s\n", tmdb.videoThumbnailUrl($v));
    }
}
```

`Video.kind` is TMDB's `type`: `"Trailer"`, `"Teaser"`, `"Clip"`,
`"Featurette"`, `"Behind the Scenes"`, `"Bloopers"`.

## Other configuration endpoints

```jennifer
for (def country in tmdb.countries($c)) {
    io.printf("%s %s (%s)\n", $country.code, $country.englishName, $country.nativeName);
}

for (def lang in tmdb.languages($c)) {
    io.printf("%s %s\n", $lang.code, $lang.englishName);
}

for (def tag in tmdb.primaryTranslations($c)) {
    io.printf("%s\n", $tag);     # "de-DE", "pt-BR", ...
}

for (def d in tmdb.jobs($c)) {
    io.printf("%s: %s\n", $d.department, strings.join($d.jobs, ", "));
}

for (def z in tmdb.timezones($c)) {
    io.printf("%s %s\n", $z.code, strings.join($z.zones, ", "));
}
```

- `countries` and `languages` decode every `iso_3166_1` and `iso_639_1` in
  the API.
- `primaryTranslations` lists the tags that return translated text; offer
  these in a language picker rather than `languages`.
- `jobs` is the vocabulary of `CrewMember.job`, which `tmdb.crewNamed`
  matches.
- `timezones` lists the zone names `tmdb.airingTodayIn` takes.
