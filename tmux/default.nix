{pkgs, ...}: {
  imports = [
    ./tmux-sessionizer.nix
  ];

  programs.tmux = {
    enable = true;

    shortcut = "Space";
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;
    keyMode = "vi";

    plugins = with pkgs; [
      tmuxPlugins.nord
      tmuxPlugins.sensible
      tmuxPlugins.prefix-highlight
    ];

    extraConfig = ''
      set -ga terminal-overrides ",screen-256color*:Tc"
      set-option -g default-terminal "screen-256color"

      # Start windows and panes at 1, not 0
      set -g base-index 1
      set -g pane-base-index 1
      set-window-option -g pane-base-index 1
      set-option -g renumber-windows on

      # vim copy
      bind -T copy-mode-vi v send-keys -X begin-selection
      bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

      # vim-like pane switching
      bind -r ^ last-window
      bind -r k select-pane -U
      bind -r j select-pane -D
      bind -r h select-pane -L
      bind -r l select-pane -R

      # start new window in current directory
      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"

      # forget the find window.  That is for chumps
      bind-key -r f run-shell "tmux neww sesh"

      set-option -g detach-on-destroy off
      set-option -g status-left-length "80"

      set -g status-right "#{prefix_highlight}#[fg=cyan,bg=black,nobold,noitalics,nounderscore]#[fg=black,bg=cyan,bold] #H "
    '';
  };
}
