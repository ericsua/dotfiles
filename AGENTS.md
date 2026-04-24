# Dotfiles (chezmoi)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), targeting macOS (Apple Silicon) as the primary platform.

## Repository Structure

```
dot_zshenv         # Zsh env (XDG vars, PATH, cargo) — sourced for ALL zsh invocations
dot_zshrc.tmpl    # Zsh config (chezmoi template — uses variables from chezmoi.toml)
dot_p10k.zsh      # Powerlevel10k prompt theme config
dot_gitconfig      # Git config (VS Code merge/diff, LFS, commit template)
dot_bashrc         # Minimal bash config (LM Studio, Cargo)
setup.sh           # Bootstrap script for fresh machines (macOS + Linux)
README.md          # User-facing setup instructions
```

### .zshenv vs .zshrc

Environment variables (XDG paths, PATH, language env init like `cargo env`) live in `dot_zshenv` so they're set for non-interactive zsh too (scripts, `ssh host 'cmd'`, GUI-launched processes). Interactive-only config (plugins, prompt, key bindings, aliases, completions) stays in `dot_zshrc.tmpl`.

## Architecture Decisions

### Zinit-only plugin management (no full Oh My Zsh framework)

All plugins are loaded via zinit. Individual OMZ plugins are loaded as snippets (`zinit snippet OMZP::git`), NOT through the full Oh My Zsh framework (`source $ZSH/oh-my-zsh.sh`). This avoids:
- Double plugin loading (zinit + OMZ loading the same plugin)
- Theme conflicts (p10k via zinit vs ZSH_THEME in OMZ)
- Slower startup from OMZ's full init

If adding a new OMZ plugin, use `zinit snippet OMZP::<plugin>`. For non-OMZ plugins, use `zinit light <github-user>/<repo>`.

### Template variables

The `.zshrc` is a chezmoi template (`dot_zshrc.tmpl`). Variables are defined in `~/.config/chezmoi/chezmoi.toml` (local, NOT committed):

- `gitlab_token` — Primary GitLab token for NUV_INDEX PyPI registries
- `gitlab_token_2` — Secondary GitLab token (project 374)
- `gen_project_id` — Google Cloud project ID

### Single compinit

`compinit` is called exactly once, after all plugins and fpath additions. Do not add extra `compinit` calls.

### Consolidated compiler flags

LDFLAGS and CPPFLAGS combine LibOMP + LLVM in a single export. Do not add separate exports that overwrite them.

## Common Tasks

- **Add a dotfile:** `chezmoi add ~/.some-config`, then commit
- **Edit managed file:** Edit the source in this repo, then `chezmoi apply`
- **Add a new secret:** Add to `chezmoi.toml` under `[data]`, reference as `{{ .var_name }}` in `.tmpl` files
- **Add a zsh plugin:** Add `zinit light <user>/<repo>` or `zinit snippet OMZP::<name>` in the Plugins section
- **Preview changes:** `chezmoi diff`

## Things to Watch Out For

- Do not re-introduce `source $ZSH/oh-my-zsh.sh` or `plugins=(...)` — use zinit instead
- Do not source plugins via `brew --prefix` if they're already loaded by zinit (causes double-loading)
- Do not call `eval "$(fzf --zsh)"` more than once
- Use `$HOME` instead of hardcoded `/Users/ericsuardi/` for portability
- `enable-fzf-tab` must be called after zsh-autocomplete to re-enable fzf-tab's overrides
- zoxide init should be near the end of shell integrations (it prints a warning otherwise)
