fx_version 'cerulean'
description 'ADVANCED HUD SYSTEM'
author 'TS SCRIPTS | THOMAS | LILPUP3'
version '2.0.0'
lua54 'yes'
game 'gta5'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua', -- COMMENT OUT IF USING QBCORE
    'config.lua'
}

client_scripts {
    'client/**/*',
}

server_scripts {
    'server/**/*',
}

ui_page 'web/build/index.html'

files {
	'web/build/index.html',
	'web/build/**/*',
    'web/assets/**/*',
}
