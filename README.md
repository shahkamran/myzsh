# myzsh

**Fast. Secure. Beautiful.**

A minimalist, security-conscious, decorative zsh framework with sub-100ms startup, powerline-style prompts, and transparency-aware themes.

<!-- Screenshot here -->

---

## ✨ Features

- ⚡ **Sub-100ms startup** — deferred loading keeps your prompt instant
- 🎨 **Rich powerline-style prompt** — git branch/status, execution time, Nerd Font icons
- 🪟 **Transparency-aware themes** — designed for blurred/transparent terminal emulators
- 🎭 **3 built-in themes** — `powerline`, `minimal`, `pure`
- 🔒 **Security first** — SHA-256 checksum verification, safe-source, file permission checks
- 📁 **Modular aliases** — git, docker, system, navigation, and custom groups
- 🔧 **Autoloaded utility functions** — extract, take, note, port-kill, and more
- 🔍 **Smart tab completion** — fuzzy matching, case-insensitive, coloured menus
- 🕵️ **Secure history** — automatically filters tokens, passwords, and secrets
- ⌨️ **Keyboard shortcuts** — word navigation, directory jumping, command editing
- 🔌 **Plugin management** — git submodules with checksum integrity verification

---

## 🚀 Quick Install

```bash
git clone https://github.com/shahkamran/myzsh.git ~/.myzsh && ~/.myzsh/install.sh
```

This will:
1. Clone the framework to `~/.myzsh`
2. Symlink the zshrc
3. Install default plugins as git submodules
4. Set correct directory permissions (`700`)

---

## 🔄 Updating

To update myzsh to the latest version:

```bash
cd ~/.myzsh && git pull && git submodule update --init --recursive
```

Or use the built-in shortcut (available after install):

```bash
myzsh-update
```

### What gets updated

- Framework files (lib/, themes/, aliases/, functions/)
- Plugin submodules (pulled to latest pinned commit)
- Lockfile should be regenerated after update:

```bash
myzsh-update-lock
```

### Safe files (never overwritten)

These are yours and won't be touched by updates:

| File | Purpose |
|------|---------|
| `myzsh.conf` | Your configuration |
| `aliases/custom.zsh` | Your personal aliases |
| `local.zsh` | Machine-specific overrides |
| `functions/*` (custom) | Your custom functions |

### Update plugins only

```bash
myzsh-plugin-update --all   # Update all plugins to latest
myzsh-plugin-update <name>  # Update a specific plugin
```

After updating plugins, regenerate the lockfile:

```bash
myzsh-update-lock
```

### Verify integrity after update

```bash
myzsh-verify
```

This checks all plugin and theme files against their SHA-256 checksums in `myzsh.lock`.

---

## ⚙️ Configuration

All settings live in `~/.myzsh/myzsh.conf`. Changes take effect on your next shell session (or run `reload`).

```zsh
# ─── Theme ───────────────────────────────────────────────────────────
MYZSH_THEME="powerline"         # powerline | minimal | pure
MYZSH_NERD_FONTS=true           # Enable Nerd Font icons
MYZSH_TRANSPARENT=true          # Transparency-aware colour scheme
MYZSH_COLOR_SCHEME="dark"       # dark | light

# ─── Prompt ──────────────────────────────────────────────────────────
MYZSH_SHOW_GIT=true             # Show git branch/status
MYZSH_SHOW_EXEC_TIME=true       # Show execution time for long commands
MYZSH_EXEC_TIME_THRESHOLD=3     # Seconds before time is shown
MYZSH_SHOW_VERSIONS=false       # Show Node/Python/Ruby version

# ─── Performance ─────────────────────────────────────────────────────
MYZSH_DEFER=true                # Enable deferred loading
MYZSH_BENCHMARK=false           # Profile startup with zprof

# ─── Security ────────────────────────────────────────────────────────
MYZSH_VERIFY_PLUGINS=true       # SHA-256 checksum verification
MYZSH_STRICT_PERMISSIONS=true   # Enforce ownership/permission checks

# ─── Aliases ─────────────────────────────────────────────────────────
MYZSH_ALIASES=(git docker system navigation custom)

# ─── Plugins ─────────────────────────────────────────────────────────
MYZSH_PLUGINS=(
  zsh-autosuggestions
  zsh-completions
  zsh-syntax-highlighting
)

# ─── History ─────────────────────────────────────────────────────────
MYZSH_HISTSIZE=50000
MYZSH_SAVEHIST=50000
MYZSH_HIST_SHARE=true           # Share history across sessions

# ─── Completion ──────────────────────────────────────────────────────
MYZSH_FUZZY_COMPLETION=true
MYZSH_CASE_INSENSITIVE=true

# ─── Key Bindings ────────────────────────────────────────────────────
MYZSH_KEYBIND_STYLE="emacs"     # emacs | vim
```

