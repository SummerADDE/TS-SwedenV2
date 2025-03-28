--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE S1 Stop signal")
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
	gShuntSignal	= true					-- is this a dwarf signal or not?
	
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
	if (gAnimState == ANIMSTATE_GO) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		0 )

	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		1 )
	end
end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"

--------------------------------------------------------------------------------------
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
function SetSignalState()
	local newSignalState = STATE_GO
	local newAnimState = ANIMSTATE_GO

	-- Check if gConnectedLink is safe to use
	local safeLink = type(gConnectedLink) == "number" and gConnectedLink >= 0
	
	gYardEntry[gConnectedLink] = false
	gShuntLink = 0
	if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
		newAnimState = ANIMSTATE_GO
		newSignalState = STATE_GO
	else
		newAnimState = ANIMSTATE_STOP
		newSignalState = STATE_STOP
	end

-- Below: Message dispatch & animation trigger. Do not modify unless protocol changes.
	
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