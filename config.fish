if status is-interactive
    # Commands to run in interactive sessions can go here
    if test -f config.local.fish && test -r config.local.fish
        source config.local.fish
    end
end
