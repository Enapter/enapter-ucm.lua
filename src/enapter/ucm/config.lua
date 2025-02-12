local OPTION_NAME_MAX_LEN = 15
local config = {}

local function storage_err(v)
  if runtime_version == 'v3' then return v end

  local err = storage.err_to_str(v)
  if err == '' then err = nil end
  return err
end

--- Initializes config options.
-- Registers required UCM commands to read and write configuration described by options param.
-- Calls callback functions before and after configuration writing. Callbacks are passed via callbacks param.
-- @param options key-value pairs with config option names and params.
-- @param callbacks key-value pairs with callback functions. Supported keys: before_write, after_write.
-- @usage
--   config.init({
--     address = { type = 'string', required = true },
--     unit_id = { type = 'number', default = 1 },
--     reconnect = { type = 'boolean', required = true }
--   })
-- @usage
--   config.init({
--     address = { type = 'string', required = true },
--     unit_id = { type = 'number', default = 1 },
--     reconnect = { type = 'boolean', required = true }
--   }, {
--     before_write = function(args)
--       if math.tointeger(args.unit_id) == nil then
--         return "unit_id must be an integer value"
--       end
--     end
--   })
function config.init(options, callbacks)
  assert(next(options) ~= nil, 'at least one config option should be provided')
  assert(not config.initialized, 'config can be initialized only once')
  for name, params in pairs(options) do
    assert(
      #name <= OPTION_NAME_MAX_LEN,
      'invalid option name `'
        .. name
        .. '`: length ('
        .. tostring(#name)
        .. ') should be less or equal '
        .. tostring(OPTION_NAME_MAX_LEN)
    )
    local type_ok = params.type == 'string' or params.type == 'number' or params.type == 'boolean'
    assert(type_ok, 'type of `' .. name .. '` option should be either string or number or boolean')
  end

  enapter.register_command_handler(
    'write_configuration',
    config.build_write_configuration_command(options, callbacks)
  )
  enapter.register_command_handler(
    'read_configuration',
    config.build_read_configuration_command(options)
  )

  config.options = options
  config.initialized = true
end

--- Checks that all config options are set.
-- @return status true if all options are set or false otherwise.
function config.is_all_options_set(args)
  for name, _ in pairs(config.options) do
    if args[name] == nil then return false end
  end

  return true
end

--- Reads all config options.
-- @return values key-value pairs table for all config options.
-- @return error string with error message or nil on success.
function config.read_all()
  local result = {}

  for name, _ in pairs(config.options) do
    local value, err = config.read(name)
    if err then
      return nil, 'cannot read `' .. name .. '`: ' .. err
    else
      result[name] = value
    end
  end

  return result, nil
end

-- @param name string: option name to read
-- @return string
-- @return nil|error
function config.read(name)
  local params = config.options[name]
  assert(params, 'undeclared config option: `' .. name .. '`, declare with config.init')

  local ok, value, ret = pcall(function() return storage.read(name) end)
  local err = storage_err(ret)

  if not ok then
    return nil, 'error reading from storage: ' .. tostring(value)
  elseif err ~= nil then
    -- FIXME: InternalError is because of a bug in UCM v1.2.1,
    -- should be removed after bug is fixed.
    if err == 'NotFound' or err == 'InternalError' then
      return params.default, nil
    else
      return nil, 'error reading from storage: ' .. err
    end
  elseif value then
    return config.deserialize(name, value), nil
  else
    return params.default, nil
  end
end

-- @param name string: option name to write
-- @param val string: value to write
-- @return nil|error
function config.write(name, val)
  local ok, ret = pcall(function()
    if val == nil then
      return storage.remove(name)
    else
      return storage.write(name, config.serialize(name, val))
    end
  end)

  local err = storage_err(ret)

  if not ok then
    return 'error writing to storage: ' .. tostring(ret)
  elseif err ~= nil and err ~= 'NotFound' then
    return 'error writing to storage: ' .. err
  end
end

-- Serializes value into string for storage
function config.serialize(_, value)
  if value ~= nil then
    return tostring(value)
  else
    return nil
  end
end

-- Deserializes value from stored string
function config.deserialize(name, value)
  local params = config.options[name]
  assert(params, 'undeclared config option: `' .. name .. '`, declare with config.init')

  if params.type == 'number' then
    return tonumber(value)
  elseif params.type == 'string' then
    return value
  elseif params.type == 'boolean' then
    if value == 'true' then
      return true
    elseif value == 'false' then
      return false
    else
      return nil
    end
  end
end

function config.build_write_configuration_command(options, callbacks)
  return function(ctx, args)
    local callback_args = {}
    for name, params in pairs(options) do
      if params.required then assert(args[name] ~= nil, '`' .. name .. '` argument required') end
      callback_args[name] = args[name] or params.default
    end

    if callbacks ~= nil and callbacks.before_write ~= nil then
      local err = callbacks.before_write(callback_args)
      if err then ctx.error('before handler failed: ' .. err) end
    end

    for name, _ in pairs(options) do
      local err = config.write(name, args[name])
      if err then ctx.error('cannot write `' .. name .. '`: ' .. err) end
    end

    if callbacks ~= nil and callbacks.after_write ~= nil then
      local err = callbacks.after_write(callback_args)
      if err then ctx.error('after handler failed: ' .. err) end
    end
  end
end

function config.build_read_configuration_command(_config_options)
  return function(ctx)
    local result, err = config.read_all()
    if err then
      ctx.error(err)
    else
      return result
    end
  end
end

return config
