--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE F3 Distant signal")
	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_HEAD_NAME == nil) then
		SIGNAL_HEAD_NAME = ""
	end
	-- Add support for custom text & numbers to child objects.
	local number = Call("GetId")
	if type(number) == "string" or type(number) == "number" then
		Call("Post:SetText", number, 0)
	end
	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	SIGNAL_HEAD_NAME 		= "SE F3:"
	-- Set our light node names
	-- Distance
	LIGHT_NODE_GREEN2		= "G1"
	LIGHT_NODE_WHITE		= "W1"
	LIGHT_NODE_GREEN3		= "G2"

	-- Initialise global variables
	gHomeSignal 	= false
	gDistanceSignal = true
	gBlockSignal	= false				 	-- is this an intermediate block signal?
	gShuntSignal	= false					-- is this a dwarf signal or not?
	
	BaseInitialise()
	DebugStatus()
end

--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()
	if (gExpectState == STATE_GO) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )
	elseif (gExpectState == STATE_SLOW) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	gLightFlashOn )
	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )
	end
end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()

end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"