--====================================================================================
-- All work by jojos38, Titch2000, Preston (Cobalt)
-- You have no permission to edit, redistribute or upload. Contact us for more info!
--====================================================================================



local M = {}

-- ============= VARIABLES =============
local currentInputs = {}
local lastInputs = {}
local inputsToSend = {}
local remoteGear
-- ============= VARIABLES =============

local translationTable = {
	['R'] = -1,
	['N'] = 0,
	['P'] = 1,
	['D'] = 2,
	['S'] = 3,
	['2'] = 4,
	['1'] = 5,
	['M'] = 6
}

local function applyGear(data) --TODO: add handling for mismatched gearbox types between local and remote vehicle
	if electrics.values.isShifting then return end
	if not electrics.values.gearIndex or electrics.values.gear == data then return end
	local gearboxType = (powertrain.getDevice("gearbox") or powertrain.getDevice("frontMotor") or powertrain.getDevice("rearMotor") or powertrain.getDevice("mainMotor") or "none").type
	if gearboxType == "manualGearbox" or gearboxType == "sequentialGearbox" then
		local index = tonumber(data)
		if not index then return end
		controller.mainController.shiftToGearIndex(index)
	elseif gearboxType == "dctGearbox" or gearboxType == "cvtGearbox" or gearboxType == "automaticGearbox" or gearboxType == "electricMotor" then
		local remoteGearMode = string.sub(data, 1, 1)
		local localGearMode = string.sub(electrics.values.gear, 1, 1)
		local remoteIndex = tonumber(string.sub(data, 2))
		if remoteGearMode == 'M' and localGearMode == 'M' then
			if electrics.values.gearIndex < remoteIndex then
				controller.mainController.shiftUp()
			elseif electrics.values.gearIndex > remoteIndex then
				controller.mainController.shiftDown()
			end
		else
			controller.mainController.shiftToGearIndex(translationTable[remoteGearMode])
		end
	end
end

local function updateGFX()
	if v.mpVehicleType == 'R' and remoteGear then applyGear(remoteGear) end
end


local function getInputs() --TODO: uncomment the difference checking for final release, currently commented because the current release will not apply inputs if all the inputs are not present in the data
	currentInputs = {
		s = electrics.values.steering_input and math.floor(electrics.values.steering_input * 1000) / 1000,
		t = electrics.values.throttle and math.floor(electrics.values.throttle * 1000) / 1000,
		b = electrics.values.brake and math.floor(electrics.values.brake * 1000) / 1000,
		p = electrics.values.parkingbrake and math.floor(electrics.values.parkingbrake * 1000) / 1000,
		c = electrics.values.clutch and math.floor(electrics.values.clutch * 1000) / 1000,
		g = electrics.values.gear
	}
	--for k,v in pairs(currentInputs) do
	--	if currentInputs[k] ~= lastInputs[k] then
	--		inputsToSend[k] = currentInputs[k]
	--	end
	--end
	--lastInputs = currentInputs

	--obj:queueGameEngineLua("MPInputsGE.sendInputs(\'"..jsonEncode(inputsToSend).."\', "..obj:getID()..")") -- Send it to GE lua
	obj:queueGameEngineLua("MPInputsGE.sendInputs(\'"..jsonEncode(currentInputs).."\', "..obj:getID()..")") -- Send it to GE lua
end


local function applyInputs(data)
	local decodedData = jsonDecode(data)
	if not decodedData then return end
	if decodedData.s then input.event("steering", decodedData.s, FILTER_PAD) end -- using gamepad filter for better smoothing
	if decodedData.t then input.event("throttle", decodedData.t, FILTER_DIRECT) end
	if decodedData.b then input.event("brake", decodedData.b, FILTER_DIRECT) end
	if decodedData.p then input.event("parkingbrake", decodedData.p, FILTER_DIRECT) end
	if decodedData.c then input.event("clutch", decodedData.c, FILTER_DIRECT) end
	if decodedData.g then remoteGear = decodedData.g end
end


M.updateGFX = updateGFX
M.getInputs   = getInputs
M.applyInputs = applyInputs


return M
