local function new_dummy_rl6()
  return {
    setup = function() end,
    is_closed = function() return false end,
  }
end

local function setup_generic_rl6()
  local stub = { stubs = {} }
  package.loaded['enapter.ucm.generics.rl6'] = false
  package.preload['enapter.ucm.generics.rl6'] = function()
    return {
      new = function() return table.remove(stub.stubs, 1) or new_dummy_rl6() end,
    }
  end
  return stub
end

local function teardown_generic_rl6()
  package.loaded['enapter.ucm.generics.rl6'] = false
  package.preload['enapter.ucm.generics.rl6'] = nil
end

return {
  new_dummy_rl6 = new_dummy_rl6,
  setup_generic_rl6 = setup_generic_rl6,
  teardown_generic_rl6 = teardown_generic_rl6,
}
