local QueryType = table.freeze({
	Box = 'box',
	Radius = 'radius',
	Cast = 'cast',
})

local RejectReason = table.freeze({
	SameTeam = 'same-team',
	MaxLatency = 'max-latency',
	MaxDistance = 'max-distance',
	LineOfSight = 'line-of-sight',
	DuplicateAttack = 'duplicate-attack',
	TargetCooldown = 'target-cooldown',
	MissingSnapshot = 'missing-snapshot',
	UnsupportedQuery = 'unsupported-query',
})

return table.freeze({
	QueryType = QueryType,
	RejectReason = RejectReason,
})
