-------------------------------------------------------------------------------------
-- Swedish CommonScript to switch lights on/off
-- KMW / Anders Eriksson
-- 090108 First version.
-- 201223 Added support for child objects
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
	-- If we're a signal head, we don't need to know our own name to switch our lights on and off
	if (SIGNAL_HEAD_NAME == nil) then
		SIGNAL_HEAD_NAME = ""
	if (gSignalState == STATE_GO) then
		SwitchLight( LIGHT_NODE_GREEN,		1 )
		SwitchLight( LIGHT_NODE_RED,			0 )
		SwitchLight( LIGHT_NODE_GREEN2,		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 		0 )

	elseif (gSignalState == STATE_SLOW) then
		SwitchLight( LIGHT_NODE_GREEN,		1 )
		SwitchLight( LIGHT_NODE_RED,			0 )
		SwitchLight( LIGHT_NODE_GREEN2,		1 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 		0 )

	else	-- stop or blocked
		SwitchLight( LIGHT_NODE_GREEN,		0 )
		SwitchLight( LIGHT_NODE_RED,			1 )
		SwitchLight( LIGHT_NODE_GREEN2,		0 )
		SwitchLight( LIGHT_NODE_WHITE, 		0 )
		SwitchLight( LIGHT_NODE_GREEN3, 		0 )
	end
end

