-- Telescope: fuzzy finder / popup picker (files, live-grep, buffers, ...).
-- Configured in lua/jwn/telescope.lua. plenary.nvim is a required
-- library; telescope-fzf-native is a compiled sorter (built via `make`).
return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
		},
	},
}
