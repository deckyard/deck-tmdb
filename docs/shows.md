# Series, seasons and episodes

TMDB's `tv` catalogue is called *shows* in this deck; the wire still says
`tv`. Seasons and episodes are addressed by number under their series, not by
ids of their own:

```jennifer
def s as tmdb.Show init tmdb.show($c, 1399);
def one as tmdb.Season init tmdb.season($c, 1399, 1);
def first as tmdb.Episode init tmdb.episode($c, 1399, 1, 1);
```

Season 0 holds the specials, so a season or episode number of 0 is legal;
negative numbers throw.

## One series

```jennifer
def s as tmdb.Show init tmdb.show($c, 1399);

io.printf("%s (%s-%s)\n", $s.name, tmdb.year($s.firstAirDate), tmdb.year($s.lastAirDate));
io.printf("%s, %d seasons, %d episodes\n", $s.status, $s.numberOfSeasons, $s.numberOfEpisodes);
io.printf("on %s\n", $s.networks[0].name);

if ($s.inProduction and $s.nextEpisodeToAir.id != 0) {
    io.printf("next: %dx%02d %s on %s\n",
        $s.nextEpisodeToAir.seasonNumber,
        $s.nextEpisodeToAir.episodeNumber,
        $s.nextEpisodeToAir.name,
        $s.nextEpisodeToAir.airDate);
}
```

`lastEpisodeToAir` and `nextEpisodeToAir` are `Episode` records. When TMDB
sends `null` they are zeroed, so test `id != 0`.

## Seasons

Each entry of `Show.seasons` carries the `seasonNumber` that `tmdb.season`
takes:

```jennifer
for (def entry in $s.seasons) {
    io.printf("%-12s %2d episodes  %s\n", $entry.name, $entry.episodeCount, $entry.airDate);
}
```

Season 0 is only listed when the series has specials, so `seasons[3]` is not
necessarily season 3. `seasonOf` finds a season by number and returns a zeroed
summary carrying the requested number when there is none:

```jennifer
def third as tmdb.SeasonSummary init tmdb.seasonOf($s, 3);
io.printf("%d episodes\n", $third.episodeCount);
```

A season carries its episodes:

```jennifer
def one as tmdb.Season init tmdb.season($c, 1399, 1);

for (def e in $one.episodes) {
    io.printf("%dx%02d  %-32s %s  %d min\n",
        $e.seasonNumber, $e.episodeNumber, $e.name, $e.airDate, $e.runtime);
}
```

`Episode.kind` is TMDB's `episode_type`: `"standard"`, `"finale"`,
`"mid_season"`.

## Credits and aggregate credits

`tmdb.showCredits` returns the regular cast billed for the series as a whole;
for a long-running series that is a fraction of who appeared.
`tmdb.showAggregateCredits` returns one row per person across all seasons,
with every role and its episode count:

```jennifer
for (def actor in tmdb.showAggregateCredits($c, 1399).cast) {
    io.printf("%-24s %-28s %d episodes\n",
        $actor.name, $actor.roles[0].character, $actor.totalEpisodeCount);
}
```

`roles` is a list because one performer can play several parts; crew rows
have `jobs` in the same shape. `tmdb.seasonAggregateCredits($c, 1399, 1)` does
the same for one season.

`tmdb.episodeCredits($c, 1399, 1, 1)` returns the episode's guest stars in
`cast`, after the regulars.

## The series page in one request

`showBundle` fetches the series and ten sub-resources (aggregate credits,
images, videos, keywords, external ids, content ratings, recommendations,
similar, reviews, watch providers) with `append_to_response`. The paged parts
are page 1; see [Movies](movies.md#the-detail-page-in-one-request).

```jennifer
def b as tmdb.ShowBundle init tmdb.showBundle($c, 1399);

io.printf("%s - %s\n", $b.show.name, tmdb.contentRatingOf($b.contentRatings, "US"));
io.printf("%d in the cast, %d keywords\n", len($b.credits.cast), len($b.keywords));
io.printf("TheTVDB id %d\n", $b.externalIds.tvdbId);
```

## Age ratings

Series ratings are a separate system from film certifications:

```jennifer
def ratings as list of tmdb.ContentRating init tmdb.showContentRatings($c, 1399);
io.printf("US %s, DE %s\n",
    tmdb.contentRatingOf($ratings, "US"),
    tmdb.contentRatingOf($ratings, "DE"));
```

`ContentRating.descriptors` holds the content warnings behind a rating, where
the country publishes them.

## Episode orderings

Broadcast, production, DVD and story order can differ. `showEpisodeGroups`
lists the alternative orderings:

```jennifer
for (def g in tmdb.showEpisodeGroups($c, 1399)) {
    io.printf("%-16s %d episodes in %d groups\n", $g.name, $g.episodeCount, $g.groupCount);
}
```

There is no typed verb for one ordering's contents; `EpisodeGroup.id` is a
string:

```jennifer
def ordering as json.Value init tmdb.call($c, "/3/tv/episode_group/" + $groupId, {});
```

## External ids

`ExternalIds.tvdbId` is filled for series, which matters to media servers that
index by TheTVDB:

```jennifer
tmdb.showExternalIds($c, 1399);
tmdb.seasonExternalIds($c, 1399, 1);
tmdb.episodeExternalIds($c, 1399, 1, 1);
```

`tmdb.find` goes the other way; see [Collections and lookups](catalog.md).

## Curated lists

```jennifer
tmdb.airingToday($c, 1);                            # an episode today
tmdb.airingTodayIn($c, "Europe/Berlin", 1);         # today in that time zone
tmdb.onTheAir($c, 1);                               # an episode in the next 7 days
tmdb.popularShows($c, 1);
tmdb.topRatedShows($c, 1);
tmdb.latestShow($c);
```

`airingToday` uses TMDB's own time zone for "today". `airingTodayIn` takes an
IANA zone name; `tmdb.timezones` lists them by country.

## Other sub-resources

| verb | returns |
| --- | --- |
| `tmdb.showImages` / `seasonImages` / `episodeImages` | `Images`, every language |
| `tmdb.showVideos` / `seasonVideos` / `episodeVideos` | `list of Video` |
| `tmdb.showKeywords` | `list of Keyword` |
| `tmdb.showRecommendations` / `showSimilar` | `ShowPage` |
| `tmdb.showReviews` | `ReviewPage` |
| `tmdb.showTranslations` | `list of Translation` |
| `tmdb.showAlternativeTitles` | `list of AlternativeTitle` |
| `tmdb.showWatchProviders` | `list of WatchOffers`; see `tmdb.offersIn` |
