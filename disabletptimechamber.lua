local AFKChamberClient = require(game:GetService("StarterPlayer").Modules.Miscellaneous.AFKChamberClient)
local AFKEvent = game:GetService("ReplicatedStorage").Networking.AFKEvent
local afkConnection = getconnections(AFKEvent.OnClientEvent)[1]
local initFunction = AFKChamberClient._Init



afkConnection:Fire()


