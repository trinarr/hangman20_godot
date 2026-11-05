#!/usr/bin/env python3
"""Bake current Roboto Flex UI profiles into overlap-free fonts for Godot MSDF.

Development-only dependencies: fonttools and skia-pathops. Run after changing
UI font axes in scripts/ui/ui_fonts.gd. Body copy, small UI and variable-width gameplay letters retain
the original variable font and its raster cache.
"""
import argparse
import ast
import configparser
import csv
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'fonts/RobotoFlex-Variable.ttf'
OUTPUT = ROOT / 'fonts/msdf'
IMPORT_PARAMS = {'multichannel_signed_distance_field': 'true', 'msdf_size': '64', 'msdf_pixel_range': '24'}
PRELOAD_PATTERN = r'(?ms)^preload=(.*?)(?=^[A-Za-z_]\w*=|^\[|\Z)'


def preload_value(text):
    return ast.literal_eval(re.sub(r'Vector2i\((\d+),\s*(\d+)\)', r'(\1, \2)', text.strip()))


def preload_characters():
    characters = set('0123456789 +−×%/.,:!?()')
    with (ROOT / 'localization/translations.csv').open(encoding='utf-8', newline='') as source:
        for row in csv.DictReader(source):
            for language in ('ru', 'en'):
                text = row[language]
                characters.update(text)
                characters.update(text.upper())
    return sorted(ord(character) for character in characters if ord(character) > 32)


def preload_config(path):
    values = settings()
    shared = {(values['ROBOTO_FLEX_DISPLAY_WEIGHT'], values['ROBOTO_FLEX_DISPLAY_WIDTH']),
              (values['ROBOTO_FLEX_BUTTON_WEIGHT'], values['ROBOTO_FLEX_BUTTON_WIDTH'])}
    for profile in profiles():
        if filename(profile) == path.name and profile[:2] in shared:
            # Match FontVariation's exact axes, even for the static generated TTF.
            axes = ', '.join(f'{int.from_bytes(tag.encode(), "big")}: {float(value)}'
                             for tag, value in zip(('wght', 'wdth', 'GRAD', 'YOPQ', 'XOPQ'), profile))
            return ('[{"name": "Shared UI RU EN", "size": Vector2i(64, 0), '
                    f'"chars": {preload_characters()}, "glyphs": [], '
                    f'"variation_opentype": {{{axes}}}}}]')
    return '[]'


def import_params(path):
    values = dict(IMPORT_PARAMS)
    values['preload'] = preload_config(path)
    # The heavy multiplier caption retains its authored smaller MSDF cache.
    if path.name.startswith('RobotoFlexUI_900_'):
        values['msdf_size'] = '48'
    return values


def import_errors(path):
    errors = []
    if not path.is_file():
        errors.append(f'Missing font: {path.name}')
    metadata = path.with_suffix(path.suffix + '.import')
    config = configparser.ConfigParser(interpolation=None)
    config.optionxform = str
    try:
        if not metadata.is_file():
            return errors + [f'Missing Godot import: {metadata.name}']
        text = metadata.read_text(encoding='utf-8')
        preload = re.search(PRELOAD_PATTERN, text)
        # Godot serializes Variant arrays/dictionaries across unindented lines.
        config.read_string(re.sub(PRELOAD_PATTERN, 'preload=[]\n', text))
        for key, value in import_params(path).items():
            matches = (preload is not None and preload_value(preload.group(1)) == preload_value(value)
                       if key == 'preload' else config.get('params', key, fallback='').strip() == value)
            if not matches:
                errors.append(f'{metadata.name}: expected {key}={value}')
        if config.get('remap', 'importer', fallback='') != '"font_data_dynamic"':
            errors.append(f'{metadata.name}: unexpected importer')
    except (configparser.Error, OSError, ValueError, SyntaxError) as error:
        errors.append(f'{metadata.name}: {error}')
    return errors


def verify_imports():
    errors = [error for profile in profiles() for error in import_errors(OUTPUT / filename(profile))]
    expected = {filename(profile) for profile in profiles()}
    errors += [f'Obsolete MSDF profile: {path.name}' for path in OUTPUT.glob('RobotoFlexUI_*.ttf')
               if path.name not in expected]
    if errors:
        raise ValueError('\n'.join(errors))
    print(f'MSDF imports verified: {len(profiles())} profiles', flush=True)


def prepare_imports(godot):
    # Let Godot create remaps and UIDs; change only the authored import options.
    from godot_test_runner import isolated_environment, run_godot, has_engine_errors
    with isolated_environment(godot, ROOT) as env:
        missing = any(not (OUTPUT / (filename(p) + '.import')).is_file() for p in profiles())
        if missing:
            result = run_godot(godot, ROOT, ['--editor', '--import'], env, timeout=240)
            if result.returncode or has_engine_errors(result.stdout):
                raise ValueError('Godot import failed:\n' + result.stdout)
        for profile in profiles():
            metadata = OUTPUT / (filename(profile) + '.import')
            text = metadata.read_text(encoding='utf-8')
            original = text
            for key, value in import_params(OUTPUT / filename(profile)).items():
                pattern = PRELOAD_PATTERN if key == 'preload' else rf'(?m)^{key}=.*$'
                if re.search(pattern, text):
                    text = re.sub(pattern, key + '=' + value + ('\n' if key == 'preload' else ''), text)
                else:
                    text = text.replace('[params]', '[params]\n' + key + '=' + value, 1)
            if text != original:
                metadata.write_text(text, encoding='utf-8', newline='\n')
        # Reimport newly configured or regenerated fonts with their MSDF options.
        result = run_godot(godot, ROOT, ['--editor', '--import'], env, timeout=240)
        if result.returncode or has_engine_errors(result.stdout):
            raise ValueError('Godot MSDF reimport failed:\n' + result.stdout)
    verify_imports()

