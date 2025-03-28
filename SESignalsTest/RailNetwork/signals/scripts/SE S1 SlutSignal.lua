--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE S1 End signal")
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
	SIGNAL_HEAD_NAME 		= "SE S1:"
	-- Set our light node names
	-- Main
	LIGHT_NODE_RED			= "R1"

	-- Initialise global variables
	gHomeSignal 	= true
	gDistanceSignal = false
	gBlockSignal	= false				 	-- is this an intermediate block signal?
	gShuntSignal	= false					-- is this a dwarf signal or not?
	
	BaseInitialise()
	DebugStatus()
end

--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()

end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()
--	DebugPrint("DefaultSetLights()")
	SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		1 )
end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"

--------------------------------------------------------------------------------------
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
function SetSignalState()
	local newSignalState = STATE_STOP
	local newAnimState = ANIMSTATE_STOP

-- Below: Message dispatch & animation trigger. Do not modify unless protocol changes.

	if newSignalState ~= gSignalState then
		DebugPrint("SetSignalState() - signal state changed from " .. gSignalState .. " to " .. newSignalState .. " - sending message" )
		gSignalState = newSignalState
		if gSignalState == STATE_BLOCKED and not gBlockSignal then
			Call( "SendSignalMessage", SIGNAL_STOP, "BLOCKED", -1, 1, 0 )
		else
			Call( "SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0 )
		end
	end
	
	if newAnimState ~= gAnimState then
		DebugPrint("SetSignalState() - signal aspect changed from " .. gAnimState .. " to " .. newAnimState .. " - change lights" )
		gAnimState = newAnimState
		SetLights()
		if gHomeSignal then
			if gSignalState >= STATE_STOP then
				Call( "Set2DMapSignalState", STATE_STOP)
			else
				Call( "Set2DMapSignalState", gSignalState)
			end
		end
	end

	DebugStatus()
end