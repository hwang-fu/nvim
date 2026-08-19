# Git

Three tools split the work: gitsigns edits hunks inside the buffer, lazygit operates on the repository, and diffview presents read-only diffs and history.

## Hunks - gitsigns

*Defined in `lua/jwn/plugins/spec/gitsigns.lua`; the keys exist only in git-tracked buffers.*

A hunk is one contiguous block of changed lines. Lowercase keys act on the hunk under the cursor, uppercase on the whole buffer.

The index is git's name for the staging area: the snapshot being assembled for the next commit. Staging (`git add`, or `<leader>hs` here) copies changes from your working file into it. The gutter signs and the diffs below all compare the buffer against the index - which is why signs disappear the moment a change is staged.

| Key | Action |
|-----|--------|
| `]h` | Jump to the next hunk |
| `[h` | Jump to the previous hunk |
| `<leader>hs` | Stage the hunk; pressing again unstages. In visual mode, stage only the selected lines |
| `<leader>hr` | Reset the hunk to the index version. In visual mode, only the selected lines |
| `<leader>hS` / `<leader>hR` | Stage / reset the entire buffer |
| `<leader>hp` / `<leader>hi` | Preview the hunk in a float / inline as virtual text |
| `<leader>hb` | Toggle inline blame virtual text |
| `<leader>hd` / `<leader>hD` | Diff split against the index / against HEAD~ |
| `<leader>hq` / `<leader>hQ` | Send this buffer's / the whole repo's hunks to the quickfix list |
| `<leader>hB` | Blame the current line with the full commit message |
| `<leader>hw` | Toggle word-level diff |
| `ih` | Hunk text object: `vih` selects it, `dih` deletes it |

Every action is also available as `:Gitsigns <subcommand>` with tab completion, including a few that have no keymap - whole-buffer blame, showing a file at an old revision, and changing the diff base. `:Gitsigns <Tab>` shows the full list.

## Repository - lazygit

*Defined in `lua/jwn/git.lua`.*

| Key | Action |
|-----|--------|
| `<leader>gg` | Open lazygit in a floating window, rooted at the buffer's repository |

Inside the float you are talking to lazygit itself; press `?` there for its key list. Quit with `q`, which also closes the float - avoid `:q`, which would orphan the running program. To scroll or copy from the float, `Ctrl-\ Ctrl-N` leaves terminal mode and `i` returns.

## Diffs and history - diffview

*Defined in `lua/jwn/plugins/spec/diffview.lua`.*

| Key | Action |
|-----|--------|
| `<leader>gd` | Open the working tree diff against the index. Staged changes drop out of view |
| `<leader>gh` | History of the whole repository |
| `<leader>gH` | History of the current file |

Inside a diffview tab, `Tab` and `S-Tab` cycle through changed files, `g?` opens its help, and `q` leaves. The commands accept revisions and paths, for example `:DiffviewOpen main...HEAD -- lua/`, and `:DiffviewFileHistory` over a visual range traces the history of just those lines.
