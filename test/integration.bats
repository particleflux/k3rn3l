#!/usr/bin/env bats

setup()
{
    . shellmock
    shellmock_clean
}

teardown()
{
    if [ -z "$TEST_FUNCTION" ];then
        shellmock_clean
        rm -f sample.out
    fi
}

@test "version" {
    run "$BATS_TEST_DIRNAME/../k3rn3l.sh" --version

    [ "$status" = "0" ]
    [[ "$output" =~ [0-9]+\.[0-9]+\.[0-9]+ ]]
}

@test "usage" {
    run "$BATS_TEST_DIRNAME/../k3rn3l.sh" --help

    [ "$status" = "0" ]
    [[ "$output" =~ 'available commands' ]]
}
