local webhookUrl = getgenv().KaitunWebhook
local http = game:GetService("HttpService")
local player = game:GetService("Players").LocalPlayer


----------- CONFIG

local levelTarget = 11
local debug = true

function postWebhook(body)

	if typeof(body) == "string" then
		body = http:JSONEncode({
			["content"] = body
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
			["Content-Type"] = "application/json"
		}
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
    end

    local replicatedStorage = game:GetService("ReplicatedStorage")
    local gameHandler = require(replicatedStorage.Modules.Gameplay.GameHandler)

    return gameHandler.GameData.Stage
end

function getIcedTea(): number
	for i = 1,20 do

		if player:GetAttribute("IcedTea") then
			break
		end

		task.wait(1)
	end

    return player:GetAttribute("IcedTea")
end

function getLevel(): number
    for i = 1,20 do

		if player:GetAttribute("Level") then
			break
		end

		task.wait(1)
	end

	return player:GetAttribute("Level")
end

local haveEscanor = false

	local units

	if(isLobby()) then
		if debug then postWebhook("In lobby, trying to check escanor status...") end
		local ownedUnitsHandler = require(game:GetService("StarterPlayer").Modules.Interface.Loader.Gameplay.Units.OwnedUnitsHandler)
		units = ownedUnitsHandler:GetOwnedUnits()
	else
		if debug then postWebhook("In Stage, trying to check escanor status...") end
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

if getLevel() < levelTarget then
	loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()

	local embed = {
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = "Player " .. player.Name .. " is farming until level " .. levelTarget .. "!",
				["color"] = 16711680,
				["fields"] = {
					{
						["name"] = "Current Level",
						["value"] = tostring(getLevel()),
						["inline"] = true
					},
					{
						["name"] = "Current Iced Tea",
						["value"] = tostring(getIcedTea()),
						["inline"] = true
					},
					{
						["name"] = "Has Escanor?",
						["value"] = tostring(hasEscanor()),
						["inline"] = true
					},
					{
						["name"] = "Game Stage",
						["value"] = getStage(),
						["inline"] = true
					},
				},
				["footer"] = {
					["text"] = "Made by dotwired.org"
				}
			}
		}
	}

	postWebhook(embed)
elseif getLevel() >= levelTarget and not hasEscanor() then
	loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()

		local embed = {
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = "Player " .. player.Name .. " is farming until getting escanor!",
				["color"] = 16711680,
				["fields"] = {
					{
						["name"] = "Current Level",
						["value"] = tostring(getLevel()),
						["inline"] = true
					},
					{
						["name"] = "Current Iced Tea",
						["value"] = tostring(getIcedTea()),
						["inline"] = true
					},
					{
						["name"] = "Has Escanor?",
						["value"] = tostring(hasEscanor()),
						["inline"] = true
					},
					{
						["name"] = "Game Stage",
						["value"] = getStage(),
						["inline"] = true
					},
				},
				["footer"] = {
					["text"] = "Made by dotwired.org"
				}
			}
		}
	}

	postWebhook(embed)
	getgenv().Config["Summoner"]["Auto Summon Summer"] = true
elseif getLevel() >= levelTarget and hasEscanor() and getIcedTea() < 300000 then
	loadstring(requestGet("https://paste.dotwired.org/Dried%20Lake.txt"))()

	local embed = {
		["embeds"] = {
			{
				["title"] = "Kaitun dotwired",
				["description"] = "Player " .. player.Name .. " is farming until 300k iced tea!",
				["color"] = 16711680,
				["fields"] = {
					{
						["name"] = "Current Level",
						["value"] = tostring(getLevel()),
						["inline"] = true
					},
					{
						["name"] = "Current Iced Tea",
						["value"] = tostring(getIcedTea()),
						["inline"] = true
					},
					{
						["name"] = "Has Escanor?",
						["value"] = tostring(hasEscanor()),
						["inline"] = true
					},
					{
						["name"] = "Game Stage",
						["value"] = getStage(),
						["inline"] = true
					},
				},
				["footer"] = {
					["text"] = "Made by dotwired.org"
				}
			}
		}
	}

	postWebhook(embed)
	
	getgenv().Config["Summoner"]["Auto Summon Summer"] = false
elseif getLevel() >= levelTarget and hasEscanor() and getIcedTea() >= 300000 then
	-- Account Done!
	postWebhook({["content"] = "Player " .. player.Name .. " reached level " .. getLevel() .. " and has Escanor! Doing Namak act 1"})
	loadstring(requestGet("https://paste.dotwired.org/Namak.txt"))()
end


loadstring(requestGet("https://nousigi.com/loader.lua"))()


task.defer(function()
	while true do
		if getLevel() >= levelTarget and getStage() == "Stage1" and not hasEscanor() then
			postWebhook("Player " .. player.Name .. " reached level " .. getLevel() .. ", getting back to lobby...")
			player:Kick("Reached target level!")
			break
		end

		if getIcedTea() >= 375000 and getStage() == "Summer" and not hasEscanor() then
			postWebhook("Player " .. player.Name .. " reached 375k Iced Tea, getting back to lobby...")
			player:Kick("Reached 375k Iced Tea!")
			break
		elseif getIcedTea() >= 300000 and getStage() == "Summer" and hasEscanor() then
			postWebhook("@everyone Player " .. player.Name .. " reached 300k Iced Tea and has Escanor, getting back to lobby...")
			player:Kick("Reached 300k Iced Tea and has Escanor!")
			break
		end

		task.wait(30)
	end
end)