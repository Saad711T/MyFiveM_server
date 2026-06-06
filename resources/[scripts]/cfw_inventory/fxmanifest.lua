fx_version 'cerulean'
game 'gta5'

name 'cfw_inventory'
author 'saadthelegend'
description 'Standalone inventory'
version '0.1.0'

shared_script 'config.lua'
server_script 'server.lua'
client_script 'client.lua'

ui_page 'web/index.html'

files {
  'web/index.html',
  'web/images/*.png'
}