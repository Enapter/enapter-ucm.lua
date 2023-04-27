local stubs = require('enapter.ucm.stubs')

_G.inspect = require('inspect')

describe('generic can', function()
  local can, ucm_stubs, cursor

  local function prepare_peer_stub()
    local peer_stub = stubs.new_dummy_ucm_peer()
    ucm_stubs.stubs = { peer_stub }
    peer_stub:should_return('execute_command', 'completed', { cursor = cursor })
    return peer_stub
  end

  before_each(function()
    ucm_stubs = stubs.setup_enapter_ucm()

    package.loaded['enapter.ucm.generics.can'] = false
    can = require('enapter.ucm.generics.can').new()
    can:setup('test_ucm_id', {})
  end)

  after_each(function()
    stubs.teardown_generic_can()
    stubs.teardown_enapter_ucm()
  end)

  it('shoud execute read command when setup', function()
    local messages = {
      { msg_id = 123 },
      { msg_id = 789 },
    }
    local timeout = math.random(5000)

    local peer_stub = prepare_peer_stub()
    local s = spy.on(peer_stub, 'execute_command')
    assert.is_nil(can:setup('', { test_cmd = messages }, timeout))
    assert.spy(s).was_called(1)
    assert.spy(s).was_called_with(peer_stub, 'read', { msg_ids = '123,789' }, { timeout = timeout })
  end)

  it('should store cursor', function()
    cursor = math.random(100)
    assert.is_nil(can:setup('', { test_cur = {} }))

    local peer_stub = prepare_peer_stub()

    local s = spy.on(peer_stub, 'execute_command')
    local _, err = can:get('test_cur')
    assert.is_nil(err)
    assert.spy(s).was_called(1)
    assert.spy(s).was_called_with(peer_stub, 'read', { msg_ids = '' }, { timeout = 1000 })

    peer_stub = prepare_peer_stub()
    local s2 = spy.on(peer_stub, 'execute_command')
    _, err = can:get('test_cur')
    assert.is_nil(err)
    assert.spy(s2).was_called(1)
    assert
      .spy(s2)
      .was_called_with(peer_stub, 'read', { cursor = cursor, msg_ids = '' }, { timeout = 1000 })
  end)

  it('should not get for unknow subscription', function()
    local _, err = can:get('unknown')
    assert.is.equals("subscritpion with name 'unknown' is not exists", err)
  end)

  it('should handle error from generic can io', function()
    assert.is_nil(can:setup('', { test_can_error = {} }))

    local peer_stub = prepare_peer_stub()
    peer_stub:should_return('execute_command', 'completed', nil, 'can error')

    local _, err = can:get('test_can_error')
    assert.is.equals('command failed: can error', err)
  end)

  it('should handle non-completed state from generic can io', function()
    assert.is_nil(can:setup('', { test_non_completed = {} }))

    local peer_stub = prepare_peer_stub()
    peer_stub:should_return('execute_command', 'non-completed', { errmsg = 'error msg' })

    local _, err = can:get('test_non_completed')
    assert.is.equals('command failed: non-completed: {errmsg = "error msg"}', err)
  end)

  it('should get with name and names', function()
    local messages = {
      {
        name = 't_name',
        msg_id = 0x318,
        parser = function() return 'test name' end,
      },
      {
        names = { 'n_1', 'n_2' },
        msg_id = 0x418,
        parser = function() return { 1, 2 } end,
      },
    }

    assert.is_nil(can:setup('', { test_names = messages }))

    local peer_stub = prepare_peer_stub()
    peer_stub:should_return('execute_command', 'completed', { results = { { 'r1' }, { 'r2' } } })

    local ret, err = can:get('test_names')
    assert.is_nil(err)

    assert.is_same({ t_name = 'test name', n_1 = 1, n_2 = 2 }, ret)
  end)

  it('should differ pass data to multi_msg', function()
    local test_data = { 'r1', 'r2' }
    local messages = {
      {
        name = 't_multi',
        msg_id = 0x318,
        multi_msg = true,
        parser = function(datas) return datas[1] .. datas[2] end,
      },
      {
        name = 't_single',
        msg_id = 0x418,
        parser = function(data) return data end,
      },
    }

    assert.is_nil(can:setup('', { test_multi = messages }))

    local peer_stub = prepare_peer_stub()
    peer_stub:should_return('execute_command', 'completed', { results = { test_data, test_data } })

    local ret, err = can:get('test_multi')
    assert.is_nil(err)

    assert.is_same({ t_multi = 'r1r2', t_single = 'r2' }, ret)
  end)

  it('should handle errors from parser function', function()
    local messages = {
      {
        name = 'fail',
        msg_id = 0x404,
        parser = function() error('not found') end,
      },
    }

    assert.is_nil(can:setup('', { test_names = messages }))

    local peer_stub = prepare_peer_stub()
    peer_stub:should_return('execute_command', 'completed', { results = { { 'any data' } } })

    local _, err = can:get('test_names')
    assert.is_equals(
      'data processing failed [msg_id=0x404 data={97 110 121 32 100 97 116 97 }]: <place>: not found',
      err:gsub('spec/generic_can_spec.lua:%d+', '<place>')
    )
  end)
end)
