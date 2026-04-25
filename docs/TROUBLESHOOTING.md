# Troubleshooting

## VirtualBox Shared Folders

### CRLF Line Endings (Auto-Fixed)

**Problem**: VirtualBox `vboxsf` mounts inject `\r` (CRLF) into every file, breaking bash scripts.

**Solution**: gideon handles this automatically. The main script detects CRLF contamination and re-executes itself through `tr -d '\r'` at runtime. No manual intervention needed.

If you're developing gideon itself on a shared folder, see [ARCHITECTURE.md](ARCHITECTURE.md#crlf-self-healing-virtualbox) for how the self-healing works.

### SSH Key Permissions

**Problem**: SSH keys on VirtualBox shared folders (`vboxsf`) get `0777` permissions, which SSH rejects.

**Solution**: Store SSH keys on the native filesystem, not the shared folder:

```bash
# Keys should be at ~/.ssh/ on the VM's native filesystem
# NOT at /media/sf_dev/.ssh/ or similar shared paths
ls -la ~/.ssh/id_ed25519_*
# Should show: -rw------- (600)
```

If permissions are wrong:
```bash
chmod 600 ~/.ssh/id_ed25519_*
chmod 644 ~/.ssh/id_ed25519_*.pub
```

### `safe.directory` Warnings

**Problem**: Git refuses to operate in shared folders, showing `unsafe repository` errors.

**Solution**:
```bash
# Add specific paths (recommended)
git config --global --add safe.directory /media/sf_dev/pro/myrepo

# Or allow all (less secure, but convenient for dev VMs)
git config --global safe.directory '*'
```

## WSL (Windows Subsystem for Linux)

### SSH Agent

WSL does not share the Windows SSH agent. Start the agent in each WSL session:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_<label>
```

To auto-start, add to your `~/.bashrc`:
```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
```

### Path Differences

WSL uses Linux paths (`/home/user/`) not Windows paths (`C:\Users\user\`). gideon detects WSL automatically and uses the correct path format.

## Git Bash on Windows

### Line Endings

gideon's `.gitattributes` enforces LF line endings. If you see CRLF-related issues:
```bash
git config --global core.autocrlf input
```

### Path Format

Git Bash uses POSIX-style paths (`/c/Users/...`). gideon normalizes paths automatically, but if you manually edit config files, use forward slashes.

## SSH Issues

### "Permission denied (publickey)"

This means the SSH key hasn't been added to GitHub/GitLab:

1. Copy your public key: `cat ~/.ssh/id_ed25519_<label>.pub`
2. Add it at: https://github.com/settings/ssh/new
3. Test: `ssh -T git@github-<label>`

### "Key already exists" on GitHub

Each SSH public key can only be added to ONE GitHub account. If you see this error:
- The key is already registered on a different GitHub account
- Remove it from the other account first, or generate a new key

### "Could not resolve hostname github-pro"

The host alias `github-pro` is defined in `~/.ssh/config`. Check that:
1. The file exists: `cat ~/.ssh/config`
2. It contains the `Host github-pro` block
3. There are no syntax errors (extra spaces, missing fields)

### Testing SSH Connectivity

```bash
# Test each profile
ssh -T git@github-global
ssh -T git@github-pro
ssh -T git@github-work

# Expected success output:
# Hi username! You've successfully authenticated...

# Debug mode for detailed info:
ssh -vT git@github-pro
```

> **Note:** These host aliases (`github-pro`, `github-work`) are generated **purely for testing connectivity**. You do NOT need to use them when cloning repositories. You can always clone normally using `git clone git@github.com:...` as long as you are inside your profile's configured directory!

## Git Config Issues

### includeIf Not Working

The `includeIf "gitdir:..."` directive requires:

1. **Trailing slash** on the path: `gitdir:~/dev/pro/` (not `gitdir:~/dev/pro`)
2. **The directory must contain a git repo** (`.git` directory)
3. **Case sensitivity**: Use `gitdir/i:` on Windows/Git Bash for case-insensitive matching

gideon handles all three automatically, but if you manually edit `~/.gitconfig`, watch for these.

### Checking Active Identity

```bash
# In any directory:
git config user.email
git config user.name
git config core.sshCommand

# See where a value comes from:
git config --show-origin user.email
```

## Guard Hook Issues

### Hook Not Triggering

Check that `core.hooksPath` is set:
```bash
git config --global core.hooksPath
# Should show: ~/.config/gideon/hooks
```

Check the hook is executable:
```bash
ls -la ~/.config/gideon/hooks/pre-commit
# Should show: -rwx------
```

### Bypassing the Hook

For a single commit:
```bash
git commit --no-verify -m "message"
```

To disable permanently:
```bash
./gideon guard --uninstall
```
