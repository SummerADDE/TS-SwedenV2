--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE DV4 Shunt signal")
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
	
	if (gAnimState == ANIMSTATE_GO or gAnimState == ANIMSTATE_CALLON) then
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
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
function SetSignalState()
	-- Define new signal and animation state
	local newSignalState = STATE_GO
	local newAnimState = ANIMSTATE_GO

	-- Check if gConnectedLink is safe to use
	local safeLink = type(gConnectedLink) == "number" and gConnectedLink >= 0
	
	-- Call-on mode logic
	if gCallOn == 1 then
		if safeLink then gYardEntry[gConnectedLink] = false end
		gShuntLink = 0
		-- If train in block, show shunt
		if safeLink and type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0 then
			newAnimState = ANIMSTATE_SHUNT
			newSignalState = STATE_SHUNT
		else
			newAnimState = ANIMSTATE_CALLON
			newSignalState = STATE_CALLON
		end

	-- If this is a block signal
	elseif gBlockSignal then
		if safeLink then gYardEntry[gConnectedLink] = false end
		gShuntLink = 0
		if gOccupationTable[0] > 0 and gGoingForward then
			newSignalState = STATE_STOP
			newAnimState = ANIMSTATE_STOP
		elseif gOccupationTable[0] > 0 or gLinkState[0] == STATE_BLOCKED then
			newSignalState = STATE_BLOCKED
			newAnimState = ANIMSTATE_STOP
		end

	-- Entry signal with consist going backward into a block
	elseif gOccupationTable[0] > 0 and not gGoingForward then
		if safeLink and Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
			-- Unprotected yard
			gShuntLink = 1
			gYardEntry[gConnectedLink] = true
			newAnimState = ANIMSTATE_UNPROTECTED
			newSignalState = STATE_UNPROTECTED	
		else
			gShuntLink = 0
			if safeLink then gYardEntry[gConnectedLink] = false end
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_BLOCKED
		end

	-- No route or route occupied
	elseif gConnectedLink == -1 or gOccupationTable[0] > 0 or (safeLink and type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0) then
		if safeLink and Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
			-- Unprotected yard
			gShuntLink = 1
			gYardEntry[gConnectedLink] = true
			newAnimState = ANIMSTATE_UNPROTECTED
			newSignalState = STATE_UNPROTECTED	
		else
			gShuntLink = 0
			if safeLink then gYardEntry[gConnectedLink] = false end
			newAnimState = ANIMSTATE_STOP
			newSignalState = STATE_STOP
		end

	-- Route is clear, evaluate the next signal
	elseif safeLink then
		if safeLink and gLinkState[gConnectedLink] == STATE_BLOCKED then
			-- Exit signal facing an occupied block
			if Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
				-- Unprotected yard
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
			-- Diverging route logic
			gYardEntry[gConnectedLink] = false
			gShuntLink = 0
			if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
				newAnimState = ANIMSTATE_GO
				newSignalState = STATE_GO
			else
				newAnimState = ANIMSTATE_STOP
				newSignalState = STATE_STOP
			end
		elseif Call("GetLinkApproachControl", gConnectedLink) ~= 0 or Call("GetLinkFeatherChar", gConnectedLink) == 50 then
			-- Check for shunt-only route
			if Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
				-- Unprotected yard
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
		DebugPrint("SetSignalState() - signal state changed from " .. gSignalState .. " to " .. newSignalState .. " - sending message")
		gSignalState = newSignalState
		if gSignalState == STATE_BLOCKED and not gBlockSignal then
			Call("SendSignalMessage", SIGNAL_STOP, "BLOCKED", -1, 1, 0)
		else
			Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)
		end
	end

	if newAnimState ~= gAnimState then
		DebugPrint("SetSignalState() - signal aspect changed from " .. gAnimState .. " to " .. newAnimState .. " - change lights")
		gAnimState = newAnimState
		SetLights()
		if gHomeSignal then
			if gSignalState == STATE_BLOCKED and not gBlockSignal then
				Call("SendSignalMessage", SIGNAL_STOP, "BLOCKED", -1, 1, 0)
			else
				Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)
			end
		end
	end

	DebugStatus()
end