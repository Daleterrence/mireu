_addon.name = 'Mireu'
_addon.author = 'DTR'
_addon.version = '1.0.0'
_addon.commands = {'mireu'}

packets = require('packets')
require('logger')

---[[WARNING: The following code injects "Update Request" packets to the server to forcibly spawn Mireu on your client as a workaround for the client failing to do so, due to severe lag. You SHOULD NOT change any of the below unless you are sure of what you are doing. Consider this your warning. Whilst this addon contains safeguards and checks to ensure you're in a scenario where these packets would be sent to the server naturally, there is always a risk. If you are uncomfortable with the idea of packet injection, please do not use this addon.]]

-- Spawn tracking
local spawn_active = false
local spawn_start_time = 0
local spawn_duration = 20 -- Duration in seconds to keep trying to spawn, you should not change this.
local spawn_interval = 4 -- Interval in seconds between spawn attempts, you should not change this.

-- Valid zones for Mireu, these may need to be changed in a future patch if SE changes zone IDs at all.
local di_zones = {
    [288] = "Escha - Zi'Tah",
    [289] = "Escha - Ru'Aun",
    [291] = "Reisenjima"
}

-- Mireu target IDs for each zone, these IDs might need to be updated in a future patch if SE shuffles around anything in these zones.
local mireu_ids = {
    ["288"] = 545,  -- Escha - Zi'Tah
    ["289"] = 690,  -- Escha - Ru'Aun
    ["291"] = 728   -- Reisenjima 
}

-- Check if Mireu has been successfully spawned
function is_mireu_spawned()
    local zone = tostring(windower.ffxi.get_info().zone)
    if not mireu_ids[zone] then
        return false
    end
    
    local mob = windower.ffxi.get_mob_by_index(mireu_ids[zone])
    
    if mob and mob.name == "Mireu" and mob.spawn_type == 16 then
        return true
    end
    
    return false
end

-- Attempt to spawn Mireu
function attempt_spawn()
    local zone = tostring(windower.ffxi.get_info().zone)
    if mireu_ids[zone] and mireu_ids[zone] ~= 0 then
        local p = packets.new('outgoing', 0x016)
        p["Target Index"] = mireu_ids[zone]
        packets.inject(p)
    end
end

-- Spawn loop
function start_spawn_loop()
    -- Prevents loop if already running
    if spawn_active then
        warning("You're already trying to spawn Mireu. Please wait until it completes.")
        return
    end
    
    local zone_id = windower.ffxi.get_info().zone
    local zone = tostring(zone_id)
    
    -- Check for Elvorseal buff as a safeguard
    local player = windower.ffxi.get_player()
    local has_elvorseal = false
    if player and player.buffs then
        for _, buff_id in ipairs(player.buffs) do
            if buff_id == 603 then
                has_elvorseal = true
                break
            end
        end
    end
    
    if not has_elvorseal then
        error("You need the Elvorseal buff first!")
        return
    end
    
    -- Validate zone as fail-safe
    if not di_zones[zone_id] then
        local zone_list = ""
        for id, name in pairs(di_zones) do
            zone_list = zone_list .. name .. " (" .. id .. "), "
        end
        zone_list = zone_list:sub(1, -3)
        error("You're not in a zone Mireu can spawn in. You should never see this message unless you have messed with the addon's code, or something has gone horribly wrong.")
        return
    end
    
    -- Validate index exists as fail-safe
    if not mireu_ids[zone] or mireu_ids[zone] == 0 then
        error("Mireu cannot spawn in " .. zone .. ". You should never see this message unless you have messed with the addon's code or something has reallllly broken.")
        return
    end
    
    -- Check if already spawned successfully
    if is_mireu_spawned() then
        error("Mireu has already been spawned!")
        return
    end
    
    -- Start spawn attempts
    spawn_active = true
    spawn_start_time = os.clock()
        notice("Attempting to spawn Mireu, retrying every " .. spawn_interval .. " seconds for up to " .. spawn_duration .. " seconds.")
    attempt_spawn()
end

-- Stop spawn loop
function stop_spawn_loop(reason)
    spawn_active = false
    if reason then
        notice(reason)
    end
end

-- Help command
function display_help()
    notice("Mireu - Attempts to forcibly spawn Mireu on your screen.")
    notice("Commands:")
    notice("  //mireu        - Attempts to spawn Mireu.")
    notice("  //mireu help   - Display this help message")
    notice("")
    notice("How it works:")
    notice("  - Must be in Escha - Zi'Tah, Escha - Ru'Aun, or Reisenjima, and have Elvorseal.")
    notice("  - Inject spawn packets every " .. spawn_interval .. " seconds for up to " .. spawn_duration .. " seconds, attempting to spawn Mireu on your client.")
    notice("  - Automatically stops when Mireu is spawned or time expires, and may require multiple attempts depending on network conditions.")
    notice("  - Only one spawn attempt can run at a time.")
end

windower.register_event('addon command', function (command, ...)
    command = command and command:lower() or ""
    
    if command == "help" then
        display_help()
    else
        start_spawn_loop()
    end
end)

-- Main spawn checking loop (runs every frame)
windower.register_event('prerender', function()
    if not spawn_active then
        return
    end
    
    local elapsed = os.clock() - spawn_start_time
    
    -- Check if Mireu has been spawned
    if is_mireu_spawned() then
        stop_spawn_loop("Mireu successfully spawned! Have fun and remember to stand on her front feet!")
        return
    end
    
    -- Check if attempt expired
    if elapsed >= spawn_duration then
        stop_spawn_loop("Spawn attempt timed out after " .. spawn_duration .. " seconds")
        return
    end
    
    -- Attempt spawn at intervals
    if elapsed % spawn_interval < 0.1 then
        attempt_spawn()
    end
end)

-- Halts all spawn attempts on zone change as a safeguard
windower.register_event('zone change', function()
    if spawn_active then
        stop_spawn_loop("You have changed areas, preventing further spawn attempts.")
    end
end)
