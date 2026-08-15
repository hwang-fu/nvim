# Completion - blink.cmp (lua/hwangfu/completion.lua)

Popup opens as you type; docs float after 200ms; first item preselected
but not inserted.

| Key | Action |
|-----|--------|
| Down / Up, Ctrl-N / Ctrl-P | Move through the menu |
| Ctrl-Space | Open the menu on demand |
| Enter | Accept highlighted (or first) suggestion |
| Ctrl-F / Ctrl-B | Scroll the documentation window |
| Esc | Menu open: dismiss, stay in insert. Menu closed: leave insert |
| Tab / S-Tab | Jump between snippet placeholders (vim.snippet) |

Cmdline (`:` and `/`) has the same popup: Tab shows/cycles, arrows
navigate, Enter accepts and runs.
