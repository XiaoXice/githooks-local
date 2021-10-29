#!/bin/sh
process_git_hook() {
    set_main_variables "$1" || return 1
    shift 1

    execute_local_hooks_in "$LOCAL_HOOKS_DIR" "$@" || return 1
}

set_main_variables() {
    HOOK_NAME="$(basename "$1")"
    GIT_DIR="$(cd "$(git rev-parse --git-dir)" && pwd)"
    LOCAL_HOOKS_DIR="${GIT_DIR}/hooks"
}

execute_local_hooks_in() {
    PARENT="$1"
    shift

    if [ -d "${PARENT}/${HOOK_NAME}" ]; then
        for HOOK_FILE in "${PARENT}/${HOOK_NAME}"/*; do
            execute_hook "$HOOK_FILE" "$@" || return 1
        done
    elif [ -f "${PARENT}/${HOOK_NAME}" ]; then
        execute_hook "${PARENT}/${HOOK_NAME}" "$@" || return 1
    fi
}

execute_hook() {
    HOOK_PATH="$1"
    shift

    # stop if the file does not exist
    [ -f "$HOOK_PATH" ] || return 0

    is_auto_generated_by_githooks || return 0
    is_auto_generated_by_githooks_go || return 0

    run_hook_file "$@"
    return $?
}

is_auto_generated_by_githooks() {
    grep "Base Git hook template from" "$HOOK_PATH"
    if [ $? -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

is_auto_generated_by_githooks_go() {
    grep "git-hooks run" "$HOOK_PATH"
    if [ $? -eq 0 ]; then
        return 1
    else
        return 0
    fi
}

run_hook_file() {
    if [ -x "$HOOK_PATH" ]; then
        # Run as an executable file
        "$HOOK_PATH" "$@"
        return $?

    elif [ -f "$HOOK_PATH" ]; then
        # Run as a Shell script
        sh "$HOOK_PATH" "$@"
        return $?
    fi

    return 0
}

process_git_hook "$@" || exit 1