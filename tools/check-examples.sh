#!/bin/sh

get_dependencies() {
    opam install --yes omd nonstd jbuilder
}
comd=_build/default/tools/code-of-markdown/main.exe
build_comd () {
    jbuilder build tools/code-of-markdown/main.exe
}

get_to_tmp() {
    local markdown_file=$1
    local nth=$2
    local ext=$3
    local base="$(basename ${markdown_file%.md})"
    local tmp="/tmp/coscomd-$base-$nth.$ext"
    $comd get -i $markdown_file --nth $2 -o $tmp
    echo $tmp
}

check_shell_command() {
    local shell="$1"
    local tmp="$(get_to_tmp $2 $3 "sh")"
    shift; shift; shift
    (
        cd /tmp/
        echo "Running $shell $tmp on: '$*'"
        $shell $tmp $* > $tmp-out 2> $tmp-err
    )
    if [ $? -eq 0 ]; then
        echo "Success !"
    else
        echo "####### FAILURE !"
        cat $tmp-out
        cat $tmp-err
        exit 2
    fi
}

if [ "$without_deps" = "true" ]; then
    echo "Not checking deps"
else
    get_dependencies
fi

build_comd

# First simple input-script:
check_shell_command ocaml doc/biokepi-input-scripts.md 2

# More complex input-script with basic CLI parsing:
check_shell_command ocaml doc/biokepi-input-scripts.md 4 gbucket rna

# `curl` the debug workflow:
check_shell_command sh doc/debug-workflow-node.md 5
ls /tmp/debug-workflow.ml > /dev/null || { echo "debug-workflow.ml IS NOT there!" ; exit 1 ; }

