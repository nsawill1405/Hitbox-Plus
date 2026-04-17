local Process = nil

do
	local ok, loaded = pcall(require, '@lune/process')
	if ok then
		Process = loaded
	end
end

local function loadShared(moduleName, relativePath)
	if script ~= nil and script.Parent ~= nil then
		return require(script.Parent.Parent.Shared[moduleName])
	end

	return require(string.format('%s%s', Process.cwd, relativePath))
end

local SpatialMath = loadShared('SpatialMath', 'src/Shared/SpatialMath.luau')
local Types = loadShared('Types', 'src/Shared/Types.luau')

local Validators = {}
Validators.__index = Validators

local function pruneSeenAttacks(self, serverTime)
	if self.duplicateWindowSeconds <= 0 then
		return
	end

	for attackId, seenAt in self.seenAttacks do
		if serverTime - seenAt > self.duplicateWindowSeconds then
			self.seenAttacks[attackId] = nil
		end
	end
end

function Validators.create(config)
	local source = config or {}

	return setmetatable({
		maxLatencySeconds = source.maxLatencySeconds or 0.2,
		maxDistance = source.maxDistance or math.huge,
		allowFriendlyFire = source.allowFriendlyFire == true,
		duplicateWindowSeconds = source.duplicateWindowSeconds or 0,
		targetCooldownSeconds = source.targetCooldownSeconds or 0,
		lineOfSight = source.lineOfSight == true,
		seenAttacks = {},
		targetHitTimes = {},
	}, Validators)
end

function Validators:validateRequest(request)
	local latencySeconds = request.serverTime - request.clientTime
	if latencySeconds > self.maxLatencySeconds then
		return false, Types.RejectReason.MaxLatency, {
			latencySeconds = latencySeconds,
		}
	end

	pruneSeenAttacks(self, request.serverTime)

	if self.duplicateWindowSeconds > 0 then
		local seenAt = self.seenAttacks[request.attackId]
		if seenAt ~= nil and request.serverTime - seenAt <= self.duplicateWindowSeconds then
			return false, Types.RejectReason.DuplicateAttack, {
				seenAt = seenAt,
			}
		end

		self.seenAttacks[request.attackId] = request.serverTime
	end

	return true
end

function Validators:validateCandidate(request, candidate, snapshot)
	if
		not self.allowFriendlyFire
		and candidate.team ~= nil
		and candidate.team == request.attackerTeam
	then
		return false, Types.RejectReason.SameTeam
	end

	if request.attackerPosition ~= nil then
		local distance = SpatialMath.distance(request.attackerPosition, candidate.position)
		if distance > self.maxDistance then
			return false, Types.RejectReason.MaxDistance, {
				distance = distance,
			}
		end

		if self.lineOfSight and snapshot.occluders ~= nil then
			for _, occluder in snapshot.occluders do
				if
					SpatialMath.segmentIntersectsSphere(
						request.attackerPosition,
						candidate.position,
						occluder.position,
						SpatialMath.entityRadius(occluder)
					)
				then
					return false, Types.RejectReason.LineOfSight
				end
			end
		end
	end

	if self.targetCooldownSeconds > 0 then
		local key = string.format('%s::%s', tostring(request.attackerId), tostring(candidate.id))
		local lastAcceptedAt = self.targetHitTimes[key]
		if
			lastAcceptedAt ~= nil
			and request.serverTime - lastAcceptedAt <= self.targetCooldownSeconds
		then
			return false,
				Types.RejectReason.TargetCooldown,
				{
					lastAcceptedAt = lastAcceptedAt,
				}
		end
	end

	return true,
		nil,
		{
			distance = if request.attackerPosition ~= nil
				then SpatialMath.distance(request.attackerPosition, candidate.position)
				else nil,
		}
end

function Validators:markAccepted(request, candidate)
	if self.targetCooldownSeconds <= 0 then
		return
	end

	local key = string.format('%s::%s', tostring(request.attackerId), tostring(candidate.id))
	self.targetHitTimes[key] = request.serverTime
end

return Validators
