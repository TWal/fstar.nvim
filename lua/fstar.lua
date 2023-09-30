local M = {}

local setup_lsp = function (fstar_lsp_path)
    vim.lsp.start({
        cmd = { fstar_lsp_path },
        root_dir = vim.fn.getcwd(), -- Use PWD as project root dir.
    })
end

local fstar_verify_all = function()
    for _, client in ipairs(vim.lsp.get_active_clients({bufnr = 0})) do
        client.notify("fstar-lsp/verifyAll", {
            ["textDocument"] = vim.lsp.util.make_text_document_params()
        })
    end
end

local setup_fstar_command = function ()
    vim.api.nvim_buf_create_user_command(0, 'FStar',
        function(input)
            if input.fargs[1] == "verify_all" then
                fstar_verify_all()
            end
        end,
        {
            desc = "Communicate with F* LSP",
            nargs = 1,
            complete = function(ArgLead, CmdLine, CursorPos)
                return { "verify_all" }
            end,
        }
    )
end

M.setup = function(cfg)
    vim.api.nvim_create_autocmd({"BufEnter"}, {
        pattern = {"*.fst", "*.fsti"},
        callback = function()
            setup_lsp(cfg.fstar_lsp_path)
            setup_fstar_command()
        end,
    })
end

return M
