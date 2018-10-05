#!/usr/bin/env bats

kernelDir=

setup()
{
    . shellmock
    shellmock_clean

    kernelDir=$(mktemp -d)
}

teardown()
{
    if [ -z "$TEST_FUNCTION" ];then
        shellmock_clean
        rm -f sample.out
    fi

    rm -rf "$kernelDir"
}

@test "utils log function" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    result=$(l "Hello World")
    [ "$result" = "Hello World" ]

    result=$(l "\e[01;31merror\e[0m")
    [ "$result" = "$(echo -e '\e[01;31merror\e[0m')" ]
}

@test "utils v function" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    run v "Hello World"

    [[ "$status" -eq 1 ]]
    [[ -z "$output" ]]

    verbose=1
    run v "Hello World"

    [[ "$status" -eq 0 ]]
    [[ "$output" = "Hello World" ]]
}

@test "utils error log function" {
   source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    # no output to stdout
    result=$(e "total error")
    [ "$result" = "" ]

    # instead to stderr
    result=$(e "total error" 2>&1)
    [ "$result" = "$(echo -e '\e[31mtotal error\e[0m')" ]
}

@test "utils die function" {
   source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    run die "total error"
    [ "$output" = "$(echo -e '\e[31mtotal error\e[0m')" ]
    [ "$status" -eq 1 ]
}

@test "beginsWith" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    beginsWith "hello world" "hello"
    ! beginsWith "hello world" "world"
    ! beginsWith "asdf hello world" "hello"
}

@test "detectCurrentKernel" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    shellmock_expect uname --status 0 --match '-r' --output '1.3.37-gentoo'
    shellmock_expect eselect --status 0 --match 'kernel list' --output "Available kernel symlink targets:
  [1]   linux-1.0.0-gentoo
  [2]   linux-1.3.37-gentoo *
"

    run detectCurrentKernel

    echo $output
    [ "$status" -eq 0 ]
    [ "$output" == 'linux-1.3.37-gentoo' ]
}

@test "detectCurrentKernel reboot required" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    shellmock_expect uname --status 0 --match '-r' --output '1.0.0-gentoo'
    shellmock_expect eselect --status 0 --match 'kernel list' --output "Available kernel symlink targets:
  [1]   linux-1.0.0-gentoo
  [2]   linux-1.3.37-gentoo *
"

    run detectCurrentKernel

    [ "$status" -eq 1 ]
    [ "$output" == "$(echo -e '\e[31mPlease reboot to the current kernel before issuing clean\e[0m')" ]
}

@test "mountBoot mount required & successful" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    shellmock_expect findmnt --status 1 --match '/boot'
    shellmock_expect mount --status 0 --match '/boot'

    run mountBoot
    [ "$status" -eq 0 ]
}

@test "mountBoot mount required & failed" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    shellmock_expect findmnt --status 1 --match '/boot'
    shellmock_expect mount --status 1 --match '/boot'

    run mountBoot
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Failed to mount /boot" ]]
}

@test "mountBoot mount not required" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"

    shellmock_expect findmnt --status 0 --match '/boot'
    shellmock_expect mount --status 1 --match '/boot'

    run mountBoot
    [ "$status" -eq 0 ]

    shellmock_verify
    [[ "${capture[0]}" = "findmnt-stub /boot" ]]
    # mount should not be called
    [[ -z "${capture[1]}" ]]
}

@test "recompile failing compilation" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"
    KERNEL_SOURCE_DIRECTORY="$kernelDir/"
    mkdir -p "$kernelDir/linux"

    shellmock_expect findmnt --status 0 --match '/boot'
    shellmock_expect make --status 1

    run recompile

    [[ "$status" -eq "1" ]]
    [[ "$output" =~ 'Kernel compilation failed' ]]
}

@test "recompile successful compilation" {
    source "$BATS_TEST_DIRNAME/../k3rn3l.sh"
    KERNEL_SOURCE_DIRECTORY="$kernelDir/"
    mkdir -p "$kernelDir/linux"

    shellmock_expect findmnt --status 0 --match '/boot'
    shellmock_expect make --status 0 --match '' --type partial
    shellmock_expect grub-mkconfig --status 0 --match '-o /boot/grub/grub.cfg'

    run recompile

    [[ "$status" -eq "0" ]]

    shellmock_verify
    [[ "${capture[0]}" = "findmnt-stub /boot" ]]
    [[ "${capture[1]}" =~ "make-stub" ]]
    [[ "${capture[4]}" =~ "grub-mkconfig-stub" ]]
}
