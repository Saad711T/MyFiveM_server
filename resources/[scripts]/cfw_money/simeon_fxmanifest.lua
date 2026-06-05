fx_version 'cerulean'
game 'gta5'

name 'simeon_ownership'
author 'saadthelegend'
description 'Buy cars at Simeon (NUI), spawn owned cars at multiple locations, with map blips'
version '2.0.0'

dependency 'cfw_money'

ui_page 'html/index.html'

server_scripts {
    'server.lua'
}

client_scripts {
    'config.lua',
    'client.lua'
}

files {
    'vehicles.json',
    'html/index.html',
    'html/style.css',
    'html/app.js'
}
