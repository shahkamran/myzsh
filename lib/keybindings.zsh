#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: keybindings                                              ║
# ║  Keyboard shortcuts and key bindings                               ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Key Binding Mode ─────────────────────────────────────────────────
if [[ "$MYZSH_KEYBIND_STYLE" == "vim" ]]; then
  bindkey -v
  export KEYTIMEOUT=1
else
  bindkey -e  # emacs mode (default)
fi

# ─── Common Shortcuts ─────────────────────────────────────────────────
# Navigation
bindkey '^[[H'  beginning-of-line       # Home
bindkey '^[[F'  end-of-line             # End
bindkey '^[[1~' beginning-of-line       # Home (alternate)
bindkey '^[[4~' end-of-line             # End (alternate)
bindkey '^A'    beginning-of-line       # Ctrl+A
bindkey '^E'    end-of-line             # Ctrl+E

# Word navigation
bindkey '^[[1;5C' forward-word          # Ctrl+Right
bindkey '^[[1;5D' backward-word         # Ctrl+Left
bindkey '^[f'     forward-word          # Alt+F
bindkey '^[b'     backward-word         # Alt+B

# Deletion
bindkey '^[[3~' delete-char             # Delete key
bindkey '^H'    backward-delete-char    # Backspace
bindkey '^W'    backward-kill-word      # Ctrl+W (delete word back)
bindkey '^[d'   kill-word               # Alt+D (delete word forward)
bindkey '^U'    backward-kill-line      # Ctrl+U (delete to start)
bindkey '^K'    kill-line               # Ctrl+K (delete to end)

# History
bindkey '^R'    history-incremental-search-backward  # Ctrl+R
bindkey '^S'    history-incremental-search-forward   # Ctrl+S

# Editing
bindkey '^L'    clear-screen            # Ctrl+L
bindkey '^Z'    undo                    # Ctrl+Z (undo last edit)
bindkey '^Y'    yank                    # Ctrl+Y (paste killed text)

# ─── Custom Widgets ───────────────────────────────────────────────────
# Ctrl+Space: accept autosuggestion
_myzsh_accept_suggestion() {
  if (( ${+functions[autosuggest-accept]} )); then
    zle autosuggest-accept
  else
    zle end-of-line
  fi
}
zle -N _myzsh_accept_suggestion
bindkey '^ ' _myzsh_accept_suggestion

# Alt+Enter: insert newline (for multiline commands)
bindkey '^[^M' self-insert-unmeta

# Ctrl+X Ctrl+E: edit command in $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# ─── Directory shortcuts ──────────────────────────────────────────────
# Alt+Up: go to parent directory
_myzsh_up_dir() {
  cd ..
  zle reset-prompt
}
zle -N _myzsh_up_dir
bindkey '^[[1;3A' _myzsh_up_dir  # Alt+Up

# Alt+Left: go back in directory stack
_myzsh_back_dir() {
  popd 2>/dev/null
  zle reset-prompt
}
zle -N _myzsh_back_dir
bindkey '^[[1;3D' _myzsh_back_dir  # Alt+Left
