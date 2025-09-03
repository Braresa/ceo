local webhookUrl = getgenv().KaitunWebhook
local http = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer

----------- CONFIG

local levelTarget = 11
local debug = true

function postWebhook(body)
	if typeof(body) == "string" then
		body = http:JSONEncode({
			["content"] = body,
		})
	elseif typeof(body) == "table" then
		body = http:JSONEncode(body)
	else
		return nil
	end

	local options = {
		Url = webhookUrl,
		Method = "POST",
		Body = body,
		Headers = {
			["Content-Type"] = "application/json",
		},
	}

	local response = request(options)
	return response
end

function requestGet(url: string): string
	local options = {
		Url = url,
		Method = "GET",
	}

	return request(options).Body
end

-- Game functions

function isLobby()
	local currentPlaceId = game.PlaceId

	local lobbyId = 16146832113
	local inGameId = 16277809958

	if currentPlaceId == lobbyId then
		return true
	elseif currentPlaceId == inGameId then
		return false
	else
		postWebhook("Unknown place ID: " .. currentPlaceId)
		return false
	end
end

function getStage()
	if isLobby() then
		return "Lobby"
	elseif game.PlaceId == 18219125606 then
		return "Time Chamber"
	end

	local replicatedStorage = game:GetService("ReplicatedStorage")
	local gameHandler = require(replicatedStorage.Modules.Gameplay.GameHandler)

	return gameHandler.GameData.Stage
end

-- Attributes

function getIcedTea(): number
	for i = 1, 20 do
		if player:GetAttribute("IcedTea") then
			break
		end

		task.wait(1)
	end

	return player:GetAttribute("IcedTea")
end

function getLevel(): number
	for i = 1, 20 do
		if player:GetAttribute("Level") then
			break
		end

		task.wait(1)
	end

	return player:GetAttribute("Level")
end

function getRR(): number
	for i = 1, 20 do
		if player:GetAttribute("TraitRerolls") then
			break
		end

		task.wait(1)
	end

	return (player:GetAttribute("TraitRerolls"))
end

function getFlower(): number
	for i = 1, 20 do
		if player:GetAttribute("Flowers") then
			break
		end

		task.wait(1)
	end

	return (player:GetAttribute("Flowers"))
end

function getGems(): number
	for i = 1, 20 do
		if player:GetAttribute("Gems") then
			break
		end

		task.wait(1)
	end

	return (player:GetAttribute("Gems"))
end

function getGold(): number
	for i = 1, 20 do
		if player:GetAttribute("Gold") then
			break
		end

		task.wait(1)
	end

	return (player:GetAttribute("Gold"))
end

-- Trait rerolls

function buyRRfromEventShop(quantity: number, event: string)
	local args = {
		"Purchase",
		{
			"TraitRerolls",
			quantity,
		},
	}

	if event == "SummerShop" then
		game:GetService("ReplicatedStorage")
			:WaitForChild("Networking")
			:WaitForChild("Summer")
			:WaitForChild("ShopEvent")
			:FireServer(unpack(args))
	elseif event == "WinterShop" then
		game:GetService("ReplicatedStorage")
			:WaitForChild("Networking")
			:WaitForChild("Winter")
			:WaitForChild("ShopEvent")
			:FireServer(unpack(args))
	end
end

function getRemainingRRFromShop(shop)
    -- SummerShop or WinterShop
	local StockHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.StockHandler)
	return StockHandler.GetStockData(shop)["TraitRerolls"]
end

-- Milestones

local haveEscanor = false

local units

if isLobby() then
	local ownedUnitsHandler =
		require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
	units = ownedUnitsHandler:GetOwnedUnits()
else
	local UnitWindows = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)

	for i = 1, 20 do
		if UnitWindows._Cache ~= nil then
			units = UnitWindows._Cache
			break
		else
			if debug == true then
				postWebhook("Cache from unit windows is nil, waiting..." .. i .. "/20")
			end
		end

		if i == 20 then
			postWebhook("Failed getting cache from unit windows!")
		end
		task.wait(1)
	end
end

