-- Phantom Hub | Server Hop Module (Optimized)

local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local VISITED_FILE = "server-hop-temp.json"

local visitedServers = {}
local cursor = nil
local currentHour = os.date("!*t").hour

-- Load visited servers
local function loadVisited()
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(VISITED_FILE))
    end)

    if success and type(data) == "table" then
        visitedServers = data
    else
        visitedServers = { currentHour }
        pcall(function()
            writefile(VISITED_FILE, HttpService:JSONEncode(visitedServers))
        end)
    end
end

-- Save visited servers
local function saveVisited()
    pcall(function()
        writefile(VISITED_FILE, HttpService:JSONEncode(visitedServers))
    end)
end

-- Reset visited servers every hour
local function resetIfNeeded()
    if visitedServers[1] ~= currentHour then
        visitedServers = { currentHour }
        pcall(function()
            delfile(VISITED_FILE)
        end)
        saveVisited()
    end
end

-- Fetch servers
local function getServers(placeId)
    local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
    if cursor then
        url ..= "&cursor=" .. cursor
    end

    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url))
    end)

    if success then
        cursor = result.nextPageCursor
        return result.data
    end

    return nil
end

-- Attempt server hop
local function hop(placeId)
    resetIfNeeded()

    local servers = getServers(placeId)
    if not servers then return end

    for _, server in ipairs(servers) do
        if server.playing < server.maxPlayers then
            local serverId = tostring(server.id)

            if not table.find(visitedServers, serverId) then
                table.insert(visitedServers, serverId)
                saveVisited()

                TeleportService:TeleportToPlaceInstance(
                    placeId,
                    serverId,
                    LocalPlayer
                )
                return
            end
        end
    end
end

-- Module
local ServerHop = {}

function ServerHop:Teleport(placeId)
    loadVisited()

    while task.wait(1) do
        hop(placeId)
    end
end

return ServerHop
