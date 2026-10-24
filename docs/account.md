# Account collections

These verbs need a client with a user access token and the v4 account object
id returned with it; see [Authenticating a user](authentication.md).

```jennifer
def id as string init $granted.accountId;   # "4bc8892a017a3c0f92000002"

def favourites as tmdb.MoviePage init tmdb.favoriteMovies($c, $id, 1, "");
def watchlist as tmdb.MoviePage init tmdb.watchlistMovies($c, $id, 1, "");
def rated as tmdb.MoviePage init tmdb.ratedMovies($c, $id, 1, "");
def suggested as tmdb.MoviePage init tmdb.recommendedMovies($c, $id, 1);
```

The series counterparts are `favoriteShows`, `watchlistShows`, `ratedShows`
and `recommendedShows`. All return an ordinary `MoviePage` or `ShowPage`.

## The account id

An all-digit id is the numeric v3 account id, which the v4 endpoints answer
with a 404. It throws before the request:

```jennifer
tmdb.favoriteMovies($c, "548", 1, "");
# Error{kind: "tmdb"}: "548" is the numeric v3 account id; v4 wants the
# account *object* id, the hex string that came back with the access token
# (AccessToken.accountId)
```

## Sorting

Favourites, ratings and watchlists take a sort order; `""` is TMDB's default.

| constant | orders by |
| --- | --- |
| `tmdb.ACCOUNT_SORT_ADDED_ASC`, `tmdb.ACCOUNT_SORT_ADDED_DESC` | when it was added |
| `tmdb.ACCOUNT_SORT_RELEASE_ASC`, `tmdb.ACCOUNT_SORT_RELEASE_DESC` | the title's release date |
| `tmdb.ACCOUNT_SORT_TITLE_ASC`, `tmdb.ACCOUNT_SORT_TITLE_DESC` | title |
| `tmdb.ACCOUNT_SORT_RATING_ASC`, `tmdb.ACCOUNT_SORT_RATING_DESC` | the title's mean rating |

```jennifer
tmdb.watchlistMovies($c, $id, 1, tmdb.ACCOUNT_SORT_ADDED_DESC);
```

Any other string throws. The recommendation verbs take no sort.

## Recommendations

`recommendedMovies` is computed from everything the account has rated,
favourited and listed; `movieRecommendations` starts from one title.

```jennifer
for (def m in tmdb.recommendedMovies($c, $id, 1).results) {
    io.printf("%.1f  %s (%s)\n", $m.voteAverage, $m.title, tmdb.year($m.releaseDate));
}
```

## The account's lists

```jennifer
for (def l in tmdb.accountLists($c, $id, 1).results) {
    io.printf("%7d  %-28s %3d items  public=%t\n",
        $l.id, $l.name, $l.numberOfItems, $l.public);
}
```

A `ListSummary` has the item count but no items; `tmdb.listDetails` fetches
them (see [Custom lists](lists.md)). The v4 list rows write booleans as `1` /
`0` and revenue as a string; the fold reads them as `bool` and `int`.

## Paging

The account collections page like any other result; `tmdb.morePages` is the
loop condition:

```jennifer
def page as int init 1;
def batch as tmdb.MoviePage init tmdb.watchlistMovies($c, $id, $page, "");
def all as list of tmdb.MovieSummary init [];

while (true) {
    for (def m in $batch.results) {
        $all[] = $m;
    }
    if (not tmdb.morePages($batch.page, $batch.totalPages)) {
        break;
    }
    $page = $page + 1;
    $batch = tmdb.watchlistMovies($c, $id, $page, "");
}
```

## Not covered

Adding to favourites, ratings and watchlists are v3 endpoints that need a v3
`session_id`, from a separate authentication flow this deck does not
implement. `tmdb.callPost` cannot send one either, because it takes no query
parameters and refuses a path containing `?`. Custom lists are the v4
equivalent and are fully covered; see [Custom lists](lists.md).
