-- ============================================================================
-- SchemaStore.nvim: the schemastore.org catalog, vendored as Lua data.
--
-- Data-only plugin, no setup() and no keymaps: it exposes
-- require("schemastore").json.schemas(), a list of { fileMatch, url }
-- entries mapping well-known filenames (package.json, tsconfig.json,
-- .eslintrc, GitHub config files, ...) to their JSON schemas. The sole
-- consumer is lua/jwa/lsp/servers/jsonls.lua, which passes that list to
-- vscode-json-language-server.
--
-- Why a plugin at all: unlike yamlls (which fetches the same catalog
-- from schemastore.org itself - see lsp/servers/yamlls.lua), jsonls has
-- no catalog support. It only validates against schemas the client
-- hands it explicitly, so something on our side must own the
-- filename -> schema-url table. This plugin is that table, kept current
-- upstream by automated daily updates.
--
-- lazy = true: nothing loads at startup; lazy.nvim's module loader
-- pulls the plugin in when jsonls.lua require()s it during LSP setup.
-- ============================================================================

return {
	"b0o/SchemaStore.nvim",
	lazy = true,
}
