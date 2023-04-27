local GENERAL_IO_CHANNEL = 'gio'
local UCM_COMMAND_DEFAULT_TIMEOUT_MS = 1000

local function extract_msg_ids(messages)
  local msg_ids = {}
  for _, msg in ipairs(messages) do
    if msg.msg_id then table.insert(msg_ids, msg.msg_id) end
  end
  return table.concat(msg_ids, ',')
end

local can_read = function(self, name)
  local sub = self.subscriptions[name]
  if not sub then return nil, nil, "subscritpion with name '" .. name .. "' is not exists" end

  local peer = ucm.new(self.ucm_id, GENERAL_IO_CHANNEL)
  local state, payload, err = peer:execute_command(
    'read',
    { cursor = sub.cursor, msg_ids = extract_msg_ids(sub.messages) },
    { timeout = self.timeout }
  )

  if err then return nil, nil, 'command failed: ' .. err end

  if state ~= 'completed' then
    local payload_str = inspect(payload, { newline = '', indent = '' })
    return nil, nil, 'command failed: ' .. tostring(state) .. ': ' .. payload_str
  end

  return sub, payload, nil
end

return {
  new = function()
    local can = { subscriptions = {} }

    function can:setup(ucm_id, subscriptions, timeout)
      self.ucm_id = ucm_id
      self.timeout = timeout or UCM_COMMAND_DEFAULT_TIMEOUT_MS
      self.subscriptions = {}

      local sub_err
      for name, messages in pairs(subscriptions) do
        self.subscriptions[name] = { messages = messages }
        local _, _, err = can_read(self, name)
        sub_err = sub_err or err
      end

      return sub_err
    end

    function can:get(name)
      local sub, payload, err = can_read(self, name)
      if err then return nil, err end

      sub.cursor = payload.cursor

      local ret = {}
      for i, h in ipairs(sub.messages) do
        local data = payload.results[i]
        if #data > 0 then
          if not h.multi_msg then data = data[#data] end

          local rr
          local ok, err = pcall(function() rr = h.parser(data) end)
          if not ok then
            local data_arr = data:gsub('.', function(c) return string.byte(c) .. ' ' end)
            return nil,
              'data processing failed [msg_id='
                .. string.format('0x%x', h.msg_id)
                .. ' data={'
                .. data_arr
                .. '}]: '
                .. err
          end

          if h.name ~= nil then
            ret[h.name] = rr
          else
            for j, k in ipairs(h.names) do
              ret[k] = rr[j]
            end
          end
        end
      end

      return ret, nil
    end

    return can
  end,
}
