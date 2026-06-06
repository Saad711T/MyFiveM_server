fx_version 'cerulean'
game 'gta5'

name 'cfw_spawn_map'
author 'saadthelegend'
description 'Interactive GTA map spawn selector. Self-contained HTML (embedded image). Crash-safe with PD fallback.'
version '2.0.0'

dependency 'spawnmanager'

ui_page 'web/index.html'

client_script 'client.lua'

files {
  'web/index.html'
}
