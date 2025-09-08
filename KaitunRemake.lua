local CONFIG = getgenv().KaitunWiredConfig
	or {
		LEVEL = {
			MINIMUM_LEVEL_TARGET = 11,
			WEEKEND_LEVEL_TARGET = 30,
			ONLY_FARM_LEVEL_ON_WEEKEND = true,
		},
		ICED_TEA_TO_SUMMON = 400000,
		FARM_SPRING_RR = false,
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
		WEBHOOK_URL = "",
		ERROR_WEBHOOK_URL = "",
		SPREADSHEET_REST_URL = "",
		API_KEY = "",
	}

-- Version check

-- Services

local HTTP = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local StarterPlayer = game:GetService("StarterPlayer")
local RunService = game:GetService("RunService")

local VERSION = "8"

local Player = Players.LocalPlayer

-- Checking version

-- Core game functions (works on any place)

function isLobby()
	return game.PlaceId == CONFIG.PLACE_IDS.LOBBY
end

function isGame()
	return game.PlaceId == CONFIG.PLACE_IDS.INGAME
end

function isTimeChamber()
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
		local function checkhasEscanor()
			if data ~= nil and data.hasEscanor ~= nil then
				return data.hasEscanor
			else
				return "N/A"
			end
		end

		local function checkGameStage()
			if data ~= nil and data.stage ~= nil then
				return data.stage
			else
				return "N/A"
			end
		end
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
				["value"] = checkhasEscanor(),
				["inline"] = true,
			},
			{
				["name"] = "Game Stage",
				["value"] = checkGameStage(),
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
				["name"] = "Spring RR left",
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

	message = function(message)
		local options = {
			Url = CONFIG.WEBHOOK_URL,
			Method = "POST",
			Body = HTTP:JSONEncode({ content = message }),
			Headers = { ["Content-Type"] = "application/json" },
		}
		return request(options)
	end,
}

-- Version check
task.spawn(function()
	local versionUrl = "https://raw.githubusercontent.com/Braresa/ceo/refs/heads/main/version.txt"
	while true do
		local attempts = 0
		local maxAttempts = 3

		while attempts < maxAttempts do
			local remoteVersion = game:HttpGet(versionUrl)

			if VERSION ~= remoteVersion then
				attempts += 1
				if attempts >= maxAttempts then
					WebhookManager.message(`> *{Player.Name}* was kicked for having an outdated Kaitun version.`)
					Player:Kick("Kaitun outdated.")
					return
				end
			else
				attempts = 0 -- reset attempts if version matches
			end

			task.wait(Random.new(os.time()):NextInteger(60, 180)) -- Check every 2 to 3 minutes
		end
	end
end)

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

function teleportToLobby()
	-- For some reason teleport doesn't work properly, we are kicking the player instead.
	-- teleportToPlace(CONFIG.PLACE_IDS.LOBBY)
	Player:Kick("Returning to lobby.")
	WebhookManager.message(`> *{Player.Name}* is returning to lobby.`)
end

