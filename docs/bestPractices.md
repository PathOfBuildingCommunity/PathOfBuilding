#Standards and Best Practices

###General formatting and coding standards

* Don't separate logic with whitespace if it belongs to the same idea or calculation
* Do use [LDoc notation](https://github.com/lunarmodules/LDoc) when creating new functions
* Do use Lua's version of ternary statements in favor of if statements where applicable
* Do format tables like so, breaking each key into separate lines once the table is too long for the screen: `{ key = value, key2 = value }`
* Do end table entries with a comma if they're on multiple lines, so new lines can be added succinctly

###Backwards compatibility

* Don't remove old mod parsing.  People still will have those items in their builds
* Do add variants for uniques if the mods will be made legacy.  Standard players exist and will want to use those mods
* Do make sure any changes to the tree work on old tree versions.  Bricking old trees is not okay
* Don't bother keeping legacy calculations around, as it increases code complexity to an unsustainable point

### What mods to support

* Don't add parsing for a mod unless it displays on UI, or is used in some calculation.  If everything is blue "just because", users won't know what is actually supported
* Don't support mods that let you gain charges.  We don't want to support chances to gain charges under many different conditions.  Users can decide if they'll have charges or not

###Pull Requests

* Do name your pull request starting with "Add [support for]" or "Fix" if you can.  This is what is used for the release note
* Do label your pull request with "enhancement" or "bug" and any other applicable labels, like "technical" for a PR that shouldn't appear in the change log
* Do include screenshots of what your PR changes, both before and after if applicable
* Do include a build link that demonstrates a build that benefits from your PR, if applicable.  This will help the maintainer test your PR more quickly
* Do include the scenarios you've tested/accounted for, so less time is wasted on confirming you've covered all the bases
* Do include "Fixes #<issue-id>" if the PR pertains to a certain issue.  This will allow GitHub to auto-close the issue when it's released

###UI Standards

* Controls should have relative positioning to other controls
* Controls should be tested in vertical screen mode for compatibility
* Controls should have a height of 20px
* Controls should be separated by 6px
* Borders should have a width of 2px
* Controls within a popup should total roughly 75% of the width of the popup
