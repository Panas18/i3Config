# Install this setup on a fresh Ubuntu PC

The installer deploys the current repository checkout and its declared tools.
It installs software **inside an existing Ubuntu Desktop installation**; it does
not install Ubuntu, partition disks, install a display manager, or replace GNOME.
A regular user account with `sudo`, working network access, and an interactive
terminal are required. Package sources need Ubuntu's `universe` component.

## Get the configuration and review it

If Git is missing, install it using Ubuntu's normal APT prompt first:

```sh
sudo apt install git
git clone --branch linux https://github.com/Panas18/i3Config.git
cd i3Config
./install.sh --dry-run
```

Do not pipe a remote download into Bash. Read `install.sh` and the manifests:

- [Package names and purposes](../install/packages.tsv).
- [Pinned Oh My Zsh and tmux source revisions](../install/sources.tsv).
- Eww is pinned to `d87c2fdbfdc012e76d229e4e9ea3325bc0f23e89` (official v0.6.0),
  with this repository's IPC timeout patch and a locked `time` update to 0.3.36.

`--dry-run` prints the package/source/destination plan and architecture. It does
not create logs, modify the home directory, call sudo, refresh APT, download
sources, compile code, install packages or touch services. Candidate versions
are resolved from refreshed APT indexes during an actual approved installation.

## Run interactively

Run as the regular account that will own the desktop configuration:

```sh
./install.sh
```

Options:

```sh
./install.sh --with-editor        # Also configure Neovim and development tools
./install.sh --backend xrender    # Alternative compositor backend for GPU issues
./install.sh --jobs 2             # Two Eww build workers; default is one
```

Options can be combined. There is no `--yes` or unattended installation mode.
Non-interactive installation and running the actual installer as root are
rejected. Preview mode can still be used without installing anything.

Prefer a fresh Ubuntu/GNOME login or a text console. If i3 is already running,
the script asks an additional question because Polybar/Eww can automatically
reload when their configuration files change.

## Permission and execution order

The complete plan appears first. The script then creates a private log/backup
run directory, requests permission for `sudo apt-get update`, and validates that
all selected package names have a candidate. It stops if a required package is
missing, before any stage installs or copies configuration. It never silently
adds repositories, changes PPAs, or disables signature checks. If `universe` is
missing, enable that Ubuntu component explicitly and rerun.

Each stage shows:

1. Every explicitly requested **package name and purpose**.
2. Any external source URL, pinned revision and user-local destination.
3. APT's installed/candidate versions.
4. A simulated APT transaction, including dependencies and upgrades.
5. The configuration paths affected.
6. A default-**No** approval prompt for that whole stage.

Approval is per visible stage/package list, rather than dozens of separate
single-package questions. Declining stops before that stage changes anything.
APT retains its own confirmation where applicable. Both simulation and actual
installation use `--no-remove --no-install-recommends`; package removals are
refused. Package-manager maintainer scripts may start/restart their own system
services as part of a normal Ubuntu package installation.

| Order | Stage | Configured after approval and successful package installation |
| --- | --- | --- |
| 1 | i3 | X11/session/lock dependencies, i3/i3blocks configuration, all runtime helpers |
| 2 | Polybar | Fonts, icons, three-island bar configuration |
| 3 | Kitty | Terminal configuration; Kitty explicitly launches zsh |
| 4 | tmux | Configuration, themes, TPM and its pinned plugins |
| 5 | zsh | Oh My Zsh, autosuggestions, syntax highlighting and `.zshrc` |
| 6 | Desktop tools | Rofi, Dunst, Picom, Autorandr hooks, settings/calendar dependencies, audio/network/Bluetooth/clipboard/screenshot tools, services and desktop entries |
| 7 | Eww | Native X11 build, patched IPC handling and quick-settings configuration |
| 8 | Neovim, optional | Editor configuration, locked plugins and configured language tools |

These stages run serially. Eww compilation is the only explicitly parallel step,
limited to one worker by default and two if requested. The shell login default
is not changed; SSH/console shells remain yours. Existing tmux servers are not
reloaded or killed. The installer does not log out or reboot the machine.

## Versions, downloads and resource use

“Current configuration” means this checkout, recorded by Git revision in the
run report (local Git changes are recorded separately). APT applications use the candidate versions offered by the target
Ubuntu release, **not an exact binary clone of the original laptop**. Source
plugins are pinned in `sources.tsv`. Eww is built for the target architecture;
the resulting executable hash and Cargo lockfile are retained. Installer-created
Git checkouts do not run a curl-pipe-shell bootstrap script.

Eww is not available from this machine's Ubuntu APT indexes. Its approved stage
installs the Rust/GTK build dependencies and downloads Rust crates. Compilation
can take minutes and substantial RAM/disk space. A single worker and lower CPU
priority reduce contention; they are not a hard memory limit. Build files and
Cargo caches remain until you choose to remove them. No build dependency is
automatically purged, because it might be needed by other software.

Neovim's development stack is opt-in because Node/npm, Go, clang and language
tools are unnecessary for a desktop-only installation. `--with-editor` requires
APT Neovim 0.11+ and restores `lazy-lock.json`; the configured Mason integration
may also fetch its declared language tools. AI services still require your own
accounts/authentication. Spotify, proprietary chat applications, accounts,
API keys and personal data are not installed or transferred.

