# Collections, companies and lookups

The records films and series point at. Each has its own id space.

## Collections

A collection is a franchise box set (*Star Wars Collection*).

```jennifer
def set as tmdb.Collection init tmdb.collection($c, 10);

io.printf("%s - %d films\n", $set.name, len($set.parts));
for (def part in $set.parts) {
    io.printf("  %s (%s)\n", $part.title, tmdb.year($part.releaseDate));
}
```

`parts` is in TMDB's order, which is release order, not story order: the
*Star Wars* collection starts at Episode IV.

Reach one from a film or by search:

```jennifer
def film as tmdb.Movie init tmdb.movie($c, 11);
if ($film.belongsToCollection.id != 0) {
    tmdb.collection($c, $film.belongsToCollection.id);
}

tmdb.searchCollections($c, "lord of the rings", 1);
```

`tmdb.collectionImages` and `tmdb.collectionTranslations` return its artwork
and translations.

## Companies

```jennifer
def studio as tmdb.CompanyDetails init tmdb.company($c, 41077);
io.printf("%s, %s\n", $studio.name, $studio.headquarters);
io.printf("%s\n", $studio.homepage);

tmdb.companyAlternativeNames($c, 41077);   # other trading names
tmdb.companyImages($c, 41077);             # logos, in Images.logos
```

`parentCompanyId` links a studio to its parent (Marvel Studios to Disney) and
is `0` for an independent. Company ids are what discovery's `withCompanies`
takes; find them with `tmdb.searchCompanies`.

## Networks

Networks have the same shape as companies but a separate id space: network 49
is HBO, company 49 is not.

```jennifer
def n as tmdb.NetworkDetails init tmdb.network($c, 49);
tmdb.networkAlternativeNames($c, 49);
tmdb.networkImages($c, 49);
```

Network ids come from a series' `networks` field and are what discovery's
`withNetworks` takes.

## Keywords

```jennifer
def tags as tmdb.KeywordPage init tmdb.searchKeywords($c, "time loop", 1);
def one as tmdb.Keyword init tmdb.keyword($c, $tags.results[0].id);
def films as tmdb.MoviePage init tmdb.keywordMovies($c, $one.id, 1);
```

`discoverMovies` with `withKeywords` returns the same films and combines with
other criteria.

## Reviews

A review fetched by id has `mediaId`, `mediaTitle` and `mediaKind` filled;
a review from a title's `reviews` page does not. `content` is Markdown.

```jennifer
def r as tmdb.Review init tmdb.review($c, "60d3672d3cc0e0007e6b1c0d");
io.printf("%s on %s: %.1f/10\n", $r.author, $r.mediaTitle, $r.rating);
io.printf("%s\n", $r.content);
```

## Credits

Every cast and crew row has a `creditId`; `tmdb.credit` resolves it to the
person, the title and the role:

```jennifer
def credits as tmdb.Credits init tmdb.movieCredits($c, 550);
def one as tmdb.CreditDetail init tmdb.credit($c, $credits.cast[0].creditId);

io.printf("%s played %s in %s\n",
    $one.person.name, $one.character, $one.media.title);
```

## Finding a TMDB record by an outside id

`tmdb.find` looks up an IMDb, TheTVDB, Wikidata or social-media id:

```jennifer
def hits as tmdb.FindResults init tmdb.findByImdb($c, "tt0903747");
io.printf("%s\n", $hits.shows[0].title);        # Breaking Bad

def person as tmdb.FindResults init tmdb.findByImdb($c, "nm0000158");
io.printf("%s\n", $person.people[0].title);     # Tom Hanks
```

All five lists (`movies`, `shows`, `people`, `episodes`, `seasons`) come back;
usually one is non-empty.

```jennifer
tmdb.find($c, "121361", tmdb.SOURCE_TVDB);
tmdb.find($c, "Q190050", tmdb.SOURCE_WIKIDATA);
tmdb.find($c, "tomhanks", tmdb.SOURCE_INSTAGRAM);
```

The sources are `SOURCE_IMDB`, `SOURCE_TVDB`, `SOURCE_WIKIDATA`,
`SOURCE_FACEBOOK`, `SOURCE_INSTAGRAM`, `SOURCE_TWITTER`, `SOURCE_TIKTOK` and
`SOURCE_YOUTUBE`; TMDB's retired `freebase_mid`, `freebase_id` and
`tvrage_id` are also accepted. Any other source throws.

The reverse lookup is `movieExternalIds`, `showExternalIds` or
`personExternalIds`.
