# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# TODO: adapt this
asdf plugin test gcc-arm-none-eabi https://github.com/vhdirk/asdf-gcc-arm-none-eabi.git "arm-none-eabi-c++ --version"
```

Tests are automatically run in GitHub Actions on push and PR.
