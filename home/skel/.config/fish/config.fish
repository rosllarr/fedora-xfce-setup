if status is-interactive
    set EDITOR /usr/bin/nvim
    fish_add_path -g ~/.cargo/bin
    # fish_add_path -g ~/scripts
    # fish_add_path -g ~/.nvm
    fish_add_path -g ~/.local/bin
    zoxide init fish | source
end
