# Enapter UCM Stdlib

[![Busted](https://github.com/enapter/enapter-ucm.lua/actions/workflows/busted.yml/badge.svg)]()
[![Luacheck](https://github.com/enapter/enapter-ucm.lua/actions/workflows/luacheck.yml/badge.svg)]()
[![StyLua](https://github.com/enapter/enapter-ucm.lua/actions/workflows/stylua.yml/badge.svg)]()
[![Coverage Status](https://coveralls.io/repos/github/Enapter/enapter-ucm.lua/badge.svg?branch=main)](https://coveralls.io/github/Enapter/enapter-ucm.lua?branch=main)

This repository contains libraries for development and test Enapter UCMs.

## Config
`enapter.ucm.config` helps with ucm configurations. It [registers commands](https://developers.enapter.com/docs/reference/ucm/enapter#enapterregister_command_handler) to read and write UCM configuration into persistent storage.

### Example
Take for example an UCM with two configuration arguments:
- `api_url` — string with API URL. It has default vaule to public api host "api.units.com", but can be changed to use another server for testing or security purpose.
- `unit_id` — integer with connected unit ID. It should be set manually, because it is individual per UCM. So, it is required config option.

In `manifest.yml` (the following commands should be described)[https://developers.enapter.com/docs/reference#commands]:
```yml
commands:
  write_configuration:
    populate_values_command: read_configuration
    display_name: Configure
    group: config
    ui:
      icon: wrench-outline
    arguments:
      api_url:
        display_name: API URL
        type: integer
        default: api.units.com
      unit_id:
        display_name: Unit ID
        type: integer
        required: true
  read_configuration:
    display_name: Read Configuration
    group: config
    ui:
      icon: wrench-outline
```

And in Lua config should be initialised:
```lua
local API_URL_CONFIG = 'api_url'
local UNI_ID_CONFIG = 'unit_id'

config.init({
    [API_URL_CONFIG] = { type = 'string', default = 'api.units.com' },
    [UNI_ID_CONFIG] = { type = 'number', require = true }
})
```

After that commands to read/write config are registered and values can be get in Lua code via `config.read` and `config.read_all` methods.


## Generics

`enapter.ucm.generics` provides helpers to communicate with [Enapter Generic-IO](https://marketplace.enapter.com/blueprints/generic_io).

### RL6

```lua
local rl6 = require('enapter.ucm.generics.rl6')

local power_relay = rl6.new() -- creates a new instance of relay contact
power_relay:setup('AABBCC', 5) -- setup to operate on contact 5 of generic RL-6 UCM with hardware id AABBCC
power_relay:open() -- open contact
power_relay:close() -- close contact
local power_is_on = power_relay:is_closed() -- check contact status
```

### CAN

```lua
local can_pkg = require('enapter.ucm.generics.can')

local can = can_pkg.new() -- creates a new instance of client to generic CAN UCM
local err = can:setup('AABBCC', subscriptions) -- setup to operate with UCM with hardware id AABBCC (about subscriptions see below)
local payload, err = can:get('telemetry') -- get can messages for 'my_subscription' messages
```

#### CAN Subscriptions
Subscriptions is a table:
  - key is a name of subscritption
  - value is an array of talbes describig CAN messages parsing rules

The parsing rule contains:
  - `name` or `names` of parsed values (one CAN message can contain more then one value).
  - CAN message ID `msg_id`.
  - `parser` function which received CAN message and return parsed value(s).
  - `multi_msg` flag if parser function receives array of message.

```lua
subscriptoins = {
  example = {
    { name = 'fw_ver', msg_id = 0x318, parser = software_version },
    {
      name = 'dump_0x400',
      msg_id = 0x400,
      multi_msg = true,
      parser = dump_0x400,
    },
  }
}

function dump_0x400(datas)
  local str_0x400 = nil
  for _, data in pairs(datas) do
    str_0x400 = str_0x400 or ''
    str_0x400 = str_0x400 .. ' ' .. data
  end
  return str_0x400
end

function software_version(data)
  data = convert_input_data(data)
  return string.format('%u.%u.%u', string.byte(data, 1), string.byte(data, 2), string.byte(data, 3))
end

--- Converts message from Generic CAN to bytes
-- Generic CAN passes message as a 16-char string where every 2 char represent a byte in hex format.
function convert_input_data(data)
  local v = { string.unpack('c2c2c2c2c2c2c2c2', data) }
  local vv = {}
  for j = 1, 8 do
    vv[j] = tonumber(v[j], 16)
  end
  return string.pack('BBBBBBBB', table.unpack(vv))
end
```
