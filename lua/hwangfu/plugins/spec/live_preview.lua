-- Browser live preview (live-preview.nvim): markdown, HTML (+CSS/JS),
-- AsciiDoc and SVG, served at 127.0.0.1:5500 with live updates and
-- markdown sync-scroll. Pure Lua backend - no NodeJS or Python.
--
-- Replaced iamcco/markdown-preview.nvim (2026-08): upstream effectively
-- unmaintained (last push 2024-07), and live-preview covers everything
-- it did. Markdown renders with live-preview's built-in GitHub-style
-- CSS; the old custom Newsprint stylesheet is archived untouched at
-- mkdp/newsprint.css (its fonts remain installed user-wide) in case it
-- is ever revived via a fork of live-preview or a browser-side
-- user-CSS (Stylus) rule scoped to 127.0.0.1:5500.
--
-- Config goes through require("livepreview.config").set() - the
-- current API. require("live-preview").setup() still works but both
-- the module name and setup() are deprecated shims upstream. Settings
-- kept at their defaults, deliberately: port = 5500, sync_scroll =
-- true, dynamic_root = false (server root = cwd, so relative links
-- resolve from the project root), browser = "default", address =
-- "127.0.0.1". The one non-default is picker = "telescope" - explicit
-- beats auto-detect, and telescope is the only picker installed.
--
-- Keymaps (<leader>m* namespace, shared with render-markdown's mr):
--   <leader>mp   :LivePreview start   preview current file in browser
--   <leader>ms   :LivePreview close   stop the preview server
--   <leader>mt   :LivePreview pick    telescope picker of previewable files
-- Semantics vs the old mkdp maps: mp now works on any supported
-- filetype (not just markdown), ms was "stop" (now close), mt was
-- "toggle" (live-preview has no toggle; pick is the nearest verb).
--
-- cmd + keys lazy-load the plugin on first use; it previously loaded
-- eagerly at startup for no benefit.
return {
	"brianhuster/live-preview.nvim",
	cmd = { "LivePreview" },
	keys = {
		{ "<leader>mp", "<cmd>LivePreview start<CR>", desc = "Preview: start (browser)" },
		{ "<leader>ms", "<cmd>LivePreview close<CR>", desc = "Preview: stop server" },
		{ "<leader>mt", "<cmd>LivePreview pick<CR>", desc = "Preview: pick file (telescope)" },
	},
	config = function()
		require("livepreview.config").set({
			picker = "telescope",
		})
	end,
}
