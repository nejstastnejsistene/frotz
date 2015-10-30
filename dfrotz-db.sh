#!/bin/bash

git_user=nejstastnejsistene
git_name="Peter Johnson"
git_email=peter@peterjohnson.io
repo_name=frotz-save-files
lock_dir=/tmp/frotz-git-lock

function acquire_github_repo {
    if ! mkdir "$lock_dir" &>/dev/null; then
        sleep 1
        acquire_github_repo
        return 0
    fi
    cd "$lock_dir"

    git clone -q "git@github.com:$git_user/$repo_name.git"
    cd "$repo_name"
    git config user.name "$git_name"
    git config user.email "$git_email"

    trap release_github_repo EXIT
}

function release_github_repo {
    rm -rf "$lock_dir"
}

cmd="$1"
save_file="$2"
target="$USER_ID/$(echo "$save_file" | sed 's!/!%2F!g')"
tmp_file="$3"

case "$cmd" in
    save)
        acquire_github_repo
        mkdir -p "$USER_ID"
        if [ -f "$target" ]; then
            release_github_repo
            echo -n 'Overwrite existing file? '
            read input
            [[ ${input:0:1} == y ]] || exit 1
            acquire_github_repo
        fi
        cp -T "$tmp_file" "$target" &>/dev/null || exit 1
        git add "$target"
        if ! git diff --staged --exit-code &>/dev/null; then
            git commit -qm "\"$USER_ID\" saved to \"$save_file\""
            git push -q origin master
        fi
        ;;
    restore)
      acquire_github_repo
      cp "$target" "$tmp_file" &>/dev/null || exit 1
      ;;
    *) exit 1 ;;
esac
