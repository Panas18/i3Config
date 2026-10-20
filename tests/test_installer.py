"""Installer checks use temporary homes and fake APT/sudo; never install packages."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
INSTALLER = ROOT/'install.sh'


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.home = self.root/'home'
        self.home.mkdir()
        self.env = {**os.environ, 'HOME': str(self.home)}

    def shell(self, code, *args):
        return subprocess.run(['bash', '-c', 'source "$1"; shift; '+code,
                               'installer-test', str(INSTALLER), *map(str, args)],
                              env=self.env, text=True, capture_output=True)

    def test_dry_run_is_read_only_and_does_not_execute_privileged_or_network_tools(self):
        fake = self.root/'fake-bin'
        fake.mkdir()
        trace = self.root/'executed'
        for command in ('sudo', 'apt-get', 'git', 'cargo', 'curl', 'systemctl', 'install'):
            program = fake/command
            program.write_text('#!/bin/sh\necho forbidden >> "$TRACE"\nexit 99\n')
            program.chmod(0o755)
        env = {**self.env, 'PATH': str(fake)+':'+self.env['PATH'], 'TRACE': str(trace)}
        result = subprocess.run([str(INSTALLER), '--dry-run', '--with-editor'],
                                env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(trace.exists())
        self.assertEqual(list(self.home.iterdir()), [])
        self.assertIn('i3 -> Polybar -> Kitty -> tmux', result.stdout)
        self.assertIn('Packages for editor', result.stdout)
        self.assertIn('libdbusmenu-gtk3-dev', result.stdout)

    def test_editor_is_opt_in_and_invalid_flags_fail(self):
        result = self.shell('main --dry-run --backend xrender --jobs 2')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn('Packages for editor', result.stdout)
        self.assertIn('Picom: xrender', result.stdout)
        for flag in ('--yes', '--jobs 16', '--backend mystery'):
            result = self.shell('main '+flag)
            self.assertNotEqual(result.returncode, 0)
        self.assertEqual(list(self.home.iterdir()), [])

    def test_symlink_backup_replaces_link_without_modifying_its_target(self):
        outside = self.root/'outside'
        outside.write_text('external contents')
        source = self.root/'new config'
        source.write_text('new contents')
        target = self.home/'config with spaces'
        target.symlink_to(outside)
        result = self.shell('BACKUP_ROOT="$HOME/backup"; BACKUP_MANIFEST="$HOME/index"; '
                            'copy_file "$1" "$2"', source, target)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(outside.read_text(), 'external contents')
        self.assertFalse(target.is_symlink())
        self.assertEqual(target.read_text(), 'new contents')
        self.assertTrue((self.home/'backup/config with spaces').is_symlink())

    def test_repeated_copy_preserves_original_backup(self):
        target = self.home/'config'
        target.write_text('original')
        source = self.root/'new'
        source.write_text('replacement')
        result = self.shell('BACKUP_ROOT="$HOME/backup"; BACKUP_MANIFEST="$HOME/index"; '
                            'copy_file "$1" "$2"; copy_file "$1" "$2"', source, target)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual((self.home/'backup/config').read_text(), 'original')
        self.assertEqual(len((self.home/'index').read_text().splitlines()), 1)

    def test_copy_refuses_destination_outside_home(self):
        source = self.root/'source'
        source.write_text('new')
        outside = self.root/'outside'
        outside.write_text('old')
        result = self.shell('BACKUP_ROOT="$HOME/backup"; BACKUP_MANIFEST="$HOME/index"; '
                            'copy_file "$1" "$2"', source, outside)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(outside.read_text(), 'old')

    def test_missing_configuration_tree_fails_instead_of_marking_stage_complete(self):
        result = self.shell('copy_tree "$HOME/missing" "$HOME/destination"')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing configuration directory', result.stderr)
        self.assertFalse((self.home/'destination').exists())

    def test_declining_package_stage_never_calls_sudo(self):
        result = self.shell('apt-cache() { echo "kitty: Candidate: test"; }; '
                            'apt-get() { echo "SIMULATED $*"; }; '
                            'sudo() { echo FORBIDDEN_SUDO; exit 99; }; '
                            'confirm() { return 1; }; install_group kitty test-scope')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('kitty', result.stdout)
        self.assertIn('SIMULATED --simulate --no-remove --no-install-recommends install kitty', result.stdout)
        self.assertNotIn('FORBIDDEN_SUDO', result.stdout)

    def test_simulation_failure_stops_before_prompt_and_installation(self):
        result = self.shell('apt-cache() { return 0; }; apt-get() { return 42; }; '
                            'confirm() { echo FORBIDDEN_CONFIRM; }; '
                            'sudo() { echo FORBIDDEN_SUDO; }; install_group kitty test-scope')
        self.assertEqual(result.returncode, 42)
        self.assertNotIn('FORBIDDEN_CONFIRM', result.stdout)
        self.assertNotIn('FORBIDDEN_SUDO', result.stdout)

    def test_approved_stage_uses_no_remove_and_never_assume_yes(self):
        result = self.shell('apt-cache() { return 0; }; apt-get() { return 0; }; '
                            'confirm() { return 0; }; sudo() { printf "APPROVED %s\\n" "$*"; }; '
                            'install_group kitty test-scope; printf "PACKAGE %s\\n" "${INSTALLED_PACKAGES[@]}"')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('APPROVED apt-get --no-remove --no-install-recommends install kitty', result.stdout)
        self.assertNotIn('--assume-yes', result.stdout)
        self.assertIn('PACKAGE kitty', result.stdout)

    def test_stage_order_is_serial_and_completed_only_after_configuration(self):
        result = self.shell('RUN_ROOT="$HOME"; install_group() { echo APPROVAL-$1; }; '
                            'configure_i3() { echo CONFIG-i3; }; configure_tmux() { echo CONFIG-tmux; }; '
                            'configure_shell() { :; }; configure_desktop() { :; }; configure_eww() { :; }; '
                            'copy_tree() { :; }; '
                            'for group in i3 polybar kitty tmux shell desktop eww; do run_stage "$group"; done')
        self.assertEqual(result.returncode, 0, result.stderr)
        groups = [line.split('\t')[0] for line in (self.home/'completed.tsv').read_text().splitlines()]
        self.assertEqual(groups, ['i3', 'polybar', 'kitty', 'tmux', 'shell', 'desktop', 'eww'])
        self.assertLess(result.stdout.index('APPROVAL-i3'), result.stdout.index('CONFIG-i3'))
        self.assertLess(result.stdout.index('CONFIG-i3'), result.stdout.index('APPROVAL-polybar'))

    def test_manifests_have_valid_unique_package_names_and_pinned_sources(self):
        seen = set()
        for line in (ROOT/'install/packages.tsv').read_text().splitlines():
            if line.startswith('#') or not line:
                continue
            group, package, reason = line.split('|')
            self.assertRegex(package, r'^[a-z0-9][a-z0-9+.-]*$')
            self.assertNotIn(package, seen)
            seen.add(package)
            self.assertTrue(reason)
        self.assertTrue({'i3-wm','polybar','kitty','tmux','lxappearance','cargo','gir1.2-gtk-3.0'} <= seen)
        for line in (ROOT/'install/sources.tsv').read_text().splitlines():
            if line.startswith('#') or not line:
                continue
            group, name, url, revision, relative = line.split('|')
            self.assertRegex(revision, r'^[a-f0-9]{40}$')
            self.assertTrue(url.startswith('https://github.com/'))
            self.assertNotIn('..', Path(relative).parts)

    def test_desktop_configuration_preserves_wallpaper_and_uses_selected_backend(self):
        personal = self.home/'Pictures/Wallpapers/default.png'
        personal.parent.mkdir(parents=True)
        personal.write_bytes(b'personal wallpaper')
        result = self.shell('BACKUP_ROOT="$HOME/backup"; BACKUP_MANIFEST="$HOME/index"; '
                            'BACKEND=xrender; configure_desktop')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(personal.read_bytes(), b'personal wallpaper')
        self.assertIn('backend = "xrender"', (self.home/'.config/picom/picom.conf').read_text())
        hook = self.home/'.config/autorandr/postswitch.d/20-i3-desktop'
        self.assertTrue(os.access(hook, os.X_OK))
        self.assertFalse((self.home/'.config/autorandr/docked').exists())
        self.assertTrue((self.home/'.config/systemd/user/i3-picom.service').exists())


if __name__ == '__main__':
    unittest.main()
