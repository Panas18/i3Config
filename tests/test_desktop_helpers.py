"""Regression checks for player selection and safe Autorandr profile creation."""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import subprocess
import sys
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]


def helper(name):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT/'bin'/name))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class MediaTests(unittest.TestCase):
    def setUp(self):
        self.media = helper('i3-media')

    def test_stopped_browser_does_not_hide_paused_music(self):
        with patch.object(self.media, 'player', return_value='brave.instance1\tStopped\nspotify\tPaused'):
            self.assertEqual(self.media.selected(), ['spotify', 'Paused'])
            self.assertEqual(self.media.render('icon'), '')

    def test_playing_player_has_priority_and_pause_icon(self):
        with patch.object(self.media, 'player', return_value='spotify\tPaused\nfirefox.instance1\tPlaying'):
            self.assertEqual(self.media.selected(), ['firefox.instance1', 'Playing'])
            self.assertEqual(self.media.render('icon'), '')

    def test_controls_use_the_selected_player(self):
        with patch.object(self.media, 'selected', return_value=('spotify', 'Paused')), \
             patch.object(self.media, 'player') as command, \
             patch('sys.argv', ['i3-media', 'play-pause']):
            self.media.main()
            command.assert_called_once_with('--player', 'spotify', 'play-pause')

    def test_metadata_is_sanitized_and_bounded(self):
        with patch.object(self.media, 'selected', return_value=('spotify', 'Playing')), \
             patch.object(self.media, 'player', return_value='Artist %{A:bad:}\nLong title'), \
             patch.dict(os.environ, {'MEDIA_CHARS': '18'}):
            value = self.media.render('title')
            self.assertNotIn('%{', value)
            self.assertNotIn('\n', value)
            self.assertLessEqual(len(value), 18)

    def test_no_player_fallback(self):
        with patch.object(self.media, 'player', return_value=''):
            self.assertEqual(self.media.render('title'), 'Nothing playing')
            self.assertEqual(self.media.render('icon'), '')


class AutorandrTests(unittest.TestCase):
    def test_laptop_profile_handles_separate_preferred_marker_without_switching(self):
        setup = helper('i3-autorandr-setup')
        query = ('eDP-1 connected\n   1366x768  60.06 + 40.04\n'
                 '   1280x720  60.00\nHDMI-1 connected primary 1920x1080+0+0\n')
        with tempfile.TemporaryDirectory() as directory:
            dock = Path(directory)/'autorandr/docked'
            dock.mkdir(parents=True)
            (dock/'config').write_text('existing docked layout')
            with patch.dict(os.environ, {'XDG_CONFIG_HOME': directory}), \
                 patch.object(setup, 'output', side_effect=[query, 'eDP-1 abcd\nHDMI-1 efgh\n', 'laptop\ndocked']), \
                 patch.object(setup.subprocess, 'run') as run, \
                 contextlib.redirect_stdout(io.StringIO()):
                setup.main()
            config = (Path(directory)/'autorandr/laptop/config').read_text()
            self.assertIn('mode 1366x768', config)
            self.assertIn('rate 60.06\n', config)
            self.assertEqual((dock/'config').read_text(), 'existing docked layout')
            run.assert_not_called()


class SettingsTests(unittest.TestCase):
    def setUp(self):
        self.settings = helper('i3-settings')

    def test_device_rows_include_only_saved_or_connected_and_sort_connected_first(self):
        rows = self.settings.bluetooth_rows({
            '/ignored': {'org.bluez.Device1': {'Alias': 'Nearby beacon'}},
            '/saved': {'org.bluez.Device1': {'Alias': 'Headphones', 'Paired': True}},
            '/connected': {'org.bluez.Device1': {'Alias': 'Speaker\n%{bad}', 'Connected': True}},
        })
        self.assertEqual([row[0] for row in rows], ['/connected', '/saved'])
        self.assertNotIn('\n', rows[0][1])
        self.assertEqual(rows[0][2], True)

    def test_menu_cancellation_and_invalid_indices_do_not_select_actions(self):
        for code, value in [(1, ''), (0, '-1'), (0, '999'), (0, 'not a number')]:
            result = type('Result', (), {'returncode': code, 'stdout': value})()
            with patch.object(self.settings.subprocess, 'run', return_value=result):
                self.assertIsNone(self.settings.menu('Test', ['one', 'two']))

    def test_cancelled_notifications_menu_does_not_change_state(self):
        with patch.object(self.settings, 'run', return_value='false') as run, \
             patch.object(self.settings, 'menu', return_value=None):
            self.settings.notifications()
            run.assert_called_once_with('dunstctl', 'is-paused')

    def test_cancelled_hub_does_not_launch_tool(self):
        with patch('sys.argv', ['i3-settings', 'tools']), \
             patch.object(self.settings, 'run', return_value='balanced'), \
             patch.object(self.settings, 'menu', return_value=None), \
             patch.object(self.settings, 'discovered_settings', return_value=[]), \
             patch.object(self.settings, 'launch') as launch:
            self.settings.main()
            launch.assert_not_called()


