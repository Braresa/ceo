-- TODO
-- Sistema de detectar se é dobro de XP
-- Automaticamente fechar o alerta

local CONFIG = getgenv().KaitunWiredConfig
	or {
		LEVEL = {
			MINIMUM_LEVEL_TARGET = 11,
			WEEKEND_LEVEL_TARGET = 50,
			ONLY_FARM_LEVEL_ON_WEEKEND = true,
		},
		ICED_TEA_TO_SUMMON = 400000,
		PLACE_IDS = {
			LOBBY = 16146832113,
			INGAME = 16277809958,
			TIME_CHAMBER = 18219125606,
		},
		NOUSIGI = {
			KEY = getgenv().Key or "",
			CONFIGS = {
				NAMAK_LEVEL_FARM = "https://paste.dotwired.org/Namak.txt",
				DRIED_LAKE = "https://paste.dotwired.org/Dried%20Lake.txt",
			},
		},
		ERROR_WEBHOOK_URL = "https://discord.com/api/webhooks/1413456894978293760/x69F2siE7P-rFGl4xuZBCKXLGosUS9sukyPjy9ui1aGBmU-guuHG5CYU0J569dG6tLlf",
		WEBHOOK_URL = "https://discord.com/api/webhooks/1411173677474648154/HW89L4WEq69UMOw_VFfWjvBDjGHtQbeym0Qg_ns-5PC0KRTETJd952jS253-BIwdOGA-",
	}

local CACHE = {
	hasEscanor = nil,
}
-- Services

local HTTP = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local StarterPlayer = game:GetService("StarterPlayer")

local Player = Players.LocalPlayer

-- Core game functions (works on any place)

function isLobby(): boolean
	return game.PlaceId == CONFIG.PLACE_IDS.LOBBY
end

function isGame()
	return game.PlaceId == CONFIG.PLACE_IDS.INGAME
end

function isTimeChamber(): boolean
	return game.PlaceId == CONFIG.PLACE_IDS.TIME_CHAMBER
end

function getAttribute(attributeName, timeout)
	timeout = timeout or 20

	for i = 1, timeout do
		if Player:GetAttribute(attributeName) then
			return Player:GetAttribute(attributeName)
		end
		task.wait(1)
	end

	return nil
end

-- Webhook Handler

local WebhookManager = {

	post = function(description, customColor, data, mentionEveryone)
		local defaultFields = {
			{
				["name"] = "Username",
				["value"] = Player.Name,
				["inline"] = false,
			},
			{
				["name"] = "Level",
				["value"] = tostring(getAttribute("Level")),
				["inline"] = true,
			},
			{
				["name"] = "Iced Tea",
				["value"] = tostring(getAttribute("IcedTea")),
				["inline"] = true,
			},
			{
				["name"] = "Flower",
				["value"] = tostring(getAttribute("Flowers")),
				["inline"] = true,
			},
			{
				["name"] = "Has Escanor?",
				["value"] = data.hasEscanor or "N/A",
				["inline"] = true,
			},
			{
				["name"] = "Game Stage",
				["value"] = data.stage or "N/A",
				["inline"] = true,
			},
			{
				["name"] = "RR's",
				["value"] = tostring(getAttribute("TraitRerolls")),
				["inline"] = true,
			},
			{
				["name"] = "Gems / Gold",
				["value"] = `{getAttribute("Gems")} / {getAttribute("Gold")}`,
				["inline"] = true,
			},
		}

		local fields = {}
		for _, field in ipairs(defaultFields) do
			table.insert(fields, field)
		end

		if isLobby() then
			table.insert(fields, {
				["name"] = "Summer RR left",
				["value"] = data.summerRR or "N/A",
				["inline"] = true,
			})
			table.insert(fields, {
				["name"] = "Winter RR left",
				["value"] = data.winterRR or "N/A",
				["inline"] = true,
			})
			table.insert(fields, {
				["name"] = "Max Units",
				["value"] = require(StarterPlayer.Modules.Interface.WindowCacheHandler)
					.GetWindow("Units")
					:WaitForChild("Holder").OwnedUnitsLabel.UnitAmount.Text,
				["inline"] = true,
			})
		end

		local embed = {
			["content"] = mentionEveryone and "@everyone" or "",
			["embeds"] = {
				{
					["title"] = "Kaitun dotwired",
					["description"] = description,
					["color"] = customColor or 16711680,
					["fields"] = fields,
					["footer"] = {
						["text"] = "Made by dotwired.org",
					},
				},
			},
		}

		local body = HTTP:JSONEncode(embed)


		if CONFIG.WEBHOOK_URL == nil then
			warn("Webhook URL is not set.")
			return nil
		end

		return request({
			Url = CONFIG.WEBHOOK_URL,
			Method = "POST",
			Body = body,
			Headers = { ["Content-Type"] = "application/json" },
		})
	end,

	error = function(message)
		local formatted
		if typeof(message) == "string" then
			formatted = { content = "**[ERROR]**\nPlayer: " .. Player.Name .. "\nMessage: " .. message }
		elseif typeof(message) == "table" then
			formatted = message
			formatted.content = "**[ERROR]**\nPlayer: " .. Player.Name .. "\nMessage: " .. tostring(formatted.content)
		else
			return nil
		end

		return request({
			Url = CONFIG.ERROR_WEBHOOK_URL,
			Method = "POST",
			Body = HTTP:JSONEncode(formatted),
			Headers = { ["Content-Type"] = "application/json" },
		})
	end,

	warn = function(message)
		if CONFIG.ERROR_WEBHOOK_URL == nil then
			warn("Error Webhook URL is not set.")
			return nil
		end

		local formatted
		if typeof(message) == "string" then
			formatted = { content = "**[WARN]**\nPlayer: " .. Player.Name .. "\nMessage: " .. message }
		elseif typeof(message) == "table" then
			formatted = message
			formatted.content = "**[WARN]**\nPlayer: " .. Player.Name .. "\nMessage: " .. tostring(formatted.content)
		else
			return nil
		end

		return request({
			Url = CONFIG.ERROR_WEBHOOK_URL,
			Method = "POST",
			Body = HTTP:JSONEncode(formatted),
			Headers = { ["Content-Type"] = "application/json" },
		})
	end,
}

