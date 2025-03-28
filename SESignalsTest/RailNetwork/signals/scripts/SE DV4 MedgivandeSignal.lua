--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE DV4 Medgivandesignal")
	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_SHUNT_NAME == nil) then
		SIGNAL_SHUNT_NAME = ""
	end
	-- Add support for custom text & numbers to child objects.
	local number = Call("GetId")
	if type(number) == "string" or type(number) == "number" then
		Call("Post:SetText", number, 0)
	end
	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	SIGNAL_SHUNT_NAME 		= "SE DV4:"
	-- Set our light node names
	-- Shunt
	LIGHT_NODE_WHITE1		= "W1"
	LIGHT_NODE_WHITE2		= "W2"
	LIGHT_NODE_WHITE3		= "W3"
	LIGHT_NODE_WHITE4		= "W4"

	-- Initialise global variables
	gHomeSignal 	= false
	gDistanceSignal = true
	gBlockSignal	= false				 	-- is this an intermediate block signal?
	gShuntSignal	= false					-- is this a dwarf signal or not?

	if not gHomeSignal then
		Call("SetLinkAspect", 0, 0)
	end
		
	BaseInitialise()
	DebugStatus()
end

--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()
	if (gExpectState == STATE_GO or gExpectState == STATE_SLOW or gExpectState == STATE_CALLON) then
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		0 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		1 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		0 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		1 )
	elseif (gExpectState == STATE_SHUNT) then
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		1 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		0 )	-- o.
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		0 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		1 )
	elseif (gExpectState == STATE_UNPROTECTED) then
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		0 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		1 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		1 )	-- o.
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		0 )
	else
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		0 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		0 )	-- ..
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		1 )	-- oo
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		1 )
	end
end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()

end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"
