# Neovim configuration

A personal Neovim setup for polyglot development - Rust and OCaml first, with full support for the Lisp family, Haskell, Elixir, Erlang, Go, Python, and more. It leans on Neovim's native machinery wherever possible: the built-in LSP client instead of wrapper frameworks, built-in `gc` commenting, built-in snippets, and hand-rolled floating windows instead of UI plugins.

Two conventions run through everything. Every file carries extensive comments explaining not just what is configured but why - the comments are the primary documentation. And all config files are ASCII-only; any fancy glyphs on screen come from plugins at runtime, never from these files.

Requires Neovim 0.12+, a terminal with a Nerd Font, and the language toolchains you actually use (see below).

## Keybindings

`<leader>` is Space, `<localleader>` is backslash, and comma belongs to slimv. The full reference lives in [docs/keymappings/](docs/keymappings/README.md), one page per topic, and `<leader>fk` searches every live keymap from inside the editor.

## Layout

| Path | Contents |
|------|----------|
| `init.lua` | Entry point: sets the leader keys, then wires up the modules below |
| `lua/hwangfu/keymappings/` | Global keys, one file per domain (editor, mouse, navigation) |
| `lua/hwangfu/plugins/` | lazy.nvim bootstrap plus one spec file per plugin under `spec/` |
| `lua/hwangfu/lsp/` | Native LSP: one file per server under `servers/`, format-on-save, external linters |
| `lua/hwangfu/completion.lua` | Completion behavior (blink.cmp) |
| `lua/hwangfu/colors.lua` | Automatic per-filetype colorscheme switching |
| `lua/hwangfu/explorer.lua` | The oil.nvim file sidebar |
| `lua/hwangfu/git.lua`, `term.lua`, `repl.lua` | The lazygit float, the shared floating-terminal helper, and the utop REPL float built on it |
| `lua/hwangfu/dap.lua` | Debugger setup and F-key bindings |
| `lua/hwangfu/crates.lua` | Cargo.toml dependency intelligence |
| `colors/` | Local colorschemes (256_noir, green, minimo) |
| `docs/keymappings/` | The keybinding reference, one Markdown page per topic |

## Plugins

Managed by lazy.nvim; each plugin's spec, keymaps, and documentation live together in its own file under `lua/hwangfu/plugins/spec/`.

### Editing

| Plugin | Purpose |
|--------|---------|
| nvim-treesitter | Syntax-aware highlighting and parsing |
| nvim-treesitter-textobjects | Function / class / parameter text objects and motions |
| vim-surround | Add, change, and delete surrounding pairs |
| blink.cmp | Completion engine with a compiled fuzzy matcher |
| which-key.nvim | Popup showing available keys as you type a prefix |

### Files and search

| Plugin | Purpose |
|--------|---------|
| oil.nvim | File listings you edit like text, presented as a 35-column sidebar |
| telescope.nvim | Fuzzy finding: files, grep, buffers, diagnostics, keymaps |

### Git

| Plugin | Purpose |
|--------|---------|
| gitsigns.nvim | Change signs in the gutter and hunk-level staging |
| diffview.nvim | Side-by-side changeset diffs and file history |

The repository-level UI is lazygit in a floating terminal - a system binary, not a plugin.

### Languages

| Plugin | Purpose |
|--------|---------|
| rustaceanvim | Rust: owns rust-analyzer and exposes its extras as `:RustLsp` commands |
| ocaml.nvim | OCaml: Merlin features beyond standard LSP (typed holes, interface switching, type search) |
| haskell-tools.nvim | Haskell: owns HLS, adds Hoogle-aware hover and a GHCi REPL |
| elixir-tools.nvim | Elixir: owns ElixirLS, adds `:Mix` and pipe-rewriting commands |
| crates.nvim | Cargo.toml: version hints, update / upgrade actions, crates.io data |
| arm-syntax-vim | ARM assembly highlighting |
| fhir.nvim | FHIR resource tooling |

### Lisp

| Plugin | Purpose |
|--------|---------|
| parinfer-rust | Parentheses follow indentation automatically while editing |
| rainbow-delimiters.nvim | Parentheses colored by nesting depth |
| conjure | Evaluate code from the buffer with inline results (Clojure, Fennel, Racket, Scheme) |
| slimv | Full SLIME environment for Common Lisp: debugger, inspector, sbcl+swank |

### Debugging

| Plugin | Purpose |
|--------|---------|
| nvim-dap (+ dap-ui, virtual text) | Debug Adapter Protocol client with a panel and inline values |
| mason.nvim (+ mason-nvim-dap) | Installs the codelldb adapter binary - its only job here |

### Appearance

| Plugin | Purpose |
|--------|---------|
| lualine.nvim | Statusline, fed by gitsigns for its diff counts |
| render-markdown.nvim | Styled Markdown inside the editing buffer |
| live-preview.nvim | Browser preview with live reload for Markdown, HTML, and AsciiDoc |
| dracula, gruvbox, tokyonight, vague | Colorschemes; dracula is the active one |

## Language servers

Most servers run through Neovim's native `vim.lsp.config()`, one small file each under `lua/hwangfu/lsp/servers/`: clangd, gopls, pyright, lua_ls, ts_ls, vue_ls, ocamllsp, elp (Erlang), clojure_lsp, racket_langserver, fennel_ls, taplo, bashls, html, cssls, jsonls, yamlls, dockerls, buf_ls, perlnavigator, fortls, autotools_ls, and verible.

Three are owned by their language plugin instead, because the plugin manages the client end-to-end: rust-analyzer (rustaceanvim), HLS (haskell-tools), and ElixirLS (elixir-tools).

Servers and formatters come from each language's own toolchain - rustup, opam, ghcup, go install, luarocks - rather than from mason, so they always match the compiler in use. Formatting runs on save per language; missing formatter binaries are reported once at startup.

## Setup on a new machine

Clone this repository to `~/.config/nvim` and start `nvim`. lazy.nvim bootstraps itself and installs every plugin (parinfer-rust compiles with cargo; telescope's fzf sorter compiles with make). Install the language toolchains you need, and the startup warning will name any missing formatter binaries.
