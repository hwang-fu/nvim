# Everything else

- vim-surround (plugin defaults): `ys{motion}{char}` add, `cs{old}{new}`
  change, `ds{char}` delete, visual `S{char}` wrap.
- `:ToggleWS` - toggle whitespace visualization for this window
  (lua/hwangfu/init.lua).
- `:Lazy` - plugin manager UI; `:Lazy sync` install/update.
- `:Mason`, `:MasonInstall`, `:MasonUpdate` - external tool binaries
  (currently just the codelldb debug adapter).
- `:TSInstall <lang>` / `:TSUpdate` - treesitter parsers.
- Colorschemes switch automatically per filetype (lua/hwangfu/colors.lua);
  no keybinding. Two groups since 2026-08: web/markup (html/htmlangular/
  css/scss) gets 256_noir; everything else - code, structured config, and
  markdown alike - gets dracula with a dark-green background. (Markdown
  previously had its own look via the local green.vim theme.)
