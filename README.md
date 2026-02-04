# Dotfiles

One command to configure a fresh machine.

## Quick Start

Run this command on a fresh macOS or Linux system:

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/bjk/dotfiles/main/bootstrap.sh)"
```

## What This Does

The bootstrap script will:

- Install Homebrew (if not already present)
- Install chezmoi dotfiles manager via Homebrew
- Apply dotfiles configuration from this repository
- Configure your shell and development environment

Works on both macOS and Linux.

## Encryption & Secrets

This repository uses age encryption for sensitive files. On first setup:

1. An age encryption key is automatically generated
2. The public key is displayed - **back it up immediately**
3. See [docs/encryption.md](docs/encryption.md) for full documentation

### Important

- Back up your age key to Bitwarden or another secure location
- Without the key backup, encrypted files cannot be recovered

## Requirements

- macOS or Linux operating system
- curl (pre-installed on both platforms)
- Internet connection

## Re-running

The bootstrap script is idempotent - it's safe to run multiple times. If interrupted or if you want to update your configuration, just run the command again. The script will skip steps that are already complete.

## Troubleshooting

If something goes wrong:

1. Check `~/.dotfiles-bootstrap.log` for detailed output
2. Common issues:
   - Network connectivity: Ensure you can reach github.com and brew.sh
   - Permissions: The script may prompt for sudo password during Homebrew installation
   - Disk space: Ensure you have at least 1GB free space

To manually verify installations:
```bash
# Check Homebrew
brew --version

# Check chezmoi
chezmoi --version

# Check applied dotfiles
chezmoi status
```

## Managing Dotfiles

After bootstrap completes, use these commands:

```bash
# See what would change
chezmoi diff

# Apply latest dotfiles
chezmoi apply

# Update from repository
chezmoi update

# Edit a dotfile
chezmoi edit ~/.bashrc
```

For more information, see the [chezmoi documentation](https://www.chezmoi.io/).
