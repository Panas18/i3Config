#!/usr/bin/env bash
# Install this checkout on Ubuntu Desktop. Run as the normal login user, not root.
# Every package/configuration stage requires approval. --dry-run is read-only.
set -Eeuo pipefail
# APT field parsing and logs use a stable locale.
export LC_ALL=C.UTF-8

REPO_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DRY_RUN=false
WITH_EDITOR=false
BACKEND=glx
BUILD_JOBS=1
EWW_REV=d87c2fdbfdc012e76d229e4e9ea3325bc0f23e89
STAGE=preflight
INSTALLED_PACKAGES=()

usage() {
  cat <<'HELP'
Usage: ./install.sh [--dry-run] [--with-editor] [--backend glx|xrender] [--jobs 1|2]

Target: Ubuntu Desktop 26.04+, amd64 (Intel/AMD); arm64 is experimental.
Order: i3 -> Polybar -> Kitty -> tmux -> zsh -> desktop tools -> Eww -> optional Neovim.

  --dry-run       Print every package, source revision and destination. No writes,
                  sudo, downloads, package refresh, or service changes.
  --with-editor   Also install/configure Neovim and its development tools/plugins.
  --backend       Picom backend; glx by default, xrender for troublesome GPU drivers.
  --jobs          Eww compilation workers (default 1; at most 2 for low RAM).
  --help          Show this help.

Normal installation is interactive. There is deliberately no --yes option.
APT may also request its own transaction approval after this script's prompts.
HELP
}

log() { printf '[%s] [%-12s] %s\n' "$(date '+%F %T%z')" "$STAGE" "$*"; }
die() { log "ERROR: $*" >&2; exit 1; }

parse_args() {
  while (($#)); do
    case $1 in
      --dry-run) DRY_RUN=true ;;
      --with-editor) WITH_EDITOR=true ;;
      --backend) (($# >= 2)) || die '--backend needs a value'; BACKEND=$2; shift ;;
      --jobs) (($# >= 2)) || die '--jobs needs a value'; BUILD_JOBS=$2; shift ;;
      --help|-h) usage; exit 0 ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done
  [[ $BACKEND == glx || $BACKEND == xrender ]] || die 'Backend must be glx or xrender'
  [[ $BUILD_JOBS == 1 || $BUILD_JOBS == 2 ]] || die 'Build jobs must be 1 or 2'
}

packages_for() {
  local group package reason
  while IFS='|' read -r group package reason; do
    [[ $group == "$1" ]] && printf '%s\n' "$package"
  done < "$REPO_ROOT/install/packages.tsv"
  return 0
}

show_group() {
  local group package reason name url revision relative
  printf '\nPackages for %s (plus the dependencies APT will list):\n' "$1"
  while IFS='|' read -r group package reason; do
    [[ $group == "$1" ]] || continue
    printf '  %-27s %s\n' "$package" "$reason"
  done < "$REPO_ROOT/install/packages.tsv"
  while IFS='|' read -r group name url revision relative; do
    [[ $group == "$1" ]] || continue
    printf '  Source: %s @ %s\n          %s -> ~/%s\n' "$url" "$revision" "$name" "$relative"
  done < "$REPO_ROOT/install/sources.tsv"
}

print_plan() {
  local group
  printf 'Checkout: %s\n' "$REPO_ROOT"
  printf 'Configuration: i3 -> Polybar -> Kitty -> tmux -> zsh -> desktop -> Eww'
  $WITH_EDITOR && printf ' -> Neovim'
  printf '\nNative APT architecture: %s; Picom: %s; Eww workers: %s\n' \
    "$(dpkg --print-architecture)" "$BACKEND" "$BUILD_JOBS"
  for group in i3 polybar kitty tmux shell desktop eww; do show_group "$group"; done
  $WITH_EDITOR && show_group editor
  printf '\nEww: https://github.com/elkowar/eww.git @ %s\n' "$EWW_REV"
  printf 'Eww changes: repository IPC timeout patch; time crate 0.3.34 -> 0.3.36.\n'
  printf 'Cargo downloads dependencies and compiles natively; this can take minutes and several GB of build/cache disk.\n'
  printf '\nConfiguration destinations:\n'
  printf '  ~/.config/{i3,i3blocks,polybar,kitty,tmux,rofi,dunst,picom,eww,autorandr,networkmanager-dmenu}\n'
  printf '  ~/.local/bin/i3-* and eww; ~/.config/systemd/user/i3-*.service\n'
  printf '  ~/.tmux.conf; ~/.zshrc; ~/.oh-my-zsh; ~/.tmux/plugins; ~/.local/share/applications\n'
  printf '  ~/Pictures/Wallpapers/default.png (generated only if missing)\n'
  $WITH_EDITOR && printf '  ~/.config/nvim and downloaded Neovim plugins/language tools\n'
  printf '\nExisting files/source directories are backed up before replacement.\n'
  printf 'No CPU-specific binaries, monitor IDs, credentials, default-shell change, GPU proprietary drivers,\n'
  printf 'full desktop environment, automatic logout, explicit live service restart, or whole-system upgrade.\n'
  return 0
}

confirm() {
  local answer
  printf '\n%s [y/N] ' "$1"
  read -r answer || return 1
  case $answer in y|Y|yes|YES) log 'Approved'; return 0 ;; *) log 'Declined'; return 1 ;; esac
}

