if status is-interactive
    # Commands to run in interactive sessions can go here
    if test -f ~/.config/fish/config.local.fish && test -r ~/.config/fish/config.local.fish
        source ~/.config/fish/config.local.fish
    end
end

# Aliases
## Git
alias gitsp="git add . && git stash && git pull && git stash pop"