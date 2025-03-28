--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE H4 Signal")
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
	SIGNAL_HEAD_NAME 		= "SE H4:"
	-- Set our light node names
	-- Main
	LIGHT_NODE_GREEN		= "G1"
	LIGHT_NODE_RED			= "R1"
	LIGHT_NODE_GREEN2		= "G2"
	LIGHT_NODE_WHITE		= "W1"

	-- Initialise global variables
	gHomeSignal 	= true
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
	if gHomeSignal and (gSignalState ~= STATE_GO) then
		return
	end
	if (gExpectState == STATE_GO) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	gLightFlashOn )
	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
	end
end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()
--	DebugPrint("DefaultSetLights()")
	if (gAnimState == ANIMSTATE_GO) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )

	elseif (gAnimState == ANIMSTATE_SLOW) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )

	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
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
	
	-- Call-on mode logic
	if gCallOn == 1 then
		gYardEntry[gConnectedLink] = false
		gShuntLink = 0
		if type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0 then
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
		if Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
			-- Unprotected yard.
			gShuntLink = 1
			gYardEntry[gConnectedLink] = true
			newAnimState = ANIMSTATE_UNPROTECTED
			newSignalState = STATE_UNPROTECTED		
		else
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_BLOCKED
		end
	elseif gConnectedLink == -1 or gOccupationTable[0] > 0 or (type(gConnectedLink) == "number" and type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0) then
		-- no route or occupied
		if Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
			-- Unprotected yard.
			gShuntLink = 1
			gYardEntry[gConnectedLink] = true
			newAnimState = ANIMSTATE_UNPROTECTED
			newSignalState = STATE_UNPROTECTED		
		else
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_STOP
		end
	elseif gConnectedLink > 0 then
		if safeLink and gLinkState[gConnectedLink] == STATE_BLOCKED then
			-- exit signal facing an occupied block
			if Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
				-- Unprotected yard.
				gShuntLink = 1
				gYardEntry[gConnectedLink] = true
				newAnimState = ANIMSTATE_UNPROTECTED
				newSignalState = STATE_UNPROTECTED		
			else
				gShuntLink = 0
				gYardEntry[gConnectedLink] = false
				newAnimState = ANIMSTATE_STOP
				newSignalState = STATE_STOP
			end
		elseif Call("GetLinkFeatherChar", gConnectedLink) == 49 then
			-- Check if the Character field for this link is set to "1". if so,  Check if next signal is at stop, show a stop signal if that is the case.
			gYardEntry[gConnectedLink] = false
			gShuntLink = 0
			if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
				if Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
					-- diverging route, signal slow
					newAnimState = ANIMSTATE_SLOW
					newSignalState = STATE_SLOW
				else
					newAnimState = ANIMSTATE_GO
					newSignalState = STATE_GO
				end
			else
				newAnimState = ANIMSTATE_STOP
				newSignalState = STATE_STOP
			end		
		elseif Call ( "GetLinkApproachControl", gConnectedLink ) ~= 0 then
			-- Check if next signal is at stop, show a slow signal if that is the case.
			gYardEntry[gConnectedLink] = false
			gShuntLink = 0
			if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
				newSignalState = STATE_GO
				newAnimState = ANIMSTATE_GO
			else
				newSignalState = STATE_SLOW
				newAnimState = ANIMSTATE_SLOW
			end
		elseif Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
			-- diverging route, signal slow
			gYardEntry[gConnectedLink] = false
			gShuntLink = 0
			newSignalState = STATE_SLOW
			newAnimState = ANIMSTATE_SLOW
		elseif Call("GetLinkFeatherChar", gConnectedLink) == 50 then
			-- Check if the Character field for this link is set to "2". if so, Shunt-only route. Only use shunt signal.
			if Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
				-- Unprotected yard.
				gShuntLink = 1
				gYardEntry[gConnectedLink] = true
				newAnimState = ANIMSTATE_UNPROTECTED
				newSignalState = STATE_UNPROTECTED		
			else
				gShuntLink = 0
				gYardEntry[gConnectedLink] = false
				newAnimState = ANIMSTATE_CALLON
				newSignalState = STATE_CALLON		
			end
		end
	end

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