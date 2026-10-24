# People

## One person

```jennifer
def p as tmdb.Person init tmdb.person($c, 31);

io.printf("%s (%s)\n", $p.name, tmdb.genderName($p.gender));
io.printf("born %s in %s\n", $p.birthday, $p.placeOfBirth);
io.printf("known for %s\n", $p.knownForDepartment);
io.printf("%s\n", $p.biography);
```

`deathday` is `""` for the living and when TMDB has no date. `gender` is
TMDB's code: `0` unknown, `1` female, `2` male, `3` non-binary;
`tmdb.genderName` turns it into `"unknown"`, `"female"`, `"male"` or
`"non-binary"`.

## Filmography

In a person's credits each row is a title, carrying the role that connects it
to the person:

```jennifer
def credits as tmdb.PersonCredits init tmdb.personCombinedCredits($c, 31);

for (def role in $credits.cast) {
    io.printf("%-40s %-24s %s\n",
        $role.title, $role.character, tmdb.year($role.releaseDate));
}
```

| verb | covers |
| --- | --- |
| `tmdb.personMovieCredits` | films |
| `tmdb.personShowCredits` | series |
| `tmdb.personCombinedCredits` | both; each row carries its `kind` |

A `PersonCredit` fills `title` from `title` or `name` and `releaseDate` from
`release_date` or `first_air_date`. A `cast` row has `character`; a `crew` row
has `job` and `department`. Someone who directed and wrote a film appears
twice in `crew`, once per job. `episodeCount` is filled for series only.

`creditsInDepartment` keeps the crew credits of one department (matched
case-insensitively). It never returns cast credits, so `"Acting"` gives an
empty list; use `credits.cast` for that.

```jennifer
def p as tmdb.Person init tmdb.person($c, 525);
def credits as tmdb.PersonCredits init tmdb.personCombinedCredits($c, 525);

for (def film in tmdb.creditsInDepartment($credits, $p.knownForDepartment)) {
    io.printf("%s (%s)\n", $film.title, tmdb.year($film.releaseDate));
}
```

## The profile page in one request

`personBundle` fetches the person with combined credits, images and external
ids through `append_to_response`:

```jennifer
def b as tmdb.PersonBundle init tmdb.personBundle($c, 31);

io.printf("%s: %d acting credits, %d crew credits\n",
    $b.person.name, len($b.credits.cast), len($b.credits.crew));
io.printf("%d photographs\n", len($b.images.profiles));
io.printf("instagram: %s\n", $b.externalIds.instagramId);
```

## Photographs

`tmdb.personImages` fills `Images.profiles` only. Build a URL with
`tmdb.profileUrl` and a size from `Configuration.profileSizes`:

```jennifer
def cfg as tmdb.Configuration init tmdb.configuration($c);
for (def photo in tmdb.personImages($c, 31).profiles) {
    io.printf("%s  %dx%d\n",
        tmdb.profileUrl($cfg, $photo.filePath, "w185"), $photo.width, $photo.height);
}
```

## External ids

`tmdb.personExternalIds` returns the IMDb `nm...` id and the social handles
(Instagram, TikTok, YouTube ...). A field is `""` when TMDB has no id of that
kind, which is common for everything but `imdbId`.

```jennifer
def ids as tmdb.ExternalIds init tmdb.personExternalIds($c, 31);
io.printf("imdb.com/name/%s\n", $ids.imdbId);
```

## Popularity

```jennifer
tmdb.popularPeople($c, 1);
tmdb.trendingPeople($c, tmdb.TREND_WEEK, 1);
tmdb.latestPerson($c);
```

`popularPeople` changes slowly; `trendingPeople` follows current views. See
[Trending and vocabularies](browsing.md).
