#!/bin/bash
# Module: git
# Version: 0.3.0
# Description: Git aliases and clone helpers for multiple remotes with SSH key management
# BashMod Dependencies: ssh-agent@0.2.0

alias gitaddcommit='git add -A . && git commit -m '

# Function to load SSH key based on a git URL (before cloning)
ssh_load_key_for_url() {
    local git_url="$1"
    local ssh_host
    local key_file

    if [ -z "$git_url" ]; then
        echo "No Git URL provided"
        return 1
    fi

    # Extract SSH host from git URL
    case "$git_url" in
        git@*:*)
            # Extract the SSH host from git@host:repo format
            ssh_host=$(echo "$git_url" | sed -E 's|^git@([^:]+):.*|\1|')
            ;;
        ssh://git@*)
            # Extract from ssh://git@host/repo format
            ssh_host=$(echo "$git_url" | sed -E 's|^ssh://git@([^:/]+).*|\1|')
            ;;
        *)
            echo "Not an SSH Git URL: $git_url"
            return 1
            ;;
    esac

    # Check if get_ssh_key_for_host is available from ssh-agent.sh
    if ! type get_ssh_key_for_host &>/dev/null; then
        echo "Error: get_ssh_key_for_host function not found"
        echo "Please ensure ~/.bashrc.d/ssh-agent.sh is loaded"
        return 1
    fi

    # Use the shared function from ssh-agent.sh
    key_file=$(get_ssh_key_for_host "$ssh_host")

    if [ -z "$key_file" ]; then
        echo "Could not find SSH key for host: $ssh_host"
        return 1
    fi

    # Check if the key is already loaded
    if is_key_loaded "$key_file"; then
        return 0
    fi

    # Load the specific key
    echo "Loading SSH key for $ssh_host: $(basename "$key_file")"
    ssh-add "$key_file"
}

function clone-repo () {
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "Usage: clone-repo <owner> <repo-name>"
        echo "Examples:"
        echo "  clone-repo EBSCOIS platform.shared.bookjacket-image-resolver"
        echo "    -> git@ebscois:EBSCOIS/platform.shared.bookjacket-image-resolver.git"
        echo "    -> ~/development/platform.shared.bookjacket-image-resolver"
        echo ""
        echo "  clone-repo daevski my-personal-project"
        echo "    -> git@daevski:daevski/my-personal-project.git"
        echo "    -> ~/development/my-personal-project"
        return 1
    fi

    local owner="$1"
    local repo_name="$2"
    local ssh_host=$(echo "$owner" | tr '[:upper:]' '[:lower:]')

    local git_url="git@${ssh_host}:${owner}/${repo_name}.git"
    local clone_path="~/development/${repo_name}"

    ssh_load_key_for_url "$git_url" && git clone "$git_url" "$clone_path"
}

function clone-eis () {
    if [ -z "$1" ]; then
        echo "Usage: clone-eis <repo-name>"
        echo "Example: clone-eis platform.shared.bookjacket-image-resolver"
        echo "         -> git@eis:EBSCOIS/platform.shared.bookjacket-image-resolver.git"
        return 1
    fi
    clone-repo eis EBSCOIS "$1"
}

function clone-daevski () {
    if [ -z "$1" ]; then
        echo "Usage: clone-daevski <repo-name>"
        echo "Example: clone-daevski my-personal-project"
        echo "         -> git@daevski:daevski/my-personal-project.git"
        return 1
    fi
    clone-repo daevski daevski "$1"
}

function git-del-branch() {
    branch="$1"
    git checkout main
    git branch -D "$branch" && git push origin --delete "$branch" && git fetch --prune
}