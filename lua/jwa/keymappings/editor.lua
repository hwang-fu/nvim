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

    -- Forward declaration: the disk-aware save behind every Ctrl-S.
    -- Defined in the Save / quit section below; declared here because
    -- the visual-mode Ctrl-S in the Clipboard section calls it too.
    local smart_save

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
    -- Then smart_save() writes (disk-aware; see the Save / quit
    -- section below).
    map("v", "<C-s>", function()
        local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
        vim.api.nvim_feedkeys(esc, "tx", false)
        smart_save()
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
    -- --- Disk-aware Ctrl-S (2026-08-23, user request) ---------------
    -- "If someone else changed the file while we are inside it, a
    -- Ctrl-S should refresh the buffer to the newest state rather
    -- than overwrite the changes others made."
    --
    -- Every Ctrl-S therefore starts with :checktime, and the
    -- FileChangedShell handler below decides what an on-disk change
    -- means. Three cases:
    --   * only WE changed     -> ordinary write (the common path).
    --   * only the DISK moved -> the buffer is clean, so it reloads
    --     to the newest version and NOTHING is written; a WARN notice
    --     says the refresh happened.
    --   * BOTH changed        -> a real conflict no key can merge.
    --     Ctrl-S prompts (user request, same day): Mine overwrites
    --     the disk with your buffer, Theirs discards your edits and
    --     loads the disk version, Cancel (the default) leaves both
    --     versions where they are - yours in the buffer, theirs on
    --     disk - so nothing is lost by accident.
    --
    -- The handler is global (pattern *), so it also governs the
    -- checktime Neovim runs by itself (FocusGained etc.): clean
    -- buffers silently track the disk - same net effect as the
    -- 'autoread' default - and conflicted buffers are kept, warned
    -- about once, and left for Ctrl-S to explain at the moment that
    -- actually matters.
    --
    -- Bookkeeping lives in closure tables keyed by buffer number, NOT
    -- in b: variables: the reload that fcs_choice = "reload" triggers
    -- WIPES buffer-local variables (verified live - a flag set by the
    -- handler read back as nil after the reload, silently skipping the
    -- refresh notice and issuing a redundant write). disk_check holds
    -- the per-checktime result smart_save reads back; disk_warned
    -- dedupes the background conflict ERROR so focus-switching in a
    -- conflicted state does not spam. Entries clear on write, on
    -- taking the disk version, and on buffer wipeout.
    local disk_check = {}
    local disk_warned = {}
    local save_group = vim.api.nvim_create_augroup("JwaSmartSave", { clear = true })

    vim.api.nvim_create_autocmd("FileChangedShell", {
        group = save_group,
        pattern = "*",
        callback = function(args)
            local reason = vim.v.fcs_reason
            local modified = vim.bo[args.buf].modified
            if reason == "deleted" then
                -- File vanished from disk. Keep the buffer; a later
                -- save simply recreates the file.
                vim.v.fcs_choice = ""
            elseif reason == "mode" then
                -- Permission-only change; contents are untouched.
                vim.v.fcs_choice = ""
            elseif modified or reason == "conflict" then
                -- Disk changed AND the buffer holds local edits.
                vim.v.fcs_choice = ""
                disk_check[args.buf] = "conflict"
                if not disk_warned[args.buf] then
                    disk_warned[args.buf] = true
                    local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(args.buf), ":.")
                    vim.schedule(function()
                        vim.notify(
                            string.format(
                                "%s changed on disk while this buffer holds unsaved edits - kept your version; Ctrl-S will ask which one wins",
                                name
                            ),
                            vim.log.levels.ERROR
                        )
                    end)
                end
            else
                -- "changed" / "time" with a clean buffer: track disk.
                vim.v.fcs_choice = "reload"
                disk_check[args.buf] = "reloaded"
                disk_warned[args.buf] = nil
            end
        end,
    })

    vim.api.nvim_create_autocmd({ "BufWritePost", "BufWipeout" }, {
        group = save_group,
        pattern = "*",
        callback = function(args)
            disk_check[args.buf] = nil
            disk_warned[args.buf] = nil
        end,
    })

    smart_save = function()
        local buf = vim.api.nvim_get_current_buf()
        -- Non-file buffers and unnamed scratch: plain :write, whose
        -- own errors explain the situation better than we could.
        if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
            vim.cmd("write")
            return
        end
        disk_check[buf] = nil
        -- Two reload detectors are needed: with 'autoread' on (the
        -- Neovim default) a clean buffer is reloaded WITHOUT firing
        -- FileChangedShell (verified live - the handler never ran for
        -- the clean-disk-change case), so disk_check stays empty and
        -- only the changedtick bump betrays that the buffer was
        -- replaced. The FCS "reloaded" marking still covers setups
        -- where 'autoread' is off.
        local tick = vim.api.nvim_buf_get_changedtick(buf)
        vim.cmd("silent! checktime " .. buf)
        if disk_check[buf] == "conflict" then
            local choice = vim.fn.confirm(
                "The file changed on disk while you edited it. Which version wins?",
                "&Mine (overwrite disk)\n&Theirs (discard my edits)\n&Cancel",
                3,
                "Warning"
            )
            if choice == 1 then
                vim.cmd("silent write!")
                vim.notify("Ctrl-S: wrote your version over the on-disk changes", vim.log.levels.WARN)
            elseif choice == 2 then
                vim.cmd("silent edit!")
                disk_check[buf] = nil
                disk_warned[buf] = nil
                vim.notify("Ctrl-S: took the on-disk version; your edits were discarded", vim.log.levels.WARN)
            else
                vim.notify(
                    "Ctrl-S: nothing done - your edits stay in the buffer, the other version stays on disk",
                    vim.log.levels.WARN
                )
            end
            return
        end
        local reloaded = disk_check[buf] == "reloaded"
            or vim.api.nvim_buf_get_changedtick(buf) ~= tick
        if reloaded and not vim.bo[buf].modified then
            vim.notify(
                "Ctrl-S: refreshed to the newer on-disk version (you had no unsaved edits)",
                vim.log.levels.WARN
            )
            return
        end
        -- :update, not :write. Ctrl-S gets pressed reflexively, often on a
        -- buffer nobody touched; an unconditional write would bump mtime
        -- every time and wake watchers, rebuilds and reload loops for a file
        -- whose bytes did not change. An explicit :w stays the way to force
        -- a write regardless.
        vim.cmd("update")
    end

    map("n", "<C-s>", smart_save, { desc = "Save (refreshes from disk if others changed the file)" })
    map("i", "<C-s>", function()
        vim.cmd("stopinsert")
        smart_save()
    end, { desc = "Save (refreshes from disk if others changed the file)" })
    map("n", "<C-q>", ":q<CR>", { desc = "Quit window" })
    map("i", "<C-q>", function()
        vim.notify("Can't quit from insert mode; press <Esc> first", vim.log.levels.ERROR)
    end, { desc = "Reject quit-from-insert (use <Esc> first)" })
    map("v", "<C-q>", function()
        vim.notify("Can't quit from visual mode; press <Esc> first", vim.log.levels.ERROR)
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
    map(
        "v",
        "<C-r>",
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
