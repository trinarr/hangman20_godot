#!/usr/bin/env python3
"""Bake current Roboto Flex UI profiles into overlap-free fonts for Godot MSDF.

Development-only dependencies: fonttools and skia-pathops. Run after changing
UI font axes in scripts/ui/ui_fonts.gd. Body copy, small UI and variable-width gameplay letters retain
the original variable font and its raster cache.
"""
import argparse
import configparser
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'fonts/RobotoFlex-Variable.ttf'
OUTPUT = ROOT / 'fonts/msdf'
IMPORT_PARAMS = {'multichannel_signed_distance_field': 'true', 'msdf_size': '64', 'msdf_pixel_range': '24'}


def import_params(path):
    values = dict(IMPORT_PARAMS)
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
        if not config.read(metadata, encoding='utf-8'):
            return errors + [f'Missing Godot import: {metadata.name}']
        for key, value in import_params(path).items():
            if config.get('params', key, fallback='').strip() != value:
                errors.append(f'{metadata.name}: expected {key}={value}')
        if config.get('remap', 'importer', fallback='') != '"font_data_dynamic"':
            errors.append(f'{metadata.name}: unexpected importer')
    except (configparser.Error, OSError) as error:
        errors.append(f'{metadata.name}: {error}')
    return errors


def verify_imports():
    errors = [error for profile in profiles() for error in import_errors(OUTPUT / filename(profile))]
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
                pattern = rf'(?m)^{key}=.*$'
                if re.search(pattern, text):
                    text = re.sub(pattern, key + '=' + value, text)
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

def profiles():
    values = settings()
    thick = values['ROBOTO_FLEX_THICK_STROKE']
    result = []
    for kind in ['DISPLAY', 'BUTTON']:
        prefix = 'ROBOTO_FLEX_' + kind + '_'
        for width in range(int(values[prefix+'MIN_WIDTH']), int(values[prefix+'WIDTH'])+1):
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
    parser.add_argument('--check', action='store_true', help='Verify every expected font/import without generating files')
    parser.add_argument('--godot', type=Path, help='Godot executable to create missing metadata and reimport generated fonts')
    args = parser.parse_args()
    try:
        if args.check:
            verify_imports()
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
        parser.exit(1, str(error) + '\nUse --godot to prepare MSDF imports with the engine.\n')


if __name__ == '__main__':
    main()
