local config
local cmd_read
local cmd_write
local cmd_ctx = { error = function(err) error(err) end }

_G.enapter = {
  register_command_handler = function(name, fn)
    if name == 'read_configuration' then
      cmd_read = fn
    elseif name == 'write_configuration' then
      cmd_write = fn
    end
  end,
}

describe('config', function()
  before_each(function()
    _G.runtime_version = 'v1'
    _G.storage = {
      read = function() return nil, 0 end,
      write = function() return 0 end,
      remove = function() return 0 end,
      err_to_str = function(ret)
        if ret == 0 then
          return ''
        elseif ret == 404 then
          return 'NotFound'
        elseif ret == 500 then
          return 'InternalError'
        end
        return 'error ' .. tostring(ret)
      end,
    }

    package.loaded['enapter.ucm.config'] = false
    config = require('enapter.ucm.config')
    config.init({ name = { type = 'string' } })
  end)

  describe('read', function()
    it('should read all config', function()
      local s = spy.on(storage, 'read')
      cmd_read(cmd_ctx)
      assert.spy(s).was_called_with('name')
    end)

    it('should handle storage read error', function()
      _G.storage.read = function() return nil, 1 end

      local errmsg = 'cannot read `name`: error reading from storage: error 1'
      assert.has_error(function() cmd_read(cmd_ctx) end, errmsg)
    end)

    it('should handle storage read error v3', function()
      _G.runtime_version = 'v3'
      _G.storage.read = function() return nil, 'read failed' end

      local errmsg = 'cannot read `name`: error reading from storage: read failed'
      assert.has_error(function() cmd_read(cmd_ctx) end, errmsg)
    end)

    it('should handle storage read NotFound error', function()
      _G.storage.read = function() return nil, 404 end

      local s = spy.on(storage, 'read')
      cmd_read(cmd_ctx)
      assert.spy(s).was_called_with('name')
    end)

    it('should handle storage read NotFound error v3', function()
      _G.runtime_version = 'v3'
      _G.storage.read = function() return nil, 'NotFound' end

      local s = spy.on(storage, 'read')
      cmd_read(cmd_ctx)
      assert.spy(s).was_called_with('name')
    end)

    it('should handle storage read InternalError error', function()
      _G.storage.read = function() return nil, 500 end

      local s = spy.on(storage, 'read')
      cmd_read(cmd_ctx)
      assert.spy(s).was_called_with('name')
    end)

    it('should handle storage read InternalError error v3', function()
      _G.runtime_version = 'v3'
      _G.storage.read = function() return nil, 'InternalError' end

      local s = spy.on(storage, 'read')
      cmd_read(cmd_ctx)
      assert.spy(s).was_called_with('name')
    end)
  end)

  describe('write', function()
    it('should write to storage', function()
      local s = spy.on(storage, 'write')
      local args = { name = 'test_value' }
      cmd_write(cmd_ctx, args)
      assert.spy(s).was_called_with('name', 'test_value')
    end)

    it('should handle storage write error', function()
      _G.storage.write = function() return 2 end

      local args = { name = 'test_value' }
      local errmsg = 'cannot write `name`: error writing to storage: error 2'
      assert.has_error(function() cmd_write(cmd_ctx, args) end, errmsg)
    end)

    it('should handle storage write error v3', function()
      _G.runtime_version = 'v3'
      _G.storage.write = function() return 'write failed' end

      local args = { name = 'test_value' }
      local errmsg = 'cannot write `name`: error writing to storage: write failed'
      assert.has_error(function() cmd_write(cmd_ctx, args) end, errmsg)
    end)

    it('should handle write NotFound err', function()
      _G.storage.write = function() return 404 end

      local args = { name = 'test_value' }
      cmd_write(cmd_ctx, args)
    end)

    it('should handle write NotFound err v3', function()
      _G.runtime_version = 'v3'
      _G.storage.write = function() return 'NotFound' end

      local args = { name = 'test_value' }
      cmd_write(cmd_ctx, args)
    end)

    it('should handle storage remove error', function()
      _G.storage.remove = function() return 3 end

      local args = { name = nil }
      local errmsg = 'cannot write `name`: error writing to storage: error 3'
      assert.has_error(function() cmd_write(cmd_ctx, args) end, errmsg)
    end)

    it('should handle storage remove error v3', function()
      _G.runtime_version = 'v3'
      _G.storage.remove = function() return 'remove failed' end

      local args = { name = nil }
      local errmsg = 'cannot write `name`: error writing to storage: remove failed'
      assert.has_error(function() cmd_write(cmd_ctx, args) end, errmsg)
    end)

    it('should handle remove NotFound err', function()
      _G.storage.remove = function() return 404 end

      local args = { name = nil }
      cmd_write(cmd_ctx, args)
    end)

    it('should handle remove NotFound err v3', function()
      _G.runtime_version = 'v3'
      _G.storage.remove = function() return 'NotFound' end

      local args = { name = nil }
      cmd_write(cmd_ctx, args)
    end)
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
    cmd_write(cmd_ctx, args)
    assert.spy(bw).was_called()
    assert.spy(sw).was_called_with('name', 'test_value')
  end)

  it('should not write if before callback returns error', function()
    local errmsg = 'check error'
    local callbacks = {
      before_write = function() return errmsg end,
    }
    config.init({ name = { type = 'string' } }, callbacks)

    local sw = spy.on(storage, 'write')
    local bw = spy.on(callbacks, 'before_write')

    local args = { name = 'test_value' }
    assert.has_error(function() cmd_write(cmd_ctx, args) end, 'before handler failed: ' .. errmsg)
    assert.spy(bw).was_called()
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
    cmd_write(cmd_ctx, args)
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
