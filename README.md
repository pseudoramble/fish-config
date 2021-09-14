# Fish Config

Configuration and functions for the [fish shell](https://fishshell.com/docs/current/index.html).

## How to use

Install fish and git. Clone this as your `~/.config/fish` directory. Enjoy!

## Features

### Local private config
Loads a specific file that is ignored in git, and will only be accessible on that particular login.
Useful for aliases and features that are private to that particular machine.

See `config.fish` for the specifics.

### Gitflow-like functionality
A set of scripts to perform something like gitflow, except with a major difference of using a rebase
strategy instead of a merge strategy. It also has some extra utilities to handle specific odd cases as well.

See `functions/git-tools.fish` for the specifics.
