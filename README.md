# gabrielbelli/homebrew-tap

Homebrew formulae for my Claude Code tools.

```bash
brew install gabrielbelli/tap/claude-statusline
```

| Formula | What it is |
| :--- | :--- |
| `claude-statusline` | [Status line for Claude Code](https://github.com/gabrielbelli/claude-statusline) — which account is billing the session, which profile is active, git, MCP servers, context and plan-limit usage |

Updating is `brew upgrade`, and uninstalling is `brew uninstall` — which is the point of the tap. Both tools are otherwise a `git clone` and a manual copy, and the manual route leaves you to notice new versions yourself.

## Releasing

Each formula pins a release tarball by checksum, so a new version is two edits — `url` and `sha256`:

```bash
gh release view --repo gabrielbelli/claude-statusline --json tagName
curl -fsSL https://github.com/gabrielbelli/claude-statusline/archive/refs/tags/vX.Y.Z.tar.gz | shasum -a 256
```

GitHub's generated tag tarballs are stable, so a checksum recorded once stays valid.

## Notes

`claude-statusline` installs as a command on `PATH`, so `~/.claude/settings.json` can say `"command": "claude-statusline"` instead of an absolute path into a clone. A path breaks the moment the repository moves; a command does not.
