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
-- Command-driven, no keymaps (the <leader>m* set was removed
-- 2026-08-15 to free the namespace): :LivePreview start / close /
-- pick, working on any supported filetype.
--
-- cmd lazy-loads the plugin on first use; it previously loaded
-- eagerly at startup for no benefit.
return {
	"brianhuster/live-preview.nvim",
	cmd = { "LivePreview" },
	config = function()
		require("livepreview.config").set({
			picker = "telescope",
		})
	end,
}
