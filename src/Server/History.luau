local Rewind = require('./Rewind.luau')

local History = {}
History.__index = History

local function sortSnapshots(snapshots)
	table.sort(snapshots, function(left, right)
		return left.timestamp < right.timestamp
	end)
end

function History.create(config)
	local source = config or {}

	return setmetatable({
		retentionSeconds = source.retentionSeconds or source.retention or 0.25,
		snapshots = {},
	}, History)
end

function History:push(snapshot)
	assert(type(snapshot) == 'table', 'snapshot must be a table')
	assert(type(snapshot.timestamp) == 'number', 'snapshot.timestamp must be a number')
	assert(type(snapshot.entities) == 'table', 'snapshot.entities must be a table')

	table.insert(self.snapshots, snapshot)
	sortSnapshots(self.snapshots)

	local newestTimestamp = self.snapshots[#self.snapshots].timestamp
	local retained = {}

	for _, candidate in self.snapshots do
		if newestTimestamp - candidate.timestamp <= self.retentionSeconds then
			table.insert(retained, candidate)
		end
	end

	self.snapshots = retained

	return snapshot
end

function History:getClosest(timestamp)
	return Rewind.selectSnapshot(self.snapshots, timestamp)
end

function History:getSnapshots()
	return self.snapshots
end

return History
