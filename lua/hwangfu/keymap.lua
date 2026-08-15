-- ============================================================================
-- Global keymaps.
--
-- Goal: make Neovim feel closer to mainstream editor conventions for the
-- handful of universal shortcuts (Ctrl-S to save, Ctrl-A to select all,
-- Ctrl-Shift-arrow word navigation, Alt-arrow line moving) WITHOUT touching
-- Vim's core motions.
--
-- Sections (in order):
--   * Helpers           - small wrappers around vim.keymap.set so the maps
--                         themselves stay one-line declarations
--   * Clipboard         - system-clipboard yank/cut in visual mode
--   * Save / quit       - Ctrl-S (n + i), Ctrl-Q (n quits; i + v error)
--   * Substitute        - Ctrl-R (n: char under cursor; v: selection)
--   * Undo              - Ctrl-U (n), Ctrl-Z (n + i)
--   * Select all        - Ctrl-A (n + i)
--   * Visual selection  - Shift + arrows (n) enter visual and extend
--   * Scrolling         - Ctrl + Up/Down (n/i scroll, v extends by line)
--   * Word motion       - Ctrl + Left/Right (n/i jump, v extends by word)
--   * Move line         - Alt + Up/Down (with re-indent)
--   * Comment toggle    - Ctrl-/ (n + v); delegates to gcc / gc
--   * Mouse smart jump  - Ctrl+LeftClick: LSP definition; references
--                         when clicked at the definition itself; quiet
--                         ctags fallback in non-LSP buffers (back: <C-o>)
--   * Oil explorer      - Ctrl-T sidebar toggle (at buffer's dir; see
--                         lua/hwangfu/explorer.lua); `..` goes up
--   * Buffers           - ]b / [b cycle, <leader>bd close
--
-- NOT in this file (buffer-local maps defined where their plugin is
-- configured, in lua/hwangfu/plugins/spec/<plugin>.lua):
--   * Git hunks         - ]c / [c, <leader>h*, <leader>tb, <leader>tw, ih
--                         (gitsigns.nvim spec; see its "Keymap quick
--                         reference" comment for the full table)
--   * Oil buffer keys   - <CR> open (also on the always-visible ../ first
--                         row, NERDTree-style), - / .. up, g. hidden,
--                         dd + :w ops (oil.nvim spec; see its "Keymap
--                         quick reference" comment for the full table)
--   * Git UI            - <leader>gg lazygit float (lua/hwangfu/git.lua);
--                         <leader>gd / gh / gH diffview (its spec's keys)
--   * Browser preview   - <leader>mp start / ms close / mt pick
--                         (live-preview.nvim spec)
--   * Markdown render   - <leader>mr (or :MarkdownRender toggle) toggles
--                         in-buffer rendering on/off (render-markdown.nvim
--                         spec; lazy `ft`/`keys`/`cmd` triggers, default on)
--   * Textobjects       - af/if, ac/ic, aa/ia (visual + operator-
--                         pending); ]f/[f, ]F/[F, ]]/[[ motions
--                         (nvim-treesitter-textobjects spec; ]c/[c stay
--                         with gitsigns hunks)
--   * Keymap discovery  - which-key popup on any pending prefix; leader
--                         groups labeled in its spec (which-key.nvim)
--   * OCaml editing     - <localleader>* in OCaml buffers, <localleader>
--                         being backslash: \c construct/fill hole, \n / \p
--                         next / prev hole, \s switch .ml/.mli, \i infer
--                         interface, \t type enclosing, \j jump
--                         (ocaml.nvim spec; see its command reference
--                         comment for the full table)
--   * OCaml REPL        - <localleader>r toggle the project-scoped utop
--                         float (lua/hwangfu/repl.lua)
--   * Lisp eval         - conjure: <localleader>e* eval maps + \l* log
--                         maps in clojure/fennel/racket/scheme buffers
--                         (its spec); slimv: ,* SLIME maps for Common
--                         Lisp - GLOBAL once loaded, so the comma
--                         namespace belongs to slimv (its spec).
--                         parinfer-rust and rainbow-delimiters add no
--                         keys at all.
--   * Debugging         - F5 start/continue, S-F5 stop, F6 pause, F7 UI,
--                         F8 Rust debuggables, F9 breakpoint, F10/F11/
--                         S-F11 step over/into/out - global, defined in
--                         lua/hwangfu/dap.lua (bare `keys` triggers in the
--                         nvim-dap spec lazy-load the stack on first press)
--============================================================================

local M = {}

-- ----------------------------------------------------------------------------
-- Smart mouse jump (VSCode-style), bound to <C-LeftMouse> in setup().
--
-- Replaces Vim's built-in Ctrl+click tag jump (2026-08-15), which had an
-- ugly failure mode: when the LSP had no target for the clicked position
-- (typically: clicking a symbol AT its own definition), tagfunc fell
-- back to classic ctags and errored with E433 "No tags file" + E426
-- "Tag not found" + a press-ENTER prompt.
--
-- Behavior by case:
--   * click a usage                  -> jump to its definition (LSP)
--   * click a symbol at its own
--     definition                     -> list its REFERENCES instead
--                                       (what VSCode does for this)
--   * no target at all               -> references (which then reports
--                                       politely if there are none)
--   * buffer with no LSP definition
--     support                        -> the old tag jump, pcall-wrapped:
--                                       ctags projects still work, and
--                                       failures give one quiet notify
--                                       instead of the E433/E426 pair
--
-- Jump back with <C-o> (jumplist) - NOT <C-t>, which is the oil sidebar
-- toggle here (and tag-stack based anyway; this jump bypasses the tag
-- stack).
--
-- Implementation note: the decision runs in a RAW buf_request handler,
-- not vim.lsp.buf.definition's on_list - discovered 2026-08-15 that
-- on_list is never invoked for EMPTY results (the handler prints "No
-- locations found" and stops), which made the empty/at-definition
-- branch unreachable. On a real target the stock
-- vim.lsp.buf.definition() is re-run for the actual jump; that second
-- request is deliberate: definition lookups are millisecond-cheap, and
-- re-using the stock path keeps all of its behavior (single-target
-- jump, multi-target list) without re-implementing it here.
-- ----------------------------------------------------------------------------
function M.smart_definition()
    local bufnr = vim.api.nvim_get_current_buf()
    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
        method = "textDocument/definition",
    })

    if #clients == 0 then
        local ok = pcall(vim.cmd, "normal! \x1d") -- <C-]>: classic tag jump
        if not ok then
            vim.notify("No definition found (no LSP, no tags)", vim.log.levels.INFO)
        end
        return
    end

    local cur = vim.api.nvim_win_get_cursor(0)
    local curfile = vim.api.nvim_buf_get_name(bufnr)

    -- Params as a function: position encodings differ per client, so
    -- the position is computed with each client's own offset_encoding.
    local handled = false
    vim.lsp.buf_request(bufnr, "textDocument/definition", function(client, _)
        return vim.lsp.util.make_position_params(0, client.offset_encoding)
    end, function(_, result, _)
        -- With several capable clients the handler runs once per
        -- response; the first one wins.
        if handled then
            return
        end
        handled = true

        -- result: nil | Location | Location[] | LocationLink[]
        local locs = result or {}
        if not vim.islist(locs) then
            locs = { locs }
        end

        -- "Already at the definition" = every returned target is the
        -- very line the cursor sits on (column ignored: the name spans
        -- several columns).
        local at_self = #locs > 0
        for _, loc in ipairs(locs) do
            local uri = loc.uri or loc.targetUri
            local range = loc.range or loc.targetSelectionRange
            if vim.uri_to_fname(uri) ~= curfile or (range.start.line + 1) ~= cur[1] then
                at_self = false
                break
            end
        end

        if #locs == 0 or at_self then
            vim.lsp.buf.references()
        else
            vim.lsp.buf.definition()
        end
    end)
end

-- require("hwangfu.keymap").setup()
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
    map("v", "<C-l>", "gc", {
        remap = true,
        desc = "Toggle comment",
    })

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
    -- Note: the visual-mode <C-l> map in the Clipboard section above
    -- ALSO toggles comment (it predates this section). The two
    -- bindings coexist; they delegate to the same `gc` operator.
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

    -- --- Mouse: Ctrl+LeftMouse smart jump --------------------------------
    -- The <LeftMouse> prefix first moves the cursor to the clicked
    -- position (a pending mouse click in a mapping RHS is consumed as
    -- "position the cursor there"); the <Cmd> half then runs the smart
    -- jump from that spot. Full behavior table in M.smart_definition's
    -- comment above. Normal mode only, matching the LSP keymaps.
    map(
        "n",
        "<C-LeftMouse>",
        "<LeftMouse><Cmd>lua require('hwangfu.keymap').smart_definition()<CR>",
        { silent = true, desc = "LSP: smart definition / references (mouse)" }
    )

    -- --- Oil (file explorer sidebar) ------------------------------------
    -- <C-t> toggles a fixed-width left SIDEBAR listing the *current
    -- buffer's* directory. The behavior lives in lua/hwangfu/explorer.lua
    -- (width, auto-close-on-open, and the no-inline-expansion limitation
    -- are all documented in that module's header); this map is just the
    -- global entry point. Case summary:
    --   * Sidebar open (focus anywhere) -> close it.
    --   * Current buffer is a FULL-WINDOW oil listing (`nvim some/dir`)
    --     -> close the listing, back to the previous buffer (the
    --     pre-sidebar behavior, kept for that case).
    --   * Otherwise -> open the sidebar at the buffer's directory
    --     (re-roots on every press: after gd / telescope into a file
    --     elsewhere on disk, the sidebar shows THAT file's directory).
    --
    -- History: from 2026-08 to 2026-08-14 this map opened oil in the
    -- current window (full screen); replaced by the sidebar for NERDTree
    -- parity.
    --
    -- Side-effect free: does NOT change Neovim's :cwd, so plugins keyed
    -- off cwd (lazy, telescope's default scope, etc.) keep behaving the
    -- same. If you also want :cwd to follow, see `:h 'autochdir'`.
    --
    -- Buffer-local keys inside oil listings (`..` up-dir alias, the
    -- sidebar-aware <CR> and <C-t> overrides, <C-s> passthrough to save)
    -- are configured in oil's spec (plugins/spec/oil.lua), next to
    -- the plugin they belong to -- the same split used for the gitsigns
    -- hunk maps.
    map("n", "<C-t>", function()
        require("hwangfu.explorer").toggle()
    end, {
        silent = true,
        desc = "Toggle oil sidebar at current buffer's directory",
    })

    -- --- Buffers --------------------------------------------------------
    -- A buffer is a file Neovim has loaded into memory; these keys move
    -- between buffers and close them. Opening a file, or picking a buffer
    -- from a list, is handled by telescope (<leader>ff / <leader>fb).
    --
    -- Returning after a jump: commands like gd (go-to-definition) can send
    -- you off into another file. Neovim records each such jump in the
    -- jumplist; press <C-o> to jump back to where you were and <C-i> to go
    -- forward again. <C-^> toggles between the current and previous buffer.
    -- (<C-o> / <C-i> / <C-^> are built-in Neovim keys, listed here for
    -- reference; this file does not map them.)
    map("n", "]b", ":bnext<CR>", {
        silent = true,
        desc = "Next buffer",
    })
    map("n", "[b", ":bprevious<CR>", {
        silent = true,
        desc = "Previous buffer",
    })
    map("n", "<leader>bd", ":bdelete<CR>", {
        silent = true,
        desc = "Close (delete) current buffer",
    })
end

return M
