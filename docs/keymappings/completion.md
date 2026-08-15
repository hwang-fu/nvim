# Completion

*Defined in `lua/hwangfu/completion.lua` (blink.cmp).*

The completion menu opens as you type. Documentation for the highlighted item appears in a float after a moment. The first item is preselected but nothing is inserted until you accept it.

| Key | Action |
|-----|--------|
| `Down` / `Up`, `Ctrl-N` / `Ctrl-P` | Move through the menu |
| `Ctrl-Space` | Open the menu without typing |
| `Enter` | Accept the highlighted suggestion |
| `Ctrl-F` / `Ctrl-B` | Scroll the documentation float |
| `Esc` | Close the menu and stay in insert mode; if no menu is open, leave insert mode |
| `Tab` / `S-Tab` | Jump between snippet placeholders |

The command line (`:` and `/`) gets the same popup: `Tab` opens and cycles it, arrows navigate, and `Enter` accepts and runs.
