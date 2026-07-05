#!/usr/bin/env zsh
# ╔══════════════════════════════════════════════════════════════════════╗
# ║  myzsh :: aliases/git                                              ║
# ║  Git shortcuts for daily workflow                                   ║
# ╚══════════════════════════════════════════════════════════════════════╝

# ─── Status & Info ────────────────────────────────────────────────────
alias gs='git status -sb'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all -30'
alias glp='git log --pretty=format:"%C(yellow)%h%Creset %C(blue)%ad%Creset %C(green)%an%Creset %s%C(red)%d%Creset" --date=short -20'
alias gd='git diff'
alias gds='git diff --staged'
alias gsh='git show --stat'

# ─── Branching ────────────────────────────────────────────────────────
alias gb='git branch'
alias gba='git branch -a'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gsc='git switch -c'
alias gbd='git branch -d'

# ─── Staging & Committing ─────────────────────────────────────────────
alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'

# ─── Push & Pull ──────────────────────────────────────────────────────
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpu='git push -u origin HEAD'
alias gpl='git pull'
alias gplr='git pull --rebase'
alias gf='git fetch --all --prune'

# ─── Stash ────────────────────────────────────────────────────────────
alias gst='git stash'
alias gstl='git stash list'
alias gstp='git stash pop'
alias gstd='git stash drop'

# ─── Rebase & Merge ──────────────────────────────────────────────────
alias grb='git rebase'
alias grbi='git rebase -i'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gm='git merge'
alias gma='git merge --abort'

# ─── Utility ─────────────────────────────────────────────────────────
alias gcp='git cherry-pick'
alias gcl='git clone --depth 1'
alias grh='git reset HEAD'
alias grhh='git reset HEAD --hard'
alias gclean='git clean -fd'
alias gwip='git add -A && git commit -m "🚧 WIP"'
alias gunwip='git log -1 --format="%s" | grep -q "WIP" && git reset HEAD~1'
