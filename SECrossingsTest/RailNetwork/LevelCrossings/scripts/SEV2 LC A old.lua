-- States enumeration
LC_STATE_NONE = -1
LC_STATE_OPEN = 0
LC_STATE_APPROACH = 1
LC_STATE_CLOSING = 2
LC_STATE_CLOSED = 3
LC_STATE_OPENING = 4


-- Animation names
ANIM_OPEN = "Clear01"
ANIM_CLOSED = "Clear01"

NODE_CLOSED_LEFT = "R1"
NODE_CLOSED_RIGHT = "R2"
NODE_OPEN = "W1"
NODE_SIGNAL = "Y1"

WARN_LIGHT_FLASH_SECS = 0.5

-- Trigger distances
WARN_DISTANCE = 1000.0
CLOSE_DISTANCE = 950.0
PASS_DISTANCE = -30.0
CLOSED_TIME = 6.0
WARN_TIME = 1.0

-- Current state
gState = LC_STATE_NONE
gWarningTime = 0.0
gWarningAnimTime = 0.0
gClosedTime = 0.0
gAnimTime = 0.0
gFlashSide = 0
gFlashSide = 0

-- debugging stuff
DEBUG = true	-- set to true to turn debugging on
function DebugPrint( message )
	if (DEBUG) then
		Print( message )
	end
end

--------------------------------------------
-- Initialise
function Initialise ()
	Call ( "*:BeginUpdate" );

end -- function Initialise ()

--------------------------------------------
-- OnConsistApproach
function OnConsistApproach ( frontDistance, endDistance, speed )

	distance = frontDistance;
	if frontDistance < 0.0 then
		distance = -frontDistance;
	end
	
	if endDistance >= 0.0 and endDistance < distance then
		distance = endDistance;
	end
	
	if endDistance < 0.0 and -endDistance < distance then
		distance = -endDistance;
	end
		
	--DebugPrint ( "OnConsistApproach: " .. distance .. " fr: " .. frontDistance .. " rr: " .. endDistance .. " speed: " .. speed );
	
	movingAway = false;
	if endDistance < PASS_DISTANCE then
		
		-- moving away over 100m passed gate open in 5.0seconds
		movingAway = true;
		
	end -- endDistance < PASS_DISTANCE ...
	
	if distance < CLOSE_DISTANCE then
	
		if gState == LC_STATE_OPEN or gState == LC_STATE_APPROACH or gState == LC_STATE_OPENING then
		
			if movingAway == false then
			
				CloseGates();
				
			end -- if movingAway == false then
		
		end -- if gState == LC_STATE_OPEN or ...
		
		if movingAway == false then
		
			gClosedTime = 0.0;
			gWarningTime = 0.0;
		
		end
		
	elseif distance < WARN_DISTANCE and movingAway == false then
	
		gWarningTime = 0.0;
		StartWarning();
	
	end -- if distance < 50.0 then ... else ...

end -- function OnConsistApproach ( distance )

--------------------------------------------
-- SetState
function SetState ( state )

	if gState ~= state then
	
		if state == LC_STATE_OPEN then
		
			StopWarning();
			
		elseif state == LC_STATE_OPENING then
		
			StartWarning();
			OpenGates();
			
		elseif state == LC_STATE_CLOSING then
		
			StartWarning();
			CloseGates();
			
		else
		
			StartWarning();
			Call ( "BarrierRight01:AddTime", ANIM_CLOSED, -1000.0 ); -- force closed
			Call ( "BarrierRight02:AddTime", ANIM_CLOSED, -1000.0 ); -- force closed
			Call ( "BarrierLeft01:AddTime", ANIM_CLOSED, -1000.0 ); -- force closed
			Call ( "BarrierLeft02:AddTime", ANIM_CLOSED, -1000.0 ); -- force closed
	
		end -- if state == LC_STATE_OPEN then ...
		
		gState = state;
	
	end -- if gState ~= state then

end -- function SetState ( state )

