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
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )
	elseif (gExpectState == STATE_SLOW) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	gLightFlashOn )
	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2, 	gLightFlashOn )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )
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
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )

	elseif (gAnimState == ANIMSTATE_SLOW) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )

	elseif (gAnimState == ANIMSTATE_SLOWER) then
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	1 )

	else	-- stop or blocked
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN,	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_RED,		1 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN2,	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_WHITE, 	0 )
		SwitchLight( SIGNAL_HEAD_NAME, LIGHT_NODE_GREEN3, 	0 )
	end
end

require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/SE V2 CommonScript.lua"