local M = {}

M.setup = function(cfg)
    vim.api.nvim_create_autocmd({"BufEnter"}, {
        pattern = {"*.fst"},
        callback = function()
            vim.lsp.start({
                cmd = { cfg.fstar_lsp_path },
                root_dir = vim.fn.getcwd(), -- Use PWD as project root dir.
            })
        end,
    })
end

return M
