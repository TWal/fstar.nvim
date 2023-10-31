local status = require("status")
local M = {}

local status_displayers = {}

local uri_to_bufnr = function(uri)
    return vim.fn.bufadd(vim.uri_to_fname(uri))
end

local get_position = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    return {
        line = pos[1]-1,
        character = pos[2],
    }
end

local setup_lsp = function (cfg, namespace_id)
    local my_bufnr = vim.api.nvim_get_current_buf()
    status_displayers[my_bufnr] = status.StatusDisplayer:new(namespace_id, my_bufnr, cfg.refresh_delay)
    vim.lsp.start({
        cmd = { cfg.fstar_lsp_path },
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

local for_all_clients = function(callback)
    for _, client in ipairs(vim.lsp.get_active_clients({bufnr = 0})) do
        callback(client)
    end
end

M.commands = {}

M.commands.verify_all = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/verifyAll", {
            textDocument = vim.lsp.util.make_text_document_params()
        })
    end)
end

M.commands.lax_to_position = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/laxToPosition", {
            textDocument = vim.lsp.util.make_text_document_params(),
            position = get_position(),
        })
    end)
end

M.commands.verify_to_position = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/verifyToPosition", {
            textDocument = vim.lsp.util.make_text_document_params(),
            position = get_position(),
        })
    end)
end

M.commands.cancel_all = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/cancelAll", {
            textDocument = vim.lsp.util.make_text_document_params()
        })
    end)
end

M.commands.reload_dependencies = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/reloadDependencies", {
            textDocument = vim.lsp.util.make_text_document_params()
        })
    end)
end

M.commands.restart_z3 = function()
    for_all_clients(function (client)
        client.notify("fstar-lsp/restartZ3", {
            textDocument = vim.lsp.util.make_text_document_params()
        })
    end)
end

local setup_fstar_command = function ()
    local command_keys = {}
    for key,_ in pairs(M.commands) do
        table.insert(command_keys, key)
    end
    vim.api.nvim_buf_create_user_command(0, 'FStar',
        function(input)
            local fun = M.commands[input.fargs[1]]
            if fun ~= nil then
                fun()
            end
        end,
        {
            desc = "Communicate with F* LSP",
            nargs = 1,
            complete = function(ArgLead, CmdLine, CursorPos)
                return command_keys
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
    vim.api.nvim_set_hl(namespace_id, "LaxChecked", {
        bg = cfg.colors.lax_checked,
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
            setup_lsp(cfg, namespace_id)
            setup_fstar_command()
        end,
    })
end

return M
