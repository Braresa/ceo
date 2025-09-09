local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local StarterPlayer = game:GetService("StarterPlayer")
local ClickToMove = require(StarterPlayer.StarterPlayerScripts.PlayerModule.ControlModule.ClickToMoveController).new(Enum.ContextActionPriority.Medium.Value)
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local TimeChamberProximityPrompt = game.Workspace.MainLobby.NPC:WaitForChild("Rocket"):WaitForChild("Time Chamber")
local position = TimeChamberProximityPrompt.Parent.PrimaryPart.Position
-- function ClickToMove:MoveTo(position, showPath, useDirectPath)
ClickToMove:MoveTo(position, true, false)
