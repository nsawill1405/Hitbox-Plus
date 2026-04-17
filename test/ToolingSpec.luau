return function()
	local fs = require('@lune/fs')

	local requiredFiles = {
		'aftman.toml',
		'wally.toml',
		'stylua.toml',
		'selene.toml',
		'README.md',
		'examples/SandboxServer.luau',
		'examples/SandboxClient.luau',
	}

	for _, path in requiredFiles do
		assert(fs.isFile(path), string.format('missing repo file %s', path))
	end
end
