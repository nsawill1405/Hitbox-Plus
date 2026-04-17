local Roblox = nil

do
	local ok, loaded = pcall(require, '@lune/roblox')
	if ok then
		Roblox = loaded
	end
end

return {
	Vector3 = if Roblox ~= nil then Roblox.Vector3 else Vector3,
	CFrame = if Roblox ~= nil then Roblox.CFrame else CFrame,
}
