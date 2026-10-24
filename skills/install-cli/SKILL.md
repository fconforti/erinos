---
name: install-cli
description: Install a command-line tool on this machine. Use when a command is missing, when asked to install or add a tool, or when another skill says a tool it requires is not installed.
allowed-tools: Bash(command -v *) Bash(pacman -Si *) Bash(pacman -Ss *) Bash(pacman -Qi *)
---

# Installing a command-line tool

This machine runs Arch Linux and is used as a server. Installing software is
a system operation: do it deliberately and leave a record.

## 1. Check

Run `command -v <name>` first. If the tool is already installed, say so and
stop. If two different tools share the name, confirm which one is wanted.

## 2. Evaluate the options and pick the best one

Look at how the tool can be installed here and choose, weighing:

- **Trust:** who publishes it. The official Arch repositories and the tool's
  own vendor are the trusted sources. The AUR is user-submitted.
- **Updates:** whether it will be kept current by `pacman -Syu`, by its own
  updater, or not at all.
- **Footprint:** a user-level install in `~/.local/bin` is easier to remove
  than a system-wide one, and needs no sudo.

The usual candidates are the official repositories (`sudo pacman -S --needed
<package>`), the vendor's own binary downloaded over HTTPS into
`~/.local/bin`, the tool's language installer (npm, pipx, gem, cargo,
go install) at user level, and the AUR.

State in one line which option you chose and why, then install.

## 3. Rules

- Never run `pacman -Sy <package>`. That causes a partial upgrade.
- Ask before using the AUR, and show what the build script does first.
- Ask before running a downloaded install script, and show what it does.
- Do not replace or remove an existing tool to make room for a new one
  without asking.

## 4. Verify and record

Run the tool's version command to confirm it works. Then append a line to
`~/.config/erinos/tools.md` (create it if missing) with: date, tool, version, source,
and how to remove it.
