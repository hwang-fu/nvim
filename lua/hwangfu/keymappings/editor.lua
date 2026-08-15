-- ============================================================================
-- Editing keymappings: mainstream-editor conventions on top of Vim.
-- Split out of the old single keymap.lua (2026-08-15); the maps and
-- their rationale are verbatim from there. Master index: ./init.lua.
--
-- Sections (in order): Clipboard, Save / quit, Substitute, Undo,
-- Select all, Visual selection, Scrolling, Word motion, Move line,
-- Comment toggle.
-- ============================================================================

local M = {}

-- require("hwangfu.keymappings.editor").setup()
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

    -- Word/cursor motion in n/i/v. The same RHS works in all three modes:
    --   n: built-in motion jumps the cursor (e.g. b/w move by word).
    --   i: the motion wrapped in <Cmd>normal! ...<CR>, which executes
    --      a normal-mode command without visibly switching modes --
    --      the mode indicator stays on "-- INSERT --" and the cursor
    --      keeps its insert shape throughout. The "<C-o>" .. motion
    --      alternative does the same jump but briefly enters the
    --      "-- (insert) --" one-shot sub-mode, which flashes the
    --      mode indicator (and, with our guicursor settings, the
    --      cursor shape). Readers tend to parse that flicker as
    --      "I was kicked back to normal mode" even though the
    --      buffer state is fine, so <Cmd> is the friendlier shape.
    --   v: the motion extends the active selection in that direction.
    -- Visual mode intentionally does NOT prepend <Esc>: dropping the
    -- selection mid-extend is the opposite of what these keys are for.
    local function word_motion(lhs, motion)
        map("n", lhs, motion, { silent = true })
        map("i", lhs, "<Cmd>normal! " .. motion .. "<CR>", { silent = true })
        map("v", lhs, motion, { silent = true })
    end

    -- Scroll cmd in n/i; extend selection by visual_motion in v.
    --   n/i: cmd (e.g. <C-e>/<C-y>) scrolls the viewport without
    --        moving the cursor. Insert mode wraps cmd in
    --        <Cmd>normal! ...<CR> so the scroll runs without
    --        dropping into the "-- (insert) --" sub-mode -- same
    --        reasoning as word_motion's insert variant above.
    --        The <C-e> / <C-y> notation inside the <Cmd> span is
    --        handled by Vim's `<>` notation pass and expands to the
    --        literal control character before the command executes,
    --        so :normal! sees the correct keystroke.
    --   v: visual_motion (e.g. <Up>/<Down>) extends the selection by
    --      one line. The raw scroll command would leave the selection
    --      range unchanged while pushing it off-screen, which is
    --      rarely what you want once a select is in progress.
    local function scroll(lhs, cmd, visual_motion)
        map("n", lhs, cmd)
        map("i", lhs, "<Cmd>normal! " .. cmd .. "<CR>")
        map("v", lhs, visual_motion, { silent = true })
    end

    -- --- Clipboard (system) ---------------------------------------------
    map("v", "<C-D>", '"+y')
    map("v", "<C-c>", '"+y')
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

    -- --- Substitute across file (Ctrl-R) --------------------------------
    --
    -- Pre-fill the cmdline with `:%s/\V<pat>//g` and park the cursor
    -- between the two slashes. You type the replacement and press Enter.
    -- Neovim's built-in `inccommand` (default = "nosplit" in modern
    -- Neovim) lights up every match in the buffer as you type the
    -- replacement, so a misfire is recoverable with <Esc> before
    -- committing.
    --
    -- Pre-fill anatomy: `:%s/\V<pat>//g`
    --   * %       file-wide range (every line).
    --   * \V      very-nomagic: everything in the pattern is literal
    --             except backslash and the delimiter /, which we
    --             escape via vim.fn.escape. So cursor on `.` matches
    --             literal dots, cursor on `*` matches literal stars.
    --   * <pat>   the character / selection, escaped.
    --   * //      empty replacement; cursor lands here (the 2 <Left>s
    --             at the end of the feedkeys string walk the cursor
    --             back over `g` and over the trailing `/`).
    --   * g       replace every occurrence on each line. No `c` flag
    --             by design: you almost never want to confirm hundreds
    --             of single-char replacements. Add `c` manually before
    --             pressing Enter on the rare occasion you want to step.
    --
    -- Behavior per mode:
    --   * n  Substitute the single character under the cursor.
    --        Multi-byte-aware: matchstr(line, ".", col-1) returns one
    --        whole character (UTF-8 / Chinese / emoji safe), not one
    --        byte. On an empty line (or any cursor position where no
    --        character resolves) vim.notify warns at WARN level and
    --        we bail without opening the cmdline.
    --   * v  Substitute the visual selection. The yank uses register
    --        "z" so we don't clobber " (unnamed) or + (system
    --        clipboard); empty selection bails silently because the
    --        only way to land here is via an aborted visual that has
    --        no length. Multi-line selections work because we convert
    --        literal newlines in the yank to \n in the pattern (Vim's
    --        regex syntax for end-of-line).
    --   * i  Deliberately unbound. Preserves Vim's built-in "insert
    --        register" (<C-r>" pastes last yank, <C-r>0 pastes most
    --        recent explicit yank, <C-r>+ pastes from system
    --        clipboard, etc.) -- too useful to override.
    --
    -- This mapping replaces the previous <C-r> = reload-buffer
    -- binding. Reload is now `:e<CR>` (3 keystrokes). Vim's built-in
    -- redo on <C-r> remains shadowed by this mapping (same as before);
    -- use `:redo<CR>` for redo, or remember that `.` (repeat last
    -- change) covers most "do that again" cases without needing redo.
    map("n", "<C-r>", function()
        local char = vim.fn.matchstr(vim.fn.getline("."), ".", vim.fn.col(".") - 1)
        if char == "" then
            vim.notify(
                "Ctrl-R: no character under cursor (empty line or past EOL)",
                vim.log.levels.WARN
            )
            return
        end
        local pat = vim.fn.escape(char, [[\/]])
        vim.api.nvim_feedkeys(
            ":%s/\\V" .. pat .. "//g"
                .. string.rep(vim.api.nvim_replace_termcodes("<Left>", true, false, true), 2),
            "n",
            false
        )
    end, { desc = "Substitute char under cursor across file" })

    -- Visual variant: string-RHS / <C-r>= idiom instead of a Lua
    -- callback. A Lua function callback in a visual-mode mapping has
    -- timing weirdness around the visual-mode exit and the
    -- '< / '> marks not being set yet when the callback fires; the
    -- canonical Vim approach below sidesteps the whole question by
    -- letting Vim execute the key sequence directly while still in
    -- visual mode. Breakdown of the RHS:
    --   "zy     yank the active selection into register z (preserves
    --           the unnamed " register and the system clipboard +)
    --   :       open the cmdline
    --   %s/\V   start substitute, file-wide, very-nomagic so the
    --           contents match literally
    --   <C-r>=  expression register insertion -- the next expression's
    --           result gets inserted into the cmdline
    --     substitute(escape(@z, '\/'), '\n', '\\n', 'g')
    --       escape \ and / in @z (for \V and the / delimiter), then
    --       convert real newlines to the literal two-char \n so multi-
    --       line selections match end-of-line in the regex.
    --   <CR>    end the expression-register evaluation
    --   //g     empty replacement, global flag (no `c`; add manually
    --           on the rare occasion you want per-match confirm)
    --   <Left><Left>   park cursor between the two slashes
    map("v", "<C-r>",
        [["zy:%s/\V<C-r>=substitute(escape(@z, '\/'), '\n', '\\n', 'g')<CR>//g<Left><Left>]],
        { desc = "Substitute selection across file" }
    )

    -- --- Undo -----------------------------------------------------------
    -- Ctrl-U and Ctrl-Z both undo, mirroring mainstream-editor muscle
    -- memory. Note that mapping <C-u> in normal mode shadows Vim's
    -- built-in "scroll half a page up"; the Ctrl/Shift + Up/Down maps
    -- below cover scrolling, so the override is intentional.
    --
    -- Insert mode (<C-z> added 2026-08 on user request - Windows-style
    -- undo while typing):
    --   * <C-z> exits insert, then undoes. Because leaving insert mode
    --     closes the current undo block, a mid-typing <C-z> reverts the
    --     WHOLE chunk typed since insert began - not just the last
    --     keystroke; same granularity as typing <Esc>u by hand. You
    --     land in normal mode afterwards, like the <C-s> save map.
    --     (This replaces an earlier decision to keep <C-z> normal-mode
    --     only out of stray-keypress caution.)
    --   * <C-u> stays UNMAPPED in insert: its built-in there (delete
    --     back to start of line) is genuinely handy and worth keeping.
    map("n", "<C-u>", ":u<CR>", { silent = true, desc = "Undo" })
    map("n", "<C-z>", ":u<CR>", { silent = true, desc = "Undo" })
    map("i", "<C-z>", "<Esc>:u<CR>", { silent = true, desc = "Undo (exits insert first)" })

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

    -- --- Scrolling (Ctrl + Up/Down) -------------------------------------
    -- Normal/insert: scroll the viewport without moving the cursor.
    -- Visual: extend the selection by one line in that direction, so
    -- the same key keeps a live select growing instead of scrolling
    -- away from it.
    scroll("<C-Down>", "<C-e>", "<Down>")
    scroll("<C-Up>", "<C-y>", "<Up>")

    -- --- Word motion (Ctrl + Left/Right) --------------------------------
    -- Normal/insert: jump the cursor by one word in that direction.
    -- Visual: extend the selection by one word, keeping visual mode
    -- active across the press.
    word_motion("<C-Left>", "b")
    word_motion("<C-Right>", "w")

    -- --- Move line / block (Alt + Up/Down) ------------------------------
    map("n", "<A-Up>", ":m .-2<CR>==", {
        silent = true,
        desc = "Move line up",
    })
    map("n", "<A-Down>", ":m .+1<CR>==", {
        silent = true,
        desc = "Move line down",
    })
    map("v", "<A-Up>", ":m '<-2<CR>gv=gv", {
        silent = true,
        desc = "Move block up",
    })
    map("v", "<A-Down>", ":m '>+1<CR>gv=gv", {
        silent = true,
        desc = "Move block down",
    })
    map("i", "<A-Up>", "<Esc>:m .-2<CR>==gi", {
        silent = true,
        desc = "Move line up (insert)",
    })
    map("i", "<A-Down>", "<Esc>:m .+1<CR>==gi", {
        silent = true,
        desc = "Move line down (insert)",
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