function teleportToTimeChamber()
	-- teleportToPlace(CONFIG.PLACE_IDS.TIME_CHAMBER)
	TeleportService:Teleport(CONFIG.PLACE_IDS.TIME_CHAMBER, Player)
	WebhookManager.message(`> *{Player.Name}* is going to time chamber (teleport is broken ~20min).`)
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

		local popupEvent =
			ReplicatedStorage:WaitForChild("Networking"):WaitForChild("ClientListeners"):WaitForChild("PopupEvent")

		for _, connection in ipairs(getconnections(popupEvent.OnClientEvent)) do
			connection:Disable()
		end

		for _, milestone in ipairs(LevelMilestones) do
			if level >= milestone then
				ReplicatedStorage:WaitForChild("Networking")
					:WaitForChild("Milestones")
					:WaitForChild("MilestonesEvent")
					:FireServer("Claim", milestone)
				print("Claimed level milestone for level " .. milestone)
			else
				break
			end

			task.wait(1)
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
						WebhookManager.warn(`> *{Player.Name}* doesn't have enough gold to expand unit capacity!`)
					else
						WebhookManager.message(`> *{Player.Name}* is expanding unit capacity`)
						UnitExpansionEvent:FireServer("Purchase")
					end
				end
				task.wait(10)
			end
		end)
	end,

	ClaimCodes = function()
		local CodesEvent = ReplicatedStorage.Networking.CodesEvent
		local codes = game:HttpGet("https://raw.githubusercontent.com/Braresa/ceo/refs/heads/main/codes.txt")

		for code in string.gmatch(codes, "[^\r\n]+") do
			CodesEvent:FireServer(code)

			task.wait(2)
		end
	end,

	CloseUpdateLog = function()
		-- Here we just disable the update log appearing every time we enter the lobby
		-- The update log close function is local
		local UpdateLogEvent = ReplicatedStorage.Networking.UpdateLogEvent

		UpdateLogEvent:FireServer("Update", true)
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

	UpdateSpreadsheet = function(hasEscanor, summerRR, springRR)
		local playerDataString = `{CONFIG.SPREADSHEET_REST_URL}/Username/*{Player.Name}*`
		local playerDataJson = game:HttpGet(playerDataString)

		local data = {
			Username = Player.Name,
			Level = getAttribute("Level"),
			IcedTea = getAttribute("IcedTea"),
			TraitRerolls = getAttribute("TraitRerolls"),
			Flowers = getAttribute("Flowers"),
			["Gems / Gold"] = `{getAttribute("Gems")} / {getAttribute("Gold")}`,
			HasEscanor = tostring(hasEscanor),
			LeftSummerRR = summerRR,
			LeftSpringRR = springRR,
			HasFalcon = "N/A",
		}

		local body = HTTP:JSONEncode(data)

		local response

		if #playerDataJson > 0 then
			response = request({
				Url = playerDataString,
				Method = "PATCH",
				Body = body,
				Headers = { ["Content-Type"] = "application/json" },
			})
		else
			response = request({
				Url = CONFIG.SPREADSHEET_REST_URL,
				Method = "POST",
				Body = body,
				Headers = { ["Content-Type"] = "application/json" },
			})
		end

		if response and response.Success then
			WebhookManager.message(`> *{Player.Name}* updated spreadsheet successfully (LOBBY).`)
		else
			WebhookManager.warn(
				`> *{Player.Name}* failed to update spreadsheet: {response and response.Body or "No response"}`
			)
		end
	end,

	hasEscanor = function()
		local OwnedUnitsHandler =
			require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
		local units = OwnedUnitsHandler:GetOwnedUnits()

		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						-- Has escanor
						return true
					end
				end
			end
		end

		return false
	end,

	SetupEscanorEvent = function(callback)
		local SummonEvent = game:GetService("ReplicatedStorage").Networking.Units.SummonEvent

		SummonEvent.OnClientEvent:Connect(function(action, units, ...)
			if action == "ReplicateBanner" then
				return
			end

			if action == "SummonTenAnimation" then
				if units[1] then
					-- Table
					for _, unit in pairs(units) do
						if unit.UnitObject.Identifier == 270 then
							callback()
						end
					end
				else
					-- Single unit
					local unit = units
					if unit.UnitObject.Identifier == 270 then
						callback()
					end
				end
			end
		end)
	end,
}

-- In-game functions (works only on Tomer Defense Game Base)

local Game = {
	getStage = function(): string
		local gameHandler = require(ReplicatedStorage.Modules.Gameplay.GameHandler)
		return gameHandler.GameData.Stage
	end,

	hasEscanor = function(): boolean
		local UnitWindows = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Windows.UnitWindowHandler)
		local units = UnitWindows._Cache

		for attempt = 1, 20 do
			if units ~= nil then
				for _, unit in pairs(units) do
					if (unit.ID == 270) or (unit.Identifier == 270) then
						return true
					end
				end
			end
		end

		return false
	end,
}

