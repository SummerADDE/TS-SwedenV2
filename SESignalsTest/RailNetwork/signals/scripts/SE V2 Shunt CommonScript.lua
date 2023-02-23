--------------------------------------------------------------------------------------
-- Animate Swedish distance signals
-- switch on/off the appropriate lights
function DefaultAnimate()
	DebugPrint("SetLights()")
	if (gAnimState == ANIMSTATE_GO) then
		if gExpectState == STATE_GO then
			if (LIGHT_NODE_GREEN2 ~= nil) then
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		1 )
			else
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		1 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )
			end
		else
			if (LIGHT_NODE_GREEN2 ~= nil) then
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		gLightFlashOn )
			else
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		gLightFlashOn )
				SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )
			end		
		end
	elseif (gAnimState == ANIMSTATE_SLOW or gAnimState == ANIMSTATE_SLOWER) then
		if gExpectState == STATE_GO or gExpectState == STATE_SLOW then
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_RED,			0 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN1,		1 )
			SwitchLight( SIGNAL_SHUNT_NAME, LIGHT_NODE_GREEN2,		0 )
		else
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
	
	if (gAnimState == ANIMSTATE_GO or gAnimState == ANIMSTATE_SLOW or gAnimState == ANIMSTATE_SLOWER or gAnimState == ANIMSTATE_CALLON) then
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