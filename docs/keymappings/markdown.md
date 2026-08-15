# Markdown and preview

*Preview defined in `lua/hwangfu/plugins/spec/live_preview.lua`; in-buffer rendering in `lua/hwangfu/plugins/spec/render_markdown.lua`.*

Both tools are command-driven:

| Command | Action |
|---------|--------|
| `:LivePreview start` | Open the browser preview for the current file - Markdown, HTML, AsciiDoc, and SVG, with live reload |
| `:LivePreview close` | Stop the preview server |
| `:LivePreview pick` | Choose a previewable file through telescope |
| `:MarkdownRender toggle` | Toggle in-buffer Markdown rendering globally (it starts ON) |
| `:MarkdownRender buf_toggle` | Toggle it for the current buffer only |

The preview serves at `127.0.0.1:5500`. `:MarkdownRender` tab-completes its full subcommand set: enable / disable, the per-buffer variants, and debug helpers.
