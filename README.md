# changelog-tool

A tool for modifying the "standard pony" changelogs.

## Status

Production ready.

## Installation

### Ponyup

You can use [`ponyup`](https://github.com/ponylang/ponyup#installing-ponyup), our toolchain multiplexer, to download `nighly` builds, if you're using Linux. Other platforms require building from source.

Linux:

```bash
ponyup update changelog-tool nightly
```

### Building From Source

You will need `ponyc` in your PATH.

```bash
git clone https://github.com/ponylang/changelog-tool
cd changelog-tool
make
sudo make install
```

## Create a Changelog

```bash
changelog-tool new
```

## Verify a Changelog

```bash
changelog-tool verify
```

```text
CHANGELOG.md is a valid changelog.
```

## Print a single release changelog

```bash
changelog-tool get 0.2.2
```

```markdown
## [0.2.2] - 2018-01-16

### Added

- Many prior version. This was added as first entry in CHANGELOG when it was added to this project.

```

## Add an unreleased section

```bash
changelog-tool unreleased -e
```

## Add an entry to an unreleased section

```bash
changelog-tool add fixed 'We fixed some bad issues' -e
changelog-tool add added 'We just added some new cool stuff' -e
changelog-tool add changed 'And changed things a bit' -e
```

## Prepare a Changelog for a Release

```bash
changelog-tool release 0.13.1
# The changelog-tool release command prints the new changelog to standard output
# -e should be used to modify the changelog file.
```

Example CHANGELOG.md (before):

```markdown
# Change Log

All notable changes to this project will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed



### Added

- We are only adding things on this release

### Changed



```

Example CHANGELOG.md (after):

```markdown
# Change Log

All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [0.13.1] - 2017-04-14

### Added

- We are only adding things on this release

```

Note that a new unreleased area has been added to the top of the changelog and only the `Added` section of the previous unreleased area has been included in the 0.13.1 release since the other two sections had no entries.
