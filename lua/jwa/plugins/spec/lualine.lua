-- Statusline.
return {
	"nvim-lualine/lualine.nvim",
	-- Icon provider for the `filetype` component (per-language glyphs,
	-- e.g. for lua / rust / python). Only consulted because
	-- icons_enabled = true below; lualine works fine without it, just
	-- icon-less. The glyphs are Nerd Font private-use-area codepoints,
	-- so the TERMINAL font must be (or fall back to) a Nerd Font --
	-- several are installed user-wide at ~/.local/share/fonts. The
	-- icons live inside the plugins at runtime; this config file
	-- itself stays ASCII-only.
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("lualine").setup({
			options = {
				theme = "auto",
				-- Nerd Font glyphs in components: branch icon, filetype
				-- icon (via nvim-web-devicons above). If the statusline
				-- ever shows empty boxes instead (terminal without a
				-- Nerd Font, e.g. over ssh on another machine), set
				-- this back to false and drop the dependency above.
				icons_enabled = true,
				component_separators = { left = "|", right = "|" },
				section_separators = { left = "", right = "" },
			},
			sections = {
				lualine_a = {
					"mode",
				}, -- NORMAL / INSERT / VISUAL
				lualine_b = {
					"branch", -- git branch
					{
						"diff", -- git diff (+added ~modified -removed)
						-- Pull the counts from gitsigns.nvim (spec below)
						-- instead of lualine's internal `git diff`
						-- polling, so the statusline numbers and the
						-- gutter signs come from ONE git query and always
						-- agree. gitsigns publishes per-buffer counts in
						-- vim.b.gitsigns_status_dict (fields: added /
						-- changed / removed, plus head / root / gitdir).
						--
						-- Returning nil (gitsigns not attached: buffer
						-- outside a git repo, or an untracked file) makes
						-- the component render nothing -- same as
						-- lualine's internal source showed for those
						-- buffers before, so this changes no visuals.
						source = function()
							local status = vim.b.gitsigns_status_dict
							if status then
								return {
									added = status.added,
									modified = status.changed,
									removed = status.removed,
								}
							end
						end,
					},
				},
				lualine_c = {
					{
						"filename",
						path = 1,
					}, -- 0=filename, 1=relative path, 2=absolute path
					{
						"diagnostics", -- LSP diagnostics (errors/warnings)
						symbols = {
							error = "E:",
							warn = "W:",
							info = "I:",
							hint = "H:",
						},
					},
				},
				lualine_x = {
					"encoding", -- utf-8
					-- "fileformat", -- unix/dos
					"filetype", -- lua/python/go/...
				},
				lualine_y = { "progress" }, -- file progress %
				lualine_z = { "location" }, -- line:column
			},
			inactive_sections = {
				-- Statusline for inactive windows
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "filename" },
				lualine_x = { "location" },
				lualine_y = {},
				lualine_z = {},
			},
		})
	end,
}