--[[
-> IcedTea
-> Level
-> TraitRerolls
-> Flowers
-> Gold
-> Gems
]]

function IsWeekend(): boolean
	local WeekendHandler_upvr = require(game:GetService("ReplicatedStorage").Modules.Gameplay.WeekendHandler)
	return WeekendHandler_upvr.IsWeekend()
end

local function teleportToPlace(placeId)
	local success = false
	local attempts = 0

	while attempts < 3 do
		attempts = attempts + 1
		local ok, err = pcall(function()
			TeleportService:Teleport(placeId, Player)
		end)
		if ok then
			success = true
			break
		else
			if debug then
				WebhookManager.error("Teleport attempt " .. attempts .. " failed: " .. tostring(err))
			end
			task.wait(8)
		end
	end

	if not success then
		WebhookManager.post(
			"Failed to teleport to placeId " .. tostring(placeId) .. " after 3 attempts. Kicking player."
		)
		Player:Kick("Failed to teleport to placeId " .. tostring(placeId) .. ".")
	end
end

function teleportToLobby()
	teleportToPlace(CONFIG.PLACE_IDS.LOBBY)
end

-- Lobby functions (works only on the lobby)

local Lobby = {
	getRemainingRRFromEventShop = function(eventShop: string)
		local StockHandler = require(game:GetService("StarterPlayer").Modules.Gameplay.StockHandler)
		return StockHandler.GetStockData(eventShop)["TraitRerolls"]
	end,

	notEnoughSpace = false,

	ClaimLevelMilestones = function()
		local level = getAttribute("Level")
		local LevelMilestones = { 5, 10, 15, 20, 25, 30, 35, 40, 45, 50 }

		-- Disabling level pop up
		local popupEvent =
			ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("PopupEvent")

		for _, connection in ipairs(getconnections(popupEvent)) do
			connection:Disconnect()
		end

		for _, milestone in ipairs(LevelMilestones) do
			if level >= milestone then
				ReplicatedStorage:WaitForChild("Networking")
					:WaitForChild("Milestones")
					:WaitForChild("MilestonesEvent")
					:FireServer("Claim", milestone)
			else
				break
			end

			task.wait(2)
		end
	end,

	CheckIfExpandUnits = function()
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
					if getAttribute("Gold") < (timesBought * 15000 + 25000) then
						WebhookManager.warn(
							Player.Name .. " doesn't have enough gold to expand unit capacity!"
						)
					else
						WebhookManager.post(
							"Player "
								.. Player.Name
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
	end,

	buyAllRRFromEventShop = function(eventShop: string)
		local args = {
			"Purchase",
			{
				"TraitRerolls",
				200,
			},
		}

		if eventShop == "SummerShop" then
			ReplicatedStorage:WaitForChild("Networking")
				:WaitForChild("Summer")
				:WaitForChild("ShopEvent")
				:FireServer(unpack(args))
		elseif eventShop == "SpringShop" then
			ReplicatedStorage:WaitForChild("Networking")
				:WaitForChild("Winter")
				:WaitForChild("ShopEvent")
				:FireServer(unpack(args))
		end
	end,

	hasEscanor = function()
		if CACHE.hasEscanor ~= nil then
			return CACHE.hasEscanor
		end

		local OwnedUnitsHandler =
			require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
		local units = OwnedUnitsHandler:GetOwnedUnits()

		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						-- Has escanor
						CACHE.hasEscanor = true
						return true
					end
				end
			end
		end

		CACHE.hasEscanor = false
		return CACHE.hasEscanor
	end,
}

-- In-game functions (works only on Tomer Defense Game Base)

local Game = {
	getStage = function(): string
		local gameHandler = require(ReplicatedStorage.Modules.Gameplay.GameHandler)
		return gameHandler.GameData.Stage
	end,

	hasEscanor = function(): boolean
		if CACHE.hasEscanor ~= nil then
			return CACHE.hasEscanor
		end

		local UnitWindows = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
		local units = UnitWindows._Cache

		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						-- Has escanor
						CACHE.hasEscanor = true
						return true
					end
				end
			end
		end

		CACHE.hasEscanor = false

		return CACHE.hasEscanor
	end,
}

function start()
	local level = getAttribute("Level")
	local icedTea = getAttribute("IcedTea")
	local traitRerolls = getAttribute("TraitRerolls")
	local flowers = getAttribute("Flowers")
	local gold = getAttribute("Gold")
	local gems = getAttribute("Gems")

	local function loadNousigi(config)
		if config == "NamakLevelFarm" then
			loadstring(game:HttpGet(CONFIG.NOUSIGI.CONFIGS.NAMAK_LEVEL_FARM))()
		elseif config == "DriedLake" then
			loadstring(game:HttpGet(CONFIG.NOUSIGI.CONFIGS.DRIED_LAKE))()
		elseif config == "DriedLakeSummon" then
			loadstring(game:HttpGet(CONFIG.NOUSIGI.CONFIGS.DRIED_LAKE))()
			getgenv().Config["Summoner"]["Auto Summon Summer"] = true
		end
		getgenv().Key = CONFIG.NOUSIGI.KEY
		loadstring(game:HttpGet("https://nousigi.com/loader.lua"))()
	end

	-- LOBBY LOGIC
	if isLobby() then
		Lobby.ClaimLevelMilestones()
		Lobby.CheckIfExpandUnits()
		local data = {
			hasEscanor = tostring(Lobby.hasEscanor()),
			stage = "Lobby",
			summerRR = Lobby.getRemainingRRFromEventShop("SummerShop"),
			winterRR = Lobby.getRemainingRRFromEventShop("SpringShop"),
		}
		local continue = true

		if level < CONFIG.LEVEL.MINIMUM_LEVEL_TARGET then
			-- Going to namak until level 11 (LOBBY)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Going to Namak until level 11 (LOBBY)", 1752220, data)
			continue = false
		end

		if CONFIG.LEVEL.ONLY_FARM_LEVEL_ON_WEEKEND and IsWeekend() and (level < CONFIG.WEEKEND_LEVEL_TARGET) and continue then
			-- Going to namak to farm Level (is weekend, priority)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Going to Namak until level 50 (WEEKEND) (LOBBY)", 1752220, data)
			continue = false
		end

		if not Lobby.hasEscanor() and continue then
			-- Farming until Escanor (LOBBY)
			loadNousigi("DriedLakeSummon")
			WebhookManager.post("Going to Dried Lake to farm Escanor (LOBBY)", 16705372, data)
			continue = false
		end

		-- Has escanor, has sufficient level, next step is RR
		if
			(Lobby.getRemainingRRFromEventShop("SummerShop") == 200)
			and (Lobby.getRemainingRRFromEventShop("SpringShop") == 200)
			and continue
		then
			if icedTea >= 300000 and flowers >= 300000 then
				Lobby.buyAllRRFromEventShop("SummerShop")
				Lobby.buyAllRRFromEventShop("SpringShop")
				-- Bought all RR
				data.summerRR = Lobby.getRemainingRRFromEventShop("SummerShop")
				data.winterRR = Lobby.getRemainingRRFromEventShop("SpringShop")
				WebhookManager.post("Bought all RR from event shops (LOBBY)", 5763719, data, true)
			else
				-- Not enough resources, going to timechamber
				teleportToPlace(CONFIG.PLACE_IDS.TIME_CHAMBER)
				WebhookManager.post("Going to Time Chamber to farm resources (LOBBY)", 15844367, data)
				continue = false
			end
		end

		if continue then
			WebhookManager.post("Player " .. Player.Name .. " has completed all Kaitun steps!", 5763719, nil, true)
		end
	end

	-- IN-GAME LOGIC
	if isGame() then
		local continue = true
		local data = {
			hasEscanor = tostring(Game.hasEscanor()),
			stage = Game.getStage(),
		}
		if level < CONFIG.LEVEL.MINIMUM_LEVEL_TARGET then
			-- Farming until level 11 (IN-GAME)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Going to Namak until level 11 (IN-GAME)", 1752220, data)
			continue = false

			-- Checking Level (Namak, first step of kaitun)
			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "Level" then
					return
				end

				if Player:GetAttribute("Level") >= CONFIG.LEVEL.MINIMUM_LEVEL_TARGET then
					WebhookManager.post("Reached level " .. CONFIG.LEVEL.MINIMUM_LEVEL_TARGET .. ", going back to lobby", 5763719, data)
					teleportToPlace(CONFIG.PLACE_IDS.LOBBY)
				end
			end)
		end

		if CONFIG.LEVEL.ONLY_FARM_LEVEL_ON_WEEKEND and IsWeekend() and (level < CONFIG.WEEKEND_LEVEL_TARGET) and continue then
			-- Farming until level 50 (IN-GAME)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Going to Namak until level 50 (WEEKEND) (IN-GAME)", 1752220, data)
			continue = false

			-- Checking level (weekend, farming til 50)
			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "Level" then
					return
				end

				if Player:GetAttribute("Level") >= CONFIG.WEEKEND_LEVEL_TARGET then
					WebhookManager.post("Reached level " .. CONFIG.WEEKEND_LEVEL_TARGET .. ", going back to lobby", 5763719, data)
					teleportToLobby()
				end
			end)
		end

		if not Game.hasEscanor() and continue then
			-- Farming until Escanor (IN-GAME)
			loadNousigi("DriedLakeSummon")
			WebhookManager.post("Going to Dried Lake to farm Escanor (IN-GAME)", 16776960, data)
			continue = false

			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "IcedTea" and attribute ~= "Level" then
					return
				end

				-- Iced tea Check
				if Player:GetAttribute("IcedTea") >= CONFIG.ICED_TEA_TO_SUMMON then
					WebhookManager.post("Has enough iced tea to summon escanor, going back to lobby", 5763719, data)
					teleportToLobby()
					return
				end

				-- Goes back to lobby if weekend started and level is below target
				if IsWeekend() and Player:GetAttribute("Level") < CONFIG.WEEKEND_LEVEL_TARGET then
					WebhookManager.post("It's weekend and level is below " .. CONFIG.WEEKEND_LEVEL_TARGET .. ", going back to lobby", 5763719, data)
					teleportToLobby()
					return
				end
			end)
		end
	end

	if isTimeChamber() then
		-- Checking if the player has enough resources
		Player.AttributeChanged:Connect(function(attribute)
			if attribute ~= "IcedTea" or attribute ~= "Flowers" then
				return
			end

			WebhookManager.post(
				"Current resources: Iced Tea: "
					.. tostring(Player:GetAttribute("IcedTea"))
					.. " / Flowers: "
					.. tostring(Player:GetAttribute("Flowers")),
				12745742,
				nil
			)

			if (Player:GetAttribute("IcedTea") >= 300000) and (Player:GetAttribute("Flowers") >= 300000) then
				WebhookManager.post("Has enough resources, going back to lobby", 5763719, nil, true)
				teleportToLobby()
			end
		end)
	end
end

start()
