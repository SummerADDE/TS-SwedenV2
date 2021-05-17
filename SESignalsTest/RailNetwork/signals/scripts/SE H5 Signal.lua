--------------------------------------------------------------------------------------
-- KMW / Anders Eriksson
-- 090108 First version
--------------------------------------------------------------------------------------

--include=SE CommonScript.lua
--include=Signal CommonScript.lua

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
	SIGNAL_HEAD_NAME 		= "SE H5:"
	-- Set our light node names
	LIGHT_NODE_GREEN		= "G1"
	LIGHT_NODE_RED			= "R1"
	LIGHT_NODE_GREEN2		= "G2"
	LIGHT_NODE_WHITE		= "W1"
	LIGHT_NODE_GREEN3		= "G3"
	gDistanceSignal = true
	BaseInitialise()
end

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
function SwitchLight( lightNode, state, head )

	-- If no head is specified, assume that signal only has one
	if head == nil then
		head = SIGNAL_HEAD_NAME
	end

	-- If this light node exists for this signal
	if lightNode ~= nil and head ~= nil then
		Call ( head .. "ActivateNode", lightNode, state )
	end
end

--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()
	if gHomeSignal and (gSignalState ~= STATE_GO) then
		return
	end
	if (gExpectState == STATE_GO) then
		SwitchLight( LIGHT_NODE_GREEN2, 0 )
		SwitchLight( LIGHT_NODE_WHITE, gLightFlashOn )
		SwitchLight( LIGHT_NODE_GREEN3, 0 )
	elseif (gExpectState == STATE_SLOW) then
		SwitchLight( LIGHT_NODE_GREEN2, gLightFlashOn )
		SwitchLight( LIGHT_NODE_WHITE, 0 )
		SwitchLight( LIGHT_NODE_GREEN3, gLightFlashOn )
	else	-- stop or blocked
		SwitchLight( LIGHT_NODE_GREEN2, gLightFlashOn )
		SwitchLight( LIGHT_NODE_WHITE, 0 )
		SwitchLight( LIGHT_NODE_GREEN3, 0 )
	end
end

--------------------------------------------------------------------------------------
-- Swedish home signals SetLights
-- Switch the appropriate lights on and off based on our new state
function DefaultSetLights()
--	DebugPrint("DefaultSetLights()")
	if (gSignalState == STATE_GO) then
		SwitchLight( LIGHT_NODE_GREEN,		1 )
		SwitchLight( LIGHT_NODE_RED,		0 )
		SwitchLight( LIGHT_NODE_GREEN2,		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 	0 )

	elseif (gSignalState == STATE_SLOW) then
		SwitchLight( LIGHT_NODE_GREEN,		1 )
		SwitchLight( LIGHT_NODE_RED,		0 )
		SwitchLight( LIGHT_NODE_GREEN2,		1 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 	gLightOn )

	else	-- stop or blocked
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_RED,		1 )
		SwitchLight( LIGHT_NODE_GREEN2,		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 	0 )
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
STATE_RESET										= 9

-- How long to stay off/on in each flash cycle
LIGHT_FLASH_SECS	= 0.8
	
-- Signal Messages (0-9 are reserved by code)
RESET_SIGNAL_STATE							= 0
INITIALISE_SIGNAL_TO_BLOCKED 				= 1
JUNCTION_STATE_CHANGE						= 2
INITIALISE_TO_PREPARED						= 3

-- Locally defined signal mesages
SIGNAL_GO										= 10
SIGNAL_SLOW										= 11
SIGNAL_STOP										= 12
SIGNAL_BLOCKED									= 13
OCCUPATION_INCREMENT							= 14
OCCUPATION_DECREMENT							= 15

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
gHomeSignal 	= true
gDistanceSignal = false
gBlockSignal	= false				 	-- is this an intermediate block signal?
gConnectedLink	= 0						-- which link is connected?
gLightOn			= 0						-- set 3 greens or 2 greens in STATE_SLOW

-- State of flashing light
gLightFlashOn			= 0
gTimeSinceLastFlash	= 0

-- debugging stuff
gDebugId			= math.random(1, 100)
function DebugPrint( message )
	if gDebugId ~= nil then
		Print( "[" .. gDebugId .. "] " .. message )
	end
