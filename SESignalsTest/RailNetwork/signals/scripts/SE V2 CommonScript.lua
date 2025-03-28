--------------------------------------------------------------------------------------
-- KMW / Anders Eriksson
-- 090108 First version
-- 220119 Massively updated version by SummerADDE / Andreas Ulvebring
--------------------------------------------------------------------------------------

--include=SE CommonScript.lua
--include=Signal CommonScript.lua
local hasDebugging, _ = pcall(require, "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/Debugging.lua")
if not hasDebugging then
	-- Define dummy fallback
	function DebugPrint() end
	DEBUG = false
	DEBUG_STATUS = false
	function DebugStatus() end
end

--------------------------------------------------------------------------------------
-- ASCII code for GetLinkFeatherChar
-- Code: 49		Token: 1	Usage: Check next signal. If gExpectState = STATE_STOP then newSignalState = STATE_STOP.
-- Code: 50		Token: 2	Usage: For Yard entry. - Main signal shows stop and shunt script is used.
-- Code: 51		Token: 3	Usage: For H5 signals. newSignalState = STATE_SLOWER and not STATE_SLOW.
-- Code: 52		Token: 4	Usage: 
-- Code: 53		Token: 5	Usage:
-- Code: 54		Token: 6	Usage:
-- Code: 55		Token: 7	Usage:
-- Code: 56		Token: 8	Usage:
-- Code: 57		Token: 9	Usage:


--------------------------------------------------------------------------------------
-- ANIMATE
-- Any animation that needs doing
function Animate()
	-- use standard Animation
	DefaultAnimate()
end

--------------------------------------------------------------------------------------
-- SET LIGHTS
-- Set lights according to new signal state
function SetLights()
	-- use standard SetLights
	DefaultSetLights()
end

-------------------------------------------------------------------------------------
-- Swedish CommonScript to switch lights on/off
-- KMW / Anders Eriksson
-- 090108 First version.
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- SWITCH LIGHT
-- Turns the selected light node on (1) / off (0)
-- if the light node exists for this signal
function SwitchLight(head, lightNode, state)
	if type(head) ~= "string" then head = SIGNAL_HEAD_NAME end
	if type(head) == "string" and type(lightNode) == "string" then
		Call(head .. "ActivateNode", lightNode, state)
	end
end

--------------------------------------------------------------------------------------
-- Signal CommonScript
-- KMW / Anders Eriksson
-- Based on KUJU / Rail Simulator Signal Scripts
-- 090108 First version.
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- GLOBALS
-- States
STATE_GO										= 0
STATE_SLOW										= 1
STATE_STOP										= 2
STATE_BLOCKED									= 3
STATE_SHUNT										= 4
STATE_UNPROTECTED								= 5
STATE_CALLON									= 6
STATE_UNDEFINED									= 8
STATE_RESET										= 9

-- Light states
ANIMSTATE_GO										= 0
ANIMSTATE_SLOW										= 1
ANIMSTATE_SLOWER									= 2
ANIMSTATE_STOP										= 3
ANIMSTATE_SHUNT										= 4
ANIMSTATE_UNPROTECTED								= 5
ANIMSTATE_CALLON									= 6

-- How long to stay off/on in each flash cycle
LIGHT_FLASH_OFF_SECS	= 0.7
LIGHT_FLASH_ON_SECS		= 0.3
	
-- Signal Messages (0-9 are reserved by code)
RESET_SIGNAL_STATE							= 0
INITIALISE_SIGNAL_TO_BLOCKED 				= 1
JUNCTION_STATE_CHANGE						= 2
INITIALISE_TO_PREPARED						= 3
REQUEST_TO_SPAD								= 4

-- Locally defined signal mesages
SIGNAL_GO										= 10
SIGNAL_SLOW										= 11
SIGNAL_STOP										= 12
SIGNAL_BLOCKED									= 13
OCCUPATION_INCREMENT							= 14
OCCUPATION_DECREMENT							= 15
DISTANCE_INCREMENT								= 16
DISTANCE_DECREMENT								= 17

-- Check signal state for shunt signals
OFF			= 0
GO			= 1
SLOW		= 2

-- What you need to add to a signal message number to turn it into the equivalent PASS message
PASS_OFFSET										= 50

