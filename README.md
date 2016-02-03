# stack wrapper

[The Haskell Tool Stack](https://github.com/commercialhaskell/stack) installation/execution script like gradle wrapper or typesafe activator

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
--2016-01-17 00:49:12--  https://github.com/commercialhaskell/stack/releases/download/v1.0.2/stack-1.0.2-windows-x86_64.zip
/home/user/.stack/wrapper/programs/stack 100%[===================================================================================================>]   7.34M  1MB/s    in 8s

2016-01-17 00:49:28 (521 KB/s) - '/home/user/.stack/wrapper/programs/stack-1.0.2-windows-x86_64.zip' saved [7692764/7692764]

Archive:  /home/user/.stack/wrapper/programs/stack-1.0.2-windows-x86_64.zip
  inflating: stack.exe
stack - The Haskell Tool Stack

Usage: stack.exe [--help] [--version] [--numeric-version] [--docker*] [--nix*]
                 ([--verbosity VERBOSITY] | [-v|--verbose])
...
```

Yes. It is cached for next execution.

```shell
$ ./stackw --help
stack - The Haskell Tool Stack

Usage: stack.exe [--help] [--version] [--numeric-version] [--docker*] [--nix*]
                 ([--verbosity VERBOSITY] | [-v|--verbose])
...
```

# To specify stack version

Add following magic comment to your stack.yaml

```yaml
# stack version: 1.0.2
```

For example:

```yaml
# stack version: 1.0.2
resolver: lts-4.1

packages:
- '.'

extra-deps: []

extra-package-dbs: []
```

# Upgradle stack wrapper

`./stackw stackw-upgrade` updates stack wrapper to latest version.

```
$ ./stackw stackw-upgrade
```
