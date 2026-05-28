# asdf-cue

[CUE](https://cuelang.org) plugin for asdf version manager

## Build History

[![Build history](https://buildstats.info/github/chart/asdf-community/asdf-cue?branch=master)](https://github.com/asdf-community/asdf-cue/actions)

## Installation

```bash
asdf plugin add cue https://github.com/asdf-community/asdf-cue.git
```

## Usage

```bash
# Show all installable release versions
asdf list all cue

# Install the latest stable CUE release
asdf install cue latest

# Set a version for your user
asdf set -u cue latest

# Install a specific release, including prereleases
asdf install cue 0.16.1
asdf install cue 0.17.0-alpha.1
```

`latest` resolves to the newest stable GitHub release. `asdf list all cue`
lists GitHub releases rather than all Git tags, so development tags without
downloadable release assets are not shown as installable versions.

On macOS arm64, older CUE releases that do not provide a native arm64 archive
fall back to the darwin amd64 archive. Rosetta 2 is required for those older
versions.

Check [asdf](https://github.com/asdf-vm/asdf) readme for instructions on how to
install & manage versions.

## License

Licensed under the
[Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).
