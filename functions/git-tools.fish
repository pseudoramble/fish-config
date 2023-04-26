#!/usr/local/bin/fish

if test "$GIT_TOOLS_DEV_BRANCH" = ""
  set -U GIT_TOOLS_DEV_BRANCH "develop"
  echo "We have universally exported the var GIT_TOOLS_DEV_BRANCH"
  echo "It defaults the development branch name to 'develop'. This can be changed by using:"
  echo " 1. git-tools -settings develop-branch NAME_HERE"
  echo " 2. set -gx GIT_TOOLS_DEV_BRANCH \"NAME_HERE\""
  echo
end

function get_current_branch
  git branch --no-color | grep -E '^\*' | awk '{print $2}' || echo ""
end

function feature_init_setup -a branch_name
  git checkout $GIT_TOOLS_DEV_BRANCH
  git add .
  git stash
  git pull
  git stash pop
  
  git checkout -b $branch_name

  read -l -P "Would you like to share this branch with origin? [y|N] " update_remote_branch
  if test "$update_remote_branch" = "Y" || test "$update_remote_branch" = "y"
    git push -u origin $branch_name
  end
end

function feature_final_prep -a source_branch dest_branch
  if test "$source_branch" = "" || test "$dest_branch" = ""
    echo "At least one of the branches is set incorectly."
    echo "  source=$source_branch. destination=$dest_branch"
    return
  else if test "$source_branch" = "$dest_branch"
    echo "The source and destination are the same. "
    echo "  source=$source_branch. destination=$dest_branch"
    echo "Remember to check out the feature branch before running final prep."
    return
  end

  echo "Stashing leftover changes before continuing. They will be restored after final prep."
  git add .
  git stash

  git checkout $dest_branch
  git pull --no-verify # this assumes a rebase strategy set in git user config
  set pull_result $status
  git checkout $source_branch
  if test $pull_result -ne 0
    echo "An error occured while trying to update $dest_branch. Aborting!"
    return
  end
  git rebase $dest_branch --no-verify
  git rebase -i $dest_branch

  read -l -P "Would you like to update the remote branch? [y|N] " update_remote_branch
  if test "$update_remote_branch" = "Y" || test "$update_remote_branch" = "y"
    git push --force
  else
    echo "Don't forget to share the updates with the remote branch."
  end

  git stash pop
  return 0
end

function feature_finish_branch -a source_branch
  git add .
  git stash
  git checkout $source_branch
  git checkout $GIT_TOOLS_DEV_BRANCH
  git pull
  git branch -d $source_branch
  git stash pop
  return 0
end

function checkout_stash_pop -a branch update
  git add .
  git stash
  git checkout $branch
  if test -n "$update"
    git pull
  end
  git stash pop
end

function git-tools -a cmdname subcmd subcmdargs
  if test "$cmdname" = "checkout" || test "$cmdname" = "co"
    checkout_stash_pop $subcmd $subcmdargs
  else if test "$cmdname" = "feature"
    set source_branch (get_current_branch)

    if test "$subcmd" = "prep"
      feature_final_prep $source_branch $GIT_TOOLS_DEV_BRANCH
    else if test "$subcmd" = "init" || test "$subcmd" = "start"
      if test -z "$subcmdargs"
        echo "Please specify the branch name"
        exit 1
      end
      feature_init_setup $subcmdargs
    else if test "$subcmd" = "finish"
      feature_finish_branch $source_branch
    else
      echo "Error: unknown -feature argument '$subcmd'"
      echo "Valid -feature arguments are:"
      echo "  init|start: Begin a new feature branch"
      echo "  prep: Prepare a feature branch to be merged back into $GIT_TOOLS_DEV_BRANCH (rebase/squash, push, etc)"
      echo "  finish: Complete a feature branch. Assumes that the PR has been merged into $GIT_TOOLS_DEV_BRANCH already"
    end
  else if test "$cmdname" = "settings"
    if test "$subcmd" = "develop-branch"
      if test "$subcmdargs" != ""
        echo "The active develop-branch branch will be changed."
        echo "current: "$GIT_TOOLS_DEV_BRANCH". next: "$subcmdargs"."
        echo "Once changed, rebases or merges currently done against "$GIT_TOOLS_DEV_BRANCH" will be done against "$subcmdargs" instead."
        echo "This can be changed at any time."
        echo "Press enter to continue"
        read
        set -U GIT_TOOLS_DEV_BRANCH "$subcmdargs"
        echo "The current develop branch is now named "$GIT_TOOLS_DEV_BRANCH
      else
        echo "develop branch is "$GIT_TOOLS_DEV_BRANCH
      end
    else
      echo "Error: unknown -settings argument '$subcmd'"
      echo "Valid -settings arguments are:"
      echo "  develop-branch: Set the branch name which rebases and merges are done against. Ex: switch from 'develop' to 'next-develop'."
    end
  else
      echo "Error: unknown command '$cmdname'"
      echo "Valid command:"
      echo "  feature: A set of functions to mimic some git-flow operations but using a squash/rebase strategy instead of merging"
      echo "  settings: A set of functions to change how git-tools itself works"
  end
end

complete -c git-tools -f -n "not __fish_seen_subcommand_from feature settings" -a "checkout" -d "Check out a new branch. Helps shuffle unstashed/uncommitted changes over."
complete -c git-tools -f -n "not __fish_seen_subcommand_from feature settings" -a "co" -d "Check out a new branch. Helps shuffle unstashed/uncommitted changes over."
complete -c git-tools -f -n "not __fish_seen_subcommand_from feature settings" -a "feature" -d "Start, finish, or prepare a feature branch."
complete -c git-tools -f -n "not __fish_seen_subcommand_from feature settings" -a "settings" -d "Modify settings for git-tools."
complete -c git-tools -f -n "__fish_seen_subcommand_from feature" -a "start" -d "Checkout a new feature branch from develop."
complete -c git-tools -f -n "__fish_seen_subcommand_from feature" -a "prep" -d "Before finishing, update develop branch and perform interactive rebase on feature branch."
complete -c git-tools -f -n "__fish_seen_subcommand_from feature" -a "finish" -d "After prep, checkout & pull develop branch from remote, delete feature branch."
complete -c git-tools -f -n "__fish_seen_subcommand_from checkout co" -a "branch" -d "The branch to checkout."