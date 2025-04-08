-- SE DummySignal.lua
-- En osynlig dummy-signal som fångar TAB och skickar vidare till nästa riktiga signal

 require "Assets/SummerADDE/SESignalsTest/RailNetwork/signals/scripts/Debugging.lua"

function Initialise()
    BaseInitialise()

    gHomeSignal     = false
    gDistanceSignal = false
    gBlockSignal    = false
    gShuntSignal    = false
    gCallOn         = 0
    gAspectIndex    = 0

    gSignalType     = "DummySignal"

    -- Försök hitta en kopplad signal (fungerar endast om placerad korrekt i editor)
    gConnectedLink = Call("GetConnectedLink", "10", 1, 0)
    if gConnectedLink == nil or gConnectedLink < 0 then
        DebugPrint("DummySignal: Ingen kopplad signal hittades – gConnectedLink = -1")
    else
        DebugPrint("DummySignal: Kopplad signal hittad på länk " .. tostring(gConnectedLink))
    end
end

function OnSignalMessage(message, parameter, direction, linkIndex)
    DebugPrint("DummySignal: OnSignalMessage(" .. tostring(message) .. ")")

    if message == REQUEST_TO_SPAD then
        DebugPrint("DummySignal: TAB-förfrågan mottagen – skickar vidare")

        if gConnectedLink ~= nil and gConnectedLink >= 0 then
            Call("SendSignalMessage", REQUEST_TO_SPAD, parameter, direction, 1, gConnectedLink)
        else
            DebugPrint("DummySignal: Kunde inte vidarebefordra – gConnectedLink ogiltig")
        end
    end
end

function SetLights() 
    -- Gör ingenting – denna signal har inga ljus
end
