--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_HEAD_NAME == nil) then
		SIGNAL_HEAD_NAME = ""
	end
	-- Add support for custom text & numbers to child objects.
	local number = Call ("GetId")
	Call ("Post:SetText", number, 0)
	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	SIGNAL_HEAD_NAME 		= "SE DV6:"
	--------------------------------------------------------------------------------------
	-- LIGHTS
	LIGHT_NODE_RED			= "R1"
	LIGHT_NODE_GREEN1		= "G1"
	LIGHT_NODE_WHITE1		= "W1"
	LIGHT_NODE_WHITE2		= "W2"
	LIGHT_NODE_WHITE3		= "W3"
	LIGHT_NODE_WHITE4		= "W4"
	DebugPrint("DwarfSignal")
	gHomeSignal 	= true
	gDistanceSignal = false
	BaseInitialise()
end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 Shunt CommonScript.lua"