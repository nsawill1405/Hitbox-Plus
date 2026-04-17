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

	local sandboxServer = fs.readFile('examples/SandboxServer.luau')
	local sandboxClient = fs.readFile('examples/SandboxClient.luau')

	assert(
		string.find(sandboxServer, 'HitboxPlusSandboxRemotes', 1, true) ~= nil,
		'sandbox server example should reference HitboxPlusSandboxRemotes'
	)
	assert(
		string.find(sandboxServer, 'DebugPayload', 1, true) ~= nil,
		'sandbox server example should reference DebugPayload'
	)
	assert(
		string.find(sandboxServer, 'TriggerAttack', 1, true) ~= nil,
		'sandbox server example should reference TriggerAttack'
	)
	assert(
		string.find(sandboxServer, 'debug = {', 1, true) ~= nil,
		'sandbox server example should configure debug options'
	)
	assert(
		string.find(sandboxServer, 'HitboxPlusDebug', 1, true) ~= nil,
		'sandbox server example should reference the shared debug folder'
	)
	assert(
		string.find(sandboxServer, 'runAttack', 1, true) ~= nil,
		'sandbox server example should define a retriggerable attack'
	)
	assert(
		string.find(sandboxServer, 'AttackerDummy', 1, true) ~= nil,
		'sandbox server example should define sandbox dummy setup'
	)

	assert(
		string.find(sandboxClient, 'HitboxPlusSandboxRemotes', 1, true) ~= nil,
		'sandbox client example should reference HitboxPlusSandboxRemotes'
	)
	assert(
		string.find(sandboxClient, 'DebugPayload', 1, true) ~= nil,
		'sandbox client example should reference DebugPayload'
	)
	assert(
		string.find(sandboxClient, 'client:renderDebugPayload', 1, true) ~= nil,
		'sandbox client example should render incoming debug payloads'
	)
	assert(
		string.find(sandboxClient, 'TriggerAttack', 1, true) ~= nil,
		'sandbox client example should reference TriggerAttack'
	)
	assert(
		string.find(sandboxClient, 'debug = {', 1, true) ~= nil,
		'sandbox client example should configure debug options'
	)
	assert(
		string.find(sandboxClient, 'HitboxPlusClientDebug', 1, true) ~= nil,
		'sandbox client example should reference the local debug folder'
	)
	assert(
		string.find(sandboxClient, 'InputBegan', 1, true) ~= nil,
		'sandbox client example should listen for retrigger input'
	)
end