The installer uses the system LXAppearance package rather than recompiling its
standalone user-local fallback. Settings and calendar remain on demand. No
additional monitoring daemon, animated wallpaper, blur, or full desktop session
is added by the configuration. Existing session applets/services still use RAM.

## CPU, GPU and hardware compatibility

| Hardware | Status |
| --- | --- |
| Intel x86-64 / Ubuntu `amd64` | Primary target; configuration was developed on Intel HD 620 |
| AMD x86-64 / Ubuntu `amd64` | Same native package architecture and code paths; no Intel-only CPU dependency |
| ARM64 / Ubuntu `arm64` | Native APT and Eww build paths supported by the script, but not hardware-tested |
| 32-bit x86, ARM32, other architectures | Rejected for installation |

Ubuntu **26.04** is the primary target. Later releases pass the version gate but
must still provide every required package; they are not automatically certified.
Older Ubuntu releases are rejected because program/package versions differ.
Ubuntu Server/headless systems are not the intended target.

CPU vendor and GPU driver are separate questions. GLX is the default Picom
backend and requires a working driver/OpenGL stack. `--backend xrender` is an
alternative for rendering issues. Kitty separately needs working OpenGL 3.3+
drivers; changing Picom to XRender does not remove that terminal requirement. This script does not install proprietary
NVIDIA drivers, switch drivers, force an Intel graphics driver, or install
CPU-specific microcode. Use Ubuntu's driver tools where hardware requires them.

Display EDIDs, interface names, battery paths and touchpad IDs are not copied
from this laptop. Only generic Autorandr settings/hooks are installed. The first
i3 login derives local profiles from the new machine's actual displays; existing
profiles are preserved. Brightness, battery and temperature readouts depend on
what that machine exposes in sysfs. A desktop without a battery shows AC;
unsupported backlight/sensor interfaces can be unavailable. ARM boards need a
working Xorg-capable display stack independently of CPU support.

A solid Mocha `~/Pictures/Wallpapers/default.png` is generated only if absent.
Existing wallpaper files or symlinks are preserved. Personal wallpaper state,
SSH keys, network secrets and another computer's monitor profiles are not copied.

## Logs, backups, failures and reruns

Each real run creates a private directory:

```text
~/.local/state/i3config/install/<timestamp>-<process-id>/
  install.log                 timestamped stage/command output and errors
  config-revision.txt         repository revision, or unversioned-checkout note
  config-status.txt           local Git changes, for a Git checkout
  packages.tsv                the selected manifest snapshot
  sources.tsv                 pinned upstream source manifest snapshot
  packages-installed.tsv      installed versions/architectures after success
  completed.tsv               successfully completed configuration stages
  backups.tsv                 original path -> backup path
  backup/                     original files, symlinks and replaced source trees
  work/                       fetched source and Eww build artifacts
  eww-Cargo.lock              actual Eww dependency lock after the declared update
  eww.sha256                  installed Eww executable checksum
```

Passwords are handled by sudo/desktop agents, not echoed by the installer; shell
tracing is not enabled. Read log errors before sharing logs publicly because
paths, usernames, repositories and package metadata are included.

A failing stage exits with its name, exit status and line. Previously completed
stages remain installed; there is no automatic APT rollback or package purge.
Explicit declines and validation failures also stop with an error message.
Backups are made before file replacement and preserve the original on repeated
writes in the same run. Source directories replaced by pinned clones are backed
up as directories, including existing custom content. Symlink files are backed
up and replaced without overwriting the linked-to file.

To restore a configuration, review `backups.tsv` and copy the corresponding
backup to its original path while the affected application is closed. Do not
blindly restore the entire home directory. Package rollback is a separate APT
operation; installing a package is not undone by restoring its configuration.

The script is rerunnable: APT reuses installed packages; each run gets a new
backup directory; clean, matching source-plugin checkouts are retained. Eww is
rebuilt deliberately to guarantee this pinned source/patch combination. There
is no hidden resume marker that skips an unfinished stage. After validation,
its run-specific `work/` directory can be removed manually to reclaim space;
keep `backup/`, logs and reports as long as you need them.

## First login and validation limits

Log out normally, choose **i3** from the display manager's session chooser, then
log in. Session startup reloads user unit definitions, creates local Autorandr
profiles, and starts the configured bar/display/compositor services. Eww starts
on demand when quick settings is opened. The original GNOME login is retained.

This repository still has the documented GNOME Settings compatibility limits
under i3: use Desktop tools for i3 display layouts, wallpaper, Dunst and shortcuts.

Development verification includes shell syntax, ShellCheck, read-only preview,
package-candidate lookup on the current Ubuntu 26.04 machine, the Eww patch
against its pinned upstream source, and isolated installer tests with fake
APT/sudo and temporary homes. Tests cover approval/decline, simulated failures,
serial ordering, backups/symlinks, manifests and preserving personal wallpaper.
**A complete clean-VM APT installation, native Eww compilation through this new
installer, and AMD/ARM hardware runs have not been performed.**

References: [Ubuntu i3 package](https://packages.ubuntu.com/resolute/i3-wm),
[Ubuntu Polybar package](https://packages.ubuntu.com/resolute/polybar),
[Eww's native X11 build instructions](https://elkowar.github.io/eww/eww.html),
[Eww v0.6.0 source](https://github.com/elkowar/eww/releases/tag/v0.6.0),
[Kitty maintainer on GPU requirements](https://github.com/kovidgoyal/kitty/discussions/7155).
