# Structural editing - nvim-treesitter-textobjects (spec in lua/hwangfu/plugins/spec/textobjects.lua)

Syntax-aware text objects (visual + operator-pending) and motions
(normal + visual + operator-pending), added 2026-08-14. Works in every
treesitter language here EXCEPT erlang (no upstream queries - the maps
quietly no-op there).

| Key | Action |
|-----|--------|
| af / if | A function / inner function (vaf selects whole def linewise, dif deletes just the body) |
| ac / ic | A class / inner class ("class" = struct / impl / module in class-less languages) |
| aa / ia | A parameter incl. separating comma / just the parameter |
| ]f / [f | Next / previous function start |
| ]F / [F | Next / previous function end |
| ]] / [[ | Next / previous class start (overrides built-in section motions) |

]c / [c remain gitsigns hunk navigation. Motions set the jumplist, so
Ctrl-O walks back after an overshoot.
