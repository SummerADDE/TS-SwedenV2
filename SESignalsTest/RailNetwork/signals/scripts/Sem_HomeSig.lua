--------------------------------------------------------------------------------------
-- Home Semaphore Signal
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--include=CommonScripts\Common UK Semaphore Script.lua
--include=..\CommonScripts\Common Signal Script.lua

--------------------------------------------------------------------------------------
-- INITIALISE
--
function Initialise ()

	-- Initialise signal as having 1 route indication
	DefaultInitialise(1)
	
	-- Set arm anim names
	gArmTable[ROUTE_MAIN][ARM_HOME][gChildName]			= "Main Home Arm"
	gArmTable[ROUTE_MAIN][ARM_HOME][gProceedAnimIndex]	= "Clear01"
	gArmTable[ROUTE_MAIN][ARM_HOME][gBlockedAnimIndex]	= "Stop01"

	-- Initialise arm to open (clear) - this will also trigger an Update that will check junction states
	SetState( ANIMSTATE_ANIMTOOPEN, ROUTE_MAIN, ARM_HOME )
end

--------------------------------------------------------------------------------------
-- ON CONSIST PASS
--
function OnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	-- use the default consist pass for this...
	DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )
end

--------------------------------------------------------------------------------------
-- JUNCTION STATE CHANGE
--
function OnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	-- Use the default junction state change code for this... 
	DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )
end

--------------------------------------------------------------------------------------
-- UPDATE
--
function Update (time)

	-- Use the default update code for this...
	DefaultUpdate( time )
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the OnSignalMessage function
--
function ReactToSignalMessage( message, parameter, direction, linkIndex )

	-- Use the default signal message code for this...
	DefaultReactToSignalMessage( message, parameter, direction, linkIndex )
end

-------------------------------------------------------------------------------------
-- ON SIGNAL MESSAGE
--
function OnSignalMessage( message, parameter, direction, linkIndex )

	-- Use the default signal message code for this...
	DefaultOnSignalMessage( message, parameter, direction, linkIndex )	
end

--------------------------------------------------------------------------------------
-- OCCUPIED
--
function Occupied( linkIndex )

	DebugPrint( ( "DEBUG: Occupied(" .. linkIndex .. ")" ) )

	-- Don't do anything unless we weren't blocked before
	if gSignalState ~= SIGNAL_BLOCKED then

		-- Set signal arm to closed
		SetState( ANIMSTATE_ANIMTOCLOSED, ROUTE_MAIN, ARM_HOME )
		
		-- Mark the signal as blocked on the 2D map
		Call( "Set2DMapSignalState", BLOCKED )
	
		-- Set signal state to blocked and send back a message
		gSignalState = SIGNAL_BLOCKED		
		DebugPrint( ( "DEBUG: Occupied(" .. linkIndex .. "): Send SIGNAL_BLOCKED message" ) )
		Call( "SendSignalMessage", SIGNAL_BLOCKED, "", -1, 1, 0 )
	end
end

--------------------------------------------------------------------------------------
-- NOTOCCUPIED
--
function NotOccupied( linkIndex )

	DebugPrint( ( "DEBUG: NotOccupied(" .. linkIndex .. ")" ) )

	-- Don't do anything unless we weren't clear before
	if gSignalState ~= SIGNAL_CLEARED then

		-- Set signal arm to open
		SetState( ANIMSTATE_ANIMTOOPEN, ROUTE_MAIN, ARM_HOME )
		
		-- Mark the signal as clear on the 2D map
		Call( "Set2DMapSignalState", CLEAR )
	
		-- Set signal state to clear and send back a message
		gSignalState = SIGNAL_CLEARED		
		DebugPrint( ( "DEBUG: NotOccupied(" .. linkIndex .. "): Send SIGNAL_CLEARED message" ) )
		Call( "SendSignalMessage", SIGNAL_CLEARED, "", -1, 1, 0 )
	end
end

--------------------------------------------------------------------------------------
-- Common UK semaphore signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- DEFAULT INITIALISE
-- Sets up the signal
--
function DefaultInitialise ( routeCount )

	-- calls the base initialise function in the global common script
	BaseInitialise()

	-- This will be set to true once the signal does its first Update
	gInitialised = false

	-- Number of indicated routes on signal with their own arm(s)
		-- (this is not necessarily the same as the number of links)
	gRouteCount = routeCount
	
	-- Overall state of signal (defaults to cleared)
	gSignalState = SIGNAL_CLEARED
	
	-- Initialise 2D map indication to clear as well
	Call( "Set2DMapSignalState", CLEAR )
	
	-- animation states
	ANIMSTATE_OPEN				= 0
	ANIMSTATE_ANIMTOOPEN		= 1
	ANIMSTATE_CLOSED			= 2
	ANIMSTATE_ANIMTOCLOSED		= 3
	
	-- arm identifiers
	ROUTE_MAIN 					= 1		-- main route
	ROUTE_DIVERGING				= 2		-- diverging route
	ARM_HOME					= 0		-- home signal arm
	ARM_DISTANT					= 1		-- distant signal arm

	-- initialise arm states for animation
	gArmTable = {}
	gUpdatingArm = { }
	
	gStateIndex = 0
	gChildName = 1
	gProceedAnimIndex = 2
	gBlockedAnimIndex = 3
	
	for routeIndex=1, gRouteCount do
		gUpdatingArm[routeIndex] = {}
		gArmTable[routeIndex] = {}
		
		for armIndex=ARM_HOME, ARM_DISTANT do
			gUpdatingArm[routeIndex][armIndex] = false
			gArmTable[routeIndex][armIndex] = {}
			gArmTable[routeIndex][armIndex][gStateIndex] = -1
			gArmTable[routeIndex][armIndex][gChildName] = ""
			gArmTable[routeIndex][armIndex][gProceedAnimIndex] = ""
			gArmTable[routeIndex][armIndex][gBlockedAnimIndex] = ""
		end
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT UPDATE
-- Handles animation for signal arms
--
function DefaultUpdate( time )

	-- If we've not been fully initialised yet, check our junction state now
	if not gInitialised then
		OnJunctionStateChange( 0, "", 1, 0 )
		gInitialised = true
	end

	local animState
	local animIndex
	local anim
	local animCall
	
	for i=1, gRouteCount do
		for j=ARM_HOME, ARM_DISTANT do
			
			-- ignore any combinations of arms and linkIndex that don't exist
			if gArmTable[i][j][gChildName] ~= "" then	
				animState = gArmTable[i][j][gStateIndex]
				animCall = gArmTable[i][j][gChildName] .. ":AddTime"
				
				-- if animating to an open (proceed) state
				if (animState == ANIMSTATE_ANIMTOOPEN) then
					
					-- reset any animations currently running on that arm!
					Call( gArmTable[i][j][gChildName] .. ":Reset", gArmTable[i][j][gBlockedAnimIndex] )
					
					anim = gArmTable[i][j][gProceedAnimIndex]
					
					-- check that the animation has finished / update the animation
					if (anim == "") or (Call( animCall, anim, time ) ~= 0) then
						DebugPrint( ("DEBUG: DefaultUpdate: SetState Proceed " .. i .. "," .. j) )
						SetState( ANIMSTATE_OPEN, i, j )
					end
					
				-- if animating to a closed (blocked) state			
				elseif (animState == ANIMSTATE_ANIMTOCLOSED) then
					
					-- reset any animations currently running on that arm!
					Call( gArmTable[i][j][gChildName] .. ":Reset", gArmTable[i][j][gProceedAnimIndex] )
					
					anim = gArmTable[i][j][gBlockedAnimIndex]
					
					-- check that the animation has finished / update the animation
					if (anim == "") or (Call( animCall, anim, time ) ~= 0) then
						DebugPrint( "DEBUG: DefaultUpdate: SetState Blocked ", i, ",", j )
						SetState( ANIMSTATE_CLOSED, i, j )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- SET STATE
