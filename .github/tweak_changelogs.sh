#!/bin/bash

RELEASE_VERSION="$1"

# Delete until and including the first line containing "<!-- Release notes generated"
sed -i '1,/^<!-- Release notes generated/d' temp_change.md

# Check if there is more than one non-empty line (the full changelog line) before we continue
if [ $(grep -c '^[[:space:]]*[^[:space:]]' temp_change.md) -le 1 ]; then
    echo "No changes to release $RELEASE_VERSION"
    rm temp_change.md
    exit 1
fi

# Remove all CR characters from all changelog files
sed -i 's/\r//g' temp_change.md CHANGELOG.md changelog.txt

# Reverse the order of lines in the file (last line becomes first, etc.)
sed -i '1h;1d;$!H;$!d;G' temp_change.md
# Convert "**Full Changelog**: URL" format to markdown link format "[Full Changelog](URL)"
sed -i -re 's/\*\*Full Changelog\*\*: (.*)/\[Full Changelog\]\(\1\)\n/' temp_change.md
# Delete everything from "## New Contributors" line to the end of file
sed -i '/## New Contributors/,$d' temp_change.md
# Convert GitHub changelog entries to markdown format
# "* description by (@username1, @username2) in #1310, #1311" → "- description #1310, #1311 (@username1, @username2)"
sed -i -re 's/^\*\s(.*)\sby\s\(?(@[^)]*[^) ])\)?\s+in\s+(.*)/- \1 \3 (\2)/' temp_change.md
# Convert @usernames to github links
# "(@username1, @username2)" → "([username1](https://github.com/username1), [username2](https://github.com/username2))"
sed -i -re 's/@([a-zA-Z0-9_-]+)/[\1](https:\/\/github.com\/\1)/g' temp_change.md
# Convert full PR URLs to linked format  
# "https://github.com/repo/pull/1310" → "[\#1310](https://github.com/repo/pull/1310)"
sed -i -re 's/(https:\/\/[^) ]*\/pull\/([0-9]+))/[\\#\2](\1)/g' temp_change.md

# Username substitutions for preferred display names
sed -i 's/\[Quotae/\[Quote_a/' temp_change.md
sed -i 's/\[learn2draw/\[Lexy/' temp_change.md
sed -i 's/\[Voronoff/\[Tom Clancy Is Dead/' temp_change.md
sed -i 's/\[PJacek/\[TPlant/' temp_change.md
sed -i 's/\[justjuangui/\[trompetin17/' temp_change.md

cp temp_change.md changelog_temp.txt
# Append existing CHANGELOG.md content (excluding first line) to temp_change.md
cat CHANGELOG.md | sed '1d' >> temp_change.md
# Create new CHANGELOG.md with header containing version and date, followed by processed changes
printf "# Changelog\n\n## [$RELEASE_VERSION](https://github.com/PathOfBuildingCommunity/PathOfBuilding-PoE2/tree/$RELEASE_VERSION) ($(date +'%Y/%m/%d'))\n\n" | cat - temp_change.md > CHANGELOG.md
# Convert changelog entries from markdown link format to simplified "* description (username)" format
# First remove all PR links
sed -i -re 's/( \()?\[\\#[0-9]+\]\([^)]*\),? ?\)?//g' changelog_temp.txt
# Remove markdown link formatting from usernames in parentheses
sed -i -re 's/\[([^]]*)\]\(https:\/\/github\.com\/[^)]*\)/\1/g' changelog_temp.txt
# Create new changelog format: add version header, remove lines 2-3, format section headers, remove ## headers with following line, prepend to existing changelog
echo "VERSION[${RELEASE_VERSION#v}][$(date +'%Y/%m/%d')]" | cat - changelog_temp.txt | sed '2,3d' | sed -re 's/^### (.*)/\n--- \1 ---/' | sed -e '/^##.*/,+1 d' | cat - changelog.txt > changelog_new.txt
mv changelog_new.txt changelog.txt

# Normalize line endings to CRLF for all output files to ensure consistent checksums with Windows
sed -i 's/\r*$/\r/' CHANGELOG.md changelog.txt

# Clean up temporary files
rm temp_change.md
rm changelog_temp.txt
