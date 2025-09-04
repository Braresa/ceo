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
	elseif currentPlaceId == 18219125606 then
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
	elseif event == "SpringShop" then
		game:GetService("ReplicatedStorage")
			:WaitForChild("Networking")
			:WaitForChild("Winter")
			:WaitForChild("ShopEvent")
			:FireServer(unpack(args))
	end
end

function getRemainingRRFromShop(shop)
	-- SummerShop or SpringShop
	local StockHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.StockHandler)
	return StockHandler.GetStockData(shop)["TraitRerolls"]
end

if getLevel() < levelTarget then
	postWebhook({
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = "Farming until level " .. levelTarget,
				["color"] = 16711680,
				["fields"] = {
					{
						["name"] = "Username",
						["value"] = player.Name,
						["inline"] = false,
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
						["name"] = "Flower",
						["value"] = getFlower(),
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
						["name"] = "Gems / Gold",
						["value"] = `{getGems()} / {getGold()}`,
						["inline"] = true,
					},
				},
				["footer"] = {
					["text"] = "Made by dotwired.org",
				},
			},
		},
	})
	loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()
	loadstring(requestGet("https://nousigi.com/loader.lua"))()

	task.spawn(function()
		while true do
			if getLevel() >= levelTarget and getStage() == "Stage1" then
				postWebhook(
					" Player **" .. player.Name .. "** reached level " .. getLevel() .. ", getting back to lobby..."
				)
				game:GetService("TeleportService"):Teleport(16146832113, game:GetService("Players").LocalPlayer)
				break
			end

			task.wait(30)
		end
	end)

	return
end

if getStage() == "Time Chamber" then
	task.spawn(function()
		while true do
			if getFlower() >= 300000 and getIcedTea() >= 300000 then
				postWebhook({
					["content"] = "@everyone",
					["embeds"] = {
						{
							["title"] = "Kaitun dotwired",
							["description"] = "Reached 300k Flowers and 300k Iced Tea!",
							["color"] = 65280,
							["fields"] = {
								{
									["name"] = "Username",
									["value"] = player.Name,
								},
								{
									["name"] = "Flowers",
									["value"] = tostring(getFlower()),
									["inline"] = true,
								},
								{
									["name"] = "Iced Tea",
									["value"] = tostring(getIcedTea()),
									["inline"] = true,
								},
							},
							["footer"] = {
								["text"] = "Made by dotwired.org",
							},
						},
					},
				})
				game:GetService("TeleportService"):Teleport(16146832113, game:GetService("Players").LocalPlayer)
				break
			end

			postWebhook({
				["embeds"] = {
					{
						["title"] = "Kaitun dotwired",
						["description"] = "Farming timechamber...",
						["color"] = 65280,
						["fields"] = {
							{
								["name"] = "Username",
								["value"] = player.Name,
							},
							{
								["name"] = "Flowers",
								["value"] = tostring(getFlower()),
								["inline"] = true,
							},
							{
								["name"] = "Iced Tea",
								["value"] = tostring(getIcedTea()),
								["inline"] = true,
							},
						},
						["footer"] = {
							["text"] = "Made by dotwired.org",
						},
					},
				},
			})

			task.wait(600)
		end
	end)

	return
end

-- Milestones

local haveEscanor = false
local ignoreSummon = false

local units

if isLobby() then
	task.spawn(function()
		while true do
			local UnitWindowsHandler =
				require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
			local UnitExpansionEvent =
				game:GetService("ReplicatedStorage"):WaitForChild("Networking"):WaitForChild("UnitExpansionEvent")
			local maxUnits = 100
			local timesBought
			local received = false
			local connection

			UnitExpansionEvent:FireServer("Retrieve")

			connection = UnitExpansionEvent.OnClientEvent:Connect(function(action, data)
				if action == "SetData" then
					maxUnits += 25 * data
					timesBought = data
					connection:Disconnect()
					received = true
				end
			end)

			repeat
				task.wait()
			until received

			local TableUtils = require(game:GetService("ReplicatedStorage").Modules.Utilities.TableUtils)
			local currentUnits = TableUtils.GetDictionaryLength(UnitWindowsHandler._Cache)

			if maxUnits - currentUnits <= 10 then
				if getGold() < (timesBought * 15000 + 25000) then
					postWebhook(player.Name .. " doesn't have enough gold to expand unit capacity! Going to Dried Lake")
					ignoreSummon = true
				else
					postWebhook(
						"Player "
							.. player.Name
							.. " is expanding unit capacity from "
							.. maxUnits
							.. " to "
							.. (maxUnits + 25)
					)
					UnitExpansionEvent:FireServer("Purchase")
				end
			end
			task.wait(10)
		end
	end)

	local ownedUnitsHandler =
		require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
	units = ownedUnitsHandler:GetOwnedUnits()
