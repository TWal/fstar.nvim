# fstar.nvim

## Installation

Example configuration (lazy.nvim):

```lua
{
    "TWal/fstar.nvim",
    config = function()
        local fstar = require('fstar')

        fstar.setup({
            fstar_lsp_path = "/path/to/fstar-lsp",
        })

        vim.keymap.set("n", "<C-c><C-v>", fstar.commands.verify_all, { remap = false, desc = "verify buffer" })
        vim.keymap.set("n", "<C-c><C-l>", fstar.commands.lax_to_position, { remap = false, desc = "verify lax to position" })
        vim.keymap.set("n", "<C-c><CR>",  fstar.commands.verify_to_position, { remap = false, desc = "verify to position" })
        vim.keymap.set("n", "<C-c><C-c>", fstar.commands.cancel_all, { remap = false, desc = "cancel" })
        vim.keymap.set("n", "<C-c><C-r>", fstar.commands.reload_dependencies, { remap = false, desc = "reload dependencies"})
        vim.keymap.set("n", "<C-c><C-k>", fstar.commands.restart_z3, { remap = false, desc = "restart Z3" })
    end,
}
```

Default configuration for fstar.nvim (argument of `fstar.setup`) is:

```lua
{
    fstar_lsp_path = "fstar-lsp", -- path to F* LSP
    colors = { -- status colors, same as fstar-mode.el
        fully_checked = "#483D8B",
        lax_checked = "#483D00";
        in_progress = "#BA55D3",
        scheduled = "#5C3566",
    },
    refresh_delay = 50, -- wait time (in ms) before updating status (to prevent flickering)
}
```
