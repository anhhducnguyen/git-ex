# git-ex

## One-shot terminal setup with dotfiles

This repository now includes a `dotfiles` folder so you can run one command and get:

- `zsh`, `git`, `curl` (and `lsd` when available)
- Oh My Zsh
- Plugins: `zsh-autosuggestions`, `zsh-syntax-highlighting`
- Theme: `robbyrussell`
- Auto-switch from `bash` to `zsh` for interactive shells

### Run once

```bash
bash dotfiles/bootstrap.sh
```

Optional: install a global command `setupterminal`:

```bash
bash dotfiles/install-global.sh
setupterminal
```