--------------------------------------------
-- Update
function Update ( dTime )

	if gState == LC_STATE_NONE or gState == LC_STATE_OPEN then

	
		Call ( "BarrierRight01:AddTime", ANIM_CLOSED, 1000.0 ); -- force open
		Call ( "BarrierRight02:AddTime", ANIM_CLOSED, 1000.0 ); -- force open	
		Call ( "BarrierLeft01:AddTime", ANIM_CLOSED, 1000.0 ); -- force open
		Call ( "BarrierLeft02:AddTime", ANIM_CLOSED, 1000.0 ); -- force open	
		UpdateWarning ( dTime );
		Call ( "*:BeginUpdate" );
		gState = LC_STATE_OPEN;
		
	elseif gState == LC_STATE_OPENING then
	
		gAnimTime = Call ( "BarrierRight01:AddTime", ANIM_OPEN, dTime );
		Call ( "BarrierRight02:AddTime", ANIM_OPEN, dTime );
		Call ( "BarrierLeft01:AddTime", ANIM_OPEN, dTime );
		Call ( "BarrierLeft02:AddTime", ANIM_OPEN, dTime );
		UpdateWarning ( dTime );
		if gAnimTime ~= 0.0 then
		
			DebugPrint ( "Gate open" );
			StopWarning();
		
		end -- if gAnimTime < 0.f then		
	
	elseif gState == LC_STATE_CLOSING then
	
		gAnimTime = Call ( "BarrierRight01:AddTime", ANIM_CLOSED, -dTime );
		Call ( "BarrierRight02:AddTime", ANIM_CLOSED, -dTime );
		Call ( "BarrierLeft01:AddTime", ANIM_CLOSED, -dTime );
		Call ( "BarrierLeft02:AddTime", ANIM_CLOSED, -dTime );
		UpdateWarning ( dTime );
		if gAnimTime ~= 0.0 then
		
			DebugPrint ( "Gate closed" );
			gState = LC_STATE_CLOSED;
			-- stop sounds
			Call ( "Sound:SetParameter", "CrossingSound", 0 );
			UpdateWarning ( dTime );
			Call ( "*:SetCrossingState", LC_STATE_CLOSED );
			gClosedTime = 0.0;
		
		end -- if gAnimTime < 0.f then
	
	elseif gState == LC_STATE_CLOSED then
	
		gClosedTime = gClosedTime + dTime;
		UpdateWarning ( dTime );
		if gClosedTime > CLOSED_TIME then
		
			OpenGates();
		
		end -- if gClosedTime > 30.0 then
		
	elseif gState == LC_STATE_APPROACH then 
	
		gWarningTime = gWarningTime + dTime;
		UpdateWarning ( dTime );
		if gWarningTime > WARN_TIME then
		
			StopWarning();
		
		end -- if gWarningTime > 30.0 then
		
	end -- if gState == LC_STATE_OPENING then ...  elseif ...

end -- function Update ( time )

--------------------------------------------
-- CloseGates
function CloseGates()

	DebugPrint ( "Gate closing" );

	gState = LC_STATE_CLOSING;
	Call ( "*:SetCrossingState", LC_STATE_CLOSING );
	Call ( "*:BeginUpdate" );
	

end -- function CloseGates()

--------------------------------------------
-- OpenGates
function OpenGates()

	DebugPrint ( "Gate opening" );

	gState = LC_STATE_OPENING;
	Call ( "*:SetCrossingState", LC_STATE_OPENING );
	Call ( "*:BeginUpdate" );
	

end -- function OpenGates()

--------------------------------------------
-- StartWarning
function StartWarning()

	if gState == LC_STATE_OPEN then
	
		gState = LC_STATE_APPROACH;
		
		Call ( "*:SetCrossingState", LC_STATE_APPROACH );
		Call ( "*:BeginUpdate" );
		
		Call ( "Sound:SetParameter", "CrossingSound", 0 );
		Call ( "Sound:SetParameter", "CrossingSound", 1 );
		
	end -- if gState ~= LC_STATE_APPROACH then
	
end -- function StartWarning()


--------------------------------------------
-- StopWarning
function StopWarning ()

	gState = LC_STATE_OPEN;
	Call ( "*:SetCrossingState", LC_STATE_OPEN );
	Call ( "*:BeginUpdate" ); --Call ( "*:EndUpdate" );

	-- stop sounds
	Call ( "Sound:SetParameter", "CrossingSound", 0 );
	
end -- function StopWarning()

