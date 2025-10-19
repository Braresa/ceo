local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local hui = gethui()
local gui = Instance.new("ScreenGui", hui)
gui.Name = "OPLKJ"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(1, 0, 1, 0) -- Full screen size
frame.Position = UDim2.new(0, 0, 0, 0) -- Top-left corner
frame.BackgroundColor3 = Color3.new(1, 1, 1) -- White color
frame.ZIndex = 999999 -- Ensure it's on top of other UI elements

local textLabel = Instance.new("TextLabel", frame)
textLabel.Size = UDim2.new(0.8, 0, 0.3, 0)
textLabel.Position = UDim2.new(0.5, -100, 0.5, -25)
textLabel.BackgroundTransparency = 1
textLabel.Text = "DONE"
textLabel.TextColor3 = Color3.new(0, 0, 0)
textLabel.TextScaled = true
textLabel.Font = Enum.Font.SourceSansBold
textLabel.ZIndex = frame.ZIndex + 1