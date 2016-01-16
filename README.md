# stack wrapper

Automated [stack](https://github.com/commercialhaskell/stack) installation/execution script like gradle wrapper or typesafe activator

# Installation

```shell
$ wget https://raw.githubusercontent.com/saturday06/stackw/stable/stackw # Download script
$ wget https://raw.githubusercontent.com/saturday06/stackw/stable/stackw.bat # To support Windows
$ git add .; git commit -m "Add stack wrappers" # Add these scripts to your version control
```

# Execution

Executing `./stackw` downloads [stack](https://github.com/commercialhaskell/stack) and run it.

```shell
$ ./stackw --help
--2016-01-17 00:49:12--  https://github.com/commercialhaskell/stack/releases/download/v1.0.0/stack-1.0.0-windows-x86_64.zip
/home/user/.stack/wrapper/programs/stack 100%[===================================================================================================>]   7.34M  1MB/s    in 8s

2016-01-17 00:49:28 (521 KB/s) - '/home/user/.stack/wrapper/programs/stack-1.0.0-windows-x86_64.zip' saved [7692764/7692764]

Archive:  /home/user/.stack/wrapper/programs/stack-1.0.0-windows-x86_64.zip
  inflating: stack.exe
stack - The Haskell Tool Stack

Usage: stack.exe [--help] [--version] [--numeric-version] [--docker*] [--nix*]
                 ([--verbosity VERBOSITY] | [-v|--verbose])
                 [--work-dir WORK-DIR] ([--system-ghc] | [--no-system-ghc])
                 ([--install-ghc] | [--no-install-ghc]) [--arch ARCH] [--os OS]
                 [--ghc-variant VARIANT] [-j|--jobs JOBS]
                 [--extra-include-dirs DIR] [--extra-lib-dirs DIR]
                 ([--skip-ghc-check] | [--no-skip-ghc-check]) ([--skip-msys] |
                 [--no-skip-msys]) [--local-bin-path DIR] ([--modify-code-page]
                 | [--no-modify-code-page]) [--resolver RESOLVER]
                 [--compiler COMPILER] ([--terminal] | [--no-terminal])
                 [--stack-yaml STACK-YAML] COMMAND|FILE
```

# To specify stack version

Add following magic comment to your stack.yaml

```yaml
# stack version: 1.0.0
```

For example:

```yaml
# stack version: 1.0.0
resolver: lts-4.1

packages:
- '.'

extra-deps: []

extra-package-dbs: []
```
