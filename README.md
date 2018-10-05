# k3rn3l

[![CircleCI](https://circleci.com/gh/particleflux/k3rn3l.svg?style=shield)](https://circleci.com/gh/particleflux/k3rn3l)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8e240180d5ec6d717b4a/test_coverage)](https://codeclimate.com/github/particleflux/k3rn3l/test_coverage)

Gentoo kernel management script.

**DISCLAIMER** Use at your own risk! I can not guarantee that this script is 
working perfectly. It could potentially render your whole system unusable!


## Installation

```
sudo make install
```

## Usage

```
k3rn3l <command> [options]

    Gentoo linux kernel management.

available commands:

    clean
        Cleanup older kernel versions.

        This deletes all kernel files for kernels older than the current one, so
        ensure that the current kernel boots correctly.

        These occurrences are cleaned:

            - kernel source directories in /usr/src/
            - compiled kernel in /boot/
            - kernel config and system.map in /boot/

    recompile
        Recompile the current kernel.

        Recompiles the current kernel from source and updates the boot loader.
        This is useful when you changed the kernel configuration.

    update
        Update to the newest kernel version

        Update to the newest installed kernel version. The kernel compilation
        tries to use old kernel config as far as possible, asking for changed or
        new kernel configuration options (make oldconfig)


available options:

    -p, --pretend   Do a dry-run, don't actually do anything harmful
    -v, --verbose   Verbose output
    -q, --quiet     Less output
    -h, --help      Show this help screen
    --version       Show the script version
```
