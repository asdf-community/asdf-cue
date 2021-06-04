<div align="center">

# asdf-cue ![Build](https://github.com/NeoHsu/asdf-cue/workflows/Build/badge.svg) ![Lint](https://github.com/NeoHsu/asdf-cue/workflows/Lint/badge.svg)

[cue](https://cuelang.org/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

## Build History

[![Build history](https://buildstats.info/github/chart/NeoHsu/asdf-cue?branch=master)](https://github.com/NeoHsu/asdf-cue/actions)

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Why?](#why)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities.

# Install

Plugin:

```shell
asdf plugin add cue
# or
asdf plugin add cue https://github.com/NeoHsu/asdf-cue.git
```

cue:

```shell
# Show all installable versions
asdf list-all cue

# Install specific version
asdf install cue latest

# Set a version globally (on your ~/.tool-versions file)
asdf global cue latest

# Now cue commands are available
cue version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/NeoHsu/asdf-cue/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Neo Hsu](https://github.com/NeoHsu/)

