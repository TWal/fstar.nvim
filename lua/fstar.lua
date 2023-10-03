local status = require("status")
local M = {}

local status_displayers = {}

local uri_to_bufnr = function(uri)
    return vim.fn.bufadd(vim.uri_to_fname(uri))
end

local setup_lsp = function (fstar_lsp_path, namespace_id)
    local my_bufnr = vim.api.nvim_get_current_buf()
    status_displayers[my_bufnr] = status.StatusDisplayer:new(namespace_id, my_bufnr)
    vim.lsp.start({
        cmd = { fstar_lsp_path },
        root_dir = vim.fn.getcwd(), -- Use PWD as project root dir.
        handlers = {
            ["fstar-lsp/clearStatus"] = vim.lsp.with(
                function(err, result, ctx, config)
                    local bufnr = uri_to_bufnr(result.uri)
                    status_displayers[bufnr]:clear()
                    return { success = true }
                end,
            {}),

            ["fstar-lsp/setStatus"] = vim.lsp.with(
                function(err, result, ctx, config)
                    local bufnr = uri_to_bufnr(result.uri)
                    status_displayers[bufnr]:set_status(result.range.start.line, result.range["end"].line, result.statusType)
                    return { success = true }
                end,
            {}),
        }
    })
end

local fstar_verify_all = function()
    for _, client in ipairs(vim.lsp.get_active_clients({bufnr = 0})) do
        client.notify("fstar-lsp/verifyAll", {
            textDocument = vim.lsp.util.make_text_document_params()
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
    local namespace_id = vim.api.nvim_create_namespace("fstar.nvim")
    vim.api.nvim_set_hl_ns(namespace_id)

    vim.api.nvim_set_hl(namespace_id, "FullyChecked", {
        bg = cfg.colors.fully_checked,
    })
    vim.api.nvim_set_hl(namespace_id, "InProgress", {
        bg = cfg.colors.in_progress,
    })
    -- Is this highlight useful?
    vim.api.nvim_set_hl(namespace_id, "Scheduled", {
        bg = cfg.colors.scheduled,
    })

    vim.filetype.add({
        extension = {
            fst = "fstar",
            fsti = "fstar",
        }
    })

    vim.api.nvim_create_autocmd({"FileType"}, {
        pattern = {"fstar"},
        callback = function()
            setup_lsp(cfg.fstar_lsp_path, namespace_id)
            setup_fstar_command()
        end,
    })
end

return M
