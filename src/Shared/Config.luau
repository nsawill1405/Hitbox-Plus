local DEFAULT_CONFIG = table.freeze({
	history = {
		retentionSeconds = 0.25,
	},
	validation = {
		maxLatencySeconds = 0.2,
		maxDistance = math.huge,
		allowFriendlyFire = false,
		duplicateWindowSeconds = 0,
		targetCooldownSeconds = 0,
		lineOfSight = false,
	},
	query = {
		maxTargets = math.huge,
	},
	debug = {
		enabled = false,
	},
})

local Config = {}

local function clone(value)
	if type(value) ~= 'table' then
		return value
	end

	local copy = {}
	for key, nested in value do
		copy[key] = clone(nested)
	end

	return copy
end

local function deepMerge(defaults, overrides)
	local merged = clone(defaults)

	for key, value in overrides do
		if type(value) == 'table' and type(merged[key]) == 'table' then
			merged[key] = deepMerge(merged[key], value)
		else
			merged[key] = value
		end
	end

	return merged
end

function Config.normalize(config)
	local source = config or {}
	local merged = deepMerge(DEFAULT_CONFIG, source)

	merged.timeSource = source.timeSource or os.clock

	return merged
end

return Config
