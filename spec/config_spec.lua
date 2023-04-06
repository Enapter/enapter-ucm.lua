local config
local cmd_read
local cmd_write

_G.enapter = {
  register_command_handler = function(name, fn)
    if name == 'read_configuration' then
      cmd_read = fn
    elseif name == 'write_configuration' then
      cmd_write = fn
    end
  end,
}

_G.storage = {
  read = function() end,
  write = function() end,
}

describe('config', function()
  before_each(function()
    package.loaded['enapter.ucm.config'] = false
    config = require('enapter.ucm.config')
    config.init({ name = { type = 'string' } })
  end)

  it('should read from storage', function()
    local s = spy.on(storage, 'read')
    cmd_read()
    assert.spy(s).was_called_with('name')
  end)

  it('should write to storage', function()
    local s = spy.on(storage, 'write')
    local args = { name = 'test_value' }
    cmd_write(nil, args)
    assert.spy(s).was_called_with('name', 'test_value')
  end)

  it('should check all options are set or not', function()
    assert.is_true(config.is_all_options_set({ name = '' }))
    assert.is_false(config.is_all_options_set({}))
  end)

  it('should not allow to init with empty config', function()
    assert.has_error(
      function() config.init({}) end,
      'at least one config option should be provided'
    )
  end)

  it('should not allow to init twice', function()
    assert.has_error(
      function() config.init({ new_name = { type = 'number' } }) end,
      'config can be initialized only once'
    )
  end)
end)

describe('config with callbacks', function()
  before_each(function()
    package.loaded['enapter.ucm.config'] = false
    config = require('enapter.ucm.config')
  end)

  it('should call before callback write to storage', function()
    local callbacks = {
      before_write = function() end,
    }
    config.init({ name = { type = 'string' } }, callbacks)

    local sw = spy.on(storage, 'write')
    local bw = spy.on(callbacks, 'before_write')

    local args = { name = 'test_value' }
    cmd_write(nil, args)
    assert.spy(bw).was_called()
    assert.spy(sw).was_called_with('name', 'test_value')
  end)

  it('should not write if before callback returns error', function()
    local errmsg = 'check error'
    local callbacks = {
      before_write = function() return errmsg end,
    }
    config.init({ name = { type = 'string' } }, callbacks)

    local ctx_error = 'done'
    local ctx = { error = function() error(ctx_error) end }

    local sw = spy.on(storage, 'write')
    local bw = spy.on(callbacks, 'before_write')
    local ce = spy.on(ctx, 'error')

    local args = { name = 'test_value' }
    assert.has_error(function() cmd_write(ctx, args) end, ctx_error)
    assert.spy(bw).was_called()
    assert.spy(ce).was_called_with('before handler failed: ' .. errmsg)
    assert.spy(sw).was_not_called()
  end)

  it('should fill missed options with default value and remove it from storage', function()
    local callbacks = {
      before_write = function() end,
    }
    config.init({ name = { type = 'string', default = 'test string' } }, callbacks)

    local sr = spy.on(storage, 'remove')
    local bw = spy.on(callbacks, 'before_write')

    local args = {}
    local ctx = { error = function(err) error(err) end }
    cmd_write(ctx, args)
    assert.spy(bw).was_called_with({ name = 'test string' })
    assert.spy(sr).was_called_with('name')
  end)
end)

describe('config with long options name', function()
  it('should assert', function()
    package.loaded['enapter.ucm.config'] = false
    config = require('enapter.ucm.config')

    local name_with_len_15 = 'abcdefgh1234567'
    local name_with_len_16 = name_with_len_15 .. '8'
    assert.has_error(
      function() config.init({ [name_with_len_16] = { type = 'string' } }) end,
      'invalid option name `abcdefgh12345678`: length (16) should be less or equal 15'
    )
    assert.has_no_error(function() config.init({ [name_with_len_15] = { type = 'string' } }) end)
  end)
end)
