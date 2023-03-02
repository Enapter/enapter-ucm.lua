local modbus_stub = require('spec/modbus_stub')

_G.modbus = modbus_stub
local qmodbus = require('enapter.ucm.qmodbus')

local function shuffle_array(t)
  for i = 1, #t do
    local r = math.random(#t)
    if r ~= i then
      t[r], t[i] = t[i], t[r]
    end
  end
  return t
end

local function generate_read_queries()
  local rnd = function() return math.random(1, 100) end

  local queries = {
    { type = 'coils', addr = rnd(), reg = rnd(), count = rnd(), timeout = rnd() },
    { type = 'discrete_inputs', addr = rnd(), reg = rnd(), count = 6, timeout = rnd() },
    { type = 'holdings', addr = rnd(), reg = rnd(), count = rnd(), timeout = rnd() },
    { type = 'inputs', addr = rnd(), reg = rnd(), count = rnd(), timeout = rnd() },
  }
  return shuffle_array(queries)
end

local function generate_write_queries()
  local rnd = function() return math.random(1, 100) end

  local queries = {
    { type = 'coil', addr = rnd(), reg = rnd(), value = rnd(), timeout = rnd() },
    { type = 'holding', addr = rnd(), reg = rnd(), value = rnd(), timeout = rnd() },
    {
      type = 'multiple_coils',
      addr = rnd(),
      reg = rnd(),
      values = { rnd(), rnd() },
      timeout = rnd(),
    },
    {
      type = 'multiple_holdings',
      addr = rnd(),
      reg = rnd(),
      values = { rnd(), rnd(), rnd() },
      timeout = rnd(),
    },
  }
  return shuffle_array(queries)
end

local function modbus_query_to_call_args(t)
  local t2 = {}
  for k, v in pairs(t) do
    if k ~= 'type' then t2[k] = v end
  end

  return t2
end

describe('qmodbus', function()
  setup(function()
    local seed = os.time()
    print('random seed = ' .. tostring(seed))
    math.randomseed(seed)
  end)
  before_each(function() modbus_stub._reset() end)

  it('should read by queries', function()
    local queries = generate_read_queries()

    modbus_stub._calls.read_coils.data = 111
    modbus_stub._calls.read_discrete_inputs.data = 222
    modbus_stub._calls.read_holdings.data = 333
    modbus_stub._calls.read_inputs.data = 444

    local results, err = qmodbus.read(queries)
    assert.is_nil(err)

    assert.is.equal(#queries, #results)
    for i, q in ipairs(queries) do
      local stub_call = modbus_stub._calls['read_' .. q.type]
      assert.is.same({ data = stub_call.data }, results[i])
      assert.is.same(modbus_query_to_call_args(q), stub_call.called_with)
    end
  end)

  it('should read with default timeout', function()
    local query = { type = 'inputs', addr = 1, reg = 2, count = 3 }

    local stub_call = modbus_stub._calls.read_inputs
    stub_call.data = 444

    local results, err = qmodbus.read({ query })
    assert.is_nil(err)
    assert.is.same({ data = stub_call.data }, results[1])

    query.timeout = 1000
    assert.is.same(modbus_query_to_call_args(query), stub_call.called_with)
  end)

  it('should return read errors', function()
    local queries = generate_read_queries()

    modbus_stub._calls.read_coils.error = 111
    modbus_stub._calls.read_discrete_inputs.error = 222
    modbus_stub._calls.read_holdings.error = 333
    modbus_stub._calls.read_inputs.error = 444

    local results, err = qmodbus.read(queries)
    assert.is_nil(err)

    assert.is.equal(#queries, #results)
    for i, q in ipairs(queries) do
      local stub_call = modbus_stub._calls['read_' .. q.type]
      local err_result =
        { errcode = stub_call.error, errmsg = 'error code: ' .. tostring(stub_call.error) }
      assert.is.same(err_result, results[i])
      assert.is.same(modbus_query_to_call_args(q), stub_call.called_with)
    end
  end)

  describe('should validate read queries', function()
    it('without type', function()
      local _, err = qmodbus.read({ {} })
      assert.is.equal('read type is missed for #1', err)
    end)
    it('with unknown type', function()
      local _, err = qmodbus.read({ { type = 'unsupported' } })
      assert.is.equal("unknown read type 'unsupported' for #1", err)
    end)
    it('without addr', function()
      local _, err = qmodbus.read({ { type = 'coils' } })
      assert.is.equal('addr is missed for #1', err)
    end)
    it('without reg', function()
      local _, err = qmodbus.read({ { type = 'coils', addr = 1 } })
      assert.is.equal('reg is missed for #1', err)
    end)
    it('without count', function()
      local _, err = qmodbus.read({
        { type = 'coils', addr = 1, reg = 2, count = 3 },
        { type = 'coils', addr = 1, reg = 2 },
      })
      assert.is.equal('count is missed for #2', err)
    end)
  end)

  it('should write by queries', function()
    local queries = generate_write_queries()
    local results, err = qmodbus.write(queries)
    assert.is_nil(err)

    assert.is.equal(#queries, #results)
    for i, q in ipairs(queries) do
      local stub_call = modbus_stub._calls['write_' .. q.type]
      assert.is.same({}, results[i])
      assert.is.same(modbus_query_to_call_args(q), stub_call.called_with)
    end
  end)

  it('should write with default timeout', function()
    local query = { type = 'holding', addr = 1, reg = 2, value = 3 }
    local results, err = qmodbus.write({ query })
    assert.is_nil(err)

    local stub_call = modbus_stub._calls.write_holding
    assert.is.same({ data = stub_call.data }, results[1])

    query.timeout = 1000
    assert.is.same(modbus_query_to_call_args(query), stub_call.called_with)
  end)

  it('should return write errors', function()
    local queries = generate_write_queries()

    modbus_stub._calls.write_coil.error = 11
    modbus_stub._calls.write_holding.error = 22
    modbus_stub._calls.write_multiple_coils.error = 33
    modbus_stub._calls.write_multiple_holdings.error = 44

    local results, err = qmodbus.write(queries)
    assert.is_nil(err)

    assert.is.equal(#queries, #results)
    for i, q in ipairs(queries) do
      local stub_call = modbus_stub._calls['write_' .. q.type]
      local err_result =
        { errcode = stub_call.error, errmsg = 'error code: ' .. tostring(stub_call.error) }
      assert.is.same(err_result, results[i])
      assert.is.same(modbus_query_to_call_args(q), stub_call.called_with)
    end
  end)

  describe('should validate write queries', function()
    it('without type', function()
      local _, err = qmodbus.write({ {} })
      assert.is.equal('write type is missed for #1', err)
    end)
    it('with unknown type', function()
      local _, err = qmodbus.write({ { type = 'unsupported' } })
      assert.is.equal("unknown write type 'unsupported' for #1", err)
    end)
    it('without addr', function()
      local _, err = qmodbus.write({ { type = 'coil' } })
      assert.is.equal('addr is missed for #1', err)
    end)
    it('without reg', function()
      local _, err = qmodbus.write({ { type = 'coil', addr = 1 } })
      assert.is.equal('reg is missed for #1', err)
    end)
    it('without value', function()
      local _, err = qmodbus.write({
        { type = 'coil', addr = 1, reg = 2, value = 3 },
        { type = 'coil', addr = 1, reg = 2 },
      })
      assert.is.equal('value is missed for #2', err)
    end)
    it('without values', function()
      local _, err = qmodbus.write({ { type = 'multiple_coils', addr = 1, reg = 2 } })
      assert.is.equal('values is missed for #1', err)
    end)
  end)
end)