local state = "EXECUTING"

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
		print("Loaded Nousigi with config: " .. config)
	end

	local exceptions = {
		["kallbul799"] = "type3",
		["latrisag6757"] = "type3"	
	}

	local SpringRR = false

	for name, accountType in pairs(exceptions) do
		if string.lower(name) == string.lower(Player.Name) then
			if accountType == "type1" then
				CONFIG.LEVEL.WEEKEND_LEVEL_FARM = false
			elseif accountType == "type2" then
			-- Default
			elseif accountType == "type3" then
				CONFIG.LEVEL.WEEKEND_LEVEL_TARGET = 50
				SpringRR = true
			end
		end
	end

	-- LOBBY LOGIC
	if isLobby() then
		Lobby.ClaimLevelMilestones()
		Lobby.CheckIfExpandUnits()
		Lobby.CloseUpdateLog()
		Lobby.ClaimCodes()

		local data = {
			hasEscanor = tostring(Lobby.hasEscanor()),
			stage = "Lobby",
			summerRR = Lobby.getRemainingRRFromEventShop("SummerShop"),
			winterRR = Lobby.getRemainingRRFromEventShop("SpringShop"),
		}

		local continue = true

		local function finishAccount()
			data.summerRR = Lobby.getRemainingRRFromEventShop("SummerShop")
			data.winterRR = Lobby.getRemainingRRFromEventShop("SpringShop")
			state = "DONE"
			writefile(`{Player.Name}.txt`, "Completed-AV")
			WebhookManager.post("Player " .. Player.Name .. " has completed all Kaitun steps!", 5763719, data, true)
		end

		-- First stage -> WEEKEND_LEVEL_FARM
		if
			CONFIG.LEVEL.ONLY_FARM_LEVEL_ON_WEEKEND
			and IsWeekend()
			and (level < CONFIG.LEVEL.WEEKEND_LEVEL_TARGET)
			and continue
		then
			-- Going to namak to farm Level (is weekend, priority)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post(
				"Going to Namak until " .. CONFIG.LEVEL.WEEKEND_LEVEL_TARGET .. " (WEEKEND) (LOBBY)",
				1752220,
				data
			)
			state = `LOBBY_LV_{CONFIG.LEVEL.WEEKEND_LEVEL_TARGET}`
			print("Going to Namak until " .. CONFIG.LEVEL.WEEKEND_LEVEL_TARGET .. " (WEEKEND) (LOBBY)")
			continue = false
		end

		-- Second stage -> MINIMUM_LEVEL_FARM
		if level < CONFIG.LEVEL.MINIMUM_LEVEL_TARGET and continue then
			-- Going to namak until level 11 (LOBBY)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Going to Namak until level 11 (LOBBY)", 1752220, data)
			state = "LOBBY_LV_11"
			print("Going to Namak until level 11 (LOBBY)")
			continue = false
		end

		-- Third stage -> LOBBY_ESCANOR
		if not Lobby.hasEscanor() and continue then
			-- Farming until Escanor (LOBBY)
			loadNousigi("DriedLakeSummon")
			WebhookManager.post("Going to Dried Lake to farm Escanor (LOBBY)", 16705372, data)
			state = "LOBBY_ESCANOR"

			task.spawn(function()
				while true do

					if not Lobby.hasEscanor() then
						task.wait(10)
						continue
					end

					WebhookManager.post(
						"Got Escanor!",
						7419530,
						{ stage = "Lobby", hasEscanor = Lobby.hasEscanor() },
						true
					)
					WebhookManager.message(`> **{Player.Name}** got Escanor!`)
					getgenv().Config["Summoner"]["Auto Summon Summer"] = false

					if Lobby.getRemainingRRFromEventShop("SummerShop") == 200 then
						if icedTea < 300000 then
							WebhookManager.message("> **{Player.Name}** kicking player to impede spending Iced Tea.")
							state = "LOBBY_TEA"
							continue = false
							Player:Kick()
						elseif icedTea >= 300000 then
							Lobby.buyAllRRFromEventShop("SummerShop")
							WebhookManager.message(`> **{Player.Name}** bought all RR from summer shop.`)
							finishAccount()
						end
					end

					
					break
				end
			end)

			continue = false
		end

		if
			SpringRR
			and (Lobby.getRemainingRRFromEventShop("SummerShop") == 200)
			and (Lobby.getRemainingRRFromEventShop("SpringShop") == 200)
			and continue
		then
			if icedTea >= 300000 and flowers >= 300000 then
				Lobby.buyAllRRFromEventShop("SummerShop")
				Lobby.buyAllRRFromEventShop("SpringShop")

				data.summerRR = Lobby.getRemainingRRFromEventShop("SummerShop")
				data.winterRR = Lobby.getRemainingRRFromEventShop("SpringShop")

				WebhookManager.message(`> **{Player.Name}** Bought all RR available on the event shops! (LOBBY)`)
			else
				teleportToTimeChamber()
				state = "LOBBY_TIME_CHAMBER"
				continue = false
			end
		end

		-- FOURTH STAGE
		if not SpringRR and Lobby.getRemainingRRFromEventShop("SummerShop") == 200 and continue then
			if icedTea < 300000 then
				loadNousigi("DriedLake")
				WebhookManager.post("Going to Dried Lake to farm Iced Tea (LOBBY)", 16705372, data)
				state = "LOBBY_TEA"
				continue = false
			elseif icedTea >= 300000 then
				Lobby.buyAllRRFromEventShop("SummerShop")
				WebhookManager.message(`> **{Player.Name}** bought all RR from summer shop.`)
			end
		end

		-- FIFTH STAGE -> FLOWER TIME CHAMBER

		-- Fifth stage -> COMPLETED
		if continue then
			finishAccount()
		end
	end

	-- IN-GAME LOGIC
	if isGame() then
		local continue = true
		local data = {
			hasEscanor = tostring(Game.hasEscanor()),
			stage = Game.getStage(),
		}

		-- First stage -> WEEKEND_LEVEL_FARM
		if IsWeekend() and (level < CONFIG.LEVEL.WEEKEND_LEVEL_TARGET) and continue then
			-- Farming until level 50 (IN-GAME)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post(
				"Farming Namak until " .. CONFIG.LEVEL.WEEKEND_LEVEL_TARGET .. " (WEEKEND) (IN-GAME)",
				5763719,
				data
			)
			state = `GAME_LV_{CONFIG.LEVEL.WEEKEND_LEVEL_TARGET}`
			print("Going to Namak until " .. CONFIG.LEVEL.WEEKEND_LEVEL_TARGET .. " (WEEKEND) (IN-GAME)")
			continue = false

			-- Checking level (weekend, farming til 50)
			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "Level" then
					return
				end

				if getAttribute("Level") >= CONFIG.LEVEL.WEEKEND_LEVEL_TARGET then
					WebhookManager.post(
						"Reached level " .. CONFIG.LEVEL.WEEKEND_LEVEL_TARGET .. ", going back to lobby",
						5763719,
						data
					)
					teleportToLobby()
				end

				if Game.getStage() ~= "Stage1" then
					WebhookManager.post(
						"The player is in " .. Game.getStage() .. ", going back to lobby",
						5763719,
						data
					)
					teleportToLobby()
				end

				if not IsWeekend() then
					WebhookManager.post("It's no longer weekend, going back to lobby", 5763719, data)
					teleportToLobby()
				end
			end)
		end

		-- Second stage -> MINIMUM_LEVEL_FARM
		if level < CONFIG.LEVEL.MINIMUM_LEVEL_TARGET and continue then
			-- Farming until level 11 (IN-GAME)
			loadNousigi("NamakLevelFarm")
			WebhookManager.post("Farming Namak until level 11 (IN-GAME)", 5763719, data)
			print("Going to Namak until level 11 (IN-GAME)")
			state = "GAME_LV_11"
			continue = false

			-- Checking Level (Namak, first step of kaitun)
			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "Level" then
					return
				end

				if
					(not IsWeekend() and getAttribute("Level") >= CONFIG.LEVEL.MINIMUM_LEVEL_TARGET)
					or (IsWeekend() and getAttribute("Level") >= CONFIG.LEVEL.WEEKEND_LEVEL_TARGET)
				then
					teleportToLobby()
				end
			end)
		end

		if not Game.hasEscanor() and continue then
			-- Farming until Escanor (IN-GAME)
			loadNousigi("DriedLakeSummon")
			WebhookManager.post("Going to Dried Lake to farm Escanor (IN-GAME)", 5763719, data)
			state = "GAME_ESCANOR"
			continue = false

			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "IcedTea" and attribute ~= "Level" then
					return
				end

				if getAttribute("Level") < CONFIG.LEVEL.MINIMUM_LEVEL_TARGET then
					WebhookManager.message(
						`> *({Player.Name})* Level is below {CONFIG.LEVEL.MINIMUM_LEVEL_TARGET} but is farming escanor? going back to lobby!`
					)
					teleportToLobby()
					return
				end

				-- Iced tea Check
				if getAttribute("IcedTea") >= CONFIG.ICED_TEA_TO_SUMMON then
					WebhookManager.message(
						`> *({Player.Name})* has {getAttribute("IcedTea")} Iced Tea, going back to lobby to summon Escanor!`
					)
					teleportToLobby()
					return
				end

				-- Goes back to lobby if weekend started and level is below target
				if
					CONFIG.LEVEL.ONLY_FARM_LEVEL_ON_WEEKEND
					and IsWeekend()
					and getAttribute("Level") < CONFIG.LEVEL.WEEKEND_LEVEL_TARGET
				then
					WebhookManager.message(
						`> *({Player.Name})* It's now weekend and level is below {CONFIG.LEVEL.WEEKEND_LEVEL_TARGET}, going back to lobby!`
					)
					teleportToLobby()
					return
				end
			end)
		end

		if Game.hasEscanor() and continue then
			loadNousigi("DriedLake")
			WebhookManager.post("Farming Iced Tea (IN-GAME)", 5763719, data)
			state = "GAME_TEA"
			continue = false

			Player.AttributeChanged:Connect(function(attribute)
				if attribute ~= "IcedTea" and attribute ~= "Level" then
					return
				end

				-- Iced tea Check
				if getAttribute("IcedTea") >= 300000 then
					WebhookManager.message(
						`> *{Player.Name}* has {getAttribute("IcedTea")} Iced Tea, going back to lobby to buy RR!`
					)
					teleportToLobby()
					return
				end
			end)
		end
	end

	if isTimeChamber() then
		if not SpringRR then
			WebhookManager.message(
				`> *{Player.Name}* is in time chamber but doesn't need to be here, going back to lobby...`
			)
			teleportToLobby()
			return
		end
		WebhookManager.post("Farming flowers (TIME CHAMBER)", 5763719, nil)
		state = "TIME_CHAMBER"
		-- Checking if the player has enough resources
		Player.AttributeChanged:Connect(function(attribute)
			print("[AttributeChanged] (TimeChamber):", attribute)

			if attribute ~= "IcedTea" then
				return
			end

			-- Sending status
			local options = {
				Url = CONFIG.WEBHOOK_URL,
				Method = "POST",
				Body = HTTP:JSONEncode({
					["embeds"] = {
						{
							["title"] = "TIME CHAMBER",
							["description"] = "Farming Iced Tea and Flowers, last stage boys!",
							["color"] = 65280,
							["fields"] = {
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
									["name"] = "RR's",
									["value"] = tostring(getAttribute("TraitRerolls")),
									["inline"] = true,
								},
								{
									["name"] = "Gems / Gold",
									["value"] = `{getAttribute("Gems")} / {getAttribute("Gold")}`,
									["inline"] = true,
								},
							},
						},
					},
				}),
			}

			request(options)

			if (getAttribute("IcedTea") >= 300000) and (getAttribute("Flowers") >= 300000) then
				WebhookManager.message(`> *{Player.Name}* has enough Iced Tea and Flowers, going back to lobby!`)
				teleportToLobby()
			end
		end)
	end