for _, unit in pairs(units) do
	if unit.ID == 270 then
		haveEscanor = true
		break
	elseif unit.Identifier ~= nil and unit.Identifier == 270 then
		haveEscanor = true
		break
	end
end

function hasEscanor(): boolean
	return haveEscanor
end

-- Main logic

local defaultFields = {
	{
		["name"] = "Username",
		["value"] = player.Name,
		["inline"] = false
	},
	{
		["name"] = "Level",
		["value"] = tostring(getLevel()),
		["inline"] = true,
	},
	{
		["name"] = "Iced Tea",
		["value"] = tostring(getIcedTea()),
		["inline"] = true,
	},
	{
		["name"] = "Has Escanor?",
		["value"] = tostring(hasEscanor()),
		["inline"] = true,
	},
	{
		["name"] = "Game Stage",
		["value"] = getStage(),
		["inline"] = true,
	},
	{
		["name"] = "RR's",
		["value"] = getRR(),
		["inline"] = true,
	},
	{
		["name"] = "Summer Shop RR's",
		["value"] = `{getRemainingRRFromShop("SummerShop")}/200`,
		["inline"] = false,
	},
	{
		["name"] = "Gems / Gold",
		["value"] = `{getGems()} / {getGold()}`,
		["inline"] = true
	},
	{
		["name"] = "Flower",
		["value"] = getFlower(),
		["inline"] = true
	}
}




local function sendEmbed(description)
	local embed = {
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = description,
				["color"] = 16711680,
				["fields"] = defaultFields,
				["footer"] = {
					["text"] = "Made by dotwired.org",
				}
			}
		}
	}
	postWebhook(embed)
end

-- Stage 1: Level farming
if getLevel() < levelTarget then
	loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()
	sendEmbed("Farming until level " .. levelTarget)

-- Stage 2: Escanor farming
elseif not hasEscanor() then
	loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()
	sendEmbed("Farming until Escanor")
	getgenv().Config["Summoner"]["Auto Summon Summer"] = true

-- Stage 3: Summer RR farming
else
	if isLobby() then
		local icedTea = getIcedTea()

		if icedTea >= 300000 then
			local RRtoBuy = math.min(
				math.floor(icedTea / 1500),
				getRemainingRRFromShop("SummerShop")
			)
			
			if RRtoBuy > 0 then
				buyRRfromEventShop(RRtoBuy, "SummerShop")
				postWebhook("> Player " .. player.Name .. " bought " .. RRtoBuy .. " RR's from Summer Shop!")
			end
		end

		if getRemainingRRFromShop("SummerShop") == 0 then
			postWebhook("> @everyone Player " .. player.Name .. " has bought all RR's from Summer Shop! Going to Time Chamber")
			game:GetService("TeleportService"):Teleport(18219125606, game:GetService("Players").LocalPlayer)
			return
		end
	end

	loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()
	sendEmbed("Farming until getting all Summer Shop RR")
	getgenv().Config["Summoner"]["Auto Summon Summer"] = false
end

loadstring(requestGet("https://nousigi.com/loader.lua"))()

task.defer(function()
	-- In game

	if isLobby() then return end
	while true do
		if getLevel() >= levelTarget and getStage() == "Stage1" and not hasEscanor() then
			postWebhook("> Player **" .. player.Name .. "** reached level " .. getLevel() .. ", getting back to lobby...")
			player:Kick("Reached target level!")
			break
		end
	

		local icedTea = getIcedTea()

		if getStage() == "Summer" then
			if not hasEscanor() and icedTea >= 375000 then
				postWebhook("> Player **" .. player.Name .. "** reached 375k Iced Tea, getting back to lobby to summon for Escanor...")
				player:Kick("Reached 375k Iced Tea! Getting back")
				break
			elseif hasEscanor() and icedTea >= 300000 then 
				postWebhook("**" .. player.Name .. "** reached 300k Iced Tea and has Escanor, getting back to lobby to buy RR...")
				player:Kick("Reached 300k Iced Tea and has Escanor!")
				break
			end
		end

		task.wait(30)
	end
end)
