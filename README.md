# changelog-tool
Tool for modifying the ponyc changelog

## Installation
The changelog-tool requires [pony-stable](https://github.com/ponylang/pony-stable) to be installed.

```bash
git clone https://github.com/ponylang/changelog-tool
cd changelog-tool
make
sudo make install
```

## Verify a Changelog
```bash
changelog-tool verify CHANGELOG.md 
```
```
verifying CHANGELOG.md...
CHANGELOG.md is a valid changelog
```

## Prepare a Changelog for a Release
CHANGELOG.md:
```markdown
# Change Log

All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed



### Added

- We are only adding things on this release

### Changed



```

```bash
changelog-tool release CHANGELOG.md 0.13.1
# The changelog-tool release command prints the new changelog to standard output
# -e should be used to modify the file in changelog file.
```

```
# Change Log

All notable changes to the Pony compiler and standard library will be documented in this file. This project adheres to [Semantic Versioning](http://semver.org/) and [Keep a CHANGELOG](http://keepachangelog.com/).

## [unreleased] - unreleased

### Fixed



### Added



### Changed



## [0.13.1] - 2017-04-14

### Added

- We are only adding things on this release

```

Note that a new unreleased area has been added to the top of the changelog and only the `Added` section of the previous unreleased area has been included in the 0.13.1 release since the other two sections had no entries.
