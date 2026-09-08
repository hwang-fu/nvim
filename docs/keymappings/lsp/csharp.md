# C# and Blazor

*Server owned by roslyn.nvim (`lua/jwa/plugins/spec/roslyn.lua`); settings in `lua/jwa/lsp/servers/roslyn.lua`.*

All common [LSP keys](lsp.md) apply - `K`, `gd`, `grr`, `<leader>rn`, `<leader>ca` and the rest behave here exactly as they do in every other language. There is no separate key namespace to learn.

The server is Microsoft's own Roslyn language server, the same one VS Code's C# extension runs, rather than a community reimplementation. It covers `.cs` and, since it absorbed the Razor language server, `.razor` and `.cshtml` too - so a Blazor component gets completion, diagnostics and navigation across both the markup and the C# in it. Neovim already knows those extensions, so nothing had to be taught about filetypes.

| Command | Action |
|---------|--------|
| `:CSharpFmt` | Format this buffer through Roslyn and save it. Using directives are sorted at the same time (`dotnet_organize_imports_on_format`). Works in `.razor` buffers too |
| `:Roslyn target` | Choose which solution to work against, when a repository holds several |

## Formatting

C# does not format on save, matching Rust, OCaml, Haskell and Clojure - `:CSharpFmt` is the one action that formats and writes. `:FormatNotOnSave` does not affect it: that switch silences saves, and this is an explicit request.

`dotnet format` remains available from the shell for a whole project at once; it ships with the SDK and needs no setup.

## What the server needs

Two things, neither bundled with this config.

The .NET SDK, which provides `dotnet` - already present system-wide from Fedora's `dotnet-sdk-10.0`.

The server itself, a .NET global tool:

```
dotnet tool install -g roslyn-language-server --prerelease \
  --source https://pkgs.dev.azure.com/azure-public/vside/_packaging/vs-impl/nuget/v3/index.json
```

It lands in `~/.dotnet/tools`, which `~/.bashrc` appends to `PATH`; Neovim inherits that from the shell and finds it there. The Azure feed is upstream's recommendation over nuget.org, whose builds lag behind. **Versions before `5.8.0-1.26262.10` have no Razor or Blazor support at all** - the one place in this setup where the version genuinely matters. `~/.local/bin/freshup` keeps the tool current on the same feed.

## Notes on the settings

- Diagnostics are computed for the **whole solution**, not only open files. C# is compiled and cross-file: renaming a member breaks callers you are not looking at, and the narrower scope would report that only once you opened them. It costs background CPU on a large solution.
- Inlay hints are on, including the two that matter most in C# - `var` and target-typed `new()` both hide the type at exactly the place a reader wants it. Hints for literal parameter names are deliberately off; naming the parameter in front of every bare `2` or `""` reads as noise rather than annotation.
- Symbol search reaches into reference assemblies, so BCL types can be found by name instead of only through code that already mentions them.
- Code lens is left off. Roslyn can show reference and test counts, but its lenses do not refresh on their own - they would need an autocmd of their own to stay honest.
