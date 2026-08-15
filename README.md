# Neovim configuration

A personal Neovim setup for working across many languages, with Rust and OCaml at the center and the Lisp family, Haskell, Elixir, Erlang, Go, and Python close behind.

The guiding idea is to stay close to what Neovim already provides: the built-in LSP client instead of wrapper frameworks, built-in commenting and snippets, and small hand-rolled floating windows instead of UI plugins. Plugins are added where they genuinely earn their place, and each one lives in its own file together with its keymaps and an explanation of why it is configured the way it is.

Two conventions hold everywhere:

- **Comments are the documentation.** Every file explains not just what is set, but why. When something looks odd, the answer is usually right above it.
- **Config files are pure ASCII.** Any fancy glyphs you see on screen come from plugins at runtime, never from these files.

You need Neovim 0.12 or newer, a terminal with a Nerd Font, and the toolchains of the languages you actually write.

## Keybindings

`<leader>` is **Space**, `<localleader>` is **backslash**, and **comma** belongs to slimv (Common Lisp). A taste of the daily drivers:

| Key | What it does |
|-----|--------------|
| `<leader>t` | Find a file |
| `<leader>fg` | Search text across the project |
| `Ctrl-T` | Toggle the file sidebar |
| `Ctrl-LeftClick` | Jump to a symbol's definition |
| `K` | Documentation for the symbol under the cursor |
| `F5` | Start the debugger |

The full reference lives in [docs/keymappings/](docs/keymappings/README.md), one page per topic. From inside the editor, `<leader>fk` searches every live keymap, and which-key pops up the possibilities whenever you pause mid-shortcut.

## Layout

| Path | What lives there |
|------|------------------|
| `init.lua` | Entry point: sets the leader keys, then wires up the modules below |
| `lua/hwangfu/keymappings/` | Global keys, one file per domain: editor, movement, mouse, navigation |
| `lua/hwangfu/plugins/` | lazy.nvim bootstrap, plus one spec file per plugin under `spec/` |
| `lua/hwangfu/lsp/` | Language servers (one file each under `servers/`), format-on-save, external linters |
| `lua/hwangfu/completion.lua` | Completion behavior |
| `lua/hwangfu/colors.lua` | Automatic per-filetype colorschemes |
| `lua/hwangfu/explorer.lua` | The file sidebar built on oil.nvim |
| `lua/hwangfu/git.lua` | The lazygit floating window |
| `lua/hwangfu/term.lua` | The shared floating-terminal helper |
| `lua/hwangfu/repl.lua` | The utop REPL float, built on that helper |
| `lua/hwangfu/dap.lua` | Debugger setup and the F-key bindings |
| `lua/hwangfu/crates.lua` | Cargo.toml dependency intelligence |
| `colors/` | Local colorschemes |
| `docs/keymappings/` | The keybinding reference, one Markdown page per topic |

## Plugins

Managed by lazy.nvim. Each plugin's spec, keymaps, and documentation live together in one file under `lua/hwangfu/plugins/spec/`.

### Editing

| Plugin | Purpose |
|--------|---------|
| nvim-treesitter | Syntax-aware highlighting and parsing |
| nvim-treesitter-textobjects | Select or jump between functions, classes, and parameters |
| vim-surround | Add, change, and delete surrounding pairs |
| blink.cmp | Completion, with a compiled fuzzy matcher |
| which-key.nvim | Shows available keys when you pause mid-shortcut |
| flash.nvim | Labeled jumps: type two characters, press the label that appears on your target |
| glance.nvim | VSCode-style peek panel for references, definitions, and implementations |

### Files and search

| Plugin | Purpose |
|--------|---------|
| oil.nvim | File listings you edit like text, shown as a sidebar |
| telescope.nvim | Fuzzy finding: files, project-wide grep, buffers, diagnostics, keymaps |

### Git

| Plugin | Purpose |
|--------|---------|
| gitsigns.nvim | Change marks in the gutter, hunk-level staging and blame |
| diffview.nvim | Side-by-side changeset diffs and history browsing |

Repository-level work (commit, branch, push) happens in lazygit, floating in a terminal window - a system binary rather than a plugin.

### Languages

| Plugin | Purpose |
|--------|---------|
| rustaceanvim | Rust: runs rust-analyzer and adds `:RustLsp` commands for its extras |
| ocaml.nvim | OCaml: typed holes, interface switching, and type search beyond standard LSP |
| haskell-tools.nvim | Haskell: runs HLS, adds Hoogle-aware hover and a GHCi REPL |
| elixir-tools.nvim | Elixir: runs ElixirLS, adds `:Mix` and pipe-rewriting commands |
| crates.nvim | Cargo.toml: version hints and update / upgrade actions from crates.io |
| arm-syntax-vim | ARM assembly highlighting |
| fhir.nvim | FHIR resource tooling |

### Lisp

| Plugin | Purpose |
|--------|---------|
| parinfer-rust | Keeps parentheses balanced from your indentation as you type |
| rainbow-delimiters.nvim | Colors parentheses by nesting depth |
| conjure | Evaluates code from the buffer with inline results (Clojure, Fennel, Racket, Scheme) |
| slimv | The full SLIME experience for Common Lisp: debugger, inspector, sbcl + swank |

### Debugging

| Plugin | Purpose |
|--------|---------|
| nvim-dap, with dap-ui and virtual text | Debugger client with a panel and inline variable values |
| mason.nvim | Installs the codelldb adapter binary - its only job here |

### Appearance

| Plugin | Purpose |
|--------|---------|
| lualine.nvim | Statusline, sharing git counts with gitsigns |
| render-markdown.nvim | Styled Markdown inside the editing buffer |
| live-preview.nvim | Browser preview with live reload for Markdown, HTML, and AsciiDoc |
| dracula, gruvbox, tokyonight, vague | Colorschemes; dracula is the one in use |

## Language servers

Most servers run through Neovim's native LSP client, each configured in a small file under `lua/hwangfu/lsp/servers/`:

| Domain | Servers |
|--------|---------|
| Systems and general | clangd (C/C++), gopls (Go), pyright (Python), lua_ls (Lua), perlnavigator (Perl), fortls (Fortran) |
| Web | ts_ls (TypeScript), vue_ls (Vue), html, cssls, jsonls, yamlls |
| Functional | ocamllsp (OCaml), elp (Erlang), clojure_lsp (Clojure), racket_langserver (Racket), fennel_ls (Fennel) |
| Config and hardware | taplo (TOML), bashls (shell), dockerls (Docker), buf_ls (protobuf), autotools_ls, verible (Verilog) |

Three more are run by their language plugin instead, because the plugin manages the client end-to-end: rust-analyzer, HLS, and ElixirLS.

Servers and formatters come from each language's own toolchain - rustup, opam, ghcup, `go install`, luarocks - rather than from a plugin manager, so they always match the compiler in use. Formatting happens automatically on save, and a missing formatter is reported once at startup rather than failing silently.

## Setup on a new machine

1. Clone this repository to `~/.config/nvim`.
2. Start `nvim`. lazy.nvim bootstraps itself and installs every plugin; parinfer-rust compiles with cargo and telescope's sorter with make, so expect the first launch to take a minute.
3. Install the language toolchains you need. The startup warning will name any formatter binaries still missing.
