local Prediction = {}

function Prediction.predict(config, snapshot, request)
	if type(config.predictor) == 'function' then
		return config.predictor(snapshot, request)
	end

	return {
		query = request.query,
		snapshotTimestamp = if snapshot ~= nil then snapshot.timestamp else nil,
	}
end

return Prediction
