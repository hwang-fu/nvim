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
--   :OCamlPhraseNext               \N   next phrase (top-level item)
--   :OCamlPhrasePrev               \P   previous phrase
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
-- Phrase keys are the ONE deviation from upstream defaults (2026-08-21,
-- user request). Upstream's \pp / \pn made \p (previous hole) their
-- PREFIX, so every \p stalled a full timeoutlen before firing - real
-- daily friction. The phrase motions now live on \P / \N, the capital
-- siblings of the \p / \n hole motions (shift = the bigger jump), and
-- \p fires instantly.
--
-- GOTCHA that shaped the setup() call below: ocaml.nvim's config merge
-- is TOP-LEVEL ONLY - a partial { keymaps = { phrase_next = ... } }
-- would REPLACE the whole keymaps table and silently disable the other
-- eleven bindings. The full table is therefore spelled out, defaults
-- and all, with only the two phrase entries changed.
--
-- Loaded eagerly (no ft trigger) on purpose: the plugin registers
-- treesitter parser mappings and filetype detection for .mlx and cram
-- test files at setup time - gating that behind ft=ocaml would recreate
-- the netrw chicken-and-egg problem oil.nvim's spec documents. Cost is
-- one small setup() at startup.
return {
	"tarides/ocaml.nvim",
	lazy = false,
	config = function()
		require("ocaml").setup({
			keymaps = {
				jump_next_hole = "<localleader>n",
				jump_prev_hole = "<localleader>p",
				construct = "<localleader>c",
				jump = "<localleader>j",
				phrase_prev = "<localleader>P",
				phrase_next = "<localleader>N",
				infer = "<localleader>i",
				switch_ml_mli = "<localleader>s",
				type_enclosing = "<localleader>t",
				type_enclosing_grow = "<Up>",
				type_enclosing_shrink = "<Down>",
				type_enclosing_increase = "<Right>",
				type_enclosing_decrease = "<Left>",
			},
		})
	end,
}
