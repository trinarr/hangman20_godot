#!/usr/bin/env python3
"""Bake current Roboto Flex UI profiles into overlap-free fonts for Godot MSDF.

Development-only dependencies: fonttools and skia-pathops. Run after changing
UI font axes in scripts/ui/ui_fonts.gd. Body copy, small UI and variable-width gameplay letters retain
the original variable font and its raster cache.
"""
from pathlib import Path
import re
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools.ttLib.removeOverlaps import skPathFromGlyph, ttfGlyphFromSkPath
import pathops

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'fonts/RobotoFlex-Variable.ttf'
OUTPUT = ROOT / 'fonts/msdf'

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
    return result

def filename(profile):
    return 'RobotoFlexUI_%d_%d_%d_%d_%d.ttf' % profile

def build():
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

if __name__ == '__main__':
    build()
