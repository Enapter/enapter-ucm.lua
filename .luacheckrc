-- https://luacheck.readthedocs.io/en/stable/warnings.html

-- Enapter Rule Engine API
local enapter_api = {
  'inspect',
  enapter = {
    fields = { 'log', 'device', 'register_command_handler' },
  },
  ucm = {
    fields = { 'new' },
  },
  storage = {
    fields = {
      'read',
      'write',
      'remove',
      'err_to_str',
      'enable_error_mode',
      'disable_error_mode',
    },
  },
  modbustcp = {
    fields = {
      'new',
    },
  },
  modbus = {
    fields = {
      'read_coils',
      'read_discrete_inputs',
      'read_holdings',
      'read_inputs',
      'write_coil',
      'write_holding',
      'write_multiple_coils',
      'write_multiple_holdings',
      'err_to_str',
    },
  },
}

stds.enapter = {
  read_globals = enapter_api,
}

std = 'lua53+enapter'

ignore = {
  '212/self', -- allow unused `self`
  '411/ok',
  '411/error',
  '411/err', -- allow to re-define some variables
  '421/err', -- allow to shadow some variables
}