check_platform() {
  local ID VERSION_ID architecture
  # shellcheck disable=SC1091
  . /etc/os-release
  [[ $ID == ubuntu ]] || die 'This installer targets Ubuntu Desktop, not other distributions'
  dpkg --compare-versions "$VERSION_ID" ge 26.04 || die 'Ubuntu 26.04+ is required; older releases have different package versions'
  architecture=$(dpkg --print-architecture)
  case $architecture in
    amd64) log 'amd64: supports both Intel and AMD CPUs; GPU support is separate' ;;
    arm64) log 'WARNING: native arm64 build path is experimental and not hardware-tested' ;;
    *) die "Unsupported architecture: $architecture" ;;
  esac
  [[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" &&
     ${XDG_DATA_HOME:-$HOME/.local/share} == "$HOME/.local/share" &&
     ${XDG_STATE_HOME:-$HOME/.local/state} == "$HOME/.local/state" ]] ||
    die 'This checkout uses conventional ~/.config and ~/.local paths; custom XDG roots need manual migration'
}

backup_path() {
  local target=$1 relative
  [[ $target == "$HOME/"* ]] || die "Refusing a backup outside HOME: $target"
  relative=${target#"$HOME/"}
  [[ $relative != *../* && $relative != .. ]] || die 'Unsafe backup path'
  [[ -e $target || -L $target ]] || return 0
  if [[ ! -e $BACKUP_ROOT/$relative && ! -L $BACKUP_ROOT/$relative ]]; then
    mkdir -p -- "$(dirname -- "$BACKUP_ROOT/$relative")"
    cp -a -- "$target" "$BACKUP_ROOT/$relative"
    printf '%s\t%s\n' "$target" "$BACKUP_ROOT/$relative" >> "$BACKUP_MANIFEST"
    log "Backed up $target"
  fi
}

copy_file() {
  local source=$1 target=$2 mode=${3:-644}
  [[ ! -d $target || -L $target ]] || die "Expected a file, found a directory: $target"
  backup_path "$target"
  mkdir -p -- "$(dirname -- "$target")"
  # Replace symlinks themselves, never write through them to another config.
  [[ ! -L $target ]] || rm -- "$target"
  install -m "$mode" -- "$source" "$target"
  log "Configured $target"
}

copy_tree() {
  local source=$1 target=$2 file
  [[ -d $source ]] || die "Missing configuration directory: $source"
  while IFS= read -r -d '' file; do
    copy_file "$file" "$target/${file#"$source/"}"
  done < <(find "$source" -type f ! -path '*/__pycache__/*' -print0)
}

fetch_source() {
  local url=$1 revision=$2 destination=$3
  [[ $revision =~ ^[a-f0-9]{40}$ ]] || die 'Source revision must be a full Git SHA'
  git init -q "$destination"
  git -C "$destination" remote add origin "$url"
  git -C "$destination" fetch --depth 1 origin "$revision"
  git -C "$destination" checkout --detach FETCH_HEAD
  [[ $(git -C "$destination" rev-parse HEAD) == "$revision" ]] || die 'Source revision mismatch'
  log "Fetched $url @ $revision"
}

install_sources() {
  local group name url revision relative source target
  while IFS='|' read -r group name url revision relative; do
    [[ $group == "$1" ]] || continue
    source="$WORK_ROOT/$name"
    target="$HOME/$relative"
    if [[ -d $target/.git && $(git -C "$target" rev-parse HEAD) == "$revision" &&
          -z $(git -C "$target" status --porcelain --untracked-files=normal) ]]; then
      log "Keeping clean pinned source: $target"
      continue
    fi
    fetch_source "$url" "$revision" "$source"
    backup_path "$target"
    # Only these declared user-local plugin directories are replaced.
    [[ $relative == .oh-my-zsh || $relative == .oh-my-zsh/custom/plugins/* ||
       $relative == .tmux/plugins/* ]] || die "Unexpected plugin destination: $relative"
    rm -rf -- "$target"
    mkdir -p -- "$(dirname -- "$target")"
    cp -a -- "$source" "$target"
    log "Installed source $name"
  done < "$REPO_ROOT/install/sources.tsv"
}

install_group() {
  local group=$1 scope=$2 package
  local packages=()
  mapfile -t packages < <(packages_for "$group")
  show_group "$group"
  log "Configuration scope: $scope"
  printf '\nInstalled/candidate versions from the refreshed Ubuntu APT indexes:\n'
  apt-cache policy "${packages[@]}" | awk '/^[^ ]/{print} /Installed:|Candidate:/{print}'
  for package in "${packages[@]}"; do
    [[ $package =~ ^[a-z0-9][a-z0-9+.-]*$ ]] || die "Invalid package name: $package"
  done
  # Simulate the same flags before consent; --no-remove prevents package removals.
  apt-get --simulate --no-remove --no-install-recommends install "${packages[@]}"
  confirm "Install the listed $group packages/dependencies and configure the stated paths?" || die "Stopped before $group installation"
  sudo apt-get --no-remove --no-install-recommends install "${packages[@]}"
  INSTALLED_PACKAGES+=("${packages[@]}")
}

configure_i3() {
  copy_tree "$REPO_ROOT/i3" "$HOME/.config/i3"
  copy_tree "$REPO_ROOT/i3blocks" "$HOME/.config/i3blocks"
  local helper
  for helper in "$REPO_ROOT"/bin/i3-*; do copy_file "$helper" "$HOME/.local/bin/${helper##*/}" 755; done
  mkdir -p "$HOME/.local/state/i3config"
  i3 -C -c "$HOME/.config/i3/config"
}

configure_tmux() {
  copy_tree "$REPO_ROOT/tmux" "$HOME/.config/tmux"
  copy_file "$REPO_ROOT/tmux/tmux.conf" "$HOME/.tmux.conf"
  install_sources tmux
}

configure_shell() {
  install_sources shell
  copy_file "$REPO_ROOT/.zshrc" "$HOME/.zshrc"
  zsh -n "$HOME/.zshrc"
  # Kitty already explicitly uses zsh; leave login/SSH shells unchanged.
}

configure_desktop() {
  local directory service
  for directory in rofi dunst picom networkmanager-dmenu; do
    copy_tree "$REPO_ROOT/$directory" "$HOME/.config/$directory"
  done
  # Only portable Autorandr settings/hooks; never install another machine's profile.
  copy_file "$REPO_ROOT/autorandr/settings.ini" "$HOME/.config/autorandr/settings.ini"
  copy_tree "$REPO_ROOT/autorandr/postswitch.d" "$HOME/.config/autorandr/postswitch.d"
  # copy_tree creates data files; the hook itself must be executable.
  chmod 755 "$HOME/.config/autorandr/postswitch.d/20-i3-desktop"
  if [[ $BACKEND == xrender ]]; then
    sed -i 's/backend = "glx";/backend = "xrender";/' "$HOME/.config/picom/picom.conf"
  fi
  copy_tree "$REPO_ROOT/applications" "$HOME/.local/share/applications"
  copy_tree "$REPO_ROOT/vendor/networkmanager-dmenu" "$HOME/.local/share/i3config/vendor/networkmanager-dmenu"
  chmod 755 "$HOME/.local/share/i3config/vendor/networkmanager-dmenu/networkmanager_dmenu"
  for service in "$REPO_ROOT"/systemd/user/*.service; do
    copy_file "$service" "$HOME/.config/systemd/user/${service##*/}"
  done
  mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"
  if [[ ! -e $HOME/Pictures/Wallpapers/default.png && ! -L $HOME/Pictures/Wallpapers/default.png ]]; then
    python3 - "$HOME/Pictures/Wallpapers/default.png" <<'PY'
from PIL import Image
import sys
Image.new('RGB', (1920, 1080), '#1e1e2e').save(sys.argv[1])
PY
    log 'Generated a portable Mocha default wallpaper; personal wallpaper state was not copied'
  fi
}

configure_eww() {
  local source="$WORK_ROOT/eww"
  log "Building Eww natively with $BUILD_JOBS worker(s); source and crate downloads were listed in the plan"
  fetch_source https://github.com/elkowar/eww.git "$EWW_REV" "$source"
  git -C "$source" apply --check "$REPO_ROOT/eww/patches/ipc-timeout.patch"
  git -C "$source" apply "$REPO_ROOT/eww/patches/ipc-timeout.patch"
  (
    cd -- "$source"
    cargo update -p time@0.3.34 --precise 0.3.36
    nice -n 10 cargo build --release --locked --no-default-features --features x11 -j "$BUILD_JOBS"
  )
  copy_file "$source/target/release/eww" "$HOME/.local/bin/eww" 755
  copy_file "$REPO_ROOT/eww/eww.yuck" "$HOME/.config/eww/eww.yuck"
  copy_file "$REPO_ROOT/eww/eww.scss" "$HOME/.config/eww/eww.scss"
  cp "$source/Cargo.lock" "$RUN_ROOT/eww-Cargo.lock"
  sha256sum "$HOME/.local/bin/eww" > "$RUN_ROOT/eww.sha256"
  rustc --version; cargo --version; "$HOME/.local/bin/eww" --version
}

configure_editor() {
  dpkg --compare-versions "$(dpkg-query -W -f='${Version}' neovim)" ge 0.11 || die 'This Neovim configuration requires 0.11+'
  copy_tree "$REPO_ROOT/nvim" "$HOME/.config/nvim"
  log 'Restoring plugins declared in lazy-lock.json; editor config may also fetch declared Mason language tools'
  timeout 900 nvim --headless '+Lazy! restore' +qa
}

run_stage() {
  STAGE=$1
  log "BEGIN $STAGE"
  case $STAGE in
    i3) install_group i3 "$HOME/.config/i3, i3blocks and $HOME/.local/bin/i3-*"; configure_i3 ;;
    polybar) install_group polybar "$HOME/.config/polybar"; copy_tree "$REPO_ROOT/polybar" "$HOME/.config/polybar" ;;
    kitty) install_group kitty "$HOME/.config/kitty"; copy_tree "$REPO_ROOT/kitty" "$HOME/.config/kitty" ;;
    tmux) install_group tmux "$HOME/.config/tmux, $HOME/.tmux.conf and the listed TPM/plugin directories"; configure_tmux ;;
    shell) install_group shell "$HOME/.zshrc and the listed Oh My Zsh/plugin directories"; configure_shell ;;
    desktop) install_group desktop "$HOME/.config/{rofi,dunst,picom,autorandr,networkmanager-dmenu}, desktop entries, vendor menu, user services, default wallpaper"; configure_desktop ;;
    eww) install_group eww "$HOME/.local/bin/eww and $HOME/.config/eww; pinned source + Cargo crates, native compile, IPC/time fixes"; configure_eww ;;
    editor) install_group editor "$HOME/.config/nvim; locked plugins and configured language tools downloaded/executed"; configure_editor ;;
  esac
  printf '%s\t%s\n' "$STAGE" "$(date -Is)" >> "$RUN_ROOT/completed.tsv"
  log "DONE $STAGE"
}

