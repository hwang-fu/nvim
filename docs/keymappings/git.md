# Git

Three layers: gitsigns edits hunks in the buffer, lazygit acts on the
repo, diffview inspects changesets and history.

## gitsigns (spec in lua/hwangfu/plugins/spec/gitsigns.lua; buffer-local in git repos)

| Key | Action |
|-----|--------|
| `]c` / `[c` | Next / previous hunk |
| `<leader>hs` | Stage hunk (toggles; visual: selected lines) |
| `<leader>hr` | Reset hunk to index (visual: selected lines) |
| `<leader>hS` / `<leader>hR` | Stage / reset entire buffer |
| `<leader>hp` / `<leader>hi` | Preview hunk float / inline |
| `<leader>hb` | Blame line (full commit message) |
| `<leader>hd` / `<leader>hD` | Diff split vs index / vs HEAD~ |
| `<leader>hq` / `<leader>hQ` | Buffer / all-repo hunks to quickfix |
| `<leader>tb` | Toggle inline blame virtual text |
| `<leader>tw` | Toggle word diff |
| `ih` | Hunk text object (vih, dih, ...) |

Every action is also `:Gitsigns <subcommand>`. Command-only extras:
blame (whole-buffer view), show [rev], show_commit, change_base /
reset_base, setloclist, toggle_signs / toggle_numhl / toggle_linehl,
refresh, attach / detach. Full annotated list in the gitsigns spec
comment.

## lazygit float (lua/hwangfu/git.lua)

| Key | Action |
|-----|--------|
| `<leader>gg` | Open lazygit in a float, rooted at the buffer's repo |

Inside, lazygit's own keys apply (`?` for the full list): q quits (and
collapses the float - do not `:q` the window), space stages/checks out,
c commit, A amend, P/p push/pull, panels via h/l or 1-5. Full quick
reference in git.lua's header. Escape hatch: `Ctrl-\ Ctrl-N` to leave
terminal mode, `i` to resume.

## diffview (spec in lua/hwangfu/plugins/spec/diffview.lua)

| Key | Action |
|-----|--------|
| `<leader>gd` | `:DiffviewOpen` - working tree vs INDEX (staged drops out) |
| `<leader>gh` | `:DiffviewFileHistory %` - current file's history |
| `<leader>gH` | `:DiffviewFileHistory` - whole-repo history |

In a diffview tab: Tab / S-Tab cycle files, g? help, q leaves. Commands:
`:DiffviewOpen [rev] [-- paths]` (ranges like `main...HEAD` work),
`:[range]DiffviewFileHistory [paths]` (visual range = line-evolution
view), `:DiffviewToggleFiles`, `:DiffviewFocusFiles`, `:DiffviewRefresh`,
`:DiffviewLog`.
