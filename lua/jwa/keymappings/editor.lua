-- ============================================================================
-- Editing keymappings: mainstream-editor conventions on top of Vim.
-- Split out of the old single keymap.lua (2026-08-15); the maps and
-- their rationale are verbatim from there. Master index: ./init.lua.
--
-- Sections (in order): Clipboard, Save / quit, Substitute, Undo,
-- Select all, Visual selection, Comment toggle. (Scrolling, word
-- motion and line moving moved to ./movement.lua, 2026-08-15.)
-- ============================================================================

local M = {}

-- require("jwa.keymappings.editor").setup()
function M.setup()
    -- The modern API (vim.keymap.set) defaults to noremap=true and silent=false,
    -- which is what we want for nearly every binding here. The opts table
    -- below is forwarded as-is for the few maps that need overrides
    -- (silent=true for maps that shouldn't echo, remap=true for the comment
    -- toggle that delegates to Neovim's built-in `gc` operator, desc=... for
    -- which-key UIs).
    local function map(modes, lhs, rhs, opts)
        vim.keymap.set(modes, lhs, rhs, opts or {})
    end

    -- Same RHS in normal AND insert; insert version prepends <Esc>.
    local function ni(lhs, rhs)
        map("n", lhs, rhs)
        map("i", lhs, "<Esc>" .. rhs)
    end

    -- --- Clipboard (system) ---------------------------------------------
    map("v", "<C-D>", '"+y')
    -- (<C-c> copy alias removed 2026-08-15; visual <C-c> is back to its
    -- built-in cancel-selection behavior.)
    map("v", "<C-X>", '"+x')
    -- Save (visual/select) needs a Lua callback rather than the obvious
    -- string RHS "<Esc>:w<CR>". Quirk: when Select mode was entered via
    -- <C-g> from Visual (the path snippet engines like vim.snippet take when
    -- jumping to a ${1:placeholder}), an <Esc> inside a mapping's string
    -- RHS reliably saves but does NOT exit Select mode. Vim's mapping-
    -- RHS processing diverges from typed-key processing for the mode-
    -- exit transition in this specific entry path; <Esc> typed directly
    -- exits, but <Esc> as the first byte of a RHS does not. (Other
    -- entry paths -- gh, gH, the visual-mode case -- worked fine with
    -- the string RHS.)
    --
    -- A Lua callback that calls vim.api.nvim_feedkeys('<Esc>', 'tx', ...)
    -- with the 't' flag (process as if typed) and 'x' (execute
    -- synchronously) routes the <Esc> through the typed-key path,
    -- which reliably exits any visual/select mode regardless of entry.
    -- Then we vim.cmd('silent! write') to save; silent! suppresses the
    -- "N lines, M bytes" cmdline echo since the modified indicator in
    -- the lualine already shows the save state.
    map("v", "<C-s>", function()
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "tx", false)
        vim.cmd("silent! write")
    end, { silent = true, desc = "Save file (exit visual/select first)" })
    -- (A visual-mode <C-l> alias for `gc` lived here until 2026-08-15;
    -- removed on user request to free the key - Ctrl-/ in the Comment
    -- toggle section below is the one comment binding.)

    -- --- Save / quit ----------------------------------------------------
    -- Save (Ctrl-S) is bound in both normal and insert: hitting it
    -- mid-edit is common and you want the file written without first
    -- popping out to normal mode.
    --
    -- Quit (Ctrl-Q) is normal-mode only. While typing in insert mode
    -- it is far too easy to brush Ctrl-Q by accident, and having that
    -- close the window (potentially the whole editor if it is the
    -- last window) mid-sentence is the kind of surprise we want to
    -- avoid. Exit insert first, then quit.
    --
    -- The insert and visual variants below are deliberate no-ops that
    -- raise a vim.notify ERROR ("Can't quit from <mode>; press <Esc>
    -- first"). Without these maps Ctrl-Q would fall through to Vim's
    -- defaults -- "insert literal next char" in insert mode (the same
    -- as Ctrl-V), and "start blockwise visual" in visual mode -- both
    -- of which are silent. Reaching for Ctrl-Q expecting your normal-
    -- mode quit and getting nothing back feels like a swallowed
    -- keypress; the explicit error tells you what to do instead.
    --
    -- vim.notify at ERROR level renders in red on the cmdline and is
    -- captured by :messages for later review. The message text does
    -- NOT match the ^rust_analyzer:%s*%-32%d+ filter installed in
    -- lsp/servers/rust_analyzer.lua, so it passes through unfiltered.
    ni("<C-s>", ":w<CR>")
    map("n", "<C-q>", ":q<CR>", { desc = "Quit window" })
    map("i", "<C-q>", function()
        vim.notify(
            "Can't quit from insert mode; press <Esc> first",
            vim.log.levels.ERROR
        )
    end, { desc = "Reject quit-from-insert (use <Esc> first)" })
    map("v", "<C-q>", function()
        vim.notify(
            "Can't quit from visual mode; press <Esc> first",
            vim.log.levels.ERROR
        )
    end, { desc = "Reject quit-from-visual (use <Esc> first)" })

    -- --- Substitute selection (Ctrl-R, visual only) ----------------------
    -- Yank the selection into register z, then pre-fill
    -- `:%s/\V<selection>//g` with the cursor parked between the slashes:
    -- type the replacement and press Enter, with inccommand previewing
    -- matches live. \V makes the selection match literally (escape covers
    -- \ and /), and newlines become \n so multi-line selections work.
    -- No `c` flag by default; add it before Enter to confirm per match.
    --
    -- Normal-mode <C-r> is Vim's BUILT-IN REDO, restored 2026-08-15 (a
    -- substitute-under-cursor map shadowed it before). Insert-mode <C-r>
    -- keeps its built-in insert-from-register.
    map("v", "<C-r>",
        [["zy:%s/\V<C-r>=substitute(escape(@z, '\/'), '\n', '\\n', 'g')<CR>//g<Left><Left>]],
        { desc = "Substitute selection across file" }
    )

    -- --- Undo -----------------------------------------------------------
    -- Ctrl-U and Ctrl-Z both undo, mirroring mainstream-editor muscle
    -- memory, and both are normal-mode only (the insert-mode <C-z>
    -- variant was removed 2026-08-15). Mapping <C-u> shadows Vim's
    -- built-in half-page scroll; the Ctrl+Up/Down maps cover scrolling,
    -- so that is intentional. Insert-mode <C-u> keeps its built-in
    -- delete-to-line-start.
    map("n", "<C-u>", ":u<CR>", { silent = true, desc = "Undo" })
    map("n", "<C-z>", ":u<CR>", { silent = true, desc = "Undo" })

    -- --- Select all -----------------------------------------------------
    ni("<C-a>", "ggVG")

    -- --- Visual selection (Shift + arrows, n only) ----------------------
    -- Mainstream editors (VS Code, Sublime, browsers) use Shift+arrow
    -- to start a selection from the cursor and extend it as you move.
    -- These maps reproduce that gesture: enter character-wise visual
    -- mode (`v`) and then issue the matching arrow so the selection
    -- grows in that direction.
    --
    -- Once visual mode is active, the un-shifted arrow keys already
    -- continue extending the selection, so Shift is only needed for
    -- the initial keypress. <Esc> (or pressing `v` again) clears it.
    --
    -- Why character-wise (`v`) rather than line-wise (`V`): mainstream
    -- editors preserve the cursor's column when extending up/down, and
    -- character-wise visual matches that. Use `V` manually when you
    -- want whole-line selection.
    --
    -- Normal-mode only on purpose: in visual mode the un-shifted
    -- arrow keys already do the right thing (extend by one step), and
    -- in insert mode we leave Vim's defaults alone. The previous
    -- Shift+arrow bindings (scroll / word motion) were redundant with
    -- their Ctrl twins, so removing them frees these keys cleanly.
    map("n", "<S-Up>", "v<Up>", {
        silent = true,
        desc = "Start visual selection, extend up",
    })
    map("n", "<S-Down>", "v<Down>", {
        silent = true,
        desc = "Start visual selection, extend down",
    })
    map("n", "<S-Left>", "v<Left>", {
        silent = true,
        desc = "Start visual selection, extend left",
    })
    map("n", "<S-Right>", "v<Right>", {
        silent = true,
        desc = "Start visual selection, extend right",
    })

    -- --- Comment toggle (Ctrl + /) --------------------------------------
    --
    -- VS Code-style Ctrl+/ to toggle comment. Maps both <C-/> and
    -- <C-_> to the same RHS because terminals are inconsistent about
    -- which byte they send for Ctrl+/:
    --
    --   * Modern terminals with the CSI u / kitty keyboard protocol
    --     enabled (kitty, alacritty, wezterm, foot, recent xterm) can
    --     deliver a distinct <C-/> to Neovim 0.10+.
    --   * Older terminals, default tmux, default xterm -- Ctrl+/
    --     comes through as <C-_>, the original ASCII US (0x1F) byte
    --     produced by the historical Ctrl+/ keymap on ASCII keyboards.
    --
    -- Mapping both means the same physical keypress works regardless
    -- of which terminal Neovim is running under, with no per-machine
    -- branching.
    --
    -- RHS:
    --   * n: gcc  (toggle the current line; built-in operator since
    --             Neovim 0.10, language-aware via &commentstring --
    --             // for Rust / C / Go / JS, -- for Lua / Haskell /
    --             SQL, # for Python / shell, <!-- ... --> for HTML).
    --   * v: gc   (toggle the active visual selection).
    --
    -- remap = true is load-bearing: we are delegating to the gcc / gc
    -- operators, which are themselves mappings. Without remap, the
    -- RHS would be fed back as the literal keystrokes "gcc" / "gc"
    -- with no operator behind them, and nothing useful would happen.
    --
    -- Insert mode is deliberately unmapped. <C-_> in insert mode is
    -- Vim's built-in "language switch" (toggles the keymap set by
    -- :h 'keymap'; rarely used but real), and there's no clean
    -- VS Code parallel for Ctrl+/ in insert anyway -- exit insert
    -- first if you want to toggle a comment.
    --
    -- History: a visual-mode <C-l> alias (predating this section) also
    -- toggled comments until 2026-08-15; removed to keep Ctrl-/ as the
    -- ONE comment binding and free <C-l> for future use. <C-_> below is
    -- NOT a second binding in that sense: it is the same physical
    -- Ctrl+/ keypress as delivered by legacy terminal encodings (see
    -- the explanation above), so it can never be reassigned safely.
    for _, lhs in ipairs({ "<C-/>", "<C-_>" }) do
        map("n", lhs, "gcc", {
            remap = true,
            desc = "Toggle comment on current line",
        })
        map("v", lhs, "gc", {
            remap = true,
            desc = "Toggle comment on selection",
        })
    end
end

return M
