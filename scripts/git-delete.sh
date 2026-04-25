#!/bin/bash

# Exit immediately on any error — prevents partial deletes if gh fails mid-run
set -e

if [ "$#" -lt 1 ]; then
    echo "Usage: delete-repos.sh <repo-url> [repo-url-2] ..."
    exit 1
fi

# Show everything that will be deleted before asking for confirmation
echo "The following repos will be PERMANENTLY deleted:"
for repo_url in "$@"; do
    # sed handles both SSH (git@github.com:owner/repo.git)
    # and HTTPS (https://github.com/owner/repo.git) URL formats
    repo_slug=$(echo "$repo_url" | sed 's/.*github\.com[:/]\(.*\)\.git/\1/')
    echo "  - $repo_slug"
done
echo ""
read -p "Are you sure? This cannot be undone. (y/n): " confirm
[[ "$confirm" == "y" ]] || { echo "Aborted."; exit 0; }

for repo_url in "$@"; do
    repo_slug=$(echo "$repo_url" | sed 's/.*github\.com[:/]\(.*\)\.git/\1/')
    echo "Deleting $repo_slug..."
    gh repo delete "$repo_slug" --yes
done

echo "Done!"
