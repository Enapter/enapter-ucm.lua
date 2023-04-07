local GENERAL_IO_CHANNEL = 'gio'
local UCM_COMMAND_DEFAULT_TIMEOUT_MS = 1000

local function do_cmd(self, cmd_name)
  local peer = ucm.new(self.ucm_id, GENERAL_IO_CHANNEL)
  local state, payload, err = peer:execute_command(
    cmd_name,
    { channel = self.channel_id },
    { timeout = self.timeout }
  )
  if err then return nil, err end
  if state ~= 'completed' then
    return nil,
      'relay module command failed: ' .. state .. ': ' .. inspect(
        payload,
        { newline = '', indent = '' }
      )
  end

  return payload
end

return {
  new = function()
    local rl6 = {}

    function rl6:setup(ucm_id, channel_id, timeout)
      self.ucm_id = ucm_id
      self.channel_id = math.tointeger(channel_id)
      self.timeout = timeout or UCM_COMMAND_DEFAULT_TIMEOUT_MS
    end

    function rl6:open()
      local _, err = do_cmd(self, 'open_channel')
      return err
    end

    function rl6:close()
      local _, err = do_cmd(self, 'close_channel')
      return err
    end

    function rl6:is_closed()
      local payload, err = do_cmd(self, 'is_channel_closed')
      if err then return nil, err end
      if payload.closed == nil or type(payload.closed) ~= 'boolean' then
        return nil,
          'unexpected response from io: ' .. inspect(payload, { newline = '', indent = '' })
      end
      return payload.closed
    end

    return rl6
  end,
}
