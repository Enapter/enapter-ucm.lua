_G.inspect = require('inspect')
local stubs = require('enapter.ucm.stubs')

describe('generic di7', function()
  local di7, peer_stub

  before_each(function()
    local ucm_stubs = stubs.setup_enapter_ucm()
    peer_stub = stubs.new_dummy_ucm_peer()
    ucm_stubs.stubs = { peer_stub }

    package.loaded['enapter.ucm.generics.di7'] = false
    di7 = require('enapter.ucm.generics.di7').new()
  end)

  after_each(function()
    stubs.teardown_generic_di7()
    stubs.teardown_enapter_ucm()
  end)

  describe('should complete is_closed', function()
    it('success', function()
      di7:setup('test_closed_ucm_id', 5, 1000)
      peer_stub:should_return('execute_command', 'completed', { closed = false })
      local peer_execute_command_spy = spy.on(peer_stub, 'execute_command')

      local state, err = di7:is_closed()
      assert.is_nil(err)
      assert.is_false(state)

      assert.spy(peer_execute_command_spy).was_called(1)
      assert
        .spy(peer_execute_command_spy)
        .was_called_with(peer_stub, 'is_closed', { input = 5 }, { timeout = 1000 })
    end)

    it('with error', function()
      di7:setup('test_closed_with_error_ucm_id', 7, 2000)
      peer_stub:should_return('execute_command', nil, nil, 'test_exec_error')
      local peer_execute_command_spy = spy.on(peer_stub, 'execute_command')

      local state, err = di7:is_closed()
      assert.are_equal(err, 'test_exec_error')
      assert.is_nil(state)

      assert.spy(peer_execute_command_spy).was_called(1)
      assert
        .spy(peer_execute_command_spy)
        .was_called_with(peer_stub, 'is_closed', { input = 7 }, { timeout = 2000 })
    end)

    it('with uncompleted status', function()
      di7:setup('test_closed_with_uncpl_state_ucm_id', 4, 8000)
      peer_stub:should_return('execute_command', 'maybe_not_completed', {})
      local peer_execute_command_spy = spy.on(peer_stub, 'execute_command')

      local state, err = di7:is_closed()
      assert.are_equal(err, 'digital input module command failed maybe_not_completed: {}')
      assert.is_nil(state)

      assert.spy(peer_execute_command_spy).was_called(1)
      assert
        .spy(peer_execute_command_spy)
        .was_called_with(peer_stub, 'is_closed', { input = 4 }, { timeout = 8000 })
    end)

    it('with unexpected payload', function()
      di7:setup('test_closed_with_unx_payload_ucm_id', 3, 12000)
      peer_stub:should_return('execute_command', 'completed', { foo = 'bar' })
      local peer_execute_command_spy = spy.on(peer_stub, 'execute_command')

      local state, err = di7:is_closed()
      assert.are_equal(err, 'unexpected response from io: {foo = "bar"}')
      assert.is_nil(state)

      assert.spy(peer_execute_command_spy).was_called(1)
      assert
        .spy(peer_execute_command_spy)
        .was_called_with(peer_stub, 'is_closed', { input = 3 }, { timeout = 12000 })
    end)
  end)
end)
