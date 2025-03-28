--------------------------------------------------------------------------------------
-- INITIALISE
-- Signal specific initialise function
function Initialise()
	DebugPrint("Initialise() – SE DV7 Signal")
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
	gBlockSignal	= false				 	-- is this an intermediate block signal?
	gShuntSignal	= false					-- is this a dwarf signal or not?
	
	BaseInitialise()
	DebugStatus()
end



--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()

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
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
-- Refactored SetSignalState() for SE DV7 Signal.lua with safety checks and descriptive comments

function SetSignalState()
	local newSignalState = STATE_GO
	local newAnimState = ANIMSTATE_GO
	local checkSignalState = GO -- Temporary state for aspect evaluation

	-- Check if gConnectedLink is safe to use
	local safeLink = type(gConnectedLink) == "number" and gConnectedLink >= 0
	
	-- Call-on mode logic
	if gCallOn == 1 then
		checkSignalState = OFF
		if safeLink then gYardEntry[gConnectedLink] = false end
		gShuntLink = 0
		if safeLink and type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0 then
			newAnimState = ANIMSTATE_SHUNT
			newSignalState = STATE_SHUNT
		else
			newAnimState = ANIMSTATE_CALLON
			newSignalState = STATE_CALLON
		end
	-- Block signal behavior
	elseif gBlockSignal then
		checkSignalState = OFF
		if safeLink then gYardEntry[gConnectedLink] = false end
		gShuntLink = 0
		if gOccupationTable[0] > 0 and gGoingForward then
			newSignalState = STATE_STOP
			newAnimState = ANIMSTATE_STOP
		elseif gOccupationTable[0] > 0 or gLinkState[0] == STATE_BLOCKED then
			newSignalState = STATE_BLOCKED
			newAnimState = ANIMSTATE_STOP
		end
		-- Entry signal with train moving backwards into block
	--	Call("SendSignalMessage", SIGNAL_GO + newSignalState, "", -1, 1, 0)

	-- Entry signal with train moving backwards into block
	elseif gOccupationTable[0] > 0 and not gGoingForward then
		checkSignalState = OFF
		if safeLink and Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
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

	-- No route or occupied block
	elseif gConnectedLink == -1 or gOccupationTable[0] > 0 or (safeLink and type(gConnectedLink) == "number" and safeLink and gOccupationTable[gConnectedLink] > 0) then
		checkSignalState = OFF
		if safeLink and Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
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

	-- Valid link: evaluate next signal
	elseif safeLink then
											 
		if safeLink and gLinkState[gConnectedLink] == STATE_BLOCKED then
			checkSignalState = OFF
			if Call("GetLinkFeatherChar", gConnectedLink) == 50 and Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
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
			checkSignalState = GO
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
				if Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
					newAnimState = ANIMSTATE_SLOW
					checkSignalState = SLOW
				else
					newAnimState = ANIMSTATE_GO
					checkSignalState = GO
				end
			else
				newAnimState = ANIMSTATE_STOP
				newSignalState = STATE_STOP
				checkSignalState = OFF
			end
		elseif Call("GetLinkApproachControl", gConnectedLink) ~= 0 then
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			if safeLink and gLinkState[gConnectedLink] == STATE_GO or safeLink and gLinkState[gConnectedLink] == STATE_SLOW then
				checkSignalState = GO
				newAnimState = ANIMSTATE_GO
			else
				checkSignalState = SLOW
				newAnimState = ANIMSTATE_SLOW
			end
		elseif Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
			gShuntLink = 0
			gYardEntry[gConnectedLink] = false
			checkSignalState = SLOW
			newAnimState = ANIMSTATE_SLOW
		elseif Call("GetLinkFeatherChar", gConnectedLink) == 50 then
			checkSignalState = OFF
			if Call("GetLinkLimitedToYellow", gConnectedLink) ~= 0 then
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

	

	-- Set signal state based on link evaluation
	if checkSignalState == GO then
		if gExpectState == STATE_SLOW then
			newSignalState = STATE_SLOW
		elseif gExpectState == STATE_GO then
			newSignalState = STATE_GO
		else
			newSignalState = STATE_STOP
		end
	elseif checkSignalState == SLOW then
		if gExpectState == STATE_GO or gExpectState == STATE_SLOW then
			newSignalState = STATE_SLOW
		else
			newSignalState = STATE_STOP
		end
	end

	-- Final application and message handling
	if newSignalState ~= gSignalState then
		DebugPrint("SetSignalState() - signal state changed from " .. gSignalState .. " to " .. newSignalState .. " - sending message")
		gSignalState = newSignalState
	end

	-- Ensure block signals always send current state, even if unchanged
	if gBlockSignal then
		Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)
	elseif gSignalState == STATE_BLOCKED and not gBlockSignal then
		Call("SendSignalMessage", SIGNAL_STOP, "BLOCKED", -1, 1, 0)
	else
		Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)
	end

	if newAnimState ~= gAnimState then
		DebugPrint("SetSignalState() - signal aspect changed from " .. gAnimState .. " to " .. newAnimState .. " - change lights")
		gAnimState = newAnimState
		SetLights()
		if gHomeSignal then
			if gSignalState >= STATE_STOP then
				Call("Set2DMapSignalState", STATE_STOP)
			else
				Call("Set2DMapSignalState", gSignalState)
			end
		end
	end

	DebugStatus()
end