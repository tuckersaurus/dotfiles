#!/bin/bash

# Exit immediately on any error — this is critical for --delete safety:
# if anything fails mid-process, we never reach the delete step
set -e

APPEND=false
DELETE=false

# Loop handles multiple flags in any order, unlike a single if/shift approach
while [[ "$1" == --* ]]; do
    case "$1" in
        --append) APPEND=true; shift ;;
        --delete) DELETE=true; shift ;;
        *) echo "Unknown flag: $1"; exit 1 ;;
    esac
done

if [ "$#" -lt 2 ]; then
    echo "Usage: consolidate.sh [--append] [--delete] <monorepo-path> <repo-url> [repo-url-2] ..."
    exit 1
fi

ROOT="$1"
shift
REPOS=("$@")

# Fail early before doing any work if the mode/state combination is invalid
if [ "$APPEND" = true ] && [ ! -d "$ROOT/.git" ]; then
    echo "Error: $ROOT is not an existing git repo. Remove --append to create it fresh."
    exit 1
fi

if [ "$APPEND" = false ] && [ -d "$ROOT" ]; then
    echo "Error: $ROOT already exists. Use --append to add repos to it."
    exit 1
fi

echo "Mode:        $([ "$APPEND" = true ] && echo 'Append' || echo 'Create new')"
echo "Monorepo:    $ROOT"
echo "Auto-delete: $([ "$DELETE" = true ] && echo 'yes' || echo 'no')"
echo "Repos:"
for repo in "${REPOS[@]}"; do
    echo "  - $repo"
done
echo ""
read -p "Proceed? (y/n): " confirm
[[ "$confirm" == "y" ]] || { echo "Aborted."; exit 0; }

# Only create the directory in create mode — in append mode it must already exist
[ "$APPEND" = false ] && mkdir -p "$ROOT"

for repo_url in "${REPOS[@]}"; do
    repo_name=$(basename "$repo_url" .git)
    echo ""
    echo "Processing: $repo_name"

    # Clone to a temp dir just to read branch names — avoids polluting the
    # working directory and prevents name collisions if running multiple times
    tmp_dir=$(mktemp -d)
    git clone "$repo_url" "$tmp_dir"
    branches=$(git -C "$tmp_dir" branch -r | grep -v '\->' | sed 's/.*origin\///' | tr -d ' ')
    rm -rf "$tmp_dir"

    for branch in $branches; do
        # Slashes in branch names (e.g. feature/my-thing) would create
        # nested directories, so replace with hyphens for a flat structure
        safe_branch=$(echo "$branch" | tr '/' '-')
        folder="${repo_name}-${safe_branch}"

        if [ -d "$ROOT/$folder" ]; then
            echo "  Skipping $folder — already exists"
            continue
        fi

        echo "  Branch: $branch → $folder/"
        # Clone only this branch — --single-branch keeps it lightweight
        git clone --branch "$branch" --single-branch "$repo_url" "$ROOT/$folder"
        # Remove .git so the branch folder becomes a plain directory in the monorepo
        rm -rf "$ROOT/$folder/.git"
    done
done

cd "$ROOT"

# git add must come after git init in create mode — split into branches to enforce order
if [ "$APPEND" = true ]; then
    git add .
    git commit -m "chore: consolidate repos: ${REPOS[*]}"
else
    git init
    git add .
    git commit -m "chore: initial consolidated monorepo"
    echo ""
    echo "To push to GitHub:"
    echo "  cd $ROOT"
    echo "  git remote add origin <url>"
    echo "  git push -u origin main"
fi

# Only reached if every repo succeeded — set -e ensures we never get here
# after a partial failure, so it's safe to delete all repos in the list
if [ "$DELETE" = true ]; then
    echo ""
    echo "Deleting source repos..."
    for repo_url in "${REPOS[@]}"; do
        # sed handles both SSH (git@github.com:owner/repo.git)
        # and HTTPS (https://github.com/owner/repo.git) URL formats
        repo_slug=$(echo "$repo_url" | sed 's/.*github\.com[:/]\(.*\)\.git/\1/')
        echo "  Deleting $repo_slug..."
        gh repo delete "$repo_slug" --yes
    done
fi

echo "Done!"
