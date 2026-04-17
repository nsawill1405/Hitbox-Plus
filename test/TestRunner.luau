local TestRunner = {}

local function runSpec(spec)
	if type(spec.run) ~= 'function' then
		return false, string.format('spec %s must expose a callable test function', spec.name)
	end

	return pcall(spec.run)
end

function TestRunner.run(specs, filter)
	local passed = 0
	local failed = 0
	local failures = {}

	for _, spec in specs do
		if filter == nil or spec.name == filter then
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

return TestRunner
