# myzsh Plugins

Plugins extend myzsh with additional functionality. They are managed as **git submodules**, ensuring reproducible versions and easy updates.

## Commands

| Command | Description |
|---------|-------------|
| `myzsh-plugin-add <repo-url>` | Add a plugin as a git submodule |
| `myzsh-plugin-remove <name>` | Remove a plugin submodule |
| `myzsh-plugin-update [name\|--all]` | Update one or all plugins |
| `myzsh-plugin-list` | List installed plugins |

## How It Works

Each plugin is cloned as a git submodule into the `plugins/` directory. When a plugin is added or removed, the lockfile (`myzsh.lock`) is automatically regenerated to track checksums for security verification.

Plugins are sourced via their `*.plugin.zsh` entry file during shell initialization.

## Recommended Plugins

These are well-maintained community plugins that work great with myzsh:

### zsh-autosuggestions

Fish-like autosuggestions based on command history.

```sh
myzsh-plugin-add https://github.com/zsh-users/zsh-autosuggestions.git
```

### zsh-completions

Additional completion definitions for many CLI tools.

```sh
myzsh-plugin-add https://github.com/zsh-users/zsh-completions.git
```

### zsh-syntax-highlighting

Real-time syntax highlighting as you type commands.

```sh
myzsh-plugin-add https://github.com/zsh-users/zsh-syntax-highlighting.git
```

## Manual Installation

If you prefer to add plugins manually using git:

```sh
cd /path/to/myzsh
git submodule add https://github.com/zsh-users/zsh-autosuggestions.git plugins/zsh-autosuggestions
git submodule add https://github.com/zsh-users/zsh-completions.git plugins/zsh-completions
git submodule add https://github.com/zsh-users/zsh-syntax-highlighting.git plugins/zsh-syntax-highlighting
myzsh-update-lock
```
