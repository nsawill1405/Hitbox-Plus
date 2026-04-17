local Rewind = {}

function Rewind.selectSnapshot(snapshots, timestamp)
	if #snapshots == 0 then
		return nil
	end

	local latestPast = nil

	for _, snapshot in snapshots do
		if snapshot.timestamp <= timestamp then
			latestPast = snapshot
		else
			break
		end
	end

	if latestPast ~= nil then
		return latestPast
	end

	return snapshots[1]
end

return Rewind
