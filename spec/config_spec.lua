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
  end
}

_G.storage = {
  read = function() end,
  write = function() end
}

describe("config tests", function()
  before_each(function()
    package.loaded['enapter.ucm.config'] = false
    config = require('enapter.ucm.config')
    config.init({name = {type='string'}})
  end)

  it("should read from storage", function()
    local s = spy.on(storage, 'read')
    cmd_read()
    assert.spy(s).was_called_with('name')
  end)

  it("should write to storage", function()
    local s = spy.on(storage, 'write')
    local args = {name = 'test_value'}
    cmd_write(nil, args)
    assert.spy(s).was_called_with('name', 'test_value')
  end)
end)
