# Markdown and preview

*Preview defined in `lua/hwangfu/plugins/spec/live_preview.lua`; in-buffer rendering in `lua/hwangfu/plugins/spec/render_markdown.lua`.*

| Key | Action |
|-----|--------|
| `<leader>mp` | Start the browser preview - Markdown, HTML, AsciiDoc, and SVG, with live reload |
| `<leader>ms` | Stop the preview server |
| `<leader>mt` | Pick a previewable file through telescope |
| `<leader>mr` | Toggle in-buffer Markdown rendering |

The preview serves at `127.0.0.1:5500`. In-buffer rendering is on by default for Markdown files; `:MarkdownRender` offers finer control, with enable / disable / per-buffer subcommands and tab completion.
