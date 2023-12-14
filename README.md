<div align="center">

# asdf-gcc-arm-none-eabi [![Build](https://github.com/vhdirk/asdf-gcc-arm-none-eabi/actions/workflows/build.yml/badge.svg)](https://github.com/vhdirk/asdf-gcc-arm-none-eabi/actions/workflows/build.yml) [![Lint](https://github.com/vhdirk/asdf-gcc-arm-none-eabi/actions/workflows/lint.yml/badge.svg)](https://github.com/vhdirk/asdf-gcc-arm-none-eabi/actions/workflows/lint.yml)

[gcc-arm-none-eabi](https://developer.arm.com/Tools%20and%20Software/GNU%20Toolchain) plugin for the [asdf version manager](https://asdf-vm.com).
</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).

# Install

Plugin:

```shell
asdf plugin add gcc-arm-none-eabi
# or
asdf plugin add gcc-arm-none-eabi https://github.com/vhdirk/asdf-gcc-arm-none-eabi.git
```

gcc-arm-none-eabi:

```shell
# Show all installable versions
asdf list-all gcc-arm-none-eabi

# Install specific version
asdf install gcc-arm-none-eabi latest

# Set a version globally (on your ~/.tool-versions file)
asdf global gcc-arm-none-eabi latest

# Now gcc-arm-none-eabi commands are available
arm-none-eabi-c++ --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/vhdirk/asdf-gcc-arm-none-eabi/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Dirk Van Haerenborgh](https://github.com/vhdirk/)
