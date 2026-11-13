# Liberation Sans Cyrillic extension

These assets retain the original ASCII glyph metadata and atlas pixels, and
append Cyrillic glyphs from Liberation Sans Regular 2.1.5 (U+0400–U+04FF).
The accompanying `Liberation-LICENSE.txt` contains the font's license.

Font source: [Liberation Fonts 2.1.5 release](https://github.com/liberationfonts/liberation-fonts/releases/tag/2.1.5),
using the release-linked `liberation-fonts-ttf-2.1.5.tar.gz` archive.

Generation uses the [extended FontGenerator](https://github.com/PathOfBuildingCommunity/PathOfBuilding-FontGenerator/pull/3)
on Windows, with the Liberation Sans family, normal weight (400), variable pitch,
default GDI quality, and sizes 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 32, 36,
40, 48, 56 and 64. Append the generated glyphs to pristine original PoB assets
(baseline `a69391d6daaaea1aaf8054668a094aad88dd7eaa`):

```text
python extend_font.py "original/Liberation Sans.tgf" "Generated Fonts/Liberation Sans.tgf" "extended/Liberation Sans.tgf"
```

Copy the resulting TGF and 16 TGA files together. Do not use an already extended
atlas as the original input. All 2,048 ASCII metadata entries and original pixels
were compared with the baseline and are unchanged.

Displaying the new entries requires the corresponding
[SimpleGraphic Unicode glyph reader](https://github.com/PathOfBuildingCommunity/PathOfBuilding-SimpleGraphic/pull/122).
The older engine ignores the added metadata and continues using the ASCII glyphs.
