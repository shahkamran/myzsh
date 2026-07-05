#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: plugins                                                  ║
# ║  Git submodule-based plugin management                             ║
# ╚══════════════════════════════════════════════════════════════════════╝

MYZSH_PLUGINS_DIR="$MYZSH_DIR/plugins"

# ─── Plugin Add ───────────────────────────────────────────────────────
# Adds a plugin as a git submodule under plugins/
# Usage: myzsh-plugin-add <repo-url>
myzsh-plugin-add() {
  local repo_url="$1"

  if [[ -z "$repo_url" ]]; then
    echo "Usage: myzsh-plugin-add <repo-url>" >&2
    echo "  e.g. myzsh-plugin-add https://github.com/zsh-users/zsh-autosuggestions.git" >&2
    return 1
  fi

  # Extract plugin name from URL
  local plugin_name
  plugin_name=$(basename "$repo_url" .git)

  if [[ -z "$plugin_name" ]]; then
    echo "⚠️  myzsh: could not determine plugin name from URL" >&2
    return 1
  fi

  if [[ -d "$MYZSH_PLUGINS_DIR/$plugin_name" ]]; then
    echo "⚠️  myzsh: plugin '$plugin_name' is already installed" >&2
    return 1
  fi

  echo "📦 Installing plugin: $plugin_name"
  echo "   Source: $repo_url"

  # Add as git submodule
  if ! git -C "$MYZSH_DIR" submodule add "$repo_url" "plugins/$plugin_name" 2>&1; then
    echo "✗ Failed to add submodule" >&2
    return 1
  fi

  # Initialize the submodule
  git -C "$MYZSH_DIR" submodule update --init "plugins/$plugin_name"

  echo "   ✓ Plugin '$plugin_name' installed successfully"

  # Regenerate lockfile checksums
  if type myzsh-update-lock &>/dev/null; then
    myzsh-update-lock
  fi
}

# ─── Plugin Remove ────────────────────────────────────────────────────
# Removes a plugin submodule completely
# Usage: myzsh-plugin-remove <name>
myzsh-plugin-remove() {
  local plugin_name="$1"

  if [[ -z "$plugin_name" ]]; then
    echo "Usage: myzsh-plugin-remove <plugin-name>" >&2
    return 1
  fi

  local plugin_path="plugins/$plugin_name"
  local plugin_full_path="$MYZSH_PLUGINS_DIR/$plugin_name"

  if [[ ! -d "$plugin_full_path" ]]; then
    echo "⚠️  myzsh: plugin '$plugin_name' is not installed" >&2
    return 1
  fi

  echo "🗑️  Removing plugin: $plugin_name"

  # Deinitialize the submodule
  git -C "$MYZSH_DIR" submodule deinit -f "$plugin_path" 2>/dev/null

  # Remove from .git/modules
  rm -rf "$MYZSH_DIR/.git/modules/$plugin_path"

  # Remove the submodule entry and directory
  git -C "$MYZSH_DIR" rm -f "$plugin_path" 2>/dev/null

  # Clean up any remaining directory
  rm -rf "$plugin_full_path"

  echo "   ✓ Plugin '$plugin_name' removed"

  # Regenerate lockfile checksums
  if type myzsh-update-lock &>/dev/null; then
    myzsh-update-lock
  fi
}

# ─── Plugin Update ────────────────────────────────────────────────────
# Updates one or all plugin submodules to their latest commits
# Usage: myzsh-plugin-update [name|--all]
myzsh-plugin-update() {
  local target="${1:---all}"

  if [[ "$target" == "--all" ]]; then
    echo "🔄 Updating all plugins..."
    local count=0

    for plugin_dir in "$MYZSH_PLUGINS_DIR"/*(N/); do
      local name=$(basename "$plugin_dir")
      # Skip non-submodule directories
      [[ "$name" == ".gitkeep" ]] && continue
      echo "   ↻ $name"
      git -C "$plugin_dir" pull --quiet origin HEAD 2>/dev/null && ((count++))
    done

    if (( count == 0 )); then
      echo "   No plugins to update."
    else
      echo "   ✓ Updated ${count} plugin(s)"
      # Regenerate lockfile checksums
      if type myzsh-update-lock &>/dev/null; then
        myzsh-update-lock
      fi
    fi
  else
    local plugin_dir="$MYZSH_PLUGINS_DIR/$target"

    if [[ ! -d "$plugin_dir" ]]; then
      echo "⚠️  myzsh: plugin '$target' is not installed" >&2
      return 1
    fi

    echo "🔄 Updating plugin: $target"
    if git -C "$plugin_dir" pull origin HEAD 2>/dev/null; then
      echo "   ✓ Updated '$target'"
      # Regenerate lockfile checksums
      if type myzsh-update-lock &>/dev/null; then
        myzsh-update-lock
      fi
    else
      echo "   ✗ Failed to update '$target'" >&2
      return 1
    fi
  fi
}

# ─── Plugin List ──────────────────────────────────────────────────────
# Lists all installed plugins with their status
# Usage: myzsh-plugin-list
myzsh-plugin-list() {
  local count=0

  echo "📦 Installed plugins:"
  echo ""

  for plugin_dir in "$MYZSH_PLUGINS_DIR"/*(N/); do
    local name=$(basename "$plugin_dir")
    local plugin_file="$plugin_dir/${name}.plugin.zsh"
    local status_icon="✓"

    # Check if the plugin has an entry point
    if [[ ! -f "$plugin_file" ]]; then
      # Try alternative naming patterns
      if ls "$plugin_dir"/*.plugin.zsh &>/dev/null; then
        status_icon="✓"
      else
        status_icon="?"
      fi
    fi

    # Get current commit (short hash)
    local commit
    commit=$(git -C "$plugin_dir" rev-parse --short HEAD 2>/dev/null || echo "unknown")

    printf "   %s  %-30s [%s]\n" "$status_icon" "$name" "$commit"
    ((count++))
  done

  if (( count == 0 )); then
    echo "   (none)"
    echo ""
    echo "   Add a plugin with: myzsh-plugin-add <repo-url>"
  else
    echo ""
    echo "   ${count} plugin(s) installed"
  fi
}

# ─── Source Plugins ───────────────────────────────────────────────────
# Sources all installed plugins during shell initialization
myzsh-load-plugins() {
  for plugin_dir in "$MYZSH_PLUGINS_DIR"/*(N/); do
    local name=$(basename "$plugin_dir")
    local plugin_file="$plugin_dir/${name}.plugin.zsh"

    if [[ -f "$plugin_file" ]]; then
      if type myzsh-safe-source &>/dev/null; then
        myzsh-safe-source "$plugin_file"
      else
        source "$plugin_file"
      fi
    fi
  done
}
