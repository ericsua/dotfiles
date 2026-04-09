# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## What's Included

| File | Description |
|------|-------------|
| `.zshrc` | Zsh config with zinit, Powerlevel10k, fzf, zoxide, and more |
| `.p10k.zsh` | Powerlevel10k prompt configuration |
| `.gitconfig` | Git configuration (VS Code merge/diff tools, LFS) |
| `.bashrc` | Minimal bash fallback config |

## Quick Start

### One-liner (fresh machine)

```bash
curl -fsSL https://raw.githubusercontent.com/ericsua/dotfiles/main/setup.sh | bash
```

### Manual Setup

1. **Install chezmoi**

   ```bash
   # macOS
   brew install chezmoi

   # Linux
   sh -c "$(curl -fsLS get.chezmoi.io)"
   ```

2. **Configure template variables**

   Create `~/.config/chezmoi/chezmoi.toml` with your secrets:

   ```toml
   [data]
     gitlab_token = "glpat-YOUR_PRIMARY_TOKEN"
     gitlab_token_2 = "glpat-YOUR_SECONDARY_TOKEN"
     gen_project_id = "your-gcp-project-id"
   ```

   These variables are used in `.zshrc` for:
   - `gitlab_token` — GitLab PyPI package registry access (NUV_INDEX)
   - `gitlab_token_2` — GitLab PyPI access for project 374
   - `gen_project_id` — `GOOGLE_CLOUD_PROJECT` environment variable

3. **Initialize and apply**

   ```bash
   chezmoi init --apply ericsua/dotfiles
   ```

4. **Restart your terminal** — zinit will auto-download all plugins on first launch.

## Dependencies

### Required

| Tool | Install (macOS) | Install (Linux) | Purpose |
|------|----------------|-----------------|---------|
| [zsh](https://www.zsh.org/) | Pre-installed | `apt install zsh` | Shell |
| [git](https://git-scm.com/) | `brew install git` | `apt install git` | Version control |
| [fzf](https://github.com/junegunn/fzf) | `brew install fzf` | `apt install fzf` | Fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | `brew install zoxide` | [install script](https://github.com/ajeetdsouza/zoxide#installation) | Smarter cd |
| [pyenv](https://github.com/pyenv/pyenv) | `brew install pyenv` | [pyenv-installer](https://github.com/pyenv/pyenv#installation) | Python version manager |
| [uv](https://github.com/astral-sh/uv) | `brew install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` | Python package manager |

### Optional

| Tool | Install (macOS) | Purpose |
|------|----------------|---------|
| [llvm](https://llvm.org/) | `brew install llvm` | C/C++ compiler toolchain |
| [libomp](https://openmp.llvm.org/) | `brew install libomp` | OpenMP support |
| [ngrok](https://ngrok.com/) | `brew install ngrok` | Tunneling |
| [Go](https://go.dev/) | `brew install go` | Go toolchain |
| [Docker Desktop](https://www.docker.com/) | [Download](https://www.docker.com/products/docker-desktop/) | Container runtime |
| [Google Cloud SDK](https://cloud.google.com/sdk) | [Download](https://cloud.google.com/sdk/docs/install) | GCP CLI |
| [LM Studio](https://lmstudio.ai/) | [Download](https://lmstudio.ai/) | Local LLM inference |
| [Cargo/Rust](https://rustup.rs/) | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` | Rust toolchain |

### Auto-installed (no manual action needed)

- **[zinit](https://github.com/zdharma-continuum/zinit)** — Plugin manager, auto-cloned on first shell launch
- **[Powerlevel10k](https://github.com/romkatv/powerlevel10k)** — Prompt theme, installed via zinit
- **zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions, fzf-tab, zsh-autocomplete** — All managed by zinit

## Updating

```bash
# Pull latest dotfiles and apply
chezmoi update

# Or see what would change first
chezmoi diff
```

## Adding New Dotfiles

```bash
# Add an existing file to chezmoi management
chezmoi add ~/.some-config

# Edit a managed file
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply
```

## Template Variables

The `.zshrc` uses chezmoi's [template system](https://www.chezmoi.io/user-guide/templating/) to inject secrets. Template variables are stored in `~/.config/chezmoi/chezmoi.toml` (which is **not** committed to the repo).

To add a new template variable:

1. Add it to your local `chezmoi.toml`:
   ```toml
   [data]
     my_new_var = "value"
   ```
2. Reference it in any `.tmpl` file:
   ```
   export MY_VAR="{{ .my_new_var }}"
   ```
3. Run `chezmoi apply` to regenerate the target files.

## Architecture Notes

- **No full Oh My Zsh framework** — Individual OMZ plugins are loaded as zinit snippets (`OMZP::git`, `OMZP::docker`, etc.), which is faster and avoids the overhead of the full OMZ init.
- **Single `compinit` call** — Completions are loaded once, after all plugins.
- **Consolidated compiler flags** — LDFLAGS/CPPFLAGS combine LibOMP and LLVM paths in a single export.
- **`$HOME` everywhere** — No hardcoded usernames in paths.
