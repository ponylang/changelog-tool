#!/bin/sh

echo_red() {
  echo -e "\x1b[31;1m$1\x1b[0m"
}

stable env ponyc -d -V1 .. -b changelog-tool

for f in bad-changelogs/*.md; do
  if ./changelog-tool verify "$f"; then
    echo_red "changelog-tool failed to catch bad changelog: $f"
    exit 1
  fi
done

rm changelog-tool
