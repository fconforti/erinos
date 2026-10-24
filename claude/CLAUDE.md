# erinos: this machine's personal OS (Arch Linux, run as a server for Claude Code)

These conventions apply to every project. Keep them consistent and systematic; don't invent per-project variations.
This file lives in the erinos repo (`~/erinos/claude/CLAUDE.md`, linked as `~/.claude/CLAUDE.md`): change it there and commit.
What is specific to this machine (its workspaces, servers, extra tools) is in `~/.config/erinos/CLAUDE.md`, imported at the end; it stays out of the repo.

## Folder layout

- Projects live in **workspaces**: a workspace is a folder directly in `~` with a `.workspace` file (for example `~/personal`, `~/work`). `erin workspace` lists them.
- `.workspace` is in git config syntax: `user.email` (and optionally `user.name`) for every commit in the workspace, `erin.owner` for the GitHub owner of its new repos. git includes it through `includeIf "gitdir:~/<workspace>/"`, so it is the one place that decides a workspace's identity. Change it with `erin workspace set`, not by hand-editing `~/.gitconfig`.
- Conventions for one workspace only go in `~/<workspace>/CLAUDE.md`: Claude reads it in every project there, on top of this file.
- Projects sit directly in a workspace (`~/<workspace>/<project>`): no grouping subfolders. Project names are unique across all workspaces.
- `~/erinos/`: the erinos repo (github.com/fconforti/erinos, public): the `erin` CLI (`bin/`), these conventions (`claude/`), the skills every Claude gets (`skills/`), systemd user units (`systemd/`), the website (`site/`) and `install.sh`. `erin setup` links them into place. Secrets, Claude's memory, the projects and anything specific to this machine stay out of it: the repo is public.
- `~/.config/erinos/`: this machine's own part: `CLAUDE.md` (imported below) and `tools.md`, the log of every installed tool. Not in any repo.

## Projects and sessions: `erin`

- Each project runs as a Claude Code session in a tmux session named after its folder, with remote control on. The Claude session itself (prompt box, `/resume`, Remote Control in the app) is named `erinos-<project>`; the erinos repo's own session is `erinos`. `erin start` sets it, and `erin doctor --fix` renames idle sessions that drifted. Manage them with `erin`; don't hand-roll `tmux new-session` / `send-keys`.
- `erin new <workspace>/<name>` creates the folder, git repo, HTTPS remote (`<workspace owner>/<name>`) and `.envrc` following the rules below, trusts the folder for Claude, then starts Claude. `--token NAME` shares an existing token; `--repo OWNER/REPO` sets the remote.
- `erin start|stop|attach <project>`, `erin ls`, `erin resume-all` (runs at boot through the `erin-resume` user service).
- `erin rename <project> <new-name | <workspace>/<name>>` renames or moves a project with its tmux session, Claude history, memory and folder settings (trust) and `.envrc`; `erin move <project> <workspace>` is the short form for moving. Never `mv` a project by hand.
- `erin workspace new <name> --email E --owner O`, `erin workspace set <name> <email|owner|git-name> <value>`, `erin workspace rename <name> <new>` (moves every project in it the same way), `erin workspace rm <name>` (only once it has no projects).
- `erin secret [set|rm <name> <KEY>]` manages `~/.secrets/<name>.env`; `<name>` can also be a project.
- `erin restart <project> | --all` restarts Claude so it picks up changed conventions or skills.
- `erin doctor [project]` checks a project against these conventions plus its git sync (unpushed, unpulled, uncommitted); run it after changing a repo's remote, token or `.envrc`. `--fix` repairs the safe, mechanical problems (SSH remote, `.envrc` exclude, direnv allow, stray `core.sshCommand`/`user.email`, fast-forward pull when clean and no Claude runs there); it never pushes, commits or touches tokens.

## Skills

- Skills shared by every project live in `~/erinos/skills/<name>/` (`SKILL.md`, plus any scripts next to it) and are linked into `~/.claude/skills/`. Create one with `erin skill new <name>`, list them with `erin skill`. Don't put shared skills in a project's `.claude/skills/`. Skills are public: nothing machine-specific in them.

## GitHub access

- **No SSH keys or deploy keys for GitHub.** Every remote is HTTPS: `https://github.com/<owner>/<repo>.git`. Don't set `core.sshCommand` or generate keys.
- **No global `gh` login, on purpose.** Never suggest `gh auth login`.
- Each repo has its own fine-grained token, stored in `~/.secrets/<name>.env` as `GH_TOKEN`. The owner stores it with `erin secret set <name> GH_TOKEN` (any app secret the same way); never ask for, print or copy the value. To see which secrets exist (names only), run `erin secret`.
- Each repo root has a `.envrc` with exactly two lines, a comment and the dotenv line, then is hidden from git and approved:
  ```
  # GitHub access for ~/<workspace>/<repo>: fine-grained token (<owner>: <repos>), stored with: erin secret set <name> GH_TOKEN
  dotenv ~/.secrets/<name>.env
  ```
  Then run `echo .envrc >> .git/info/exclude` and `direnv allow .`.
- git authenticates through `erin git-credential` (set by `erin setup`): it hands git the token named by the repo's `.envrc`, read from `~/.secrets`, so git works in one-liners, scripts and systemd jobs without direnv and never asks for a password. `gh` and app code still read `GH_TOKEN` from the environment: direnv in a shell, `EnvironmentFile=%h/.secrets/<name>.env` under systemd.
- Commit email comes from the workspace's `.workspace` (`~/erinos/` borrows one workspace's). `user.useConfigOnly = true` is set, so a repo outside a workspace can't commit. Never set `user.email` per repo.
- If a push fails with 401 or 403, the token is missing, expired or lacks a permission (for example Workflows for `.github/workflows/`). Tell the owner which permission to add; don't switch auth methods.

## Servers and secrets

- Remote servers: one dedicated key per server (`~/.ssh/id_ed25519_<provider>`) and a `Host <app>-prod <ip>` entry in `~/.ssh/config`; the IP is listed so Kamal and other tools that connect by IP pick up the same key.
- App secrets (for example `RAILS_MASTER_KEY`, `KAMAL_REGISTRY_PASSWORD`) go in the same `~/.secrets/<name>.env` as `GH_TOKEN` and are loaded by the repo's `.envrc`. Never commit `config/master.key`; `.kamal/secrets` only references `$VARS`.
- Development databases use invented data, never copies of production.

## Installing software

- Official Arch repos: `sudo pacman -S --needed <pkg>`. Never `pacman -Sy <pkg>`.
- Vendor binaries go in `~/.local/bin`, with checksum and signature verified when they're published.
- Ask the owner before using the AUR or running a downloaded install script.
- Record every install in `~/.config/erinos/tools.md`: date, tool, version, source, how to remove it.

## This machine

@~/.config/erinos/CLAUDE.md