class UbuntuSettingsTests(unittest.TestCase):
    def test_compatibility_environment_is_local_and_keeps_existing_renderer_choice(self):
        wrapper = helper('i3-ubuntu-settings')
        original = {'XDG_CURRENT_DESKTOP': 'i3', 'DISPLAY': ':0'}
        child = wrapper.launch_environment(original)
        self.assertEqual(original['XDG_CURRENT_DESKTOP'], 'i3')
        self.assertEqual(child['XDG_CURRENT_DESKTOP'], 'GNOME')
        self.assertEqual(child['GSK_RENDERER'], 'cairo')
        self.assertEqual(wrapper.launch_environment({'GSK_RENDERER': 'gl'})['GSK_RENDERER'], 'gl')

    def test_default_settings_launches_unified_app(self):
        settings = helper('i3-settings')
        with patch('sys.argv', ['i3-settings']), patch.object(settings, 'launch') as launch:
            settings.main()
        launch.assert_called_once_with(str(settings.BIN/'i3-ubuntu-settings'))

    def test_missing_unified_app_falls_back_without_recursion(self):
        wrapper = helper('i3-ubuntu-settings')
        with patch.object(wrapper.shutil, 'which', return_value=None), \
             patch.object(wrapper.os, 'execv', side_effect=RuntimeError('exec')) as execute:
            with self.assertRaises(RuntimeError):
                wrapper.main()
        self.assertEqual(execute.call_args.args[1][-1], 'tools')

    def test_desktop_discovery_honors_visibility_and_detects_new_tools(self):
        settings = helper('i3-settings')
        class App:
            def __init__(self, name, categories='Settings;', visible=True, executable='example'):
                self.name, self.categories, self.visible, self.executable = name, categories, visible, executable
            def get_id(self): return self.name+'.desktop'
            def get_display_name(self): return self.name
            def get_categories(self): return self.categories
            def should_show(self): return self.visible
            def get_executable(self): return self.executable
        apps = [App('Existing'), App('Hidden', visible=False), App('Game', categories='Game;'),
                App('Recursive', executable='i3-settings'), App('Existing')]
        self.assertEqual([name for name, _ in settings.discovered_settings(apps)], ['Existing'])
        apps.append(App('Newly installed'))
        self.assertEqual([name for name, _ in settings.discovered_settings(apps)], ['Existing', 'Newly installed'])


    @unittest.skipUnless(importlib.util.find_spec('gi'), 'GIO integration requires PyGObject')
    def test_real_xdg_catalog_updates_and_honors_user_hidden_override(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            user = root/'user/applications'
            system = root/'system/applications'
            user.mkdir(parents=True)
            system.mkdir(parents=True)
            environment = {**os.environ, 'XDG_DATA_HOME': str(user.parent),
                           'XDG_DATA_DIRS': str(system.parent), 'XDG_CURRENT_DESKTOP': 'i3'}
            probe = system/'autodetected.desktop'
            code = ("import importlib.machinery, json; "
                    "m=importlib.machinery.SourceFileLoader('probe', " + repr(str(ROOT/'bin/i3-settings')) + ").load_module(); "
                    "print(json.dumps([a.get_id() for _, a in m.discovered_settings()]))")
            def catalog():
                return subprocess.check_output([sys.executable, '-c', code], env=environment, text=True).strip()
            self.assertEqual(catalog(), '[]')
            probe.write_text('[Desktop Entry]\nType=Application\nName=Automatically discovered\n'
                             'Exec=/usr/bin/true\nCategories=Settings;\n')
            self.assertIn('autodetected.desktop', catalog())
            (user/probe.name).write_text('[Desktop Entry]\nHidden=true\n')
            self.assertEqual(catalog(), '[]')


class CalendarTests(unittest.TestCase):
    def setUp(self):
        self.calendar = helper('i3-calendar')

    def test_month_navigation_crosses_year_boundaries(self):
        self.assertEqual(self.calendar.shift_month(2026, 12, 1), (2027, 1))
        self.assertEqual(self.calendar.shift_month(2026, 1, -1), (2025, 12))

    def test_leap_month_is_complete_and_grid_always_six_weeks(self):
        weeks = self.calendar.month_cells(2024, 2)
        self.assertEqual(len(weeks), 6)
        self.assertTrue(all(len(week) == 7 for week in weeks))
        self.assertEqual(weeks[0][0].weekday(), 0)
        self.assertEqual(sum(day.month == 2 for week in weeks for day in week), 29)

    def test_century_non_leap_year(self):
        weeks = self.calendar.month_cells(2100, 2)
        self.assertEqual(sum(day.month == 2 for week in weeks for day in week), 28)


if __name__ == '__main__':
    unittest.main()