elseif getStage() ~= "Time Chamber" then
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
		["inline"] = false,
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
		["name"] = "Flower",
		["value"] = getFlower(),
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
		["name"] = "Gems / Gold",
		["value"] = `{getGems()} / {getGold()}`,
		["inline"] = true,
	},
}

if isLobby() then
	local levels = {
		5,
		10,
		15,
		20,
		25,
		30,
		35,
		40,
		45,
		50,
	}

	for i, level in levels do
		if getLevel() >= level then
			local args = {
				"Claim",
				level,
			}
			--!
			game:GetService("ReplicatedStorage")
				:WaitForChild("Networking")
				:WaitForChild("Milestones")
				:WaitForChild("MilestonesEvent")
				:FireServer(unpack(args))
		else
			break
		end

		task.wait(1.5)
	end
end

local function sendEmbed(description)
	local fields = {}
	for _, field in ipairs(defaultFields) do
		table.insert(fields, field)
	end

	if isLobby() then
		table.insert(fields, {
			["name"] = "Summer RR left",
			["value"] = tostring(getRemainingRRFromShop("SummerShop")),
			["inline"] = true,
		})

		table.insert(fields, {
			["name"] = "Winter RR left",
			["value"] = tostring(getRemainingRRFromShop("SpringShop")),
			["inline"] = true,
		})
		table.insert(fields, {
			["name"] = "Max Units",
			["value"] = require(game:GetService("StarterPlayer").Modules.Interface.WindowCacheHandler).GetWindow("Units"):WaitForChild("Holder").OwnedUnitsLabel.UnitAmount.Text,
			["inline"] = true,
		})
	end

	local embed = {
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = description,
				["color"] = 16711680,
				["fields"] = fields,
				["footer"] = {
					["text"] = "Made by dotwired.org",
				},
			},
		},
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
	if not ignoreSummon then getgenv().Config["Summoner"]["Auto Summon Summer"] = true end
	-- Last Stage: Farm and buy all RR
else
	if getStage() == "Summer" then
		loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()
		getgenv().Config["Summoner"]["Auto Summon Summer"] = false
		sendEmbed("Farming Dried Lake")
	end

	if getStage() == "Stage1" then
		loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()
		sendEmbed("Farming Namak")
	end
end

if isLobby() and getLevel() >= levelTarget and hasEscanor() then
	local icedTea = getIcedTea()
	local flower = getFlower()

	if getRemainingRRFromShop("SummerShop") == 200 then
		if icedTea >= 300000 then
			buyRRfromEventShop(200, "SummerShop")
			sendEmbed("Bought 200 RR from summer shop!")
		else
			-- Not enough iced tea, going to Dried Lake

			-- loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()
			-- getgenv().Config["Summoner"]["Auto Summon Summer"] = false
			-- sendEmbed("Farming until 300k iced tea")
			-- loadstring(requestGet("https://nousigi.com/loader.lua"))()
			sendEmbed("Going to Time Chamber, player doesn't have enough Iced Tea...")
			game:GetService("TeleportService"):Teleport(18219125606, game:GetService("Players").LocalPlayer)
			return
		end
	end
	-- If it reaches here the player already has 200 RR from summer

	if getRemainingRRFromShop("SpringShop") == 200 then
		if flower >= 300000 then
			buyRRfromEventShop(200, "SpringShop")
			sendEmbed("Bought 200 RR from spring shop!")
		else
			-- Not enough Flowers, going to Dried Lake
			sendEmbed("Going to Time Chamber, player doesn't have enough Flowers...")
			game:GetService("TeleportService"):Teleport(18219125606, game:GetService("Players").LocalPlayer)
			return
		end
	end

	-- If it reaches here the player already has every RR possible from events and is in lobby
	postWebhook("@everyone")
	sendEmbed("CAOS TRAP")

	loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()
	return
end

loadstring(requestGet("https://nousigi.com/loader.lua"))()

task.spawn(function()
	-- In game

	if isLobby() or getStage() == "Time Chamber" then
		return
	end

	while true do
		local icedTea = getIcedTea()

		if getStage() == "Summer" then
			if not hasEscanor() and icedTea >= 375000 then
				postWebhook(
					"> Player **"
						.. player.Name
						.. "** reached 375k Iced Tea, getting back to lobby to summon for Escanor..."
				)
				--player:Kick("Reached 375k Iced Tea! Getting back")
				game:GetService("TeleportService"):Teleport(16146832113, game:GetService("Players").LocalPlayer)
				break
			elseif hasEscanor() then
				postWebhook(
					"**"
						.. player.Name
						.. "** player has escanor but is in Dried Lake... Going to Time Chamber"
				)
				--player:Kick("Reached 300k Iced Tea and has Escanor!")
				game:GetService("TeleportService"):Teleport(18219125606, game:GetService("Players").LocalPlayer)
				break
			end
		end

		task.wait(30)
	end
end)
