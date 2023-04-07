_G.inspect = require('inspect')
local stubs = require('enapter.ucm.stubs')

describe('generic rl6', function()
  local rl6, peer_stub

  before_each(function()
    local ucm_stubs = stubs.setup_enapter_ucm()
    peer_stub = stubs.new_dummy_ucm_peer()
    ucm_stubs.stubs = { peer_stub }

    package.loaded['enapter.ucm.generics.rl6'] = false
    rl6 = require('enapter.ucm.generics.rl6').new()
  end)

  after_each(function()
    stubs.teardown_generic_rl6()
    stubs.teardown_enapter_ucm()
  end)

  it('should open', function()
    rl6:setup('test_open_id', 57, 123)

    local s = spy.on(peer_stub, 'execute_command')
    assert.is_nil(rl6:open())
    assert.spy(s).was_called(1)
    assert.spy(s).was_called_with(peer_stub, 'open_channel', { channel = 57 }, { timeout = 123 })
  end)

  it('should close', function()
    rl6:setup('test_close_id', 31)

    local s = spy.on(peer_stub, 'execute_command')
    assert.is_nil(rl6:close())
    assert.spy(s).was_called(1)
    assert.spy(s).was_called_with(peer_stub, 'close_channel', { channel = 31 }, { timeout = 1000 })
  end)

  it('should report state', function()
    rl6:setup('test_state_id', 25)

    peer_stub.execute_command = function() return 'completed', { closed = true } end
    local closed, err = rl6:is_closed()
    assert.is_nil(err)
    assert.is_true(closed)
  end)

  it('should return error if state is missed', function()
    rl6:setup('test_err_id', 25)

    peer_stub.execute_command = function() return 'completed', { is_closed = true } end
    local _, err = rl6:is_closed()
    assert.is_same('unexpected response from io: {is_closed = true}', err)
  end)

  it('should return error if state is not boolean', function()
    rl6:setup('test_err_id', 25)

    peer_stub.execute_command = function() return 'completed', { closed = 'yes' } end
    local _, err = rl6:is_closed()
    assert.is_same('unexpected response from io: {closed = "yes"}', err)
  end)

  it('should return execution error (open)', function()
    rl6:setup()
    peer_stub.execute_command = function() return nil, nil, 'test exec err' end
    assert.is_same('test exec err', rl6:open())
  end)

  it('should return execution error (close)', function()
    rl6:setup()
    peer_stub.execute_command = function() return nil, nil, 'test exec err' end
    assert.is_same('test exec err', rl6:close())
  end)

  it('should return non-completed error (open)', function()
    rl6:setup()
    peer_stub.execute_command = function()
      return 'non-completed', { errcode = 117, errmsg = 'test open error' }, nil
    end
    assert.is_same(
      'relay module command failed: non-completed: {errcode = 117,errmsg = "test open error"}',
      rl6:open()
    )
  end)

  it('should return non-completed error', function()
    rl6:setup()

    peer_stub.execute_command = function()
      return 'non-completed', { errcode = 428, errmsg = 'test close error' }, nil
    end
    assert.is_same(
      'relay module command failed: non-completed: {errcode = 428,errmsg = "test close error"}',
      rl6:close()
    )
  end)
end)
