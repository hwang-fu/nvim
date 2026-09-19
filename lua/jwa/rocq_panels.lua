-- Coqtail's Goal and Info panels draw the same symbols as the source buffer.
-- The symbols themselves are after/syntax/coq.vim, brought into the two panel
-- syntaxes by after/syntax/coq-goals.vim and coq-infos.vim; this module sets
-- the window options that make them visible.
--
-- The options go on at BufWinEnter rather than when the filetype is set,
-- because of how Coqtail builds a panel (autoload/coqtail/panels.vim, s:init):
-- it edits the panel buffer inside the MAIN window, sets its filetype there,
-- and only afterwards shows it in a split of its own. An ftplugin that set the
-- options directly would land them on the main window and leave the panel's
-- window at conceallevel 0. BufWinEnter fires in whichever window finally
-- displays the panel, and again when the panels are restored after closing.

local M = {}

local function apply()
	vim.opt_local.conceallevel = 2
	vim.opt_local.concealcursor = "n"
	-- Checked first because this runs on every re-entry into the same window,
	-- and an unconditional append would stack duplicate entries.
	if vim.opt_local.winhighlight:get().Conceal == nil then
		vim.opt_local.winhighlight:append("Conceal:coqKwd")
	end
end

function M.attach(buf)
	buf = buf or vim.api.nvim_get_current_buf()
	vim.api.nvim_create_autocmd("BufWinEnter", {
		group = vim.api.nvim_create_augroup("jwa_rocq_panel_" .. buf, { clear = true }),
		buffer = buf,
		callback = apply,
	})
end

return M
