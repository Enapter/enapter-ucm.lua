--- Modbus querier
-- Allow to perform multiple reads or writes from modbus.
-- It assumes, that Enapter modbus Lua module properly configured and ready for work.
-- @module qmodbus

local qmodbus = {}

local function tointeger(val)
  if val == nil then return nil end
  return math.floor(val)
end

local read_functions = {
  coils = modbus.read_coils,
  discrete_inputs = modbus.read_discrete_inputs,
  holdings = modbus.read_holdings,
  inputs = modbus.read_inputs,
}

--- Performs multiple reads from modbus
-- Queries is an array of tables.
-- Query keys is type, addr, reg, count and timeout.
-- type can be one of "coils", "discrete_inputs", "holdings", "inputs".
-- timeout is optional and set to 1000 ms (1 second) by default.
-- @param queries table Read queries
-- @return table|nil, string|nil Read results and error message
-- @usage
--   local queries = {
--     { type="inputs", addr=1, reg=0, count=2 },
--     { type="inputs", addr=1, reg=6, count=2 },
--   }
--   qmodbus.read(queries)
function qmodbus.read(queries)
  local results = {}

  for i, query in ipairs(queries) do
    local read_type = query.type
    if read_type == nil then return nil, 'read type is missed for #' .. tostring(i) end

    local read_func = read_functions[read_type]
    if read_func == nil then
      return nil, "unknown read type '" .. tostring(read_type) .. "' for #" .. tostring(i)
    end

    local addr = tointeger(query.addr)
    if addr == nil then return nil, 'addr is missed for #' .. tostring(i) end

    local reg = tointeger(query.reg)
    if reg == nil then return nil, 'reg is missed for #' .. tostring(i) end

    local count = tointeger(query.count)
    if count == nil then return nil, 'count is missed for #' .. tostring(i) end

    local timeout = tointeger(query.timeout)
    if timeout == nil then timeout = 1000 end

    local data, result = read_func(addr, reg, count, timeout)
    if data ~= nil then
      results[i] = { data = data }
    else
      results[i] = { errcode = result, errmsg = modbus.err_to_str(result) }
    end
  end

  return results, nil
end

local write_functions = {
  coil = modbus.write_coil,
  holding = modbus.write_holding,
}

local write_multiple_functions = {
  multiple_coils = modbus.write_multiple_coils,
  multiple_holdings = modbus.write_multiple_holdings,
}

--- Performs multiple writes to modbus
-- Queries is an array of tables.
-- Query keys is type, addr, reg, value(s) and timeout.
-- type can be "coil" or "holding". In that case "value" (integer) key is expected.
-- type can be "multiple_coils" or "multiple_holdings". In that case "values" (table) key is expected.
-- timeout is optional and set to 1000 ms (1 second) by default.
-- @param queries table Read queries
-- @return table|nil, string|nil Read results and error message
-- @usage
--   local queries = {
--     { type="holding", addr=1, reg=0, value=2 },
--     { type="multiple_coils", addr=1, reg=6, values={4,5} },
--   }
--   qmodbus.write(queries)
function qmodbus.write(queries)
  local results = {}

  for i, query in ipairs(queries) do
    local write_type = query.type
    if write_type == nil then return nil, 'write type is missed for #' .. tostring(i) end

    local multiple_write = false
    local write_func = write_functions[write_type]
    if write_func == nil then
      multiple_write = true
      write_func = write_multiple_functions[write_type]
      if write_func == nil then
        return nil, "unknown write type '" .. tostring(write_type) .. "' for #" .. tostring(i)
      end
    end

    local addr = tointeger(query.addr)
    if addr == nil then return nil, 'addr is missed for #' .. tostring(i) end

    local reg = tointeger(query.reg)
    if reg == nil then return nil, 'reg is missed for #' .. tostring(i) end

    local val
    if multiple_write then
      val = query.values
      if val == nil then return nil, 'values is missed for #' .. tostring(i) end
      if type(val) ~= 'table' then return nil, 'values must be a table for #' .. tostring(i) end
    else
      val = tointeger(query.value)
      if val == nil then return nil, 'value is missed for #' .. tostring(i) end
    end

    local timeout = tointeger(query.timeout)
    if timeout == nil then timeout = 1000 end

    local result = write_func(addr, reg, val, timeout)
    if result == 0 then
      results[i] = {}
    else
      results[i] = { errcode = result, errmsg = modbus.err_to_str(result) }
    end
  end

  return results, nil
end

return qmodbus