-- Pass on messages to handle overlapping links (eg for converging junctions / crossovers)
-- Populated by BaseInitialise()
PASS = { }
	
-- SPAD and warning system messages to pass to consist
AWS_MESSAGE										= 11
TPWS_MESSAGE									= 12
SPAD_MESSAGE 									= 14

-- Initialise global variables
gGoingForward	= true
gInitialised	= false					-- has the route finished loading yet?
gSignalState	= STATE_RESET			-- state of this block/signal
gExpectState	= STATE_RESET			-- state of next block/signal
gConnectedLink	= 0						-- which link is connected?
gAnimState		= -1					-- what's the current state of our main lights?
gShuntState		= -1					-- what's the current state of our shunt lights?
gCallOn 		= 0						-- Is Call on mode active?
gShuntLink		= 0						-- Is this link a shunt path?

-- State of flashing light
gLightFlashOn			= 0
gTimeSinceLastFlash		= 0


--------------------------------------------------------------------------------------
-- BASE INITIALISE
-- initialise function used by all signal scripts
function BaseInitialise()
	DebugPrint("BaseInitialise()")
	gInitialised = false
	-- Initialise PASS constants
	for i = 0, PASS_OFFSET do
		PASS[i] = i + PASS_OFFSET
	end

	-- Initialise global variables
	gLinkCount = Call( "GetLinkCount" )		-- number of links this signal has
	gLinkState = {}								-- state of line beyond this link
	gYardEntry = {}								-- is this link going inside a yard?
	gDissabled = {}								-- is this link dissabled?
	gOccupationTable = {}						-- how many trains are in this part of our block?
	for link = 0, gLinkCount - 1 do
		gLinkState[link] = STATE_RESET
		gYardEntry[link] = false
		gDissabled[link] = false
		gOccupationTable[link] = 0
	end

	Call("BeginUpdate")
end