finish() {
  STAGE=report
  # dpkg-query expands its own format fields, not the shell.
  # shellcheck disable=SC2016
  printf '%s\n' "${INSTALLED_PACKAGES[@]}" | sort -u | \
    xargs -r dpkg-query -W -f='${binary:Package}\t${Version}\t${Architecture}\n' > "$RUN_ROOT/packages-installed.tsv"
  log "Completed stages: $RUN_ROOT/completed.tsv"
  log "Package versions: $RUN_ROOT/packages-installed.tsv"
  log "Backup index: $BACKUP_MANIFEST"
  log "Build/download workspace retained at $WORK_ROOT (can be removed after validation)"
  printf '\nConfiguration is installed. Log out normally, choose i3 in the login screen, then log in.\n'
  printf 'The first i3 login creates local display profiles and starts the configured services.\n'
  printf 'No live services were explicitly restarted. Existing config watchers may reload changed files.\n'
  printf 'If Picom fails on this GPU, change its backend to xrender. Existing GNOME Settings limitations still apply.\n'
}

on_error() {
  local status=$1 line=$2
  trap - ERR
  log "FAILED (exit $status) at line $line. Completed stages and backups: $RUN_ROOT"
  exit "$status"
}

main() {
  parse_args "$@"
  [[ -f $REPO_ROOT/install/packages.tsv && -f $REPO_ROOT/install/sources.tsv ]] || die 'Run from a complete repository checkout'
  print_plan
  if $DRY_RUN; then printf '\nDRY RUN: no changes were made.\n'; return 0; fi
  ((EUID != 0)) || die 'Run as your normal user, without sudo; individual APT commands use sudo'
  [[ -t 0 ]] || die 'An interactive terminal is required for per-stage permission'
  check_platform
  command -v sudo >/dev/null || die 'sudo is required'
  umask 077
  RUN_ROOT="$HOME/.local/state/i3config/install/$(date +%Y%m%d-%H%M%S)-$$"
  BACKUP_ROOT="$RUN_ROOT/backup"
  BACKUP_MANIFEST="$RUN_ROOT/backups.tsv"
  WORK_ROOT="$RUN_ROOT/work"
  mkdir -p "$BACKUP_ROOT" "$WORK_ROOT"
  touch "$BACKUP_MANIFEST"
  exec > >(tee -a "$RUN_ROOT/install.log") 2>&1
  trap 'on_error "$?" "$LINENO"' ERR
  log "Log/backup directory: $RUN_ROOT"
  log "Architecture: $(dpkg --print-architecture); backend=$BACKEND; build-jobs=$BUILD_JOBS; editor=$WITH_EDITOR"
  if command -v git >/dev/null && git -C "$REPO_ROOT" rev-parse HEAD > "$RUN_ROOT/config-revision.txt" 2>/dev/null; then
    log "Repository revision: $(cat "$RUN_ROOT/config-revision.txt")"
    git -C "$REPO_ROOT" status --short > "$RUN_ROOT/config-status.txt"
  else
    printf 'Unversioned checkout (source/config manifests retained)\n' > "$RUN_ROOT/config-revision.txt"
  fi
  cp "$REPO_ROOT/install/packages.tsv" "$REPO_ROOT/install/sources.tsv" "$RUN_ROOT/"
  if pgrep -u "$UID" -x i3 >/dev/null; then
    confirm 'i3 is already running. Config watchers may reload as files change; continue instead of using a fresh GNOME/TTY session?' || die 'Stopped before installing into an active i3 session'
  fi
  confirm 'Refresh Ubuntu APT package indexes with sudo apt-get update (no installation yet)?' || die 'Stopped before APT refresh'
  sudo -v
  log 'Refreshing APT indexes; any repository update error stops installation'
  sudo apt-get -o APT::Update::Error-Mode=any update
  # All names must resolve before any stage installs/copies configuration.
  local group package candidate
  for group in i3 polybar kitty tmux shell desktop eww editor; do
    [[ $group != editor ]] || $WITH_EDITOR || continue
    while IFS= read -r package; do
      candidate=$(apt-cache policy "$package" | awk '/Candidate:/{print $2; exit}')
      [[ -n $candidate && $candidate != '(none)' ]] || die "No candidate for $package. Enable Ubuntu universe if needed, then rerun; no stage installed yet"
      if [[ $package == neovim ]]; then
        dpkg --compare-versions "$candidate" ge 0.11 || die "Neovim candidate $candidate is too old"
      fi
    done < <(packages_for "$group")
  done
  for group in i3 polybar kitty tmux shell desktop eww; do run_stage "$group"; done
  $WITH_EDITOR && run_stage editor
  finish
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then main "$@"; fi
