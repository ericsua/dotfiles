# Dotfiles (chezmoi)

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), targeting macOS (Apple Silicon) as the primary platform.

## Repository Structure

```
dot_zshenv                       # Zsh env (XDG vars, PATH, cargo, ls colors) — sourced for ALL zsh invocations
dot_zshrc.tmpl                   # Zsh config (chezmoi template — uses variables from chezmoi.toml)
dot_zaliases                     # Shell aliases (sourced from .zshrc)
dot_p10k.zsh                     # Powerlevel10k prompt theme config
dot_gitconfig                    # Git config (VS Code merge/diff, LFS, commit template)
dot_bashrc                       # Minimal bash config (LM Studio, Cargo)
dot_config/ghostty/config.ghostty # Ghostty terminal config (XDG location, .ghostty extension since v1.3.0)
dot_config/tmux/tmux.conf        # tmux config + TPM bootstrap (XDG location)
setup.sh                         # Bootstrap script for fresh machines (macOS + Linux)
README.md                        # User-facing setup instructions
```

### .zshenv vs .zshrc vs .zaliases

- **`dot_zshenv`** — environment variables (XDG paths, PATH, language env init like `cargo env`, `LS_COLORS`/`LSCOLORS`/`CLICOLOR`). Sourced for every zsh invocation including non-interactive contexts (scripts, `ssh host 'cmd'`, GUI-launched processes).
- **`dot_zshrc.tmpl`** — interactive-only config: plugins, prompt, key bindings, completions, shell integrations.
- **`dot_zaliases`** — shell aliases only; sourced from `.zshrc`. Kept separate so `which <alias>` points to a single canonical file and so other shells (e.g. `.bashrc`) can source it.

### XDG-managed app configs

Tools whose configs live under `~/.config/` (the XDG default) go in `dot_config/<app>/...` in the chezmoi repo:

- **Ghostty** (>= 1.3.0) — `dot_config/ghostty/config.ghostty`. The `.ghostty` extension became the canonical name in v1.3.0 (PR ghostty-org/ghostty#8885); both names still work, but `config.ghostty` takes priority when both exist (and unlocks editor syntax highlighting via the Ghostty VS Code/Zed extensions). Ghostty checks `$XDG_CONFIG_HOME/ghostty/` first on macOS, before the legacy `~/Library/Application Support/com.mitchellh.ghostty/`.
- **tmux** (>= 3.1) — `dot_config/tmux/tmux.conf`. Auto-discovered; no need to symlink to `~/.tmux.conf`. TPM is auto-bootstrapped on first tmux start (and also installed by `setup.sh`).

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
