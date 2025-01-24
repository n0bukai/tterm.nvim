---@class Term
---@field create function(State)
---@field show function(State)
---@field toggle function(State)
---@field send_command function(State)

---@type Term
local M = {}

--- creates a new window and a term buffer within, places it in the
--- appropriate place and sets the state fields for win buf and channel
---@param state State
M.create = function(state)
  if state.opts.location == "float" then
    --- do the float thing here
    state.buf = vim.api.nvim_create_buf(false, true)
    state.win = vim.api.nvim_open_win(state.buf, true, {
      relative = 'editor',
      col = state.opts.x_offset,
      row = state.opts.y_offset,
      width = state.opts.width,
      height = state.opts.height,
    })
    vim.cmd.term()
  else
    -- create new window and make it a terminal
    vim.cmd.vnew()
    vim.cmd.term()

    local case = {
      default = function()
        vim.cmd.wincmd("H")
        vim.api.nvim_win_set_width(0, state.opts.width)
      end,
      ["right"] = function()
        vim.cmd.wincmd("L")
        vim.api.nvim_win_set_width(0, state.opts.width)
      end,
      ["above"] = function()
        vim.cmd.wincmd("K")
        vim.api.nvim_win_set_height(0, state.opts.height)
      end,
      ["below"] = function()
        vim.cmd.wincmd("J")
        vim.api.nvim_win_set_height(0, state.opts.height)
      end,
    }
    (case[state.opts.location] or case.default)()
  end

  state.win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_get_current_buf()
  state.channel = vim.bo.channel
end

--- never sends a command
--- simply shows the window
---@param state State
M.show = function(state)
  local current_win = vim.api.nvim_get_current_win()
  local win_valid = false
  if state.win then
    win_valid = vim.api.nvim_win_is_valid(state.win)
  end
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    win_valid = false
  end
  if win_valid then
    return
  else -- if win_valid
    local buf_valid = false
    if state.buf then
      buf_valid = vim.api.nvim_buf_is_valid(state.buf)
    end
    if buf_valid then
      -- open new win only
      if state.opts.location == "float" then
        state.win = vim.api.nvim_open_win(state.buf, false, {
          relative = 'editor',
          col = state.opts.x_offset,
          row = state.opts.y_offset,
          width = state.opts.width,
          height = state.opts.height,
        })
      else
        vim.api.nvim_open_win(state.buf, true, {
          split = state.opts.location,
          win = 0,
        })

        local case = {
          default = function()
            vim.cmd.wincmd("H")
            vim.api.nvim_win_set_width(0, state.opts.width)
          end,
          ["right"] = function()
            vim.cmd.wincmd("L")
            vim.api.nvim_win_set_width(0, state.opts.width)
          end,
          ["above"] = function()
            vim.cmd.wincmd("K")
            vim.api.nvim_win_set_height(0, state.opts.height)
          end,
          ["below"] = function()
            vim.cmd.wincmd("J")
            vim.api.nvim_win_set_height(0, state.opts.height)
          end,
        }
        (case[state.opts.location] or case.default)()

        state.win = vim.api.nvim_get_current_win()
      end
    else -- if buf_valid
      -- first time opening
      M.create(state)
    end -- if buf_valid
    vim.api.nvim_set_current_win(current_win)
  end   -- if win_valid

  if state.opts.command_on_show then
    M.send_command(state)
  end
end

M.send_command = function(state)
  local ft = state.last_filetype
  if not ft then
    print "So far no filetype has had a valid command"
    return
  end

  if state.opts.show_on_command then
    M.show(state)
  end

  local command = state.session_commands[ft] or state.commands[ft]
  if not command then
    -- can only reach here through defining a session command, then entering a buffer for which there is
    -- only a session_command, then deleting that command and trying to call it
    print("There is no longer a command for the " .. ft .. " filetype.")
    return
  end
  if not state.channel then
    M.create(state)
  end
  if state.opts.clear_before_command then
    vim.api.nvim_chan_send(state.channel, "clear\n")
  end
  vim.api.nvim_chan_send(state.channel, command .. "\n")
end

M.toggle = function(state)
  local win_open = false
  if state.win then
    win_open = vim.api.nvim_win_is_valid(state.win)
  end
  if win_open then
    -- close
    vim.api.nvim_win_hide(state.win)
  else
    M.show(state)
  end
end

return M
