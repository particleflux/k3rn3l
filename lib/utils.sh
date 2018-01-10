#!/usr/bin/env bash

# These are to be overridden from the script using this
verbose=
quiet=

# default log output
# deactivated when quiet=1
function l() {
    [[ -n "$quiet" ]] || echo -e "$*"
}

# log if verbose=1
function v() {
    [[ -n "$verbose" ]] && l "$*"
}

# log errors
# errors go to STDERR and always log, even if quiet=1
function e() {
    (>&2 echo -e "\e[31m$*\e[0m")
}

function die () {
    e "$@"
    exit 1
}