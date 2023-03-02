local read_functions = {
  'read_coils',
  'read_discrete_inputs',
  'read_holdings',
  'read_inputs',
}

local write_functions = {
  'write_coil',
  'write_holding',
}

local write_multiple_functions = {
  'write_multiple_coils',
  'write_multiple_holdings',
}

local _set_stub, _reset_stub

local function new()
  local modbus_stub = {
    err_to_str = function(e) return 'error code: ' .. tostring(e) end,
    _calls = {},
  }

  modbus_stub._reset = function() _reset_stub(modbus_stub) end

  for _, f in ipairs(read_functions) do
    _set_stub(modbus_stub, f, function(stub_calls)
      return function(addr, reg, count, timeout)
        stub_calls.called_with = { addr = addr, reg = reg, count = count, timeout = timeout }
        return stub_calls.data, stub_calls.error
      end
    end)
  end

  for _, f in ipairs(write_functions) do
    _set_stub(modbus_stub, f, function(stub_calls)
      return function(addr, reg, value, timeout)
        stub_calls.called_with = { addr = addr, reg = reg, value = value, timeout = timeout }
        return stub_calls.error
      end
    end)
  end

  for _, f in ipairs(write_multiple_functions) do
    _set_stub(modbus_stub, f, function(stub_calls)
      return function(addr, reg, values, timeout)
        stub_calls.called_with = { addr = addr, reg = reg, values = values, timeout = timeout }
        return stub_calls.error
      end
    end)
  end

  return modbus_stub
end

function _set_stub(self, name, fn_gen)
  self._calls[name] = {}
  self[name] = fn_gen(self._calls[name])
end

function _reset_stub(self)
  for _, v in pairs(self._calls) do
    for k, _ in pairs(v) do
      v[k] = nil
    end
    v.error = 0
  end
end

return new()
