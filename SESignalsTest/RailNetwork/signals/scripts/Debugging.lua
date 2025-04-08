-- Set the location to generate a debug log file:
local logFile = io.open("Assets/SummerADDE/SESignalsTest/debug_log.txt", "a")

-------------------------------------------
-- Set the following values to "true" to generate debug reports. Otherwise, set to "false".
DEBUG = true
DEBUG_STATUS = false

-- Add "DebugStatus()" right after SetSignalState(), InitialiseSignal() or OnSignalMessage() to generate debug reports for certain behavior.
-------------------------------------------
-- Do not change below.

function DebugPrint(message)
	if DEBUG and logFile then
		local id = "Unknown"
		local temp = Call("GetId")
		if temp ~= nil and type(temp) == "string" then
			id = temp
		end
		local signaltype = "Unknown:"
		if type(SIGNAL_HEAD_NAME) == "string" and SIGNAL_HEAD_NAME ~= "" then
			signaltype = SIGNAL_HEAD_NAME
		elseif type(SIGNAL_SHUNT_NAME) == "string" and SIGNAL_SHUNT_NAME ~= "" then
			signaltype = SIGNAL_SHUNT_NAME
		end

		logFile:write(os.date("[%H:%M:%S] ") .. "[" .. signaltype .. id .. "] " .. tostring(message) .. "\n")
		logFile:flush()
	end
end

function DebugStatus()
	if not DEBUG_STATUS then return end
	DebugPrint("------ Signal Debug Info ------")
	DebugPrint("Signal ID: " .. tostring(Call("GetId")))
	DebugPrint("gSignalState: " .. tostring(gSignalState))
	DebugPrint("gExpectState: " .. tostring(gExpectState))
	DebugPrint("gConnectedLink: " .. tostring(gConnectedLink))
	DebugPrint("gCallOn: " .. tostring(gCallOn))
	DebugPrint("gOccupationTable[0]: " .. tostring(gOccupationTable and gOccupationTable[0] or "nil"))
end
