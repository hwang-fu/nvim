# Keymap discovery

*Defined in `lua/hwangfu/plugins/spec/which_key.lua` (which-key.nvim).*

Press any mapped prefix - Space, backslash, `]`, `[`, `g`, `z` - and pause. A popup lists every continuation with its description, so the config's key namespaces explain themselves as you type. Leader groups carry labels such as "+git hunks" and "+find / telescope".

Buffer-local keys appear only in buffers where they actually exist: the popup reads the live mappings, not a static list.

There are no keys to learn for this plugin itself. It complements `<leader>fk`, which searches all keymaps through telescope, and this documentation folder.