end

start()

-- Spreadsheet Handler
task.spawn(function()
	local ss = CONFIG.SPREADSHEET_REST_URL

	local function get(url)
		local options = {
			Url = url,
			Method = "GET",
			Headers = {
				["Content-Type"] = "application/json",
				["X-Api-Key"] = CONFIG.API_KEY,
			},
		}

		return request(options).Body
	end

	local function post(url, body: string)
		local options = {
			Url = url,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["X-Api-Key"] = CONFIG.API_KEY,
			},
			Body = body,
		}

		return request(options).Body
	end

	local function patch(url, body: string)
		local options = {
			Url = url,
			Method = "PATCH",
			Headers = {
				["Content-Type"] = "application/json",
				["X-Api-Key"] = CONFIG.API_KEY,
			},
			Body = body,
		}

		return request(options).Body
	end

	local function isPlayerinSS(playerDataJson)
		if #HTTP:JSONDecode(playerDataJson) <= 0 then
			return false
		else
			return true
		end
	end

	local function updateInfo(
		grindState,
		level,
		rr,
		icedtea,
		flowers,
		currency,
		hasEscanor,
		hasFalcon,
		remainingRRSummer,
		remainingRRSpring
	)
		print("Updating info to spreadsheet...")

		local playerDataString = `{ss}/Username/*{Player.Name}*`
		local playerDataJson = get(playerDataString)
		print(playerDataJson)

		local updatedInfo = {
			Username = Player.Name,
			Node = "VPS-1",
			Grinding = grindState,
			Level = level,
			TraitRerolls = rr,
			IcedTea = icedtea,
			Flowers = flowers,
			["Gems / Gold"] = currency,
			HasEscanor = hasEscanor or nil,
			HasFalcon = hasFalcon or nil,
			LeftSummerRR = remainingRRSummer or nil,
			LeftSpringRR = remainingRRSpring or nil,
			UPDATED = getBrazilianTimestamp(),
		}

		if isPlayerinSS(playerDataJson) then
			print(patch(playerDataString, HTTP:JSONEncode(updatedInfo)))
		else
			print(post(ss, HTTP:JSONEncode(updatedInfo)))
		end
	end

	while true do
		print("Updating info...")

		if isLobby() then
			updateInfo(
				state,
				getAttribute("Level"),
				getAttribute("TraitRerolls"),
				getAttribute("IcedTea"),
				getAttribute("Flowers"),
				`{getAttribute("Gems")} / {getAttribute("Gold")}`,
				tostring(Lobby.hasEscanor()),
				"N/A",
				Lobby.getRemainingRRFromEventShop("SummerShop"),
				Lobby.getRemainingRRFromEventShop("SpringShop")
			)
		end

		if isGame() then
			updateInfo(
				state,
				getAttribute("Level"),
				getAttribute("TraitRerolls"),
				getAttribute("IcedTea"),
				getAttribute("Flowers"),
				`{getAttribute("Gems")} / {getAttribute("Gold")}`,
				Game.hasEscanor(),
				"N/A"
			)
		end

		if isTimeChamber() then
			updateInfo(
				state,
				getAttribute("Level"),
				getAttribute("TraitRerolls"),
				getAttribute("IcedTea"),
				getAttribute("Flowers"),
				`{getAttribute("Gems")} / {getAttribute("Gold")}`
			)

			break
		end

		task.wait(14400) -- 4 hours
	end
end)

function getBrazilianTimestamp()
	-- Obter data atual em UTC
	local currentUTC = os.date("!*t", os.time())

	-- Ajustar para UTC-3 (Brasil)
	currentUTC.hour = currentUTC.hour - 3

	-- Se a hora ficar negativa, ajustar para o dia anterior
	if currentUTC.hour < 0 then
		currentUTC.hour = currentUTC.hour + 24
		currentUTC.day = currentUTC.day - 1

		-- Verificar se precisamos ajustar o mês/ano
		if currentUTC.day == 0 then
			currentUTC.month = currentUTC.month - 1

			-- Ajustar para dezembro do ano anterior
			if currentUTC.month == 0 then
				currentUTC.month = 12
				currentUTC.year = currentUTC.year - 1
			end

			-- Definir para o último dia do mês anterior
			local daysInMonth = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
			-- Verificar ano bissexto
			if
				currentUTC.month == 2
				and (currentUTC.year % 4 == 0 and (currentUTC.year % 100 ~= 0 or currentUTC.year % 400 == 0))
			then
				daysInMonth[2] = 29
			end
			currentUTC.day = daysInMonth[currentUTC.month]
		end
	end

	-- Converter a data ajustada de volta para timestamp
	return os.time(currentUTC)
end
