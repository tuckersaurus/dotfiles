_gsup_pull() {
    local submodule="$1"
    local branch="$2"

    echo "  Pulling $submodule from origin/$branch..." >&2
    git -C "$submodule" pull origin "$branch" >&2 || return 1
    git add "$submodule"

    if git diff --cached --quiet; then
        echo "  $submodule — already up to date" >&2
        return 1
    fi

    local sha
    sha=$(git -C "$submodule" rev-parse --short HEAD)
    echo "$submodule@$sha"
}

_gsup_branch() {
    local submodule="$1"
    local override="$2"
    if [ -n "$override" ]; then
        echo "$override"
    else
        git config -f .gitmodules "submodule.$submodule.branch" 2>/dev/null || echo "main"
    fi
}

gsup() {
    local branch_override=""
    local all=false
    local OPTIND=1

    while getopts "ab:" opt; do
        case "$opt" in
            a) all=true ;;
            b) branch_override="$OPTARG" ;;
            *) echo "Usage: gsup [-a] [-b <branch>] [<submodule>]"; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    if $all; then
        local submodules
        submodules=$(git submodule foreach --quiet 'echo $name' 2>/dev/null)
        if [ -z "$submodules" ]; then echo "No submodules found."; return 1; fi

        local updated=()
        while IFS= read -r sub; do
            local branch result
            branch=$(_gsup_branch "$sub" "$branch_override")
            result=$(_gsup_pull "$sub" "$branch") && updated+=("$result")
        done <<< "$submodules"

        if [ ${#updated[@]} -eq 0 ]; then
            echo "All submodules already up to date, nothing to commit."
            return 0
        fi

        local msg="chore: update submodules"$'\n\n'
        for entry in "${updated[@]}"; do msg+="  - $entry"$'\n'; done
        git commit -m "$msg"
        echo "Done. Updated ${#updated[@]} submodule(s)."
    else
        local submodule="${1:?Usage: gsup [-a] [-b <branch>] [<submodule>]}"
        local branch result
        branch=$(_gsup_branch "$submodule" "$branch_override")
        result=$(_gsup_pull "$submodule" "$branch") || return 0
        local sha="${result#*@}"
        git commit -m "chore: update $submodule to $sha"
        echo "Done. $submodule updated to $sha."
    fi
}

_gsco_checkout() {
    local submodule="$1"
    local branch="$2"
    local create="$3"

    if [ "$create" = "true" ]; then
        if git -C "$submodule" checkout -b "$branch" 2>/dev/null; then
            echo "  $submodule — created $branch"
        elif git -C "$submodule" checkout "$branch" 2>/dev/null; then
            echo "  $submodule — already exists, checked out $branch"
        else
            echo "  $submodule — failed" >&2; return 1
        fi
    else
        git -C "$submodule" fetch origin --quiet 2>/dev/null
        if git -C "$submodule" checkout "$branch" 2>/dev/null; then
            echo "  $submodule — checked out $branch"
        else
            echo "  $submodule — $branch not found, staying put"
        fi
    fi
}

gsco() {
    local create=false
    local OPTIND=1

    while getopts "c" opt; do
        case "$opt" in
            c) create=true ;;
            *) echo "Usage: gsco [-c] <branch>"; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    local branch="${1:?Usage: gsco [-c] <branch>}"
    local submodules
    submodules=$(git submodule foreach --quiet 'echo $name' 2>/dev/null)
    if [ -z "$submodules" ]; then echo "No submodules found."; return 1; fi

    while IFS= read -r sub; do
        _gsco_checkout "$sub" "$branch" "$create"
    done <<< "$submodules"
}
