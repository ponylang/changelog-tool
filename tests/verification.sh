#!/bin/sh

echo_red() {
  printf "\x1b[31;1m%s\x1b[0m\n" "$1"
}

echo_green() {
  printf "\x1b[32;1m%s\x1b[0m\n" "$1"
}

corral run -- ponyc -d -V1 ../changelog-tool -b changelog-tool

for f in bad-changelogs/*.md; do
  if ./changelog-tool verify -f="$f"; then
    echo_red "changelog-tool failed to catch bad changelog: $f"
    exit 1
  fi
done

rm changelog-tool

printf "\n"
echo_green "All verification tests have passed."
printf "\n"
