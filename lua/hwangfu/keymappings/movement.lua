-- ============================================================================
-- Movement keymappings: scrolling, word motion, and line moving.
-- Split out of editor.lua (2026-08-15) to mirror docs/keymappings/
-- movement.md. Master index: ./init.lua.
-- ============================================================================

local M = {}

-- require("hwangfu.keymappings.movement").setup()
function M.setup()
    local function map(modes, lhs, rhs, opts)
        vim.keymap.set(modes, lhs, rhs, opts or {})
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
end

return M
