# devcontainer-features

Personal [Dev Container Features](https://containers.dev/implementors/features/), applied globally via
VS Code's `dev.containers.defaultFeatures` user setting rather than being added to any individual
project's `devcontainer.json`.

## personal-mounts

Bind-mounts the host's `~/.config/gh` and `~/.claude` into the container so `gh` auth and Claude Code
config/memory persist across container rebuilds/resets — no secrets stored in git, no per-project
`devcontainer.json` edits, no re-login after every rebuild.

Assumes the container's default user is `root` (true for image-only devcontainer configs with no
`remoteUser` set, e.g. `ghcr.io/edgetx/edgetx-dev`). If a project's image runs as a non-root user by
default, fork this and change the `target` paths in `devcontainer-feature.json` to match that user's
home directory.

Works on macOS, Linux, and Windows. The mount `source` resolves the host home directory as
`${localEnv:HOME}${localEnv:USERPROFILE}` — the [documented cross-platform
idiom](https://containers.dev/implementors/json_reference/#variables-in-devcontainerjson): macOS/Linux
set `HOME` and leave `USERPROFILE` unset, Windows sets `USERPROFILE` and (usually) leaves `HOME` unset,
so concatenating them picks up whichever one exists. **Known caveat:** if you launch VS Code from Git
Bash on Windows, Git Bash sets `HOME` itself while Windows still has `USERPROFILE` set too, so both
resolve and get concatenated into one broken path — launch VS Code normally (Start Menu/Explorer,
`code .` from cmd/PowerShell) instead.

The feature also sets `CLAUDE_CONFIG_DIR=/root/.claude`, so Claude Code keeps its `.claude.json` (login
state, per-project settings, user-scoped MCP servers) inside the mounted directory too. Without it,
Claude Code reads `~/.claude.json` from the container's home, which is lost on every rebuild. The host's
own `~/.claude.json` is untouched, so host and container keep separate copies.

**Things the host and container share or don't:**

- `settings.json`, `CLAUDE.md`, skills, agents, commands and plugins are shared. Hooks, `statusLine`
  commands and `env` entries must work on both the host OS and Linux.
- Sessions and memory are keyed by the project's path, so the same repo checked out on the host and
  mounted in the container (e.g. `/workspaces/<repo>`) gets separate histories.
- On macOS, `gh` stores its token in the Keychain by default, so the host's `hosts.yml` may have no token
  the container can use. Run `gh auth login` once inside the container; the token it writes to the
  shared `hosts.yml` then persists across rebuilds.

### Publishing

Handled automatically by [`.github/workflows/publish.yml`](.github/workflows/publish.yml) on every
push to `master` that touches `src/**`, using the official
[`devcontainers/action`](https://github.com/devcontainers/action). It authenticates to GHCR with the
workflow's own `GITHUB_TOKEN` — no local Docker, no personal access token needed. To ship a new
version, bump `version` in `devcontainer-feature.json` and push; the action only publishes versions
that don't already exist as a tag.

**One-time step after the first successful run:** features publish to GHCR as a **private** package by
default. Go to the package's settings on GitHub (`pfeerick` → Packages → `devcontainer-features/personal-mounts`
→ Package settings) and change visibility to Public — otherwise any devcontainer pulling it via
`dev.containers.defaultFeatures` will hit a registry auth wall, which defeats the point.

This publishes `ghcr.io/pfeerick/devcontainer-features/personal-mounts:1`.

### Use it (VS Code user settings.json, not project-level)

```json
"dev.containers.defaultFeatures": {
  "ghcr.io/pfeerick/devcontainer-features/personal-mounts:1": {}
}
```

### One-time local safety net

Using default features can cause VS Code to write a `devcontainer-lock.json` into whatever project
you open, recording the resolved feature version. Keep that out of every project's git status without
touching any project's own `.gitignore`:

```bash
mkdir -p ~/.config/git
echo 'devcontainer-lock.json' >> ~/.config/git/ignore
git config --global core.excludesFile ~/.config/git/ignore
```
