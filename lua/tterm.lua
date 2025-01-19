---@class TTerm
---@field setup function: sets up the state for the plugin
---@field show_term function: show the terminal window
---@field toggle_term function: toggle the terminal window
---@field execute_command function: send the command and depending on settings show it
---@field add_command function: add a session override command
---@field remove_command function: remove a session override command

---@type TTerm
local M = {}

local term = require "plugin.term"

--- @alias location
--- | '"left"'
--- | '"right"'
--- | '"above"'
--- | '"below"'

--- @class State
--- @field buf number|nil: the term buffer
--- @field win number|nil: the term window
--- @field channel number|nil: the channel for the commands sent to the term
--- @field last_filetype string|nil: the most recent filetype for which a command was found
--- @field opts table|nil: the current options
--- @field session_commands table<string,string>: the commands defined in the current session
--- @field commands table<string,string>: a table of filetype, command pairs

--- @class Options
--- @field location location|nil: above, below, left, right, defines where the term window goes
--- @field skip_keymaps boolean: whether to skip standard keymaps on setup
--- @field command_on_show boolean: whether to automatically send the command when showing the terminal
--- @field show_on_command boolean: whether to automatically show the terminal when sending a command
--- @field clear_before_command boolean: clear prior output on sending a command
--- @field height number: if above or below window, how high it should be
--- @field width number: if left or right window, how wide it should be

--- These are the options which are passed to setup and override the default values
--- and may be nil to use default options instead
--- @class SetupOptions
--- @field location location|nil: above, below, left, right, defines where the term window goes
--- @field skip_keymaps boolean|nil: whether to skip standard keymaps on setup
--- @field command_on_show boolean|nil: whether to automatically send the command when showing the terminal
--- @field show_on_command boolean|nil: whether to automatically show the terminal when sending a command
--- @field clear_before_command boolean|nil: clear prior output on sending a command
--- @field height number|nil: if above or below window, how high it should be
--- @field width number|nil: if left or right window, how wide it should be
--- @field commands table<string,string>|nil: a table of filetype, command pairs

--- the current state of the environment mostly regarding the term window/buffer
--- @type State
local state = {
  buf = nil,
  win = nil,
  channel = nil,
  last_filetype = nil,
  opts = nil,
  session_commands = {},
  commands = {},
}

--- the default options provided by the plugin
--- @type Options
local default_opts = {
  location = "left",
  skip_keymaps = false,
  command_on_show = false,
  show_on_command = true,
  clear_before_command = true,
  height = 15,
  width = 40,
}

--- the default commands provided by the plugin
--- @type table<string, string>
local default_commands = {
  ["zig"] = "zig build",
  ["rust"] = "cargo build",
  ["c"] = "make",
  ["cpp"] = "make",
}

--- adds a session override for the provided filetype
--- @param filetype string: the filetype for which the command will be run
--- @param command string: the command which will be sent to the terminal, no linebreaks required
M.add_command = function(filetype, command)
  state.session_commands[filetype] = command
end

--- removes the session override for the provided filetype
--- @param filetype string: the filetype to remove the session override for
M.remove_command = function(filetype)
  state.session_commands[filetype] = nil
end

M.show_term = function()
  term.show(state)
end

M.toggle_term = function()
  term.toggle(state)
end

M.execute_command = function()
  term.send_command(state)
end

--- @param opts SetupOptions|nil
M.setup = function(opts)
  -- set options
  opts = opts or {}
  state.opts = {}
  state.opts.location = opts.location or default_opts.location
  state.opts.height = opts.height or default_opts.height
  state.opts.width = opts.width or default_opts.width
  -- boolean|nil requires nil check
  if opts.skip_keymaps ~= nil then
    state.opts.skip_keymaps = opts.skip_keymaps
  else
    state.opts.skip_keymaps = default_opts.skip_keymaps
  end
  if opts.show_on_command ~= nil then
    state.opts.show_on_command = opts.show_on_command
  else
    state.opts.show_on_command = default_opts.show_on_command
  end
  if opts.command_on_show ~= nil then
    state.opts.command_on_show = opts.command_on_show
  else
    state.opts.command_on_show = default_opts.command_on_show
  end
  if opts.clear_before_command ~= nil then
    state.opts.clear_before_command = opts.clear_before_command
  else
    state.opts.clear_before_command = default_opts.clear_before_command
  end
  -- provided commands are extended by default_commands where not defined
  state.commands = opts.commands or {}
  for k, v in pairs(default_commands) do
    if not state.commands[k] then
      state.commands[k] = v
    end
  end

  --- Keybinds
  if not state.opts.skip_keymaps then
    vim.keymap.set("n", "<leader>tt", M.toggle_term,
      { desc = "[T]oggle [T]erminal" })

    vim.keymap.set("n", "<leader>tc",
      function()
        if state.opts.show_on_command then
          print("Showing on command")
          M.show_term()
        end
        M.execute_command()
      end,
      { desc = "[T]erminal [C]ompile" })
  end

  --- Commands
  vim.api.nvim_create_user_command(
    "TermAddOverride",
    function(args)
      local ft = nil
      local command = ""
      local index = 1
      for val in string.gmatch(args.args, "([^" .. " " .. "]+)") do
        if index == 1 then
          ft = val
        else
          if val then
            command = command .. val .. " "
          end
        end
        index = index + 1
      end
      if ft and command then
        M.add_command(ft, command)
        print("Added command '" .. command .. "' for filetype " .. ft)
      else
        print("Failed to add command, you need to provide both filetype and command.")
      end
    end,
    {
      nargs = 1,
      force = true,
      desc =
          "Add a filetyp command pair, which will override the pair specified during setup." ..
          "Call with filetype as first and command as second argument." ..
          " :TermAddCommand filetype command"
    })

  vim.api.nvim_create_user_command(
    "TermRemoveOverride",
    function(args)
      local ft = args.args
      if ft then
        if state.session_commands[ft] then
          M.remove_command(ft)
          print("Successfully removed command")
        end
      else
        print("Failed to remove command, you need to provide a valid filetype.")
      end
    end,
    {
      nargs = 1,
      force = true,
      desc =
          "Remove the command which was added as a session override." ..
          "Call with the filetype of the command to remove as first argument." ..
          " :TermRemoveCommand filetype"
    })

  --- Autocommands
  local au_group = vim.api.nvim_create_augroup("term-thingy-autocmds", { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', }, {
    group = au_group,
    callback = function(_)
      local ft = vim.bo.filetype
      local command = state.session_commands[ft] or state.commands[ft]
      if command then
        state.last_filetype = ft
      end
    end,
  })
end

return M