end

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
	gDissabled = {}								-- is this link dissabled?
	gOccupationTable = {}						-- how many trains are in this part of our block?
	for link = 0, gLinkCount - 1 do
		gLinkState[link] = STATE_GO
		gDissabled[link] = false
		gOccupationTable[link] = 0
	end
	-- Get link character and store it as "gIndicator".
	gLinkFeatherChar = 0
	gIndicator = ""


	Call("BeginUpdate")
end

--------------------------------------------------------------------------------------
-- INITIALISE SIGNAL
-- Called after route is set up and all links and junctions are known
function InitialiseSignal()
	DebugPrint("InitialiseSignal()")
	-- Remember that we've been initialised
	gInitialised = true

	-- check for dissabled links (links placed before link 0)
	for link = gLinkCount - 1, 1, -1 do
		local connectedLink = Call( "GetConnectedLink", "10", 1, link )
		DebugPrint("Link " .. link .. " connected to " .. connectedLink)
		if (connectedLink ~= -1) then
			gDissabled[link] = true
			gLinkCount = gLinkCount - 1
		end
	end
	

	
	gBlockSignal = gHomeSignal and (gLinkCount == 1)	
	
	if gBlockSignal then
		SetSignalState()
		DebugPrint("BlockSignal[" .. gLinkCount .. "]")
	elseif gHomeSignal then
		gConnectedLink = Call( "GetConnectedLink", "10", 1, 0 )
		SetSignalState()
		DebugPrint("HomeSignal[" .. gLinkCount .. "]")
	end
	if gDistanceSignal then
		DebugPrint("DistanceSignal[" .. gLinkCount .. "]")
	else
		Call("EndUpdate")
	end
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
-- Called when a train passes one of the signal's links
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
	-- in which direction is the consist going?
	gGoingForward = (prevFrontDist > frontDist)
	-- only handle consist pass on active home signal links
	if gHomeSignal and linkIndex >= 0 and not gDissabled[linkIndex] then
		if (frontDist > 0 and backDist < 0) or (frontDist < 0 and backDist > 0) then
			if (prevFrontDist < 0 and prevBackDist < 0) or (prevFrontDist > 0 and prevBackDist > 0) then
				DebugPrint("OnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink)
				if gGoingForward then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
					DebugPrint("OnConsistPass: Forward INCREMENT... gOccupationTable[linkIndex]: " .. gOccupationTable[linkIndex])
				elseif (linkIndex == 0) then
					DebugPrint("OnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT.")
					Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				elseif (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint("OnConsistPass: Backward INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0])
				end
				SetSignalState()
			end
		elseif (prevFrontDist < 0 and prevBackDist > 0) or (prevFrontDist > 0 and prevBackDist < 0) then
			DebugPrint("OnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink)
			if not gGoingForward then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint("OnConsistPass: Backward DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex])
				end
			elseif (linkIndex == 0) then
				DebugPrint("OnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT.")
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
			elseif (gConnectedLink == linkIndex) and (gOccupationTable[0] > 0) then
				gOccupationTable[0] = gOccupationTable[0] - 1
				DebugPrint("OnConsistPass: Forward DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0])
			end
			SetSignalState()			
		end
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT ACTIVATE ROUTE INDICATOR
-- Switches route indicators on and off depending on connected link
--
function DefaultActivateRouteIndicator ( gConnectedLink )
	
	local newIndicator = 0
	local newIndicatorStr = ""

	-- If we're connected to a valid link and the signal isn't red
	if gConnectedLink > 0 then

		-- Check what indicator (if any) is used by that route
		newIndicator = Call("GetLinkFeatherChar", gConnectedLink)

		-- If route has a valid indicator, turn its ID into a string
		if newIndicator ~= 0 then
			newIndicatorStr = string.char(newIndicator)
		else
			newIndicatorStr = ""
		end
	end
	
	-- If we were connected to a different link before
	if gCurrentIndicator ~= newIndicatorStr then

		-- If a feather is currently switched on, switch it off
		if gCurrentIndicator ~= "" then
			gLightOn = 0
		end
			
		-- If the newly connected route has a feather, switch it on
		if newIndicatorStr ~= "" then
			if newIndicatorStr == 3 then
				gLightOn = 1
			else
				gLightOn = 0
			end
		end
		
		DebugPrint(("DEBUG: DefaultActivateRouteIndicator() - route indicator switching from " .. INDICATOR_ROOT_NAME .. gCurrentIndicator .. " to " .. INDICATOR_ROOT_NAME .. newIndicator))
	end
	
	-- Remember which indicator we just switched on
	gCurrentIndicator = newIndicatorStr
end

--------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
-- Handles messages from other signals
function OnSignalMessage( message, parameter, direction, linkIndex )
--	DebugPrint("OnSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")")
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
	if gDissabled[linkIndex] then
		return	-- Do nothing
	end

	-- BLOCK STATES
	if (message >= SIGNAL_GO) and (message <= SIGNAL_BLOCKED) then
		DebugPrint("Message: SIGNAL_STATE_CHANGE received ... gLinkState[" .. linkIndex .. "]:" .. message)
		if gBlockSignal and message == SIGNAL_STOP and parameter == "BLOCKED" then
			-- train coming our direction in an entry signal, block occupied
			gLinkState[0] = STATE_BLOCKED
		else
			gLinkState[linkIndex] = message - SIGNAL_GO
		end
		gExpectState = gLinkState[gConnectedLink]
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
		
	elseif (message == OCCUPATION_INCREMENT) then
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
			if gConnectedLink > 0 then
				gExpectState = gLinkState[gConnectedLink]
			end
			DebugPrint("Message: JUNCTION_STATE_CHANGE received ... activate link: " .. gConnectedLink)
			SetSignalState()
			-- Pass on message in case junction is protected by more than one signal
			-- NB: this message is passed on when received on link 0 instead of link 1+
			-- When it reaches a link > 0 or a signal with only one link, it will be consumed
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		end
	end
end

--------------------------------------------------------------------------------------
-- SET SIGNAL STATE
-- Figures out what state to show and messages to send
function SetSignalState()
	local newSignalState = STATE_GO
	if gBlockSignal then
		if gOccupationTable[0] > 0 and gGoingForward then
			newSignalState = STATE_STOP
		elseif gOccupationTable[0] > 0 or gLinkState[0] == STATE_BLOCKED then
			newSignalState = STATE_BLOCKED
		end
	elseif gOccupationTable[0] > 0 and not gGoingForward then
		-- might be an entry signal with a consist going backwards into a block
		newSignalState = STATE_BLOCKED
	elseif gConnectedLink == -1 or gOccupationTable[0] > 0 or gOccupationTable[gConnectedLink] > 0 then
		-- no route or occupied
		newSignalState = STATE_STOP
	elseif gConnectedLink > 0 and gLinkState[gConnectedLink] == STATE_BLOCKED then
		-- exit signal facing an occupied block
		newSignalState = STATE_STOP
	elseif Call ( "GetLinkApproachControl", gConnectedLink ) ~= 0 then
		-- Check if next signal is at red, show a slow signal if that is the case.
		if (gExpectState == STATE_GO) or (gExpectState == STATE_SLOW) then
			newSignalState = STATE_GO
		else
			newSignalState = STATE_SLOW
		end
	elseif Call ( "GetLinkLimitedToYellow", gConnectedLink ) ~= 0 then
		-- diverging route, signal slow
		newSignalState = STATE_SLOW
	end

	if newSignalState ~= gSignalState then
		DebugPrint("SetSignalState() - signal state changed from " .. gSignalState .. " to " .. newSignalState .. " - sending message" )
		gSignalState = newSignalState
		SetLights()
		if gSignalState >= STATE_STOP then
			Call( "Set2DMapSignalState", STATE_STOP)
		else
			Call( "Set2DMapSignalState", gSignalState)
		end
		if gSignalState == STATE_BLOCKED and not gBlockSignal then
			Call( "SendSignalMessage", SIGNAL_STOP, "BLOCKED", -1, 1, 0 )
		else
			Call( "SendSignalMessage", SIGNAL_GO + gSignalState, "", -1, 1, 0 )
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
		if gTimeSinceLastFlash >= LIGHT_FLASH_SECS then
			Animate()
			gLightFlashOn = 1 - gLightFlashOn
			gTimeSinceLastFlash = 0
		end
	end
end