---

## 🎭 Themes

### powerline

Rich, decorative prompt with segments, arrows, and full git integration. Requires a [Nerd Font](https://www.nerdfonts.com/).

```
  ~/.myzsh   main ✓  node 20.11   3s  
❯
```

### minimal

Clean, fast, single-line prompt with subtle git info:

```
~/projects/app on main* ❯
```

### pure

Two-line prompt inspired by [sindresorhus/pure](https://github.com/sindresorhus/pure). Async-friendly with execution time display:

```
~/projects/app main ✗ 5s

❯
```

Set your theme in `myzsh.conf`:

```zsh
MYZSH_THEME="minimal"
```

---

## 📁 Aliases

Aliases are grouped into modules. Enable or disable groups in `myzsh.conf`:

| Group | File | Examples |
|-------|------|----------|
| **git** | `aliases/git.zsh` | `gs`, `ga`, `gc`, `gp`, `gl`, `gd`, `gco` |
| **docker** | `aliases/docker.zsh` | `dk`, `dkc`, `dkps`, `dkimg`, `dkrm` |
| **system** | `aliases/system.zsh` | `ll`, `la`, `df`, `du`, `ports`, `psg` |
| **navigation** | `aliases/navigation.zsh` | `..`, `...`, `~`, `-`, `d` (dirs) |
| **custom** | `aliases/custom.zsh` | Your personal aliases |

Add your own aliases to `aliases/custom.zsh` — it won't be overwritten by updates.

---

## 🔧 Functions

Autoloaded utility functions available from `~/.myzsh/functions/`:

| Function | Description |
|----------|-------------|
| `extract <file>` | Universal archive extractor (tar, zip, rar, 7z, gz, bz2, xz, zst) |
| `take <url\|dir>` | Clone a repo and cd into it, or mkdir + cd |
| `mkcd <dir>` | Create directory and cd into it |
| `up [N]` | Go up N directories (default: 1) |
| `port-kill <port>` | Kill process running on a specific port |
| `note [msg]` | Quick scratch notes (`note -c` to clear) |
| `cheat <topic>` | Fetch cheatsheet from cheat.sh |
| `colours [256]` | Display terminal colour palette |

---

## ⌨️ Key Bindings

Default mode is **emacs** (set `MYZSH_KEYBIND_STYLE="vim"` for vi mode).

| Key | Action |
|-----|--------|
| `Ctrl+A` | Beginning of line |
| `Ctrl+E` | End of line |
| `Ctrl+R` | Reverse history search |
| `Ctrl+S` | Forward history search |
| `Ctrl+W` | Delete word backward |
| `Alt+D` | Delete word forward |
| `Ctrl+U` | Delete to beginning of line |
| `Ctrl+K` | Delete to end of line |
| `Ctrl+L` | Clear screen |
| `Ctrl+Z` | Undo |
| `Ctrl+Y` | Yank (paste killed text) |
| `Ctrl+Space` | Accept autosuggestion |
| `Ctrl+X Ctrl+E` | Edit command in `$EDITOR` |
| `Ctrl+Right/Left` | Word navigation |
| `Alt+F / Alt+B` | Forward / backward word |
| `Alt+Up` | Navigate to parent directory |
| `Alt+Left` | Pop directory stack (go back) |
| `Up/Down` | History search by prefix |

---

## 🔒 Security

myzsh takes a defence-in-depth approach:

### Safe Source

Every file is checked before being `source`'d:

1. **Ownership** — must be owned by the current user or root
2. **Permissions** — world-writable files are refused
3. **Checksum** — plugins are verified against `myzsh.lock` (SHA-256)

### Lockfile

Plugin integrity is managed via a lockfile:

```bash
myzsh-update-lock   # Generate/update checksums for all plugins and themes
myzsh-verify        # Verify all files against the lockfile
```

If a plugin file is modified unexpectedly, myzsh will refuse to load it and alert you.

### Directory Permissions

With `MYZSH_STRICT_PERMISSIONS=true`, the `~/.myzsh` directory is automatically set to `700` (owner-only access).

### History Security

Sensitive commands are **never** written to history:

- `export` commands containing `TOKEN`, `SECRET`, `PASSWORD`, or `KEY`
- Database connection strings with passwords
- `curl`/`wget` with auth headers or credentials

---

## ⚡ Performance

### How Deferred Loading Works

myzsh achieves sub-100ms startup by splitting the load into two phases:

**Phase 1 — Immediate (before prompt):**
- Security module
- Init & environment
- History configuration
- Key bindings
- Theme
- Completion
- Aliases
- Functions (autoloaded, not executed)

**Phase 2 — Deferred (after prompt is displayed):**
- Syntax highlighting
- Autosuggestions
- Plugin loading

The deferred engine uses a `precmd` hook + `zsh/sched` to execute queued commands after the first prompt renders. You see your prompt instantly while plugins load silently in the background.

### Benchmarking

Enable profiling to measure startup:

```zsh
# In myzsh.conf
MYZSH_BENCHMARK=true
```

This activates `zprof` and prints a breakdown when the shell starts.

---

## 🛠 Customization

### Adding a Custom Theme

1. Create a directory: `~/.myzsh/themes/mytheme/`
2. Create the theme file: `mytheme.zsh-theme`
3. Set it in config: `MYZSH_THEME="mytheme"`

Theme files have full access to zsh prompt escapes and should set `PROMPT`, `RPROMPT`, and optionally `PROMPT2`.

### Adding Custom Aliases

Edit `~/.myzsh/aliases/custom.zsh` — this file is designated for your personal aliases and won't be overwritten.

### Adding Custom Functions

1. Create a file in `~/.myzsh/functions/` (no extension needed)
2. The filename becomes the function name
3. Functions are autoloaded on first call (zero startup cost)

Example `~/.myzsh/functions/weather`:

```zsh
# Show weather for a city
# Usage: weather [city]
curl -s "wttr.in/${1:-}"
```

### Local Overrides

Create `~/.myzsh/local.zsh` for machine-specific settings that shouldn't be tracked by git.

---

## 🗑 Uninstall

```bash
# Remove the myzsh directory
rm -rf ~/.myzsh

# Restore your original .zshrc (if backed up)
mv ~/.zshrc.backup ~/.zshrc

# Or set zsh to use default config
echo "" > ~/.zshrc

# Clean up cache and data
rm -rf ~/.cache/myzsh
rm -rf ~/.local/share/myzsh
```

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. **Fork** the repository
2. **Create a branch**: `git checkout -b feature/my-feature`
3. **Make your changes** — follow the existing code style
4. **Test** — ensure startup stays under 100ms
5. **Commit**: `git commit -m "feat: add my feature"`
6. **Push**: `git push origin feature/my-feature`
7. **Open a Pull Request**

### Guidelines

- Keep it minimal — features should justify their startup cost
- Security matters — never bypass safe-source checks
- Document new aliases/functions with inline comments
- Test with both `MYZSH_NERD_FONTS=true` and `false`
- Use [Conventional Commits](https://www.conventionalcommits.org/) for commit messages

### Reporting Issues

Please include:
- Your OS and zsh version (`zsh --version`)
- Terminal emulator
- Relevant section of `myzsh.conf`
- Output with `MYZSH_BENCHMARK=true` if it's a performance issue

---

<p align="center">
  <sub>Made with care for the terminal aesthetic ✨</sub>
</p>
