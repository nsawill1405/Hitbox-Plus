local Results = {}

local function baseResult(entity)
	return {
		id = entity.id,
		entity = entity,
	}
end

function Results.acceptHit(entity, metadata)
	local accepted = baseResult(entity)
	accepted.accepted = true
	accepted.metadata = metadata or {}

	return accepted
end

function Results.rejectHit(entity, reason, metadata)
	local rejected = baseResult(entity)
	rejected.accepted = false
	rejected.reason = reason
	rejected.metadata = metadata or {}

	return rejected
end

function Results.createResolution(payload)
	return {
		ok = payload.ok ~= false,
		query = payload.query,
		hits = payload.hits or {},
		rejections = payload.rejections or {},
		metadata = payload.metadata or {},
	}
end

function Results.createFailure(reason, metadata)
	return {
		ok = false,
		reason = reason,
		hits = {},
		rejections = {},
		metadata = metadata or {},
	}
end

return Results
