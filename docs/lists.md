# Custom lists

Custom lists are the only part of TMDB this deck **writes**. Reading a public
list needs only the application token (`listDetails`, `listItemsAll`,
`listItemStatus`); every other verb here needs the owner's user access token
(see [Authenticating a user](authentication.md)).

A list holds films and series. An item is a `MediaKind` and an id, because
`550` is both a film and a series.

## Create

```jennifer
def made as tmdb.StatusResponse init tmdb.createList($c, "Rewatch", "worth a second look", false);
def listId as int init $made.id;
io.printf("created list %d\n", $listId);
```

The new list's id is `StatusResponse.id`; every other verb takes it.

`createListIn` also sets the list's language and country, which decide the
translation of its titles on TMDB's website for every reader. The language is
sent lowercased, the country uppercased; `""` leaves either at the account's
default.

```jennifer
tmdb.createListIn($c, "Wiedersehen", "", true, "de", "DE");
```

## Read

```jennifer
def l as tmdb.ListDetails init tmdb.listDetails($c, $listId, 1);

io.printf("%s by %s - %d items, %.1f average\n",
    $l.name, $l.createdByUsername, $l.itemCount, $l.averageRating);

for (def item in $l.results) {
    io.printf("  %-8s %s (%s)\n",
        tmdb.mediaKindName($item.kind), $item.title, tmdb.year($item.releaseDate));
}
```

The reply is the list's metadata and one page of 20 items; `itemCount` is the
total. `listItemsAll` fetches page after page up to a budget:

```jennifer
def all as list of tmdb.MediaItem init tmdb.listItemsAll($c, $listId, 10);
```

## Add and remove

One request adds or removes any number of items:

```jennifer
def added as tmdb.ItemsResponse init tmdb.addListItems($c, $listId, [
    tmdb.listItem(tmdb.MediaKind.Movie, 550),
    tmdb.listItem(tmdb.MediaKind.Movie, 680),
    tmdb.listItem(tmdb.MediaKind.Show, 1399)]);

for (def outcome in $added.results) {
    io.printf("%-6s %7d %t\n",
        tmdb.mediaKindName($outcome.kind), $outcome.id, $outcome.success);
}

tmdb.removeListItems($c, $listId, [tmdb.listItem(tmdb.MediaKind.Movie, 680)]);
```

`ItemsResponse.success` is the request's outcome and `results[i].success` each
item's: a request can succeed while some items fail, for example because they
are already in the list.

`listItem` throws for any kind but `Movie` and `Show`, where TMDB would answer
`422` without a reason:

```jennifer
tmdb.listItem(tmdb.MediaKind.Person, 31);
# Error{kind: "tmdb"}: a list holds films and series - MediaKind.Movie or
# MediaKind.Show, not "person"
```

## Checking for one title

`listItemStatus` checks one title without paging through the list:

```jennifer
def present as tmdb.ItemStatus init tmdb.listItemStatus(
    $c, $listId, tmdb.MediaKind.Movie, 550);

if (not $present.success) {
    tmdb.addListItems($c, $listId, [tmdb.listItem(tmdb.MediaKind.Movie, 550)]);
}
```

## Edit

`updateList` always sends the name, description and visibility, so pass the
current values of the ones you keep. The sort order is left alone when `""`.

```jennifer
def l as tmdb.ListDetails init tmdb.listDetails($c, $listId, 1);
tmdb.updateList($c, $listId, $l.name, "a better description", true, tmdb.LIST_SORT_RELEASE_DESC);
```

| constant | orders by |
| --- | --- |
| `tmdb.LIST_SORT_ORIGINAL_ASC`, `tmdb.LIST_SORT_ORIGINAL_DESC` | the order items were added |
| `tmdb.LIST_SORT_RATING_ASC`, `tmdb.LIST_SORT_RATING_DESC` | the title's mean rating |
| `tmdb.LIST_SORT_RELEASE_ASC`, `tmdb.LIST_SORT_RELEASE_DESC` | the title's release date |
| `tmdb.LIST_SORT_TITLE_ASC`, `tmdb.LIST_SORT_TITLE_DESC` | title |

## Clear and delete

```jennifer
tmdb.clearList($c, $listId);    # keeps the list, removes every item
tmdb.deleteList($c, $listId);   # irreversible, with no confirmation
```

TMDB defines `clearList` as a `GET` on `/4/list/{id}/clear`, so a layer that
prefetches or replays GET requests can trigger it.

## Example

Create a list and fill it from a discovery query:

```jennifer
def made as tmdb.StatusResponse init tmdb.createList($c, "Korean thrillers", "", false);
def listId as int init $made.id;

def f as tmdb.DiscoverFilter init tmdb.sortedBy(
    tmdb.withMinVotes(
        tmdb.fromCountry(tmdb.withGenres(tmdb.discoverFilter(), [53]), "KR"), 500),
    tmdb.SORT_RATING_DESC);

def items as list of tmdb.ListItem init [];
for (def m in tmdb.discoverMovies($c, $f, 1).results) {
    $items[] = tmdb.listItem(tmdb.MediaKind.Movie, $m.id);
}
tmdb.addListItems($c, $listId, $items);

def l as tmdb.ListDetails init tmdb.listDetails($c, $listId, 1);
io.printf("%s now holds %d titles\n", $l.name, $l.itemCount);
```