def settings():
    text = (ROOT / 'scripts/ui/ui_fonts.gd').read_text(encoding="utf-8")
    return {name: float(value) for name, value in re.findall(
        r'const (ROBOTO_FLEX_\w+): float = ([\d.-]+)', text)}

def display_widths():
    text = (ROOT / 'scripts/ui/ui_fonts.gd').read_text(encoding='utf-8')
    match = re.search(r'const ROBOTO_FLEX_DISPLAY_WIDTHS: Array\[int\] = \[([\d,\s]+)\]', text)
    if match is None:
        raise ValueError('Missing baked heading widths in ui_fonts.gd')
    widths = [int(value.strip()) for value in match[1].split(',') if value.strip()]
    values = settings()
    if (not widths or widths != sorted(set(widths), reverse=True)
            or widths[0] != int(values['ROBOTO_FLEX_DISPLAY_WIDTH'])
            or widths[-1] != int(values['ROBOTO_FLEX_DISPLAY_MIN_WIDTH'])):
        raise ValueError('Baked heading widths must descend from the maximum to the minimum')
    return widths


def profiles():
    values = settings()
    thick = values['ROBOTO_FLEX_THICK_STROKE']
    result = []
    for kind in ['DISPLAY', 'BUTTON']:
        prefix = 'ROBOTO_FLEX_' + kind + '_'
        widths = display_widths() if kind == 'DISPLAY' else range(int(values[prefix+'MIN_WIDTH']), int(values[prefix+'WIDTH'])+1)
        for width in widths:
            result.append((values[prefix+'WEIGHT'], width, values[prefix+'GRADE'],
                           values[prefix+'THIN_STROKE'], thick))
    result.append((values['ROBOTO_FLEX_HEAVY_DISPLAY_WEIGHT'],
                   values['ROBOTO_FLEX_DISPLAY_WIDTH'], values['ROBOTO_FLEX_DISPLAY_GRADE'],
                   values['ROBOTO_FLEX_DISPLAY_THIN_STROKE'], thick))
    return result

def filename(profile):
    return 'RobotoFlexUI_%d_%d_%d_%d_%d.ttf' % profile

def build():
    from fontTools.ttLib import TTFont
    from fontTools.varLib.instancer import instantiateVariableFont
    from fontTools.ttLib.removeOverlaps import skPathFromGlyph, ttfGlyphFromSkPath
    import pathops
    OUTPUT.mkdir(exist_ok=True)
    for profile in profiles():
        font = TTFont(SOURCE, recalcTimestamp=False)
        axes = {axis.axisTag: axis.defaultValue for axis in font['fvar'].axes}
        axes.update(dict(zip(['wght','wdth','GRAD','YOPQ','XOPQ'], profile)))
        font = instantiateVariableFont(font, axes, inplace=True, optimize=True)
        # MSDF cannot resolve self-intersections in variable-font outlines.
        # Boolean union changes topology, preserving the intended filled shape.
        advances = {glyph: metrics[0] for glyph, metrics in font["hmtx"].metrics.items()}
        glyph_set = font.getGlyphSet()
        # Snapshot all paths before replacing components. Decompose even
        # non-overlapping composites: MSDF signs must agree across every part
        # of a glyph (e.g. the two disconnected parts of Cyrillic YERU/Ы).
        paths = {name: skPathFromGlyph(name, glyph_set) for name in font.getGlyphOrder()}
        for name, path in paths.items():
            cleaned = pathops.simplify(path, fix_winding=True,
                                      keep_starting_points=True, clockwise=True)
            glyph = ttfGlyphFromSkPath(cleaned)
            font['glyf'][name] = glyph
            if glyph.numberOfContours > 0:
                width, _lsb = font['hmtx'].metrics[name]
                font['hmtx'].metrics[name] = (width, glyph.xMin)
        assert advances == {glyph: metrics[0] for glyph, metrics in font["hmtx"].metrics.items()}, "Advance widths changed"
        family = 'Hangman Flex UI'
        tag = filename(profile).removesuffix('.ttf')
        for record in font['name'].names:
            if record.nameID in (1, 4, 6, 16):
                value = tag if record.nameID == 6 else family
                record.string = value.encode(record.getEncoding())
        path = OUTPUT / filename(profile)
        font.save(path)
        font.close()
        print(path.relative_to(ROOT), path.stat().st_size, flush=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Verify expected fonts/imports and reject obsolete generated profiles without generating files')
    parser.add_argument('--godot', type=Path, help='Godot executable to create missing metadata and reimport generated fonts')
    parser.add_argument('--imports-only', action='store_true', help='Update Godot import options without regenerating TTF outlines; requires --godot')
    args = parser.parse_args()
    try:
        if args.check:
            verify_imports()
        elif args.imports_only:
            if not args.godot:
                parser.error('--imports-only requires --godot')
            prepare_imports(args.godot)
        else:
            if not args.godot:
                verify_imports()
            build()
            if args.godot:
                prepare_imports(args.godot)
            else:
                verify_imports()
                print('Reimport generated fonts in Godot before exporting.')
    except (ValueError, OSError) as error:
        parser.exit(1, str(error) + '\nUse --godot for missing imports; reconcile obsolete profiles with runtime consumers before removing them.\n')


if __name__ == '__main__':
    main()
