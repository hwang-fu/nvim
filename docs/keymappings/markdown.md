# Markdown and preview

| Key | Action |
|-----|--------|
| \<leader\>mp | `:LivePreview start` - browser preview (md/HTML/adoc/SVG) |
| \<leader\>ms | `:LivePreview close` - stop the preview server |
| \<leader\>mt | `:LivePreview pick` - telescope picker of previewable files |
| \<leader\>mr | `:MarkdownRender toggle` - in-buffer render (render-markdown) |

`:MarkdownRender` subcommands: enable / disable / toggle, buf_enable /
buf_disable / buf_toggle, set [true|false], set_buf, preview, expand,
contract, log, debug, config. (Renamed from upstream's :RenderMarkdown.)
`:LivePreview help` lists its subcommands. Server: 127.0.0.1:5500.
