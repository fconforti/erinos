# erinos

A personal OS for Claude Code, on Arch Linux: one repo that defines how a machine works. It holds
the `erin` CLI, the conventions every Claude Code session follows, the skills they all share, and
the systemd units. Site: [erinos.ai](https://erinos.ai).

```
curl -fsSL https://erinos.ai/install.sh | bash
```

The installer ([`install.sh`](install.sh)) shows what it will do and asks once before changing
anything. It installs `git tmux direnv python curl` from the official Arch repos, clones this repo
to `~/erinos`, runs `erin setup`, and enables lingering so the sessions come back at boot. Claude
Code itself is installed [its own way](https://code.claude.com/docs/en/setup).

Projects are Claude Code sessions: each one lives in a workspace (`~/<workspace>/<name>`), has its
own GitHub token, and runs Claude in a tmux session of the same name, with remote control on.

A workspace is a folder in `~` with a `.workspace` file, in git config syntax: the commit email and
name for every repo in it, and the GitHub owner of its new repos (`erin.owner`). git includes it
through `includeIf`, so commits pick up the workspace's identity with no per-repo setup. An optional
`~/<workspace>/CLAUDE.md` adds conventions for that workspace's projects.

## Layout

| Path | What | Wired as |
|------|------|----------|
| `bin/erin` | The CLI | `~/.local/bin/erin` |
| `claude/CLAUDE.md` | Conventions for every Claude session on the machine | `~/.claude/CLAUDE.md` |
| `skills/<name>/` | Skills every project's Claude can use (`SKILL.md` plus scripts) | `~/.claude/skills/<name>` |
| `systemd/` | User units (`erin-resume`: restart the Claude sessions at boot) | `~/.config/systemd/user/` |
| `site/` | The erinos.ai website (Astro), published to GitHub Pages with `install.sh` | — |

`erin setup` creates those links. It's safe to re-run, and `erin doctor` reports any link that's
missing.

Not in the repo, on purpose: secrets (`~/.secrets/`), Claude's memory and settings (`~/.claude/`),
the projects themselves, and anything about one machine. That goes in `~/.config/erinos/`:
`CLAUDE.md` (hardware, workspaces, servers; the conventions import it) and `tools.md`, the log of
every tool installed. `erin setup` creates both.

## erin

```
erin workspace [new|set|rename|rm]  workspaces: ~/<name> with a .workspace (email, owner)
erin new <workspace>/<name>      create a project (folder, git, HTTPS remote, .envrc, trust) and start Claude
erin start|stop|restart|attach <project>
erin ls                          projects: session, token, git sync, remote
erin doctor [project] [--fix]    conventions + git sync; --fix repairs the safe, mechanical problems
erin rename <project> <new>      rename a project with its session, Claude history and settings
erin move <project> <workspace>  move it to another workspace, the same way
erin secret [set|rm <name> <KEY>]  ~/.secrets/<name>.env, values never shown
erin skill [new <name>]          shared skills
erin resume-all                  restart the sessions that were running (also at boot)
erin setup                       wire erinos into the system
```

`erin help` has the details.

## A new machine

1. Install Arch and [Claude Code](https://code.claude.com/docs/en/setup), then run the installer.
2. Describe the machine in `~/.config/erinos/CLAUDE.md`.
3. Create a workspace: `erin workspace new personal --email you@example.com --owner <github-user>`.
4. Create a project: `erin new personal/hello`. It needs a fine-grained GitHub token for its repo:
   `erin secret set hello GH_TOKEN`.
5. `erin doctor` checks everything.

## The site

`site/` is an [Astro](https://astro.build) site; `.github/workflows/pages.yml` builds it on every
push to `main` that touches it or `install.sh`, and publishes it to GitHub Pages. Locally:
`cd site && npm install && npm run dev`.
