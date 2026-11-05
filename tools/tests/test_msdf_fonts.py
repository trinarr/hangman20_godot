"""Missing and malformed imports must not silently turn generated UI fonts raster."""
from pathlib import Path
import os
import shutil
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build_ui_msdf_fonts as fonts


class MSDFImports(unittest.TestCase):
    def test_sparse_heading_profiles_do_not_generate_intermediate_fonts(self):
        self.assertEqual(fonts.display_widths(), [35, 32, 30])
        self.assertEqual({(int(p[0]), int(p[1])) for p in fonts.profiles()},
                         {(760, 35), (760, 32), (760, 30), (680, 25), (900, 35)})

    def test_check_rejects_obsolete_profiles(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            (output / 'RobotoFlexUI_760_34_-10_90_80.ttf').touch()
            with patch.object(fonts, 'OUTPUT', output), patch.object(fonts, 'profiles', return_value=[]):
                with self.assertRaisesRegex(ValueError, 'Obsolete MSDF profile'):
                    fonts.verify_imports()

    def test_expected_profiles_and_import_settings(self):
        fonts.verify_imports()

    def test_missing_and_incorrect_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / fonts.filename(fonts.profiles()[0])
            self.assertTrue(fonts.import_errors(path))
            path.touch()
            metadata = path.with_suffix('.ttf.import')
            template = '[remap]\nimporter="font_data_dynamic"\n[params]\nmultichannel_signed_distance_field=true\nmsdf_size=64\nmsdf_pixel_range=24\nFallbacks=null\nfallbacks=[]\n'
            for key, wrong in [('multichannel_signed_distance_field', 'false'), ('msdf_size', '16'), ('msdf_pixel_range', '2')]:
                good = fonts.IMPORT_PARAMS[key]
                metadata.write_text(template.replace(f'{key}={good}', f'{key}={wrong}'), encoding='utf-8')
                self.assertTrue(any(key in error for error in fonts.import_errors(path)))
            metadata.write_text(template, encoding='utf-8')
            self.assertEqual(fonts.import_errors(path), [])

    @unittest.skipUnless(os.environ.get('HANGMAN_TEST_GODOT'), 'requires real Godot')
    def test_new_profile_gets_engine_metadata_then_msdf_reimport(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="MSDFImportTest"\n', encoding='utf-8')
            output = root / 'fonts/msdf'
            output.mkdir(parents=True)
            profile = fonts.profiles()[0]
            shutil.copy2(fonts.SOURCE, output / fonts.filename(profile))
            with patch.object(fonts, 'ROOT', root), patch.object(fonts, 'OUTPUT', output), patch.object(fonts, 'profiles', return_value=[profile]):
                fonts.prepare_imports(Path(os.environ['HANGMAN_TEST_GODOT']))
                self.assertEqual(fonts.import_errors(output / fonts.filename(profile)), [])


if __name__ == '__main__':
    unittest.main()
