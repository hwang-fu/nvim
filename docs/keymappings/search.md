# Searching

One page for "where is it?" - in the current file, across the project, and by symbol. The heavy lifting is shared between telescope, flash, and the LSP; this page is the map.

## In the current file

| Key | Action |
|-----|--------|
| `*` / `#` | Search the word under the cursor, forward / backward (built in) |
| `n` / `N` | Repeat the last search, forward / backward (built in) |
| `<leader>f/` | Fuzzy search the buffer's lines in a picker - scattered letters match, no regex |
| `s` | Flash jump: type a few characters of the target (matched literally, no regex, keep typing to narrow), every match on screen gets a one-letter label; press the label to land on that match, or `Enter` for the first one. Works in normal, visual, and operator-pending mode - `ds` + label deletes up to it |
| `/` and `?` | The built-in searches; starting with `/\v` switches to modern regex syntax where `+`, `(`, and `|` work without backslashes |

Flash's `s` shadows the built-in synonym for `cl`; that spelling still works.

### The `/` modifiers

Searches are case-sensitive in this config (Neovim's default; `ignorecase` is not set). The modifiers below go inside the pattern and override that per search - anywhere in the pattern, so you can append `\c` after typing the word.

| Modifier | Effect |
|----------|--------|
| `\c` | Ignore case for this search: `/hello\c` finds `Hello` and `HELLO` |
| `\C` | Force exact case |
| `\v` | "Very magic" from here on: modern regex syntax, `+`, `(`, and pipe work without backslashes |
| `\V` | "Very nomagic" from here on: everything is literal except `\`, good for searching code like `a.b(x)` |
| `/word/e` | An offset after the closing `/`: the cursor lands on the end of the match instead of the start |

Matches stay highlighted after the search; `:noh` clears the leftover highlights until the next search.

### The everyday regex atoms

The same pattern syntax drives `/`, `?`, and the pattern half of `:s`. The split that trips everyone coming from other tools: some operators work bare, the rest need a backslash in front.

These work bare:

| Atom | Matches |
|------|---------|
| `.` | Any single character |
| `*` | Zero or more of what precedes it |
| `^` and `$` | Start and end of line |
| `[abc]`, `[a-z]`, `[^abc]` | One character from the set, the range, or anything but the set |

These need the backslash:

| Atom | Matches |
|------|---------|
| `\+` | One or more of what precedes it |
| `\?` | Zero or one |
| `\{2,5}` | Two to five repeats |
| `\(...\)` | A group; counting starts at 1, so the first group comes back as `\1` on the replacement side of `:s`. `\0` is not a group but the whole match, same as `&` |
| `\<` and `\>` | Word boundaries: `/\<let\>` matches `let` but not `letter` |
| `\w` and `\W` | A word character (letter, digit, underscore) and its opposite |
| `\s` and `\S` | Whitespace and its opposite |
| `\d` and `\D` | A digit and its opposite |
| `\zs` and `\ze` | Pin where the reported match starts / ends: `/fn \zs\w\+` matches only the name after `fn ` |

Alternation is backslashed too: `\(red\|blue\)` matches either word.

The second table is the reason `\v` exists: after `\v` the operators drop their backslashes and `\v(red|blue)+` reads like a regex from any other tool. The class shorthands `\w`, `\s`, `\d` keep their backslash either way, exactly as in PCRE.

## Across the project

| Key | Action |
|-----|--------|
| `<leader>fg` | Live grep, respecting ignore files ([telescope](telescope.md)) |
| `<leader>fG` | Live grep, including ignored and hidden files |
| `<leader>fs` | Grep the word under the cursor |

## By symbol

| Key | Action |
|-----|--------|
| `grr` | Peek every reference in the [glance](lsp/glance.md) panel |
| `gd` | Jump to the definition ([lsp](lsp/lsp.md)) |
| `:Telescope lsp_workspace_symbols` | Fuzzy search every symbol in the project by name |

## Replacing

| Key / command | Action |
|---------------|--------|
| `<leader>rn` | Rename the symbol under the cursor across the project, semantically ([lsp](lsp/lsp.md)) |
| `Ctrl-R` (visual) | Search-and-replace the selected text across the current file ([editor](editor.md)) |
| `Alt-Q` in a grep picker, then `:cfdo %s/old/new/ge | update` | Project-wide text replace: send the matches to the quickfix list, then run the substitution over every listed file |

### The `:s` command

The shape is `:[range]s/pattern/replacement/flags`. The range decides which lines are touched: bare `:s` is the current line only, `:%s` is the whole file, `:10,20s` is lines 10 to 20, and starting `:` from a visual selection inserts `'<,'>` (the selected lines) for you.

The buffer previews the result live while you type, before you press Enter (`inccommand`).

| Flag | Effect |
|------|--------|
| `g` | Replace every match in each line; without it only the first match per line changes |
| `c` | Confirm each replacement one by one |
| `i` | Ignore case for the pattern |
| `I` | Force exact case |
| `n` | Report the number of matches, change nothing - a match counter |
| `e` | No error when nothing matches; keeps `:cfdo` runs going over files without a hit |

With the `c` flag, each match asks:

| Answer | Meaning |
|--------|---------|
| `y` | Replace this match |
| `n` | Skip it |
| `a` | Replace this and all remaining matches |
| `l` | Replace this one, then stop ("last") |
| `q` or `Esc` | Stop without replacing this one |
| `Ctrl-E` / `Ctrl-Y` | Scroll the view without answering |

Two habits worth stealing:

- An empty pattern reuses the last search: `/old_name`, eyeball the highlighted matches, then `:%s//new_name/g` replaces exactly what you just verified.
- In the replacement, `&` (or `\0`) inserts the whole match and `\1` the first capture group - counting starts at 1: `:%s/\v(\w+)_temp/\1/g` drops a `_temp` suffix.
