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