-----------------------------------------------
-- UpdateWarning
function UpdateWarning ( timeDelta )

		Call ( "Warning1:ActivateNode", NODE_OPEN, 0 );		
		Call ( "Warning2:ActivateNode", NODE_OPEN, 0 );		
		Call ( "Warning3:ActivateNode", NODE_OPEN, 0 );		
		Call ( "Warning4:ActivateNode", NODE_OPEN, 0 );

	gWarningAnimTime = gWarningAnimTime + timeDelta;
	if gWarningAnimTime > WARN_LIGHT_FLASH_SECS then
	
		gWarningAnimTime = gWarningAnimTime - WARN_LIGHT_FLASH_SECS;
		gFlashSide = 1 - gFlashSide;
		
	end
	
	if gState == LC_STATE_OPEN then
		--X-signals
		Call ( "Warning1:ActivateNode", NODE_CLOSED_LEFT, 0 );		
		Call ( "Warning2:ActivateNode", NODE_CLOSED_LEFT, 0 );		
		Call ( "Warning3:ActivateNode", NODE_CLOSED_LEFT, 0 );		
		Call ( "Warning4:ActivateNode", NODE_CLOSED_LEFT, 0 );
		--Barrier lights
		Call ( "BarrierRight01:ActivateNode", NODE_CLOSED_LEFT, 0 );
		Call ( "BarrierRight02:ActivateNode", NODE_CLOSED_LEFT, 0 );
		--V-signals
		Call ( "Signal1:ActivateNode", NODE_CLOSED_LEFT, 1 );
		Call ( "Signal1:ActivateNode", NODE_OPEN, 0 );
		Call ( "Signal2:ActivateNode", NODE_CLOSED_LEFT, 1 );
		Call ( "Signal2:ActivateNode", NODE_OPEN, 0 );
		--VF-signals
		Call ( "Signal3:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal4:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal5:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal6:ActivateNode", NODE_SIGNAL, gFlashSide );
	elseif gState == LC_STATE_CLOSED then
		--X-signals
		Call ( "Warning1:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		Call ( "Warning2:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );		
		Call ( "Warning3:ActivateNode", NODE_CLOSED_LEFT, 1 - gFlashSide );		
		Call ( "Warning4:ActivateNode", NODE_CLOSED_LEFT, 1 - gFlashSide );
		--Barrier lights
		Call ( "BarrierRight01:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		Call ( "BarrierRight02:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		--V-signals
		Call ( "Signal1:ActivateNode", NODE_CLOSED_LEFT, 0 );
		Call ( "Signal1:ActivateNode", NODE_OPEN, 1 );
		Call ( "Signal2:ActivateNode", NODE_CLOSED_LEFT, 0 );
		Call ( "Signal2:ActivateNode", NODE_OPEN, 1 );
		--VF-signals
		Call ( "Signal3:ActivateNode", NODE_SIGNAL, 1 );
		Call ( "Signal4:ActivateNode", NODE_SIGNAL, 1 );
		Call ( "Signal5:ActivateNode", NODE_SIGNAL, 1 );
		Call ( "Signal6:ActivateNode", NODE_SIGNAL, 1 );
	else
		--X-signals
		Call ( "Warning1:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		Call ( "Warning2:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );		
		Call ( "Warning3:ActivateNode", NODE_CLOSED_LEFT, 1 - gFlashSide );		
		Call ( "Warning4:ActivateNode", NODE_CLOSED_LEFT, 1 - gFlashSide );
		--Barrier lights
		Call ( "BarrierRight01:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		Call ( "BarrierRight02:ActivateNode", NODE_CLOSED_LEFT, gFlashSide );
		--V-signals
		Call ( "Signal1:ActivateNode", NODE_CLOSED_LEFT, 1 );
		Call ( "Signal1:ActivateNode", NODE_OPEN, 0 );
		Call ( "Signal2:ActivateNode", NODE_CLOSED_LEFT, 1 );
		Call ( "Signal2:ActivateNode", NODE_OPEN, 0 );
		--VF-signals
		Call ( "Signal3:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal4:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal5:ActivateNode", NODE_SIGNAL, gFlashSide );
		Call ( "Signal6:ActivateNode", NODE_SIGNAL, gFlashSide );
	end --if gState == LC_STATE_OPEN then ... elseif ...
	
end -- function UpdateWarning()
