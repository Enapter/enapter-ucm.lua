local GENERAL_IO_CHANNEL = 'gio'

local function do_cmd(self, cmd_name)
  local peer = ucm.new(self.ucm_id, GENERAL_IO_CHANNEL)
  local state, payload, err = peer:execute_command(
    cmd_name,
    { input = self.input },
    { timeout = self.timeout }
  )
  if err then return nil, err end

  if state ~= 'completed' then
    return nil,
      'digital input module command failed ' .. state .. ': ' .. inspect(
        payload,
        { newline = '', indent = '' }
      )
  end

  return payload
end

return {
  new = function()
    local di7 = {}

    function di7:setup(ucm_id, input, timeout)
      self.ucm_id = ucm_id
      self.input = math.tointeger(input)
      self.timeout = timeout
    end

    function di7:is_closed()
      local payload, err = do_cmd(self, 'is_closed')
      if err then return nil, err end
      if payload.closed == nil or type(payload.closed) ~= 'boolean' then
        return nil,
          'unexpected response from io: ' .. inspect(payload, { newline = '', indent = '' })
      end

      return payload.closed
    end

    return di7
  end,
}
