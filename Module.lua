local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer
local FILE_NAME = "server-hop-temp.json"

local AllIDs = {}
local foundAnything = nil
local currentHour = os.date("!*t").hour

-- Load saved server IDs
local success, data = pcall(function()
	return HttpService:JSONDecode(readfile(FILE_NAME))
end)

if success and type(data) == "table" then
	-- Reset file if hour changed
	if data.hour ~= currentHour then
		AllIDs = { hour = currentHour, servers = {} }
		writefile(FILE_NAME, HttpService:JSONEncode(AllIDs))
	else
		AllIDs = data
	end
else
	AllIDs = { hour = currentHour, servers = {} }
	writefile(FILE_NAME, HttpService:JSONEncode(AllIDs))
end

local function save()
	writefile(FILE_NAME, HttpService:JSONEncode(AllIDs))
end

local function isVisited(id)
	return table.find(AllIDs.servers, id) ~= nil
end

local function TPReturner(placeId)
	local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100"
	if foundAnything then
		url ..= "&cursor=" .. foundAnything
	end

	local site = HttpService:JSONDecode(game:HttpGet(url))
	foundAnything = site.nextPageCursor

	for _, server in ipairs(site.data) do
		if server.playing < server.maxPlayers then
			local id = tostring(server.id)
			if not isVisited(id) then
				table.insert(AllIDs.servers, id)
				save()
				TeleportService:TeleportToPlaceInstance(placeId, id, LocalPlayer)
				task.wait(4)
				return
			end
		end
	end
end

local module = {}

function module:Teleport(placeId)
	while task.wait(1) do
		pcall(function()
			TPReturner(placeId)
		end)
	end
end

return module