-- Sets animation states for a specific signal arm
--
function SetState( newState, routeIndex, armIndex )

	DebugPrint( ("DEBUG: SetState(" .. newState .. ", " .. routeIndex .. ", " .. armIndex .. ")") )
	local updateCount = gUpdating
	
	if (routeIndex > 0) and (routeIndex <= gRouteCount) and (armIndex <= ARM_DISTANT) then
		if (gArmTable[routeIndex][armIndex][gStateIndex] ~= newState) then
			
			-- begin/end update depending on the new state
			if (newState == ANIMSTATE_ANIMTOOPEN) or 
				(newState == ANIMSTATE_ANIMTOCLOSED) then
				
				-- check if this arm is already being updated
				if (not gUpdatingArm[routeIndex][armIndex]) then
					gUpdatingArm[routeIndex][armIndex] = true
					gUpdating = gUpdating + 1
					
					-- If this is the only arm updating at the moment, begin update
					if gUpdating == 1 then
						Call( "BeginUpdate" )
					end
					
					-- play sound when animation starts!
					if (newState == ANIMSTATE_ANIMTOOPEN) then
						Call ("ControlSound:SetParameter", "SignalProgress", 1)
					elseif (newState == ANIMSTATE_ANIMTOCLOSED) then
						Call ("ControlSound:SetParameter", "SignalProgress", 0)
					end
				end
				
			elseif (newState == ANIMSTATE_OPEN) or 
				(newState == ANIMSTATE_CLOSED) then
				
				-- check if this arm is being updated
				if (gUpdatingArm[routeIndex][armIndex]) then
					gUpdatingArm[routeIndex][armIndex] = false
					gUpdating = gUpdating - 1
					
					-- If this was the only arm updating, end update
					if gUpdating == 0 then
						Call( "EndUpdate" )
					end			
				end
			end
			
			gArmTable[routeIndex][armIndex][gStateIndex] = newState;
		end

		DebugPrint( ("DEBUG: SetState: UpdateCount was: " .. updateCount .. ", is now: " .. gUpdating) )
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT ON CONSIST PASS
-- OnConsistPass function used by all UK Semaphore home signal scripts
--
function DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end

	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
			
				-- Check for SPADs first
				if (gSignalState == SIGNAL_BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
				
				-- and also set signal to blocked if not already blocked or disconnected
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: DefaultOnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT" )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) or (gLinkCount == 2 and gConnectedLink ~= -1) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
				
				-- and also set signal to cleared if not blocked by another consist and junction (if any) is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
					NotOccupied(0)
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: DefaultOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					else
						Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT JUNCTION STATE
-- Uses base junction state change code
--
function DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: DefaultOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: DefaultOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				if newConnectedLink == gConnectedLink then
					-- Don't waste time doing anything else if the connected link hasn't changed
					DebugPrint( ("WARNING: DefaultOnJunctionStateChange triggered by message from junction that hasn't effected its state, still connected to " .. gConnectedLink ) )

				else
					gConnectedLink = newConnectedLink

					DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
					if (gConnectedLink > 0) then
							
						-- update occupation
						DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Update occupation: gOccupationTable[" .. gConnectedLink .. "]: " .. gOccupationTable[gConnectedLink]) )
						
						-- Check if newly connected route is blocked or not
						if (gOccupationTable[gConnectedLink] == 0) and (gOccupationTable[0] == 0) then
							NotOccupied( gConnectedLink )
						else
							Occupied( gConnectedLink )
						end

					-- AEH 13/04/2007: set the junction to blocked if there's no valid exit from it (eg for crossover when points at other end of linking track are set against us)
					elseif gConnectedLink == -1 then
					       Occupied( 0 )
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the DefaultOnSignalMessage function
--
function DefaultReactToSignalMessage( message, parameter, direction, linkIndex )
	
	if (message == OCCUPATION_DECREMENT) then
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("DEBUG: OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end
		
		-- check when cleared
		if (gConnectedLink == linkIndex) and (gOccupationTable[0] == 0) and (gOccupationTable[gConnectedLink] == 0) then
			NotOccupied( gConnectedLink )
		end
	
	elseif (message == OCCUPATION_INCREMENT) then			
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("OnSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- If this is the connected link, set it as occupied
		if (gConnectedLink == linkIndex) then
			Occupied( gConnectedLink )
		end
		
	-- added a special message for when the signal is initialised with a consist in its signal block (ignored by dist signals)				
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then		
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: OnSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- Only need to check this if we're a single link signal, otherwise when our junction state is checked we'll know if we're blocked or not
		if (gLinkCount == 1) then
			Occupied( linkIndex )
		end

	-- JB 04/05/07 - New junction state change message added
	elseif (message == JUNCTION_STATE_CHANGE) then
		DebugPrint( "DEBUG: OnSignalMessage: JUNCTION_STATE_CHANGE received" )
		
		-- Only act on message if it arrived at link 0, junction_state parameter is "0", and this signal spans a junction (ie, has more than one link)
		if linkIndex == 0 and parameter == "0" and gLinkCount > 1 and gInitialised then
			OnJunctionStateChange( 0, "", 1, 0 )
			
			-- Pass on message in case junction is protected by more than one signal
				-- NB: this message is passed on when received on link 0 instead of link 1+
				-- When it reaches a link > 0 or a signal with only one link, it will be consumed
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		end

	-- This message is to reset the signals after a scenario / route is reset
	elseif (message == RESET_SIGNAL_STATE) then
		ResetSignalState()		
	end
end
	
-------------------------------------------------------------------------------------
-- DEFAULT ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function DefaultOnSignalMessage( message, parameter, direction, linkIndex )
	
	-- Use the base function for this
	BaseOnSignalMessage( message, parameter, direction, linkIndex )
end

--------------------------------------------------------------------------------------
-- DISPLAY ARM TABLE
-- Debug used for animation
--
function DisplayArmTable()

	Print( "ArmTable" )
	for i=1, gRouteCount do
		for j=ARM_HOME, ARM_DISTANT do
			Print( "(", i, ",", j, ") " )
			Print( "State: ", gArmTable[i][j][gStateIndex], " Proceed: ", gArmTable[i][j][gProceedAnimIndex], " Blocked: ", gArmTable[i][j][gBlockedAnimIndex] )
		end
	end
end

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for AWS/TPWS scripting.
--
function GetSignalState( )

	-- Just return gSignalState
	return gSignalState
end

--------------------------------------------------------------------------------------
-- Common signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- GLOBALS

-- States
CLEAR = 0
WARNING = 1
BLOCKED = 2

-- Signal Messages (0-9 are reserved by code)
RESET_SIGNAL_STATE						= 0
INITIALISE_SIGNAL_TO_BLOCKED 			= 1
JUNCTION_STATE_CHANGE					= 2
INITIALISE_TO_PREPARED					= 3

-- Locally defined signal mesages
OCCUPATION_INCREMENT					= 10
OCCUPATION_DECREMENT					= 11

SIGNAL_BLOCKED							= 12
SIGNAL_CLEARED							= 13
SIGNAL_WARNING							= 14
SIGNAL_WARNING2							= 15

-- GERMAN SPECIFIC functionality: custom signal message used to set lights green or reset to red after consist pass
SIGNAL_PREPARE_FOR_TRAIN				= 16
SIGNAL_RESET_AFTER_TRAIN_PASS			= 17

-- special signal messages only used by the signals that message the opposite facing signal
-- in the section of track where two single direction tracks converge to one dual direction track
	-- currently only used for UK Semaphore signals
OCCUPATION_REVERSE_INCREMENT  			= 18
OCCUPATION_REVERSE_DECREMENT 			= 19

-- Signal Messages 20-29 are available for later extension or end-users

-- What you need to add to a signal message number to turn it into the equivalent PASS_ message
PASS_OFFSET								= 30

-- Pass on messages to handle overlapping links (eg for converging junctions / crossovers)
PASS_RESET_SIGNAL_STATE					= PASS_OFFSET + RESET_SIGNAL_STATE				-- Never used!
PASS_INITIALISE_SIGNAL_TO_BLOCKED		= PASS_OFFSET + INITIALISE_SIGNAL_TO_BLOCKED
PASS_JUNCTION_STATE_CHANGE				= PASS_OFFSET + JUNCTION_STATE_CHANGE
PASS_INITIALISE_TO_PREPARED				= PASS_OFFSET + INITIALISE_TO_PREPARED
PASS_OCCUPATION_INCREMENT				= PASS_OFFSET + OCCUPATION_INCREMENT
PASS_OCCUPATION_DECREMENT				= PASS_OFFSET + OCCUPATION_DECREMENT
PASS_SIGNAL_BLOCKED						= PASS_OFFSET + SIGNAL_BLOCKED
PASS_SIGNAL_CLEARED						= PASS_OFFSET + SIGNAL_CLEARED
PASS_SIGNAL_WARNING						= PASS_OFFSET + SIGNAL_WARNING
PASS_SIGNAL_WARNING2					= PASS_OFFSET + SIGNAL_WARNING2
PASS_SIGNAL_PREPARE_FOR_TRAIN			= PASS_OFFSET + SIGNAL_PREPARE_FOR_TRAIN
PASS_SIGNAL_RESET_AFTER_TRAIN_PASS 		= PASS_OFFSET + SIGNAL_RESET_AFTER_TRAIN_PASS
PASS_OCCUPATION_REVERSE_INCREMENT		= PASS_OFFSET + OCCUPATION_REVERSE_INCREMENT
PASS_OCCUPATION_REVERSE_DECREMENT		= PASS_OFFSET + OCCUPATION_REVERSE_DECREMENT
	
-- SPAD and warning system messages to pass to consist
AWS_MESSAGE								= 11
TPWS_MESSAGE							= 12
SPAD_MESSAGE 							= 14


-- Script globals
gConnectedLink = 0
gUpdating = 0


-- debugging stuff
DEBUG = false 					-- set to true to turn debugging on again (disabled now it all appears to be working)
function DebugPrint( message )
	if (DEBUG) then
		Print( message )
	end
end

--------------------------------------------------------------------------------------
-- BASE INITIALISE
-- initialise function used by all signal scripts
--
function BaseInitialise()

	-- Number of links in the signal
	gLinkCount = Call( "GetLinkCount" )
	
	-- Init occupation table
	gOccupationTable = {}
	for i=0, gLinkCount - 1 do
		gOccupationTable[i] = 0
	end

	-- JB 26/04/07 - Fix for bug #3759 - Keep track of current state of each link in case of junction change ahead
	gLinkState = {}
	for link = 0, gLinkCount - 1 do
		gLinkState[link] = SIGNAL_CLEARED
	end
end

--------------------------------------------------------------------------------------
-- RESET SIGNAL STATE
-- Resets the signal when the route / scenario is reloaded
--
function ResetSignalState ( )
	
	DebugPrint( "DEBUG: ResetSignalState() started")
	
	-- Re-initialise the signal
	Initialise()
	
	DebugPrint( "DEBUG: ResetSignalState() ended")
end

--------------------------------------------------------------------------------------
-- CHECK SIGNAL STATE
-- Change the signal based on the state of the connected link - used when our junction switches, as a fix for bug #3759
--
function CheckSignalState( )

	if gConnectedLink < 0 then
		Print("ERROR: CheckSignalState() received negative gConnectedLink - scripts should check for this before calling the function!")
	
	elseif gLinkState[gConnectedLink] == SIGNAL_CLEARED then
		NotOccupied( gConnectedLink )

	elseif gLinkState[gConnectedLink] == SIGNAL_WARNING then
		Warning( gConnectedLink )

	elseif gLinkState[gConnectedLink] == SIGNAL_WARNING2 then
		Warning2( gConnectedLink )
	
	else
		DebugPrint("CheckSignalState - Trying to switch signal based on invalid link state")
	end
end	
	
	
--------------------------------------------------------------------------------------
-- BASE ON CONSIST PASS
-- OnConsistPass function used by all signal scripts
--
function BaseOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end

	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
			
				-- Check for SPADs first
				if (gSignalState == SIGNAL_BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
				
				-- Then set the signal to blocked
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: BaseOnConsistPass: A train starts passing link 0 in the opposite direction." )
				
				-- If we're the only train in this signal's block(s) and the line is connected...
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 then

					-- Get this signal's link state
					local signalStateMessage = gLinkState[gConnectedLink]
				    DebugPrint( "DEBUG: BaseOnConsistPass: Send signal message " .. signalStateMessage)
					Call( "SendSignalMessage", signalStateMessage, "", -1,1, 0 )
				end

				DebugPrint( "DEBUG: BaseOnConsistPass: Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
				
				-- and also set signal to cleared if not blocked by another consist and junction is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
					CheckSignalState( )
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: BaseOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					else
						Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON JUNCTION STATE CHANGE
-- OnJunctionStateChange function used by all signal scripts
--
function BaseOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: BaseOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				gConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				DebugPrint( ("DEBUG: BaseOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
				-- am I a multi-link signal?
				if (gConnectedLink > 0) then
					-- block unconnected signals
					DebugPrint( "DEBUG: BaseOnJunctionStateChange: Block unconnected signals" )
					for i=1, gLinkCount - 1 do
						if i ~= gConnectedLink then
							Occupied( i )
						end
					end
					
					-- update occupation
					DebugPrint( ("DEBUG: BaseOnJunctionStateChange: Update occupation: gOccupationTable[" .. gConnectedLink .. "]: " .. gOccupationTable[gConnectedLink]) )
					
					-- do additional check for gConnectedLink 0... If that is blocked, then the junction is blocked as well
					if (gOccupationTable[gConnectedLink] == 0) and (gOccupationTable[0] == 0) then
						-- JB 26/04/07 - Fix for bug #3759 - Change signal based on state of connected link instead of just setting it to green
						CheckSignalState( )
					else
						Occupied( gConnectedLink )			-- arm should already be showing the blocked anim
					end

				-- AEH 13/04/2007: set the junction to blocked if there's no valid exit from it (eg for crossover when points at other end of linking track are set against us)
				elseif gConnectedLink == -1 then
				       Occupied( 0 )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON SIGNAL MESSAGE
-- Handles messages from other signals
--
function BaseOnSignalMessage( message, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check for signal receiving a message it might need to forward, in case there are two overlapping signal blocks (eg for a converging junction or crossover)
	if (linkIndex > 0) then
	
		-- We've received a PASS_ message, so forward it on
		if message > PASS_OFFSET then
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
			
		-- Any message other than RESET_SIGNAL_STATE and JUNCTION_STATE_CHANGE should be forwarded as PASS_ messages
		-- Also ignore initialisation messages from trains straddling a link - these will have the "DoNotForward" parameter
		elseif message ~= RESET_SIGNAL_STATE and message ~= JUNCTION_STATE_CHANGE and parameter ~= "DoNotForward" then
			Call( "SendSignalMessage", message + PASS_OFFSET, parameter, -direction, 1, linkIndex )
		end
	end
	
	-- always check for a valid link index
	if (linkIndex >= 0) then

		-- If the message is a PASS_ message...
		if message >= PASS_INITIALISE_SIGNAL_TO_BLOCKED then

			-- Only pay attention to it if we're not the base link of a signal
			if linkIndex > 0 then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )
			end

			-- Otherwise, it's a normal signal so just process it as normal
		else
			ReactToSignalMessage( message, parameter, direction, linkIndex )		
		end
	end
end

--[[
--------------------------------------------------------------------------------------
-- PRINT OCCUPATION TABLE
-- Debugging function, used to print the current occupation table
--
function DebugPrintOccupationTable( occupationTable )

	occupation = "DebugPrintOccupationTable( table )"
	for i = 0, gLinkCount - 1 do
		occupation = (occupation .. ", " .. i .. "=" .. gOccupationTable[i])
	end
	
	DebugPrint( ("DEBUG: " .. occupation) )
end
--]]


--------------------------------------------------------------------------------------
-- Common UK semaphore signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- DEFAULT INITIALISE
-- Sets up the signal
--
function DefaultInitialise ( routeCount )

	-- calls the base initialise function in the global common script
	BaseInitialise()

	-- This will be set to true once the signal does its first Update
	gInitialised = false

	-- Number of indicated routes on signal with their own arm(s)
		-- (this is not necessarily the same as the number of links)
	gRouteCount = routeCount
	
	-- Overall state of signal (defaults to cleared)
	gSignalState = SIGNAL_CLEARED
	
	-- Initialise 2D map indication to clear as well
	Call( "Set2DMapSignalState", CLEAR )
	
	-- animation states
	ANIMSTATE_OPEN				= 0
	ANIMSTATE_ANIMTOOPEN		= 1
	ANIMSTATE_CLOSED			= 2
	ANIMSTATE_ANIMTOCLOSED		= 3
	
	-- arm identifiers
	ROUTE_MAIN 					= 1		-- main route
	ROUTE_DIVERGING				= 2		-- diverging route
	ARM_HOME					= 0		-- home signal arm
	ARM_DISTANT					= 1		-- distant signal arm

	-- initialise arm states for animation
	gArmTable = {}
	gUpdatingArm = { }
	
	gStateIndex = 0
	gChildName = 1
	gProceedAnimIndex = 2
	gBlockedAnimIndex = 3
	
	for routeIndex=1, gRouteCount do
		gUpdatingArm[routeIndex] = {}
		gArmTable[routeIndex] = {}
		
		for armIndex=ARM_HOME, ARM_DISTANT do
			gUpdatingArm[routeIndex][armIndex] = false
			gArmTable[routeIndex][armIndex] = {}
			gArmTable[routeIndex][armIndex][gStateIndex] = -1
			gArmTable[routeIndex][armIndex][gChildName] = ""
			gArmTable[routeIndex][armIndex][gProceedAnimIndex] = ""
			gArmTable[routeIndex][armIndex][gBlockedAnimIndex] = ""
		end
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT UPDATE
-- Handles animation for signal arms
--
function DefaultUpdate( time )

	-- If we've not been fully initialised yet, check our junction state now
	if not gInitialised then
		OnJunctionStateChange( 0, "", 1, 0 )
		gInitialised = true
	end

	local animState
	local animIndex
	local anim
	local animCall
	
	for i=1, gRouteCount do
		for j=ARM_HOME, ARM_DISTANT do
			
			-- ignore any combinations of arms and linkIndex that don't exist
			if gArmTable[i][j][gChildName] ~= "" then	
				animState = gArmTable[i][j][gStateIndex]
				animCall = gArmTable[i][j][gChildName] .. ":AddTime"
				
				-- if animating to an open (proceed) state
				if (animState == ANIMSTATE_ANIMTOOPEN) then
					
					-- reset any animations currently running on that arm!
					Call( gArmTable[i][j][gChildName] .. ":Reset", gArmTable[i][j][gBlockedAnimIndex] )
					
					anim = gArmTable[i][j][gProceedAnimIndex]
					
					-- check that the animation has finished / update the animation
					if (anim == "") or (Call( animCall, anim, time ) ~= 0) then
						DebugPrint( ("DEBUG: DefaultUpdate: SetState Proceed " .. i .. "," .. j) )
						SetState( ANIMSTATE_OPEN, i, j )
					end
					
				-- if animating to a closed (blocked) state			
				elseif (animState == ANIMSTATE_ANIMTOCLOSED) then
					
					-- reset any animations currently running on that arm!
					Call( gArmTable[i][j][gChildName] .. ":Reset", gArmTable[i][j][gProceedAnimIndex] )
					
					anim = gArmTable[i][j][gBlockedAnimIndex]
					
					-- check that the animation has finished / update the animation
					if (anim == "") or (Call( animCall, anim, time ) ~= 0) then
						DebugPrint( "DEBUG: DefaultUpdate: SetState Blocked ", i, ",", j )
						SetState( ANIMSTATE_CLOSED, i, j )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- SET STATE
-- Sets animation states for a specific signal arm
--
function SetState( newState, routeIndex, armIndex )

	DebugPrint( ("DEBUG: SetState(" .. newState .. ", " .. routeIndex .. ", " .. armIndex .. ")") )
	local updateCount = gUpdating
	
	if (routeIndex > 0) and (routeIndex <= gRouteCount) and (armIndex <= ARM_DISTANT) then
		if (gArmTable[routeIndex][armIndex][gStateIndex] ~= newState) then
			
			-- begin/end update depending on the new state
			if (newState == ANIMSTATE_ANIMTOOPEN) or 
				(newState == ANIMSTATE_ANIMTOCLOSED) then
				
				-- check if this arm is already being updated
				if (not gUpdatingArm[routeIndex][armIndex]) then
					gUpdatingArm[routeIndex][armIndex] = true
					gUpdating = gUpdating + 1
					
					-- If this is the only arm updating at the moment, begin update
					if gUpdating == 1 then
						Call( "BeginUpdate" )
					end
					
					-- play sound when animation starts!
					if (newState == ANIMSTATE_ANIMTOOPEN) then
						Call ("ControlSound:SetParameter", "SignalProgress", 1)
					elseif (newState == ANIMSTATE_ANIMTOCLOSED) then
						Call ("ControlSound:SetParameter", "SignalProgress", 0)
					end
				end
				
			elseif (newState == ANIMSTATE_OPEN) or 
				(newState == ANIMSTATE_CLOSED) then
				
				-- check if this arm is being updated
				if (gUpdatingArm[routeIndex][armIndex]) then
					gUpdatingArm[routeIndex][armIndex] = false
					gUpdating = gUpdating - 1
					
					-- If this was the only arm updating, end update
					if gUpdating == 0 then
						Call( "EndUpdate" )
					end			
				end
			end
			
			gArmTable[routeIndex][armIndex][gStateIndex] = newState;
		end

		DebugPrint( ("DEBUG: SetState: UpdateCount was: " .. updateCount .. ", is now: " .. gUpdating) )
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT ON CONSIST PASS
-- OnConsistPass function used by all UK Semaphore home signal scripts
--
function DefaultOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: DefaultOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end

	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
			
				-- Check for SPADs first
				if (gSignalState == SIGNAL_BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
				
				-- and also set signal to blocked if not already blocked or disconnected
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: DefaultOnConsistPass: A train starts passing link 0 in the opposite direction. Send OCCUPATION_INCREMENT" )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line, or exit signal for connected line
				if (gConnectedLink == linkIndex) or (gLinkCount == 2 and gConnectedLink ~= -1) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
				
				-- and also set signal to cleared if not blocked by another consist and junction (if any) is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
					NotOccupied(0)
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: DefaultOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: DefaultOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: DefaultOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					else
						Print( "DEBUG: DefaultOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: DefaultOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- DEFAULT JUNCTION STATE
-- Uses base junction state change code
--
function DefaultOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: DefaultOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: DefaultOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				local newConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				
				if newConnectedLink == gConnectedLink then
					-- Don't waste time doing anything else if the connected link hasn't changed
					DebugPrint( ("WARNING: DefaultOnJunctionStateChange triggered by message from junction that hasn't effected its state, still connected to " .. gConnectedLink ) )

				else
					gConnectedLink = newConnectedLink

					DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
					if (gConnectedLink > 0) then
							
						-- update occupation
						DebugPrint( ("DEBUG: DefaultOnJunctionStateChange: Update occupation: gOccupationTable[" .. gConnectedLink .. "]: " .. gOccupationTable[gConnectedLink]) )
						
						-- Check if newly connected route is blocked or not
						if (gOccupationTable[gConnectedLink] == 0) and (gOccupationTable[0] == 0) then
							NotOccupied( gConnectedLink )
						else
							Occupied( gConnectedLink )
						end

					-- AEH 13/04/2007: set the junction to blocked if there's no valid exit from it (eg for crossover when points at other end of linking track are set against us)
					elseif gConnectedLink == -1 then
					       Occupied( 0 )
					end
				end
			end
		end
	end
end

-------------------------------------------------------------------------------------
-- REACT TO SIGNAL MESSAGE
-- Subfunction to save duplicate code when handling pass back messages - just takes all the old scripting out of the DefaultOnSignalMessage function
--
function DefaultReactToSignalMessage( message, parameter, direction, linkIndex )
	
	if (message == OCCUPATION_DECREMENT) then
		if gOccupationTable[linkIndex] > 0 then
			gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
			DebugPrint( ("DEBUG: OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		else
			Print( ("DEBUG: OnSignalMessage: OCCUPATION_DECREMENT received... gOccupationTable[" .. linkIndex .. "] was already 0!") )
		end
		
		-- check when cleared
		if (gConnectedLink == linkIndex) and (gOccupationTable[0] == 0) and (gOccupationTable[gConnectedLink] == 0) then
			NotOccupied( gConnectedLink )
		end
	
	elseif (message == OCCUPATION_INCREMENT) then			
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("OnSignalMessage: OCCUPATION_INCREMENT received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- If this is the connected link, set it as occupied
		if (gConnectedLink == linkIndex) then
			Occupied( gConnectedLink )
		end
		
	-- added a special message for when the signal is initialised with a consist in its signal block (ignored by dist signals)				
	elseif (message == INITIALISE_SIGNAL_TO_BLOCKED) then		
		gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
		DebugPrint( ("DEBUG: OnSignalMessage: INITIALISE_SIGNAL_TO_BLOCKED received... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
		
		-- Only need to check this if we're a single link signal, otherwise when our junction state is checked we'll know if we're blocked or not
		if (gLinkCount == 1) then
			Occupied( linkIndex )
		end

	-- JB 04/05/07 - New junction state change message added
	elseif (message == JUNCTION_STATE_CHANGE) then
		DebugPrint( "DEBUG: OnSignalMessage: JUNCTION_STATE_CHANGE received" )
		
		-- Only act on message if it arrived at link 0, junction_state parameter is "0", and this signal spans a junction (ie, has more than one link)
		if linkIndex == 0 and parameter == "0" and gLinkCount > 1 and gInitialised then
			OnJunctionStateChange( 0, "", 1, 0 )
			
			-- Pass on message in case junction is protected by more than one signal
				-- NB: this message is passed on when received on link 0 instead of link 1+
				-- When it reaches a link > 0 or a signal with only one link, it will be consumed
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
		end

	-- This message is to reset the signals after a scenario / route is reset
	elseif (message == RESET_SIGNAL_STATE) then
		ResetSignalState()		
	end
end
	
-------------------------------------------------------------------------------------
-- DEFAULT ON SIGNAL MESSAGE
-- Handles messages from other signals. 
--
function DefaultOnSignalMessage( message, parameter, direction, linkIndex )
	
	-- Use the base function for this
	BaseOnSignalMessage( message, parameter, direction, linkIndex )
end

--------------------------------------------------------------------------------------
-- DISPLAY ARM TABLE
-- Debug used for animation
--
function DisplayArmTable()

	Print( "ArmTable" )
	for i=1, gRouteCount do
		for j=ARM_HOME, ARM_DISTANT do
			Print( "(", i, ",", j, ") " )
			Print( "State: ", gArmTable[i][j][gStateIndex], " Proceed: ", gArmTable[i][j][gProceedAnimIndex], " Blocked: ", gArmTable[i][j][gBlockedAnimIndex] )
		end
	end
end

--------------------------------------------------------------------------------------
-- GET SIGNAL STATE
-- Gets the current state of the signal - blocked, warning or clear. 
-- The state info is used for AWS/TPWS scripting.
--
function GetSignalState( )

	-- Just return gSignalState
	return gSignalState
end


--------------------------------------------------------------------------------------
-- Common signal functionality
-- KUJU / Rail Simulator
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- GLOBALS

-- States
CLEAR = 0
WARNING = 1
BLOCKED = 2

-- Signal Messages (0-9 are reserved by code)
RESET_SIGNAL_STATE						= 0
INITIALISE_SIGNAL_TO_BLOCKED 			= 1
JUNCTION_STATE_CHANGE					= 2
INITIALISE_TO_PREPARED					= 3

-- Locally defined signal mesages
OCCUPATION_INCREMENT					= 10
OCCUPATION_DECREMENT					= 11

SIGNAL_BLOCKED							= 12
SIGNAL_CLEARED							= 13
SIGNAL_WARNING							= 14
SIGNAL_WARNING2							= 15

-- GERMAN SPECIFIC functionality: custom signal message used to set lights green or reset to red after consist pass
SIGNAL_PREPARE_FOR_TRAIN				= 16
SIGNAL_RESET_AFTER_TRAIN_PASS			= 17

-- special signal messages only used by the signals that message the opposite facing signal
-- in the section of track where two single direction tracks converge to one dual direction track
	-- currently only used for UK Semaphore signals
OCCUPATION_REVERSE_INCREMENT  			= 18
OCCUPATION_REVERSE_DECREMENT 			= 19

-- Signal Messages 20-29 are available for later extension or end-users

-- What you need to add to a signal message number to turn it into the equivalent PASS_ message
PASS_OFFSET								= 30

-- Pass on messages to handle overlapping links (eg for converging junctions / crossovers)
PASS_RESET_SIGNAL_STATE					= PASS_OFFSET + RESET_SIGNAL_STATE				-- Never used!
PASS_INITIALISE_SIGNAL_TO_BLOCKED		= PASS_OFFSET + INITIALISE_SIGNAL_TO_BLOCKED
PASS_JUNCTION_STATE_CHANGE				= PASS_OFFSET + JUNCTION_STATE_CHANGE
PASS_INITIALISE_TO_PREPARED				= PASS_OFFSET + INITIALISE_TO_PREPARED
PASS_OCCUPATION_INCREMENT				= PASS_OFFSET + OCCUPATION_INCREMENT
PASS_OCCUPATION_DECREMENT				= PASS_OFFSET + OCCUPATION_DECREMENT
PASS_SIGNAL_BLOCKED						= PASS_OFFSET + SIGNAL_BLOCKED
PASS_SIGNAL_CLEARED						= PASS_OFFSET + SIGNAL_CLEARED
PASS_SIGNAL_WARNING						= PASS_OFFSET + SIGNAL_WARNING
PASS_SIGNAL_WARNING2					= PASS_OFFSET + SIGNAL_WARNING2
PASS_SIGNAL_PREPARE_FOR_TRAIN			= PASS_OFFSET + SIGNAL_PREPARE_FOR_TRAIN
PASS_SIGNAL_RESET_AFTER_TRAIN_PASS 		= PASS_OFFSET + SIGNAL_RESET_AFTER_TRAIN_PASS
PASS_OCCUPATION_REVERSE_INCREMENT		= PASS_OFFSET + OCCUPATION_REVERSE_INCREMENT
PASS_OCCUPATION_REVERSE_DECREMENT		= PASS_OFFSET + OCCUPATION_REVERSE_DECREMENT
	
-- SPAD and warning system messages to pass to consist
AWS_MESSAGE								= 11
TPWS_MESSAGE							= 12
SPAD_MESSAGE 							= 14


-- Script globals
gConnectedLink = 0
gUpdating = 0


-- debugging stuff
DEBUG = false 					-- set to true to turn debugging on again (disabled now it all appears to be working)
function DebugPrint( message )
	if (DEBUG) then
		Print( message )
	end
end

--------------------------------------------------------------------------------------
-- BASE INITIALISE
-- initialise function used by all signal scripts
--
function BaseInitialise()

	-- Number of links in the signal
	gLinkCount = Call( "GetLinkCount" )
	
	-- Init occupation table
	gOccupationTable = {}
	for i=0, gLinkCount - 1 do
		gOccupationTable[i] = 0
	end

	-- JB 26/04/07 - Fix for bug #3759 - Keep track of current state of each link in case of junction change ahead
	gLinkState = {}
	for link = 0, gLinkCount - 1 do
		gLinkState[link] = SIGNAL_CLEARED
	end
end

--------------------------------------------------------------------------------------
-- RESET SIGNAL STATE
-- Resets the signal when the route / scenario is reloaded
--
function ResetSignalState ( )
	
	DebugPrint( "DEBUG: ResetSignalState() started")
	
	-- Re-initialise the signal
	Initialise()
	
	DebugPrint( "DEBUG: ResetSignalState() ended")
end

--------------------------------------------------------------------------------------
-- CHECK SIGNAL STATE
-- Change the signal based on the state of the connected link - used when our junction switches, as a fix for bug #3759
--
function CheckSignalState( )

	if gConnectedLink < 0 then
		Print("ERROR: CheckSignalState() received negative gConnectedLink - scripts should check for this before calling the function!")
	
	elseif gLinkState[gConnectedLink] == SIGNAL_CLEARED then
		NotOccupied( gConnectedLink )

	elseif gLinkState[gConnectedLink] == SIGNAL_WARNING then
		Warning( gConnectedLink )

	elseif gLinkState[gConnectedLink] == SIGNAL_WARNING2 then
		Warning2( gConnectedLink )
	
	else
		DebugPrint("CheckSignalState - Trying to switch signal based on invalid link state")
	end
end	
	
	
--------------------------------------------------------------------------------------
-- BASE ON CONSIST PASS
-- OnConsistPass function used by all signal scripts
--
function BaseOnConsistPass ( prevFrontDist, prevBackDist, frontDist, backDist, linkIndex )

	local crossingStart = 0
	local crossingEnd = 0

	-- if the consist is crossing the signal now
	if ( frontDist > 0 and backDist < 0 ) or ( frontDist < 0 and backDist > 0 ) then
		-- if the consist was previously before/after siganl then the crossing has just started
		if ( prevFrontDist < 0 and prevBackDist < 0 ) or ( prevFrontDist > 0 and prevBackDist > 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing started... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingStart = 1
		end
		
	-- otherwise the consist is not crossing the signal now
	else	
		-- the the consist was previously crossing the signal, then it has just finished crossing
		if ( prevFrontDist < 0 and prevBackDist > 0 ) or ( prevFrontDist > 0 and prevBackDist < 0 ) then
			DebugPrint( ("DEBUG: BaseOnConsistPass: Crossing cleared... linkIndex = " .. linkIndex .. ", gConnectedLink = " .. gConnectedLink) )
			crossingEnd = 1
		end
	end

	-- a train has just started crossing a link!
	if (crossingStart == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the normal direction...
		if (prevFrontDist > 0 and prevBackDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing forwards!" )
			
			-- if the train just started crossing link 0 in the normal direction, increment occupation table slot 0
			if (linkIndex == 0) then
			
				-- Check for SPADs first
				if (gSignalState == SIGNAL_BLOCKED) then
					DebugPrint("SPAD")
					Call( "SendConsistMessage", SPAD_MESSAGE, "" )
				end
				
				-- Then set the signal to blocked
				Occupied( 0 )
				
				gOccupationTable[0] = gOccupationTable[0] + 1
				DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				
			-- if the train just started crossing link 1, 2, 3 etc. increment the appropriate occupation table slot
			elseif (linkIndex > 0) then
				gOccupationTable[linkIndex] = gOccupationTable[linkIndex] + 1
				DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just started crossing in the opposite direction...
		elseif (prevFrontDist < 0 and prevBackDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Started crossing backwards!" )
			
			-- if the train just started crossing link 0 in reverse, send OCCUPATION_INCREMENT
			if (linkIndex == 0) then

				DebugPrint( "DEBUG: BaseOnConsistPass: A train starts passing link 0 in the opposite direction." )
				
				-- If we're the only train in this signal's block(s) and the line is connected...
				if gOccupationTable[0] == 1 and gConnectedLink ~= -1 then

					-- Get this signal's link state
					local signalStateMessage = gLinkState[gConnectedLink]
				    DebugPrint( "DEBUG: BaseOnConsistPass: Send signal message " .. signalStateMessage)
					Call( "SendSignalMessage", signalStateMessage, "", -1,1, 0 )
				end

				DebugPrint( "DEBUG: BaseOnConsistPass: Send OCCUPATION_INCREMENT." )
				Call( "SendSignalMessage", OCCUPATION_INCREMENT, "", -1, 1, 0 )
				
			-- if the train just started crossing link 1, 2, 3 etc. in reverse, increment occupation table slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					gOccupationTable[0] = gOccupationTable[0] + 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: INCREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )

				-- Otherwise  the train must be reversing onto another line
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist reversing down another line, don't increment occupation table for this line" )
				end
			end
		end
		
	-- a train has just finished crossing a link!
	elseif (crossingEnd == 1) then
		
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing backwards...
		if (frontDist > 0 and backDist > 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing backwards!" )
			
			-- if the train just finished crossing link 0 in reverse, decrement occupation table slot 0
			if (linkIndex == 0) then
				if gOccupationTable[0] > 0 then
					gOccupationTable[0] = gOccupationTable[0] - 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
				else
					Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
				end
				
				-- and also set signal to cleared if not blocked by another consist and junction is connected
				if (gOccupationTable[0] == 0 and gConnectedLink ~= -1 and gOccupationTable[gConnectedLink] == 0) then
					CheckSignalState( )
				end

			-- if the train just finished crossing link 1, 2, 3 etc. in reverse, decrement the appropriate occupation table slot
			elseif (linkIndex > 0) then
				if gOccupationTable[linkIndex] > 0 then
					gOccupationTable[linkIndex] = gOccupationTable[linkIndex] - 1
					DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[" .. linkIndex .. "]: " .. gOccupationTable[linkIndex]) )
				else
					Print( ( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[" .. linkIndex .. "] was already empty" ) )
				end
			end
			
		--------------------------------------------------------------------------------------
		-- if a train has just finished crossing in the normal direction...
		elseif (frontDist < 0 and backDist < 0) then
			
			DebugPrint( "DEBUG: BaseOnConsistPass: Finished crossing forwards!" )
			
			-- if the train just finished crossing link 0 in the normal direction, send OCCUPATION_DECREMENT
			if (linkIndex == 0) then
				DebugPrint( "DEBUG: BaseOnConsistPass: A train finishes passing link 0 in the normal direction, send OCCUPATION_DECREMENT." )
				Call( "SendSignalMessage", OCCUPATION_DECREMENT, "", -1, 1, 0 )
				
			-- if the train just finished crossing link 1, 2, 3 etc. in the normal direction, decrement occupation slot 0
			elseif (linkIndex > 0) then

				-- Junction connected to this line
				if (gConnectedLink == linkIndex) then
					if gOccupationTable[0] > 0 then
						gOccupationTable[0] = gOccupationTable[0] - 1
						DebugPrint( ("DEBUG: BaseOnConsistPass: DECREMENT... gOccupationTable[0]: " .. gOccupationTable[0]) )
					else
						Print( "DEBUG: BaseOnConsistPass: Attempting to DECREMENT... gOccupationTable[0] was already empty" )
					end
				else
					DebugPrint( "DEBUG: BaseOnConsistPass: Consist on another line, don't decrement occupation table for this line" )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON JUNCTION STATE CHANGE
-- OnJunctionStateChange function used by all signal scripts
--
function BaseOnJunctionStateChange( junction_state, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnJunctionStateChange(" .. junction_state .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check junction has finished transition
	if junction_state == 0 then
		if linkIndex == 0 then
			if gLinkCount == 1 then
				DebugPrint( "WARNING: BaseOnJunctionStateChange: Junction change message received by single link signal" )
			else
				-- this will be used as a search depth - it must be passed as a string
				linkCountAsString = "" .. (5 * (gLinkCount + 1))
				
				-- find the link that is now connected to the signal
				gConnectedLink = Call( "GetConnectedLink", linkCountAsString, 1, 0 )
				DebugPrint( ("DEBUG: BaseOnJunctionStateChange: Activate connected link: " .. gConnectedLink) )
				
				-- am I a multi-link signal?
				if (gConnectedLink > 0) then
					-- block unconnected signals
					DebugPrint( "DEBUG: BaseOnJunctionStateChange: Block unconnected signals" )
					for i=1, gLinkCount - 1 do
						if i ~= gConnectedLink then
							Occupied( i )
						end
					end
					
					-- update occupation
					DebugPrint( ("DEBUG: BaseOnJunctionStateChange: Update occupation: gOccupationTable[" .. gConnectedLink .. "]: " .. gOccupationTable[gConnectedLink]) )
					
					-- do additional check for gConnectedLink 0... If that is blocked, then the junction is blocked as well
					if (gOccupationTable[gConnectedLink] == 0) and (gOccupationTable[0] == 0) then
						-- JB 26/04/07 - Fix for bug #3759 - Change signal based on state of connected link instead of just setting it to green
						CheckSignalState( )
					else
						Occupied( gConnectedLink )			-- arm should already be showing the blocked anim
					end

				-- AEH 13/04/2007: set the junction to blocked if there's no valid exit from it (eg for crossover when points at other end of linking track are set against us)
				elseif gConnectedLink == -1 then
				       Occupied( 0 )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------------
-- BASE ON SIGNAL MESSAGE
-- Handles messages from other signals
--
function BaseOnSignalMessage( message, parameter, direction, linkIndex )

	DebugPrint( ("DEBUG: BaseOnSignalMessage(" .. message .. ", " .. parameter .. ", " .. direction .. ", " .. linkIndex .. ")") )
	
	-- Check for signal receiving a message it might need to forward, in case there are two overlapping signal blocks (eg for a converging junction or crossover)
	if (linkIndex > 0) then
	
		-- We've received a PASS_ message, so forward it on
		if message > PASS_OFFSET then
			Call( "SendSignalMessage", message, parameter, -direction, 1, linkIndex )
			
		-- Any message other than RESET_SIGNAL_STATE and JUNCTION_STATE_CHANGE should be forwarded as PASS_ messages
		-- Also ignore initialisation messages from trains straddling a link - these will have the "DoNotForward" parameter
		elseif message ~= RESET_SIGNAL_STATE and message ~= JUNCTION_STATE_CHANGE and parameter ~= "DoNotForward" then
			Call( "SendSignalMessage", message + PASS_OFFSET, parameter, -direction, 1, linkIndex )
		end
	end
	
	-- always check for a valid link index
	if (linkIndex >= 0) then

		-- If the message is a PASS_ message...
		if message >= PASS_INITIALISE_SIGNAL_TO_BLOCKED then

			-- Only pay attention to it if we're not the base link of a signal
			if linkIndex > 0 then

				-- Knock PASS_OFFSET off the signal message number to convert it back to a normal message for processing
				ReactToSignalMessage( message - PASS_OFFSET, parameter, direction, linkIndex )
			end

			-- Otherwise, it's a normal signal so just process it as normal
		else
			ReactToSignalMessage( message, parameter, direction, linkIndex )		
		end
	end
end

--[[
--------------------------------------------------------------------------------------
-- PRINT OCCUPATION TABLE
-- Debugging function, used to print the current occupation table
--
function DebugPrintOccupationTable( occupationTable )

	occupation = "DebugPrintOccupationTable( table )"
	for i = 0, gLinkCount - 1 do
		occupation = (occupation .. ", " .. i .. "=" .. gOccupationTable[i])
	end
	
	DebugPrint( ("DEBUG: " .. occupation) )
end
--]]


