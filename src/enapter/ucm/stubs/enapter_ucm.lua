local builder = require('enapter.ucm.stubs.builder')

local function new_dummy_ucm_peer()
  return {
    execute_command = function() return 'completed', {} end,
  }
end
new_dummy_ucm_peer = builder.wrap_new(new_dummy_ucm_peer)

local function setup_enapter_ucm()
  local stub = { stubs = {} }
  _G.ucm = {
    new = function() return table.remove(stub.stubs, 1) or new_dummy_ucm_peer() end,
  }
  return stub
end

local function teardown_enapter_ucm() _G.ucm = nil end

return {
  new_dummy_ucm_peer = new_dummy_ucm_peer,
  setup_enapter_ucm = setup_enapter_ucm,
  teardown_enapter_ucm = teardown_enapter_ucm,
}
