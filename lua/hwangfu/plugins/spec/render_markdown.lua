-- In-buffer Markdown rendering (render-markdown.nvim).
--
-- Decorates Markdown *inside the editing buffer* via treesitter --
-- styled headings, code-block backgrounds, drawn tables, bullets,
-- checkboxes, block quotes and callouts. This is the in-editor
-- counterpart to the BROWSER previewer above: live-preview.nvim opens
-- an external window, whereas this one restyles the text you are
-- already looking at -- no browser, no second process, scrolls with
-- the buffer.
--
-- Default ON. The setup() call below passes enabled = true (also the
-- plugin's own default), so rendering goes live the moment a Markdown
-- buffer loads -- no manual step. :MarkdownRender toggle flips the
-- GLOBAL render state (every Markdown buffer at once). Command-driven,
-- no keymaps: the old <leader>mr was removed 2026-08-15 to free the
-- namespace.
--
-- COMMAND NAME. Upstream hardcodes its command as `:RenderMarkdown`
-- (registered from the plugin's own plugin/ directory, which lazy sources
-- just before our config() runs). To honor the rename we delete that
-- stock command in config() and install our own `:MarkdownRender`, a thin
-- wrapper that forwards every subcommand to render-markdown's public API.
-- All upstream subcommands carry over under the new name, with
-- tab-completion:
--   :MarkdownRender enable / disable / toggle              (global)
--   :MarkdownRender buf_enable / buf_disable / buf_toggle  (this buffer)
--   :MarkdownRender set true|false  /  set_buf true|false
--   :MarkdownRender preview / expand / contract / log / debug / config
-- A bare `:MarkdownRender` with no argument enables, matching upstream.
--
-- Lazy-load triggers are `ft = "markdown"` (opening a Markdown file)
-- and `cmd = { "MarkdownRender" }` (typing the command); render-markdown
-- stays unloaded until either fires. The `ft` trigger is what makes
-- "default ON" actually visible -- opening a Markdown file loads the
-- plugin, which then renders the buffer immediately because enabled =
-- true. `cmd` still reaches it from a cold start in a non-Markdown
-- buffer.
--
-- NON-OBVIOUS side effect of the `ft` trigger: when we set no explicit
-- `file_types`, render-markdown adopts lazy.nvim's `ft` value as its
-- file_types (see its resolve_config). So `ft = "markdown"` ALSO scopes
-- rendering to Markdown buffers only -- it drops `gitcommit`, which is in
-- upstream's default file_types. To also render commit-message buffers,
-- add "gitcommit" to the ft list below.
--
-- Requirements (all already satisfied by this config except the parsers,
-- which install on demand):
--   * Icon provider -- nvim-tree/nvim-web-devicons (already pulled in as
--     a lualine dependency). Re-listed under `dependencies` so a fresh
--     clone installs it and the load order is correct.
--   * Nerd Font in the terminal -- the same one lualine's glyphs need.
--   * Treesitter parsers `markdown` AND `markdown_inline`. Our
--     nvim-treesitter spec installs parsers on demand (no
--     ensure_installed), so if a toggled-on buffer shows no styling,
--     install them once with `:TSInstall markdown markdown_inline` and
--     confirm with `:checkhealth render-markdown`.
--
-- ASCII-only rule: the glyphs render-markdown draws (heading icons,
-- bullets, table borders) are Nerd Font / Unicode, but they come from
-- the plugin's runtime defaults, NOT from this file -- the same
-- arrangement as lualine's icons. This spec itself stays ASCII.
return {
	"MeanderingProgrammer/render-markdown.nvim",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	-- Load (and therefore render) when a Markdown buffer opens. This ft
	-- value also becomes the plugin's file_types -- see the NON-OBVIOUS
	-- note above before adding more entries here.
	ft = { "markdown" },
	cmd = { "MarkdownRender" },
	config = function()
		-- Rendering ON by default. enabled = true is also the plugin's
		-- own default; we state it explicitly so the intent is obvious.
		-- Every other knob is left at the plugin's defaults.
		require("render-markdown").setup({
			enabled = true,
		})

		-- Rename :RenderMarkdown -> :MarkdownRender. Upstream registers
		-- its command from plugin/render-markdown.lua, which lazy sources
		-- just before this config() runs, so the stock :RenderMarkdown
		-- already exists here. Delete it, then install our own command of
		-- the new name. The wrapper mirrors upstream's dispatch (see
		-- render-markdown/core/command.lua): the first argument selects an
		-- API method (default "enable"); `set` / `set_buf` take an
		-- optional true|false; no other method takes an argument. We
		-- forward to the documented public API on require("render-markdown").
		pcall(vim.api.nvim_del_user_command, "RenderMarkdown")

		-- Subcommands kept in step with render-markdown's public API.
		-- `bool_methods` are the only ones that accept a true|false arg.
		local subcommands = {
			"enable",
			"disable",
			"toggle",
			"buf_enable",
			"buf_disable",
			"buf_toggle",
			"set",
			"set_buf",
			"get",
			"preview",
			"expand",
			"contract",
			"log",
			"debug",
			"config",
		}
		local bool_methods = { set = true, set_buf = true }

		local function startswith(value, prefix)
			return vim.startswith(value, prefix)
		end

		vim.api.nvim_create_user_command("MarkdownRender", function(opts)
			local fargs = opts.fargs
			if #fargs > 2 then
				vim.notify(
					"MarkdownRender: invalid # arguments - " .. #fargs,
					vim.log.levels.ERROR
				)
				return
			end
			local method = fargs[1] or "enable"
			local fn = require("render-markdown")[method]
			if type(fn) ~= "function" or method == "render" then
				vim.notify(
					"MarkdownRender: invalid command - " .. method,
					vim.log.levels.ERROR
				)
				return
			end
			local value = fargs[2]
			if value == nil then
				fn()
			elseif not bool_methods[method] then
				vim.notify(
					"MarkdownRender: no arguments allowed - " .. method,
					vim.log.levels.ERROR
				)
			elseif value == "true" or value == "false" then
				fn(value == "true")
			else
				vim.notify(
					"MarkdownRender: invalid argument - " .. method .. "(" .. value .. ")",
					vim.log.levels.ERROR
				)
			end
		end, {
			nargs = "*",
			desc = "render-markdown.nvim commands (renamed from :RenderMarkdown)",
			complete = function(arg_lead, cmd_line)
				-- A first token already present means we are completing the
				-- second argument: only set / set_buf offer one (true|false).
				local first = cmd_line:match("MarkdownRender%s+(%S+)%s+%S*$")
				if first then
					if bool_methods[first] then
						return vim.tbl_filter(function(v)
							return startswith(v, arg_lead)
						end, { "true", "false" })
					end
					return {}
				end
				return vim.tbl_filter(function(v)
					return startswith(v, arg_lead)
				end, subcommands)
			end,
		})
	end,
}
