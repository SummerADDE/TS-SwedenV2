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
	SIGNAL_HEAD_NAME 		= "SE F3:"
	-- Set our light node names
	-- Distance
	LIGHT_NODE_GREEN2		= "G1"
	LIGHT_NODE_WHITE		= "W1"
	LIGHT_NODE_GREEN3		= "G2"
	gHomeSignal = false
	gDistanceSignal = true
	BaseInitialise()
end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 Repeater CommonScript.lua"