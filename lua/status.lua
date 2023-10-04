-- F*-LSP sends us two type of verification status update:
-- - clear all status
-- - set some range to some status (fully checked, lax checked, or failed)
-- This module handle status while working around two shortcomings of status given by F*-LSP.
-- First, the status ranges are not connected, hence leaving "holes" which are ugly.
-- Second, when modifying a verified portion of the code,
-- F* needs to tell us what portions of the code aren't verified anymore.
-- It is done by sending a "clear" operation,
-- quickly followed by many "set status" operations for portions that stay verified,
-- slowly followed by other "set status" operations for new code being verified.
-- The "clear" operation followed by many "set status" operations cause some flicker,
-- Because there is no way to distinguish "still-checked" status updates and
-- "under verification" status updates other than the speed at which they occur,
-- when clearing status, we buffer them for a short period of time (10ms) to remove any flickering.
--
-- The whole module rely on the following invariant from F*-LSP:
-- - after each clear, the status updates come in increasing order
-- - a "failed" status update is the last one (before the next clear)

local StatusDisplayer = {}

local hl_group_tbl = {
    InProgress = "InProgress",
    LaxOk = "InProgress", --TODO other color
    Ok = "FullyChecked",
}

function StatusDisplayer:new(namespace_id, bufnr)
    local res = {
        namespace_id = namespace_id,
        bufnr = bufnr,
        is_waiting = false,
        status_list = {}
    }
    setmetatable(res, self)
    self.__index = self
    return res
end

function StatusDisplayer:clear()
    self.is_waiting = true
    self.status_list = {}
    -- wait 10ms before clearing and drawing next status updates,
    -- to prevent flickering
    local timer = vim.loop.new_timer()
    timer:start(10, 0, function()
        timer:stop()
        timer:close()
        vim.schedule(function ()
            -- clear all marks
            for i = 0, vim.api.nvim_buf_line_count(self.bufnr) do
                local extmark_id = i+1
                vim.api.nvim_buf_del_extmark(self.bufnr, self.namespace_id, extmark_id)
            end
            -- draw the buffered status updates
            for i = 1, #self.status_list do
                self:draw_status(i)
            end
            -- don't delay future status updates
            self.is_waiting = false
        end)
    end)
end

function StatusDisplayer:set_range_to_status(start_line, end_line, status_type)
    for i = start_line, end_line do
        -- The extmark id cannot be 0, add one to avoid that case
        local extmark_id = i+1
        if status_type == "Failed" then
            vim.api.nvim_buf_del_extmark(self.bufnr, self.namespace_id, extmark_id)
        else
            vim.api.nvim_buf_set_extmark(self.bufnr, self.namespace_id, i, 0, {
                id = extmark_id,
                line_hl_group = hl_group_tbl[status_type]
            })
        end
    end
end

function StatusDisplayer:draw_status(status_ind)
    local start_line = self.status_list[status_ind].start_line
    local end_line = self.status_list[status_ind].end_line
    local status_type = self.status_list[status_ind].status_type

    -- draw between the last and current status update
    if 1 < status_ind then
        local previous_status_type = self.status_list[status_ind-1].status_type
        local after_previous_section = start_line
        after_previous_section = self.status_list[status_ind-1].end_line+1

        local between_sections_status_type = previous_status_type

        -- do not draw between sections if there is nothing between
        -- (this condition can also be false when F* sends InProgress followed by Ok for the same range)
        if after_previous_section < start_line then
            self:set_range_to_status(after_previous_section, start_line-1, between_sections_status_type)
        end
    end

    -- draw for the current status update
    self:set_range_to_status(start_line, end_line, status_type)
end

function StatusDisplayer:set_status(start_line, end_line, status_type)
    table.insert(self.status_list, {
        start_line = start_line,
        end_line = end_line,
        status_type = status_type,
    })
    -- don't draw the status yet if we are shortly after a clear
    if not self.is_waiting then
        self:draw_status(#self.status_list)
    end
end

return {
    StatusDisplayer = StatusDisplayer,
}
