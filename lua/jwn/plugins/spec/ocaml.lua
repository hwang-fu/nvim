-- OCaml editor layer over ocamllsp's custom requests (ocaml.nvim).
--
-- First-party plugin from Tarides (the ocaml-lsp / Merlin / dune
-- maintainers, released 2025-12). Exposes the Merlin features that
-- standard LSP has no protocol for, as :OCaml* user commands.
--
-- OWNERSHIP MODEL - deliberately the OPPOSITE of rustaceanvim /
-- haskell-tools / elixir-tools: ocaml.nvim does NOT own or start the
-- LSP client. It layers commands on top of whatever ocamllsp client is
-- already attached, which is why ocamllsp REMAINS in the SERVERS table
-- in lua/jwn/lsp/init.lua (see lsp/servers/ocamllsp.lua). Do not
-- "fix" that by removing it - without the native client this plugin
-- has nothing to talk to.
--
-- Command reference (each also has a <localleader> default keymap,
-- active in OCaml buffers; <localleader> = backslash, set in the root
-- init.lua):
--   :OCamlConstruct                \c   fill the typed hole under the
--                                       cursor from a list of valid
--                                       substitutions
--   :OCamlJumpNextHole             \n   jump to the next typed hole
--   :OCamlJumpPrevHole             \p   jump to the previous hole
--   :OCamlJump [expr]              \j   syntax-aware jump (fun / let /
--                                       match / module targets)
--   :OCamlPhraseNext               \pn  next phrase (top-level item)
--   :OCamlPhrasePrev               \pp  previous phrase
--   :OCamlSwitchIntfImpl           \s   switch between .ml and .mli
--   :OCamlInferIntf                \i   infer the interface for the
--                                       matching .ml (run from the
--                                       .mli buffer)
--   :OCamlTypeEnclosing            \t   type-enclosing session; while
--                                       active: <Up>/<Down> grow /
--                                       shrink the enclosing
--                                       expression, <Right>/<Left>
--                                       raise / lower type verbosity
--   :OCamlTypeExpression <expr>         print the type of an arbitrary
--                                       expression
--   :OCamlFindIdentifierDefinition/:OCamlFindIdentifierDeclaration/
--   :OCamlDocumentIdentifier <ident>    definition / declaration /
--                                       docs of a named identifier
--   :OCamlSearchDefinition/:OCamlSearchDeclaration <type>
--                                       type-based search (find
--                                       functions by signature, e.g.
--                                       "int -> string")
--
-- Note the \p / \pp / \pn prefix overlap: \p waits timeoutlen before
-- firing. Upstream's default; left as-is to keep docs muscle-memory
-- valid.
--
-- Loaded eagerly (no ft trigger) on purpose: the plugin registers
-- treesitter parser mappings and filetype detection for .mlx and cram
-- test files at setup time - gating that behind ft=ocaml would recreate
-- the netrw chicken-and-egg problem oil.nvim's spec documents. Cost is
-- one small setup() at startup. Keymaps are left at upstream defaults
-- (the setup() table mirrors them; empty {} would disable them all).
return {
	"tarides/ocaml.nvim",
	lazy = false,
	config = function()
		require("ocaml").setup()
	end,
}
