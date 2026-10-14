#!/bin/sh
# Puts the database at RDB_URL in /data/dump.rdb before Redis starts; a no-op when
# RDB_URL is unset.
#
# The URL last fetched is kept in dump.rdb.url, so a new RDB_URL fetches anew. RDB_SHA256,
# when set, must match the download and is checked against the database in place. A
# download replaces dump.rdb only once it is complete and verified.

set -eu

[ -n "${RDB_URL:-}" ] || exit 0
rdb=/data/dump.rdb

digest() {
  sha256sum "$1" | cut -d' ' -f1
}

if [ -f "$rdb" ] && [ "$(cat "$rdb.url" 2>/dev/null)" = "$RDB_URL" ] &&
  { [ -z "${RDB_SHA256:-}" ] || [ "$(digest "$rdb")" = "$RDB_SHA256" ]; }; then
  echo "$rdb is current with $RDB_URL"
  exit 0
fi

echo "fetching $RDB_URL"
curl -fsSL --retry 3 -o "$rdb.part" "$RDB_URL"
if [ -n "${RDB_SHA256:-}" ] && [ "$(digest "$rdb.part")" != "$RDB_SHA256" ]; then
  rm -f "$rdb.part"
  echo "$RDB_URL does not match RDB_SHA256" >&2
  exit 1
fi
mv "$rdb.part" "$rdb"
echo "$RDB_URL" > "$rdb.url"
echo "fetched $rdb"