--------------------------------------------------------------------------------------
-- INITIALISE SIGNAL
-- Called after route is set up and all links and junctions are known
function InitialiseSignal()
	DebugPrint("Initialising signal with gHomeSignal=" .. tostring(gHomeSignal) .. ", gBlockSignal=" .. tostring(gBlockSignal))
	gInitialised = true

	-- check for dissabled links (links placed before link 0)
	for link = gLinkCount - 1, 1, -1 do
		local connectedLink = Call( "GetConnectedLink", "10", 1, link )
		DebugPrint("Link " .. link .. " connected to " .. connectedLink)
		if (connectedLink ~= -1) then
			gDissabled[link] = true
			gYardEntry[link] = true
			gLinkCount = gLinkCount - 1
		end
	end

	for link = 1, gLinkCount - 1 do
		if type(gConnectedLink) == "number" and gConnectedLink >= 0 then
			gLinkState[gConnectedLink] = STATE_RESET
		end
	end

	-- If 1 link only, Force gConnectedLink = 0
	if gLinkCount == 1 then
		gConnectedLink = 0
		DebugPrint("Signal has one link – forcing gConnectedLink = 0")
	end

	-- Set gConnectedLink safely for block signals
	if gBlockSignal then
		local clink = Call("GetConnectedLink", "10", 1, 0)
		if clink ~= -1 then
			gConnectedLink = clink
			DebugPrint("BlockSignal[" .. gLinkCount .. "] - Connected to " .. gConnectedLink)
		else
			DebugPrint("BlockSignal[" .. gLinkCount .. "] - No connected link")
		end
		SetSignalState()
		DebugPrint("SendSignalMessage: " .. tostring(SIGNAL_GO + gSignalState))
		-- Force signal state to propagate at init
		Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)

	elseif gHomeSignal then
		gConnectedLink = Call("GetConnectedLink", "10", 1, 0)
		SetSignalState()
		DebugPrint("HomeSignal[" .. gLinkCount .. "]")
		Call("SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0)
	end

	if gDistanceSignal then
		DebugPrint("DistanceSignal[" .. gLinkCount .. "]")
	else
		Call("EndUpdate")
	end
	
	DebugStatus()
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- Called when a train passes one of the signal's links
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
	-- in which direction is the consist going?
	gGoingForward = (prevFrontDist > frontDist)
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		if ( prevFrontDist > 0 and prevBackDist > 0 ) and linkIndex == 0 then
			if ( gSignalState == STATE_BLOCKED or gSignalState == STATE_STOP ) and not gShuntLink == 1 then
				DebugPrint("SPAD")
				Call( "SendConsistMessage", SPAD_MESSAGE, "" )
			end
			if ( gCallOn == 1 ) then
				gCallOn = 0
				DebugPrint("Train passed signal at Call-on Mode.")
			end
		end
	end
	-- only handle consist pass on active home signal links
	if linkIndex >= 0 and not gDissabled[linkIndex] then
		if (frontDist > 0 and backDist < 0) or (frontDist < 0 and backDist > 0) then
			if (prevFrontDist < 0 and prevBackDist < 0) or (prevFrontDist > 0 and prevBackDist > 0) then
				DebugPrint("OnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink)
				if gGoingForward then
					if not gYardEntry[linkIndex] then
						gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
						DebugPrint("OnConsistPass: Forward INCREMENT... gOccupationTable[linkIndex]: " .. gOccupationTable[linkIndex])
					end
				elseif linkIndex == 0 then
					DebugPrint("OnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT.")
					if gHomeSignal then
						Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
					end
					Call( "SendSignalMessage", DISTANCE_INCREMENT, "DoNotForward", -1, 1, 0 )
				elseif (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint("OnConsistPass: Backward INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0])
				end
				SetSignalState()
			end
		elseif (prevFrontDist < 0 and prevBackDist > 0) or (prevFrontDist > 0 and prevBackDist < 0) then
			DebugPrint("OnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink)
			if not gGoingForward then
				if not gYardEntry[linkIndex] and gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint("OnConsistPass: Backward DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex])
				end
			elseif linkIndex == 0 then
				DebugPrint("OnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT.")
				if gHomeSignal then
					Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				end
				Call( "SendSignalMessage", DISTANCE_DECREMENT, "DoNotForward", -1, 1, 0 )
			elseif (gConnectedLink == linkIndex) and (gOccupationTable[0] > 0) then
				gOccupationTable[0] = gOccupationTable[0] - 1
				DebugPrint("OnConsistPass: Forward DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0])
			end
			SetSignalState()			
		end
	end
end

--------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
-- Handles messages from other signals
function OnSignalMessage( message, parameter, direction, linkIndex )
	if linkIndex == nil or type(linkIndex) ~= "number" or linkIndex < 0 or linkIndex >= gLinkCount then
		DebugPrint("Invalid or out-of-range linkIndex: " .. tostring(linkIndex))
		return
	end
	-- This message is to reset the signals after a scenario / route is reset
	if (message == RESET_SIGNAL_STATE) then
		Initialise()
		return
	elseif not gInitialised then
		InitialiseSignal()
	end

	-- Check for signal receiving a message it might need to forward, 
	-- in case there are two overlapping signal blocks (eg for a converging junction or crossover)
	-- ignore messages that have the "DoNotForward" parameter
	if (parameter ~= "DoNotForward") then
		if gDissabled[linkIndex] or not gHomeSignal then	-- just forward it on
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		elseif (linkIndex > 0) then
			-- We've received a PASS message, so forward it on
			if (message > PASS_OFFSET) then
				Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
				message = message - PASS_OFFSET
			-- Any message other than JUNCTION_STATE_CHANGE should be forwarded as PASS messages
			elseif message ~= JUNCTION_STATE_CHANGE then
				Call( "SendSignalMessage", message + PASS_OFFSET, parameter, -direction, 1, linkIndex )
			end
		end
	end

	-- messages arriving on a yard entry or dissabled link should be ignored
	if (gYardEntry[linkIndex] or gDissabled[linkIndex]) then
		return	-- Do nothing
	end

	DebugPrint("OnSignalMessage precheck: type(message)=" .. tostring(type(message)) .. ", type(SIGNAL_GO)=" .. tostring(type(SIGNAL_GO)) .. ", value=" .. tostring(message))


	-- BLOCK STATES
	if type(message) == "number" and message >= SIGNAL_GO and message <= (SIGNAL_GO + STATE_CALLON) then
	   DebugPrint("Message: SIGNAL_STATE_CHANGE received ... gLinkState[" .. linkIndex .. "]:" .. message)
		if gBlockSignal and message == SIGNAL_STOP and parameter == "BLOCKED" then
			-- train coming our direction in an entry signal, block occupied
			gLinkState[0] = STATE_BLOCKED
			
		else
			gLinkState[linkIndex] = message - SIGNAL_GO
		end
		if type(gConnectedLink) == "number" and gConnectedLink >= 0 and gLinkState[gConnectedLink] ~= nil then
			gExpectState = gLinkState[gConnectedLink]
		else
			gExpectState = STATE_STOP -- fallback
		end
		DebugPrint("Link " .. linkIndex .. " is now " .. gLinkState[linkIndex])
		if gHomeSignal then
			SetSignalState()
		end

	elseif not gHomeSignal then
		return	-- do no more if we are distance signal only

	-- INITIALISATION MESSAGES
	-- There's a train on the line ahead of us when the route first loads
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint("Message: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex])
		-- Only need to do this for block signals - anything spanning a junction will initialise later when junctions are set
		if (gBlockSignal and gOccupationTable[linkIndex] == 1) then
			SetSignalState()
		end

		-- OCCUPANCY
	elseif (message == OCCUPATION_DECREMENT) then
		-- update the occupation table for this signal given the information that a train has just left this block and entered the next block
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
		end
		gGoingForward = true
		gLinkState[linkIndex] = STATE_STOP	-- train going opposite direction, block no longer occupied
		DebugPrint("Message: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex])
		-- If this is the connected link and last train leaving
		if linkIndex == gConnectedLink and gOccupationTable[linkIndex] == 0 then
			SetSignalState()
		end
		
	elseif (message == OCCUPATION_INCREMENT and gHomeSignal or
			  message == DISTANCE_INCREMENT and not gHomeSignal) then
		-- update the occupation table for this signal given the information that a train has just entered this block
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		gGoingForward = false
		DebugPrint("Message: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex])
		-- If this is the connected link and first train entered the block, check the signal state
		if linkIndex == gConnectedLink and gOccupationTable[linkIndex] == 1 then
			SetSignalState()
		end

	elseif gBlockSignal then
		return	-- do no more if we are block signal

	elseif (message == JUNCTION_STATE_CHANGE) then
		-- Only act on message if it arrived at link 0, junction_state parameter is "0",
		-- and this signal spans a junction (ie, not a block signal)
		if linkIndex == 0 and parameter == "0" then
			gConnectedLink = Call( "GetConnectedLink", "10", 1, 0 )
			if gConnectedLink >= 0 and gLinkState[gConnectedLink] ~= nil then
				gExpectState = gLinkState[gConnectedLink]
			else
				gExpectState = STATE_STOP -- Fallback om inget är kopplat
			end
			DebugPrint("Expected state after JUNCTION_STATE_CHANGE: " .. tostring(gExpectState))
			SetSignalState()
		end
		if ( gCallOn == 1 ) then
			gCallOn = 0
			SetSignalState()
		end
	elseif (message == REQUEST_TO_SPAD) then
		DebugPrint("REQUEST_TO_SPAD received.")

		if gHomeSignal then
			gCallOn = 1
			SetSignalState()
			DebugPrint("REQUEST_TO_SPAD sent to signal. Changing its aspects.")
		elseif gDistanceSignal and gConnectedLink ~= nil and gConnectedLink >= 0 then
			DebugPrint("REQUEST_TO_SPAD sent on distant signal – Forwarding.")
			Call("SendSignalMessage", REQUEST_TO_SPAD, parameter, direction, 1, gConnectedLink)
		end
	end
end


--------------------------------------------------------------------------------------
-- DEFAULT UPDATE
-- Handles flashing lights
function Update( time )
--	DebugPrint("Update(" .. time .. ")")
	if not gInitialised then
		InitialiseSignal()			
	else
		gTimeSinceLastFlash = gTimeSinceLastFlash + time
		
		-- If we're on and we've been on long enough, switch off
		if gLightFlashOn == 1 and gTimeSinceLastFlash >= LIGHT_FLASH_OFF_SECS then
			Animate()
			newLightState = 0
			gLightFlashOn = 0
			gTimeSinceLastFlash = 0
			
		elseif gLightFlashOn == 0 and gTimeSinceLastFlash >= LIGHT_FLASH_ON_SECS then
			Animate()
			newLightState = 1
			gLightFlashOn = 1
			gTimeSinceLastFlash = 0
		end
	end
end

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for TAB Funcionality.
--
function GetSignalState()
	return gSignalState
end