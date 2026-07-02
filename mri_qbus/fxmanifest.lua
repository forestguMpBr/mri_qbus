fx_version 'cerulean'
game 'gta5'

author      'mri'
description 'mri_qbus - Sistema de Motorista de Ônibus com XP e Ranking'
version     '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'utils.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

lua54 'yes'
