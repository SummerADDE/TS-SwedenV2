--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_SHUNT_NAME == nil) then
		SIGNAL_SHUNT_NAME = ""
	end
	-- Add support for custom text & numbers to child objects.
	local number = Call ("GetId")
	Call ("Post:SetText", number, 0)
	-- This is a post signal, so need reference to the attached signal head to switch lights on and off
	SIGNAL_SHUNT_NAME 		= "SE DV7:"
	-- Set our light node names
	-- Shunt
	LIGHT_NODE_RED			= "R1"
	LIGHT_NODE_GREEN1		= "G1"
	LIGHT_NODE_GREEN2		= "G2"
	LIGHT_NODE_WHITE1		= "W1"
	LIGHT_NODE_WHITE2		= "W2"
	LIGHT_NODE_WHITE3		= "W3"
	LIGHT_NODE_WHITE4		= "W4"

-- Initialise global variables
gHomeSignal 	= true
gDistanceSignal = true
gBlockSignal	= true				 	-- is this an intermediate block signal?
gShuntSignal	= true					-- is this a dwarf signal or not?
	BaseInitialise()
end

--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()
--	DebugPrint("SetLights()")
	if (gAnimState == ANIMSTATE_GO) then
		if gExpectState == STATE_GO then -- Kör80, Vänta Kör80
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		1 )
		else --Kör80, Vänta kör40/stop
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		gLightFlashOn )		
		end
	elseif (gAnimState == ANIMSTATE_SLOW) then
		if gExpectState == STATE_GO or gExpectState == STATE_SLOW then --Kör40, vänta, Kör40
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		1 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )
		else --Kör40, Vänta stopp
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		gLightFlashOn )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )		
		end
	else	-- stop or blocked
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			1 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		0 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )
	end
end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()
	
	if (gAnimState == ANIMSTATE_GO or gAnimState == ANIMSTATE_SLOW or gAnimState == ANIMSTATE_CALLON) then
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		0 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		1 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		0 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		1 )
	elseif (gAnimState == ANIMSTATE_SHUNT) then
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE1, 		1 )
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE2, 		0 )	-- o.
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE3, 		0 )	-- .o
		SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_WHITE4, 		1 )
	elseif (gAnimState == ANIMSTATE_UNPROTECTED) then
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



require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for TAB Funcionality.
-- Only to be used on main signals.
function GetSignalState()
	return gSignalState
end

--------------------------------------------------------------------------------------
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
function SetSignalState()
	local newSignalState = STATE_GO
	local newAnimState = ANIMSTATE_GO
	if (gCallOn == 1) then
		gYardEntry[gConnectedLink] = false
		gShuntLink = 0
		if gOccupationTable[gConnectedLink] > 0 then
			-- Train in block. Show slow.
			newAnimState = ANIMSTATE_SHUNT
			newSignalState = STATE_SHUNT
		else
			newAnimState = ANIMSTATE_CALLON
			newSignalState = STATE_CALLON
		end
	elseif gBlockSignal then
		gYardEntry[gConnectedLink] = false
		gShuntLink = 0
		if gOccupationTable[0] > 0 and gGoingForward then
			newSignalState = STATE_STOP
			newAnimState = ANIMSTATE_STOP
		elseif gOccupationTable[0] > 0 or gLinkState[0] == STATE_BLOCKED then
			newSignalState = STATE_BLOCKED
			newAnimState = ANIMSTATE_STOP
		end
	elseif gOccupationTable[0] > 0 and not gGoingForward then
		-- might be an entry signal with a consist going backwards into a block
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_BLOCKED
	elseif gConnectedLink == -1 or gOccupationTable[0] > 0 or gOccupationTable[gConnectedLink] > 0 then
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_STOP
	elseif not gLinkState[gConnectedLink] == STATE_GO or not gLinkState[gConnectedLink] == STATE_SLOW then
		-- Check if next signal is at stop, show a slow signal if that is the case.
			newSignalState = STATE_SLOW
			newAnimState = ANIMSTATE_SLOW
	end

-- DO NOT CHANGE BELOW - Handles sending messages and setting up the correct aspects.

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

end