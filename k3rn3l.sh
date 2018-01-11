#!/usr/bin/env bash

# constants
readonly KERNEL_SOURCE_DIRECTORY="/usr/src/"
readonly SCRIPT_VERSION="1.0.0"

# global stuff - those can be overridden via ENV vars
GRUB_CMD=grub-mkconfig


. ./lib/utils.sh


function requirements() {
    v 'Checking script requirements...'

    [[ -e '/etc/gentoo-release' ]] || die 'This script supports only gentoo'
    [[ "$EUID" -eq 0 ]] || die 'This script needs to be run as root'
    ( $GRUB_CMD --version &> /dev/null ) || die "$GRUB_CMD not found"
}


function usage {
    cat <<EOF
k3rn3l <command> [options]

    Gentoo linux kernel management.

available commands:

    clean
        Cleanup older kernel versions.

        You should run emerge --depclean first, though it is not required.
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
EOF

    exit 0
}

function parseArgs {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -p|--pretend)
                dryRun="echo"
                ;;
            -s|--skip-requirements)
                skipRequirements=1
                ;;
            -v|--verbose)
                verbose=1
                ;;
            -q|--quiet)
                quiet=1
                ;;
            -h|--help)
                usage
                ;;
            --version)
                echo "$SCRIPT_VERSION"
                exit 0
                ;;
            *)
                if beginsWith "$1" "-"; then
                    die "Unknown option '$1'"
                fi

                if [[ -z "$cmd" ]]; then
                    cmd="$1"
                else
                    die "argument is not allowed here: $1"
                fi
                ;;
        esac
        shift
    done
}

function detectCurrentKernel {
    local runningKernel eselectKernel

    runningKernel=$(uname -r)
    eselectKernel=$(eselect kernel list | grep '\*$' | awk '{print $2}')

    [[ "$eselectKernel" == "linux-$runningKernel" ]] \
        || die "Please reboot to the current kernel before issuing clean"

    echo "$eselectKernel"
}

function mountBoot {
    if ! findmnt /boot &> /dev/null ; then
        l "/boot not mounted, mounting..."
        mount /boot || die "Failed to mount /boot"
    fi
}

function clean {
    local currentKernel currentVersion removalList
    removalList=()
    currentKernel=$(detectCurrentKernel)
    currentVersion=$(echo "$currentKernel" | cut -d '-' -f 1 --complement)

    l "Current kernel: $currentKernel"

    l "\nCleaning kernel sources..."
    for directory in $KERNEL_SOURCE_DIRECTORY* ; do
        if [[ "$directory" == "$KERNEL_SOURCE_DIRECTORY$currentKernel" \
            || "$directory" == "${KERNEL_SOURCE_DIRECTORY}linux" ]]; then

            l "Skipping current kernel directory \e[32m$directory\e[0m"
            continue;
        fi

        l "Slating for removal: \e[31m$directory\e[0m"
        removalList+=("$directory")
    done

    l "\nCleaning /boot/ ..."
    mountBoot

    for bootFile in /boot/vmlinuz-* /boot/config-* /boot/System.map-* ; do
        if [[ "$(basename "$bootFile" | cut -d '-' -f 1 --complement)" \
            == "$currentVersion" ]]; then

            l "Skipping current kernel file \e[32m$bootFile\e[0m"
            continue
        fi

        l "Slating for removal: \e[31m$bootFile\e[0m"
        removalList+=("$bootFile")
    done

    l ""
    if [[ ${#removalList[@]} -eq 0 ]]; then
        l "Nothing to delete"
        exit 0
    fi

    if [[ -z "$dryRun" ]]; then
        v "About to execute: rm -rf ${removalList[@]}"
        read -r -p "Are you sure? [y/N] " response
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
            l 'User aborted'
            exit 0
        fi
    fi

    l "Deleting..."
    $dryRun rm -rf "${removalList[@]}"
}

function recompile {
    cd "${KERNEL_SOURCE_DIRECTORY}linux"

    mountBoot
    l 'Starting kernel compilation...'
    if ! ( make -j $(nproc) && make modules_install && make install ) ; then
        die 'Kernel compilation failed'
    fi

    l 'Updating grub config...'
    $dryRun $GRUB_CMD -o /boot/grub/grub.cfg
}

function update {
    local oldKernel newKernel

    l 'Updating kernel...'

    v 'Determining kernel versions...'
    oldKernel=$(eselect kernel list | grep '\*' | awk '{print $2}')
    newKernel=$(eselect kernel list | tail -n 1 | awk '{print $2}')

    if [[ -z "$oldKernel" ]]; then
        die 'Could not determine kernel versions'
    fi

    [[ "$oldKernel" != "$newKernel" ]] || die 'Only one kernel version installed'

    l "Switching from $oldKernel to $newKernel"
    ( $dryRun eselect kernel set "$newKernel" ) \
        || die "Switching to new kernel failed"

    cd "${KERNEL_SOURCE_DIRECTORY}linux"

    v 'Copying old config...'
    [[ -e "../$oldKernel/.config" ]] \
        || die "Error: No .config present for $oldKernel"
    cp "../$oldKernel/.config" ./

    mountBoot
    l 'Starting kernel compilation...'
    if ! ( make oldconfig && make -j $(nproc) && $dryRun make modules_install && $dryRun make install ) ; then
        die 'Kernel compilation failed'
    fi

    l 'Rebuilding kernel modules...'
    ( $dryRun emerge -q @module-rebuild ) || die 'module-rebuild failed'

    l 'Updating grub config...'
    $dryRun $GRUB_CMD -o /boot/grub/grub.cfg
}

function main {
    local dryRun skipRequirements grubCmd cmd

    parseArgs "$@"
    [[ $skipRequirements ]] || requirements

    v "Executing command '$cmd'"
    case "$cmd" in
        clean|recompile|update)
            $cmd
            ;;
        help)
            usage
            ;;
        *)
            die "Unknown command given: '$cmd'"
            ;;
    esac

    exit 0
}


main "$@"
