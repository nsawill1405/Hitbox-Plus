local process = require('@lune/process')
local fs = require('@lune/fs')

local filter = process.args[1]

local specs = {}

local function addSpecIfPresent(specName, modulePath, diskPath)
	if fs.isFile(diskPath) then
		local ok, loaded = pcall(require, modulePath)
		if not ok then
			error(string.format('failed to load %s: %s', specName, tostring(loaded)), 0)
		end

		table.insert(specs, {
			name = specName,
			run = loaded,
		})
	end
end

local function runSpec(spec)
	if type(spec.run) ~= 'function' then
		return false, string.format('spec %s must expose a callable test function', spec.name)
	end

	return pcall(spec.run, function(modulePath)
		return require(string.format('%s%s', process.cwd, modulePath))
	end)
end

local function runSpecs(specEntries, selectedFilter)
	local passed = 0
	local failed = 0
	local failures = {}

	for _, spec in specEntries do
		if selectedFilter == nil or spec.name == selectedFilter then
			local ok, err = runSpec(spec)
			if ok then
				passed += 1
				print(string.format('PASS %s', spec.name))
			else
				failed += 1
				table.insert(failures, string.format('%s: %s', spec.name, tostring(err)))
				warn(string.format('FAIL %s: %s', spec.name, tostring(err)))
			end
		end
	end

	return {
		passed = passed,
		failed = failed,
		failures = failures,
	}
end

addSpecIfPresent('ToolingSpec', 'test/ToolingSpec.luau', './test/ToolingSpec.luau')
addSpecIfPresent('QuerySpec', 'test/QuerySpec.luau', './test/QuerySpec.luau')
addSpecIfPresent('HistorySpec', 'test/HistorySpec.luau', './test/HistorySpec.luau')
addSpecIfPresent('ResolverSpec', 'test/ResolverSpec.luau', './test/ResolverSpec.luau')
addSpecIfPresent('PackageSpec', 'test/PackageSpec.luau', './test/PackageSpec.luau')
addSpecIfPresent('DebugSpec', 'test/DebugSpec.luau', './test/DebugSpec.luau')

table.sort(specs, function(left, right)
	return left.name < right.name
end)

local summary = runSpecs(specs, filter)

print(string.format('Summary: %d passed, %d failed', summary.passed, summary.failed))

if summary.failed > 0 then
	error(table.concat(summary.failures, '\n'), 0)
end
