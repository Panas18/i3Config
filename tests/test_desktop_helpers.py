"""Regression checks for player selection and safe Autorandr profile creation."""
import contextlib
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import tempfile
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


if __name__ == '__main__':
    unittest.main()
