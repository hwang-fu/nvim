-- ============================================================================
-- fhir.nvim: FHIR resource tooling (own plugin). Keymaps below are
-- buffer-local to FHIR buffers and documented in docs/keymappings/fhir.md.
-- ============================================================================

return {
	"hwang-fu/fhir.nvim",
	opts = {
		keymaps = {
			goto_reference = "gd",
			find_usages = "gr",
			outline = "<leader>fo",
			eval = "<leader>fe",
			diagnostics = "gl",
			fix = "ga",
		},
	},
}
